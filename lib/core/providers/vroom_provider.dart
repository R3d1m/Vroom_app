import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/ride_post.dart';
import '../models/trip_request.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';

class VroomProvider extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  final VroomApiService _apiService = VroomApiService();

  // Authentication State
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  // Current logged in user
  UserModel _currentUser = VroomMockData.currentUser;
  UserModel get currentUser => _currentUser;

  // Active role mode
  UserRoleMode get activeMode => _currentUser.activeMode;

  // All active ride posts
  List<RidePost> _ridePosts = [];
  List<RidePost> get ridePosts => _ridePosts;

  // Passenger active broadcast requests
  GroupTripRequest? _activeGroupRequest;
  GroupTripRequest? get activeGroupRequest => _activeGroupRequest;

  // Confirmed bookings & ride history
  final List<ConfirmedBooking> _bookings = VroomMockData.getInitialBookings();
  List<ConfirmedBooking> get bookings => _bookings;

  ConfirmedBooking? get activeBooking {
    try {
      return _bookings.firstWhere(
        (b) =>
            isParticipantOf(b) &&
            b.tripStatus != TripLifecycleStatus.completed &&
            b.tripStatus != TripLifecycleStatus.cancelled,
      );
    } catch (_) {
      return null;
    }
  }

  // Deduplicate internal bookings list by ridePostId + passenger and ID
  void _deduplicateBookings() {
    final seenKeys = <String>{};
    final unique = <ConfirmedBooking>[];
    for (final b in _bookings) {
      final passKey = b.passenger.id.isNotEmpty
          ? b.passenger.id
          : (b.passenger.phone.isNotEmpty ? b.passenger.phone : b.passenger.name.trim().toLowerCase());
      final key = '${b.ridePostId}_$passKey';
      if (!seenKeys.contains(key) && !seenKeys.contains(b.id)) {
        seenKeys.add(key);
        seenKeys.add(b.id);
        unique.add(b);
      }
    }
    _bookings.clear();
    _bookings.addAll(unique);
  }

  // Pending request for current passenger waiting for rider approval
  GroupTripRequest? get pendingPassengerRequest {
    if (_activeGroupRequest != null && _activeGroupRequest!.status == GroupRequestStatus.pending) {
      final targetRideIds = _activeGroupRequest!.subRequests.map((s) => s.ridePostId).toSet();
      final hasActiveBookingForThisRequest = _bookings.any((b) =>
          targetRideIds.contains(b.ridePostId) &&
          b.tripStatus != TripLifecycleStatus.cancelled &&
          b.tripStatus != TripLifecycleStatus.completed &&
          (b.passenger.id == _activeGroupRequest!.passenger.id ||
              (b.passenger.phone.isNotEmpty && b.passenger.phone == _activeGroupRequest!.passenger.phone) ||
              (b.passenger.name.isNotEmpty &&
                  _activeGroupRequest!.passenger.name.isNotEmpty &&
                  b.passenger.name.trim().toLowerCase() == _activeGroupRequest!.passenger.name.trim().toLowerCase())));
      if (hasActiveBookingForThisRequest) {
        _activeGroupRequest!.status = GroupRequestStatus.accepted;
        return null;
      }
      return _activeGroupRequest;
    }

    try {
      return _allGroupRequests.firstWhere(
        (g) {
          if (g.status != GroupRequestStatus.pending) return false;
          final isMe = g.passenger.id == _currentUser.id ||
              (_currentUser.email.isNotEmpty && g.passenger.email.toLowerCase() == _currentUser.email.toLowerCase()) ||
              (_currentUser.phone.isNotEmpty && g.passenger.phone == _currentUser.phone);
          if (!isMe) return false;

          final targetRideIds = g.subRequests.map((s) => s.ridePostId).toSet();
          final hasActiveBooking = _bookings.any((b) =>
              targetRideIds.contains(b.ridePostId) &&
              b.tripStatus != TripLifecycleStatus.cancelled &&
              b.tripStatus != TripLifecycleStatus.completed &&
              (b.passenger.id == g.passenger.id ||
                  (b.passenger.phone.isNotEmpty && b.passenger.phone == g.passenger.phone) ||
                  (b.passenger.name.isNotEmpty &&
                      g.passenger.name.isNotEmpty &&
                      b.passenger.name.trim().toLowerCase() == g.passenger.name.trim().toLowerCase())));
          return !hasActiveBooking;
        },
      );
    } catch (_) {
      return null;
    }
  }

  // Active / Confirmed bookings for current passenger
  List<ConfirmedBooking> get passengerActiveBookings {
    final seen = <String>{};
    return _bookings.where(
      (b) {
        if (!isPassengerOfBooking(b)) return false;
        if (b.tripStatus == TripLifecycleStatus.completed || b.tripStatus == TripLifecycleStatus.cancelled) return false;
        final riderKey = b.rider.id.isNotEmpty ? b.rider.id : (b.rider.phone.isNotEmpty ? b.rider.phone : b.rider.name);
        final key = '${b.ridePostId}_$riderKey';
        return seen.add(key) && seen.add(b.id);
      },
    ).toList();
  }

  // Active / Confirmed bookings for current rider (passengers booked on rider's posts)
  List<ConfirmedBooking> get riderConfirmedBookings {
    final seen = <String>{};
    return _bookings.where(
      (b) {
        if (!isRiderOfBooking(b)) return false;
        if (b.tripStatus == TripLifecycleStatus.completed || b.tripStatus == TripLifecycleStatus.cancelled) return false;
        final passKey = b.passenger.id.isNotEmpty ? b.passenger.id : (b.passenger.phone.isNotEmpty ? b.passenger.phone : b.passenger.name);
        final key = '${b.ridePostId}_$passKey';
        return seen.add(key) && seen.add(b.id);
      },
    ).toList();
  }

  // Pending payment booking for passenger
  ConfirmedBooking? get pendingPaymentBooking {
    try {
      return _bookings.firstWhere(
        (b) =>
            isPassengerOfBooking(b) &&
            b.tripStatus == TripLifecycleStatus.completed &&
            b.paymentStatus != PaymentStatus.paid,
      );
    } catch (_) {
      return null;
    }
  }

  // Check if a ride post was posted by the current user (by ID, email, or name)
  bool isRiderOf(RidePost r) {
    if (r.rider.id == _currentUser.id) return true;
    if (r.rider.email.isNotEmpty &&
        _currentUser.email.isNotEmpty &&
        r.rider.email.trim().toLowerCase() == _currentUser.email.trim().toLowerCase()) {
      return true;
    }
    if (r.rider.name.isNotEmpty &&
        _currentUser.name.isNotEmpty &&
        r.rider.name.trim().toLowerCase() == _currentUser.name.trim().toLowerCase()) {
      return true;
    }
    return false;
  }

  // Check if user participated in a booking as rider or passenger
  bool isParticipantOf(ConfirmedBooking b) {
    return isRiderOfBooking(b) || isPassengerOfBooking(b);
  }

  bool isRiderOfBooking(ConfirmedBooking b) {
    final myId = _currentUser.id;
    final myEmail = _currentUser.email.trim().toLowerCase();
    final myName = _currentUser.name.trim().toLowerCase();

    if (b.rider.id == myId) return true;
    if (myEmail.isNotEmpty && b.rider.email.trim().toLowerCase() == myEmail) return true;
    if (myName.isNotEmpty && b.rider.name.trim().toLowerCase() == myName) return true;
    return false;
  }

  bool isPassengerOfBooking(ConfirmedBooking b) {
    final myId = _currentUser.id;
    final myEmail = _currentUser.email.trim().toLowerCase();
    final myName = _currentUser.name.trim().toLowerCase();

    if (b.passenger.id == myId) return true;
    if (myEmail.isNotEmpty && b.passenger.email.trim().toLowerCase() == myEmail) return true;
    if (myName.isNotEmpty && b.passenger.name.trim().toLowerCase() == myName) return true;
    return false;
  }

  // Ride history for current user (completed rides for both rider and passenger)
  List<ConfirmedBooking> get rideHistory {
    final seen = <String>{};
    return _bookings.where((b) {
      if (!isParticipantOf(b)) return false;
      if (b.tripStatus != TripLifecycleStatus.completed) return false;
      final passKey = b.passenger.id.isNotEmpty
          ? b.passenger.id
          : (b.passenger.phone.isNotEmpty ? b.passenger.phone : b.passenger.name.trim().toLowerCase());
      final key = '${b.ridePostId}_$passKey';
      return seen.add(key) && seen.add(b.id);
    }).toList();
  }

  // All pending requests received by riders (Incoming Queue)
  final List<GroupTripRequest> _allGroupRequests = [];
  List<GroupTripRequest> get allGroupRequests => _allGroupRequests;

  // Notifications log
  final List<VroomNotification> _notifications = [];
  List<VroomNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  String? _latestBookingAlert;
  String? get latestBookingAlert => _latestBookingAlert;
  void clearLatestBookingAlert() {
    _latestBookingAlert = null;
    notifyListeners();
  }

  Timer? _pollingTimer;

  bool get _isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  // Real-time background polling for inbound bookings & status updates
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isAuthenticated) {
        loadRequestsFromBackend();
        loadBookingsFromBackend();
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void markAllNotificationsAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    _saveLocalCache();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
    _saveLocalCache();
  }

  VroomProvider() {
    _initializeData();
  }

  void _initializeData() {
    _ridePosts = VroomMockData.getInitialRidePosts();
    _notifications.addAll([
      VroomNotification(
        id: 'notif_welcome',
        title: 'Welcome to VROOM',
        message: 'Peer-to-peer campus ride sharing is live in Chattogram. Travel safe and split fuel costs!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        category: NotificationCategory.system,
        isRead: false,
      ),
      VroomNotification(
        id: 'notif_verified',
        title: 'Profile & Trust Verified',
        message: 'Your institutional ID and NID verification have been approved for campus pooling.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        category: NotificationCategory.security,
        isRead: false,
      ),
    ]);
    _loadSession();
    if (!_isTestEnvironment) {
      startPolling();
    }
  }

  // Load live rides from NeonDB PostgreSQL backend
  Future<void> loadRidesFromBackend() async {
    try {
      final remoteRides = await _apiService.fetchRides();
      if (remoteRides.isNotEmpty) {
        final remoteIds = remoteRides.map((r) => r.id).toSet();
        // Keep only active local rides created by the active user that haven't synced yet
        final localPending = _ridePosts
            .where((r) => !remoteIds.contains(r.id) && isRiderOf(r) && !r.id.startsWith('ride_post_'))
            .toList();
        _ridePosts = [...localPending, ...remoteRides];
        notifyListeners();
        _saveLocalCache();
      }
    } catch (_) {}
  }

  // Load bookings & ride history from NeonDB PostgreSQL backend
  Future<void> loadBookingsFromBackend() async {
    try {
      final remoteBookings = await _apiService.fetchBookings(_currentUser.id);
      if (remoteBookings.isNotEmpty) {
        for (final b in remoteBookings) {
          final existingIdx = _bookings.indexWhere((existing) =>
              existing.id == b.id ||
              (existing.ridePostId == b.ridePostId &&
                  (existing.passenger.id == b.passenger.id ||
                      (existing.passenger.phone.isNotEmpty && existing.passenger.phone == b.passenger.phone) ||
                      (existing.passenger.name.isNotEmpty &&
                          b.passenger.name.isNotEmpty &&
                          existing.passenger.name.trim().toLowerCase() == b.passenger.name.trim().toLowerCase()))) ||
              (existing.pinCode.isNotEmpty && existing.pinCode == b.pinCode));

          if (existingIdx != -1) {
            final existing = _bookings[existingIdx];
            final newerTripStatus = (existing.tripStatus == TripLifecycleStatus.completed ||
                    (existing.tripStatus == TripLifecycleStatus.inProgress && b.tripStatus == TripLifecycleStatus.confirmed))
                ? existing.tripStatus
                : b.tripStatus;
            final newerPayStatus = existing.paymentStatus == PaymentStatus.paid ? existing.paymentStatus : b.paymentStatus;

            _bookings[existingIdx] = b.copyWith(
              tripStatus: newerTripStatus,
              paymentStatus: newerPayStatus,
            );
          } else {
            _bookings.insert(0, b);
          }
        }
        _deduplicateBookings();

        // If current passenger has an active booking, ensure active request is marked accepted
        if (_activeGroupRequest != null) {
          final hasActive = _bookings.any((b) =>
              b.tripStatus != TripLifecycleStatus.cancelled &&
              (b.passenger.id == _activeGroupRequest!.passenger.id ||
                  (b.passenger.phone.isNotEmpty && b.passenger.phone == _activeGroupRequest!.passenger.phone)));
          if (hasActive) {
            _activeGroupRequest!.status = GroupRequestStatus.accepted;
          }
        }

        notifyListeners();
        _saveLocalCache();
      }
      await loadRequestsFromBackend();
    } catch (_) {}
  }

  // Load pending inbound requests for driver/rider from NeonDB
  Future<void> loadRequestsFromBackend() async {
    try {
      final remoteRequests = await _apiService.fetchPendingRequestsForRider(
        _currentUser.id,
        email: _currentUser.email,
        phone: _currentUser.phone,
      );
      if (remoteRequests.isNotEmpty) {
        bool hasNewInbound = false;
        String? latestPassengerName;
        String? latestRoute;

        for (final row in remoteRequests) {
          final grId = row['group_request_id']?.toString() ?? '';
          final subId = row['sub_request_id']?.toString() ?? '';
          final ridePostId = row['ride_post_id']?.toString() ?? '';
          final passId = row['passenger_id']?.toString() ?? '';
          final passPhone = row['passenger_phone']?.toString() ?? '';

          // Skip if booking already exists for this ride and passenger
          final hasBooking = _bookings.any((b) =>
              b.ridePostId == ridePostId &&
              b.tripStatus != TripLifecycleStatus.cancelled &&
              (b.passenger.id == passId ||
                  (passPhone.isNotEmpty && b.passenger.phone == passPhone)));
          if (hasBooking) {
            final existingGrIdx = _allGroupRequests.indexWhere((g) => g.id == grId);
            if (existingGrIdx != -1) {
              _allGroupRequests[existingGrIdx].status = GroupRequestStatus.accepted;
            }
            continue;
          }

          final origName = row['pickup_name'] ?? 'Pickup';
          final destName = row['dropoff_name'] ?? 'Destination';
          final passName = row['passenger_name'] ?? 'Passenger';
          final seats = row['requested_seats'] is int
              ? row['requested_seats'] as int
              : int.tryParse(row['requested_seats']?.toString() ?? '') ?? 1;

          final double parsedFare = double.tryParse(row['fare_per_seat']?.toString() ?? '') ?? 120.0;
          final double parsedRating = double.tryParse(row['passenger_rating']?.toString() ?? '') ?? 5.0;
          final double pickupLat = double.tryParse(row['pickup_lat']?.toString() ?? '') ?? 22.4608;
          final double pickupLng = double.tryParse(row['pickup_lng']?.toString() ?? '') ?? 91.9710;
          final double dropoffLat = double.tryParse(row['dropoff_lat']?.toString() ?? '') ?? 22.3590;
          final double dropoffLng = double.tryParse(row['dropoff_lng']?.toString() ?? '') ?? 91.8215;

          // 1. Notification for the driver if not already added
          final notifId = 'notif_booking_req_$subId';
          if (!_notifications.any((n) => n.id == notifId)) {
            _notifications.insert(
              0,
              VroomNotification(
                id: notifId,
                title: '🚨 New Ride Booking Request!',
                message: '$passName requested $seats seat(s) on your ride ($origName → $destName)',
                timestamp: DateTime.tryParse(row['group_created_at']?.toString() ?? '') ?? DateTime.now(),
                category: NotificationCategory.ride,
                isRead: false,
              ),
            );
            hasNewInbound = true;
            latestPassengerName = passName;
            latestRoute = '$origName → $destName';
          }

          // 2. Add or update _allGroupRequests
          final existingGrIdx = _allGroupRequests.indexWhere((g) => g.id == grId);
          final subItem = SubRequestItem(
            ridePostId: ridePostId,
            riderName: _currentUser.name,
            riderPhone: _currentUser.phone,
            vehicleType: row['vehicle_type']?.toString() ?? 'Motorcycle',
            vehicleModel: row['vehicle_model']?.toString() ?? 'Bike',
            fare: parsedFare,
            status: SubRequestStatus.pending,
          );

          final pickup = LocationPoint(
            id: row['pickup_id']?.toString() ?? 'loc_pick',
            name: origName,
            description: '',
            coordinates: LatLng(pickupLat, pickupLng),
          );

          final dropoff = LocationPoint(
            id: row['dropoff_id']?.toString() ?? 'loc_drop',
            name: destName,
            description: '',
            coordinates: LatLng(dropoffLat, dropoffLng),
          );

          if (existingGrIdx == -1) {
            final passenger = UserModel(
              id: passId,
              name: passName,
              phone: passPhone,
              email: '',
              avatarUrl: row['passenger_avatar'] ?? '',
              universityOrOrg: row['passenger_university'] ?? 'CUET',
              rating: parsedRating,
              totalTrips: 5,
              activeMode: UserRoleMode.passenger,
            );

            _allGroupRequests.insert(
              0,
              GroupTripRequest(
                id: grId,
                passenger: passenger,
                pickup: pickup,
                dropoff: dropoff,
                scheduledDeparture: DateTime.tryParse(row['scheduled_departure']?.toString() ?? '') ?? DateTime.now(),
                requestedSeats: seats,
                status: GroupRequestStatus.pending,
                subRequests: [subItem],
              ),
            );
          } else {
            final gr = _allGroupRequests[existingGrIdx];
            if (!gr.subRequests.any((s) => s.ridePostId == ridePostId)) {
              gr.subRequests.add(subItem);
            }
          }

          // 3. Ensure ride post exists in _ridePosts so that driver matching is seamless
          if (!_ridePosts.any((r) => r.id == ridePostId)) {
            _ridePosts.insert(
              0,
              RidePost(
                id: ridePostId,
                rider: _currentUser,
                origin: pickup,
                destination: dropoff,
                departureTime: DateTime.tryParse(row['scheduled_departure']?.toString() ?? '') ?? DateTime.now(),
                primaryRoute: RouteOption(
                  id: 'route_main',
                  name: row['primary_route_name'] ?? 'Direct Route',
                  viaRoadName: row['primary_route_via'] ?? 'Direct Corridor',
                  distanceKm: 20.0,
                  durationMinutes: 40,
                  polyline: const [],
                ),
                alternateRoutes: const [],
                detourToleranceKm: 2.0,
                totalSeats: 2,
                availableSeats: 2,
                farePerSeat: parsedFare,
                vehicleType: row['vehicle_type'] ?? 'Motorcycle',
                vehiclePlate: row['vehicle_plate'] ?? (_currentUser.vehiclePlate ?? 'Dhaka Metro'),
                vehicleModel: row['vehicle_model'] ?? 'Bike',
                status: RideStatus.scheduled,
              ),
            );
          }
        }

        if (hasNewInbound && latestPassengerName != null) {
          _latestBookingAlert = '🚨 New Booking: $latestPassengerName requested a seat ($latestRoute)';
        }

        notifyListeners();
        _saveLocalCache();
      }
    } catch (_) {}
  }

  // Session persistence and offline state caching via SharedPreferences
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('vroom_session_user');
      final isAuth = prefs.getBool('vroom_is_authenticated') ?? false;
      if (isAuth && userJsonStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(userJsonStr);
        _currentUser = UserModel.fromJson(userMap);
        _isAuthenticated = true;
      }

      // 1. Restore cached ride posts
      final cachedRidesStr = prefs.getString('vroom_cached_rides');
      if (cachedRidesStr != null) {
        final List list = jsonDecode(cachedRidesStr);
        if (list.isNotEmpty) {
          _ridePosts = list.map((item) => RidePost.fromJson(Map<String, dynamic>.from(item))).toList();
        }
      }

      // 2. Restore cached bookings
      final cachedBookingsStr = prefs.getString('vroom_cached_bookings');
      if (cachedBookingsStr != null) {
        final List list = jsonDecode(cachedBookingsStr);
        if (list.isNotEmpty) {
          final restored = list.map((item) => ConfirmedBooking.fromJson(Map<String, dynamic>.from(item))).toList();
          final existingIds = restored.map((b) => b.id).toSet();
          for (final b in _bookings) {
            if (!existingIds.contains(b.id)) {
              restored.add(b);
            }
          }
          _bookings.clear();
          _bookings.addAll(restored);
        }
      }

      // 3. Restore cached group requests
      final cachedReqStr = prefs.getString('vroom_cached_requests');
      if (cachedReqStr != null) {
        final List list = jsonDecode(cachedReqStr);
        if (list.isNotEmpty) {
          _allGroupRequests.clear();
          _allGroupRequests.addAll(list.map((item) => GroupTripRequest.fromJson(Map<String, dynamic>.from(item))));
        }
      }

      // 4. Restore active group request
      final cachedActiveReqStr = prefs.getString('vroom_cached_active_request');
      if (cachedActiveReqStr != null) {
        final Map<String, dynamic> map = jsonDecode(cachedActiveReqStr);
        final restoredReq = GroupTripRequest.fromJson(map);
        if (restoredReq.status == GroupRequestStatus.pending) {
          _activeGroupRequest = restoredReq;
        }
      }

      // 5. Restore cached notifications
      final cachedNotifsStr = prefs.getString('vroom_cached_notifs');
      if (cachedNotifsStr != null) {
        final List list = jsonDecode(cachedNotifsStr);
        if (list.isNotEmpty) {
          _notifications.clear();
          _notifications.addAll(list.map((item) => VroomNotification.fromJson(Map<String, dynamic>.from(item))));
        }
      }

      notifyListeners();

      // Sync latest data from backend with restored user
      await loadRidesFromBackend();
      await loadBookingsFromBackend();
    } catch (_) {}
  }

  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ridesJson = jsonEncode(_ridePosts.map((r) => r.toJson()).toList());
      final bookingsJson = jsonEncode(_bookings.map((b) => b.toJson()).toList());
      final requestsJson = jsonEncode(_allGroupRequests.map((g) => g.toJson()).toList());
      final notifsJson = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString('vroom_cached_rides', ridesJson);
      await prefs.setString('vroom_cached_bookings', bookingsJson);
      await prefs.setString('vroom_cached_requests', requestsJson);
      await prefs.setString('vroom_cached_notifs', notifsJson);
      if (_activeGroupRequest != null) {
        await prefs.setString('vroom_cached_active_request', jsonEncode(_activeGroupRequest!.toJson()));
      } else {
        await prefs.remove('vroom_cached_active_request');
      }
    } catch (_) {}
  }

  Future<void> _saveSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vroom_session_user', jsonEncode(user.toJson()));
      await prefs.setBool('vroom_is_authenticated', true);
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vroom_session_user');
      await prefs.setBool('vroom_is_authenticated', false);
      await prefs.remove('vroom_cached_active_request');
    } catch (_) {}
  }

  // Register new user via API / Database
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRoleMode roleMode,
    String? universityOrOrg,
    String? vehicleType,
    String? vehiclePlate,
    String? vehicleModel,
  }) async {
    final user = await _apiService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      roleMode: roleMode,
      universityOrOrg: universityOrOrg,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
    );
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      await _saveSession(user);
      _addNotification(
        'Account Registered',
        'Welcome to VROOM, ${user.name}! Registered as ${user.activeMode.name.toUpperCase()}',
        category: NotificationCategory.system,
      );
      loadRidesFromBackend();
      loadBookingsFromBackend();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Login user via API / Database
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final user = await _apiService.login(email: email, password: password);
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      await _saveSession(user);
      _addNotification(
        'Session Active',
        'Logged in as ${user.name} (${user.activeMode.name.toUpperCase()})',
        category: NotificationCategory.system,
      );
      loadRidesFromBackend();
      loadBookingsFromBackend();
      if (!_isTestEnvironment) {
        startPolling();
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  // Logout user
  void logout() {
    _isAuthenticated = false;
    _clearSession();
    stopPolling();
    _addNotification('Signed Out', 'Logged out successfully from VROOM session.', category: NotificationCategory.system);
    notifyListeners();
  }

  // Rider: Delete an existing scheduled ride
  void deleteRidePost(String ridePostId) {
    _ridePosts.removeWhere((r) => r.id == ridePostId);
    for (final gr in _allGroupRequests) {
      for (final sub in gr.subRequests) {
        if (sub.ridePostId == ridePostId && sub.status == SubRequestStatus.pending) {
          sub.status = SubRequestStatus.autoCancelled;
          sub.cancellationReason = 'Ride cancelled by rider';
          sub.updatedAt = DateTime.now();
        }
      }
    }
    _addNotification('Ride Deleted', 'Scheduled ride successfully deleted.', category: NotificationCategory.ride);
    notifyListeners();
    _saveLocalCache();

    // Sync deletion to NeonDB
    _apiService.deleteRide(ridePostId);
  }

  // Rider: Update an existing scheduled ride
  void updateRidePost(RidePost updatedPost) {
    final index = _ridePosts.indexWhere((r) => r.id == updatedPost.id);
    if (index != -1) {
      _ridePosts[index] = updatedPost;
      _addNotification('Ride Updated', 'Scheduled ride details updated.', category: NotificationCategory.ride);
      notifyListeners();
      _saveLocalCache();

      // Sync update to NeonDB
      _apiService.updateRide(updatedPost);
    }
  }

  // Switch between Passenger and Rider mode
  void toggleRoleMode() {
    final newMode = _currentUser.activeMode == UserRoleMode.passenger
        ? UserRoleMode.rider
        : UserRoleMode.passenger;
    _currentUser = _currentUser.copyWith(activeMode: newMode);
    _saveSession(_currentUser);
    notifyListeners();
  }

  void switchModeTo(UserRoleMode mode) {
    if (_currentUser.activeMode != mode) {
      _currentUser = _currentUser.copyWith(activeMode: mode);
      _saveSession(_currentUser);
      notifyListeners();
    }
  }

  // Rider: Post a new scheduled ride (Saves to NeonDB & Local Cache)
  void createRidePost({
    required LocationPoint origin,
    required LocationPoint destination,
    required RouteOption primaryRoute,
    required List<RouteOption> alternateRoutes,
    required double detourToleranceKm,
    required DateTime departureTime,
    required int seats,
    required double farePerSeat,
    required String vehicleType,
    required String vehiclePlate,
    required String vehicleModel,
  }) {
    final localId = 'ride_${_uuid.v4().substring(0, 8)}';
    final newPost = RidePost(
      id: localId,
      rider: _currentUser,
      origin: origin,
      destination: destination,
      primaryRoute: primaryRoute,
      alternateRoutes: alternateRoutes,
      detourToleranceKm: detourToleranceKm,
      departureTime: departureTime,
      totalSeats: seats,
      availableSeats: seats,
      farePerSeat: farePerSeat,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
    );

    _ridePosts.insert(0, newPost);
    _addNotification(
      'Ride Scheduled',
      'Scheduled ride created from ${origin.name} to ${destination.name}',
      category: NotificationCategory.ride,
    );
    notifyListeners();
    _saveLocalCache();

    // Persist to NeonDB database via API
    _apiService
        .createRide(
          rider: _currentUser,
          origin: origin,
          destination: destination,
          primaryRoute: primaryRoute,
          alternateRoutes: alternateRoutes,
          detourToleranceKm: detourToleranceKm,
          departureTime: departureTime,
          seats: seats,
          farePerSeat: farePerSeat,
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate,
          vehicleModel: vehicleModel,
        )
        .then((saved) {
      if (saved != null) {
        final idx = _ridePosts.indexWhere((r) => r.id == localId);
        final postToKeep = RidePost(
          id: saved.id,
          rider: _currentUser,
          origin: saved.origin,
          destination: saved.destination,
          primaryRoute: saved.primaryRoute,
          alternateRoutes: saved.alternateRoutes,
          detourToleranceKm: saved.detourToleranceKm,
          departureTime: saved.departureTime,
          totalSeats: saved.totalSeats,
          availableSeats: saved.availableSeats,
          farePerSeat: saved.farePerSeat,
          vehicleType: saved.vehicleType,
          vehiclePlate: saved.vehiclePlate,
          vehicleModel: saved.vehicleModel,
          status: saved.status,
        );
        if (idx != -1) {
          _ridePosts[idx] = postToKeep;
        } else {
          _ridePosts.insert(0, postToKeep);
        }
        notifyListeners();
        _saveLocalCache();
      }
    });
  }

  // AI / Rule-based Fare Estimation with Automatic Open-Meteo Weather
  // Formula: 50 BDT for 0-5 km, +10 BDT for each additional km.
  // Weather: auto-predicted via Open-Meteo (rain = 1.25x multiplier, clear = 1.0x multiplier).
  Future<Map<String, dynamic>> estimateFare({
    required double distanceKm,
    required String origin,
    required String destination,
    String? weather,
    double? originLat,
    double? originLng,
  }) async {
    return _apiService.estimateFare(
      distanceKm: distanceKm,
      origin: origin,
      destination: destination,
      weather: weather,
      originLat: originLat,
      originLng: originLng,
    );
  }

  // Passenger: Search matching rides by route corridor and optional travel date
  List<RidePost> searchMatchingRides(LatLng pickup, LatLng dropoff, {DateTime? travelDate}) {
    final matches = _ridePosts.where((post) {
      if (isRiderOf(post)) return false;
      if (post.availableSeats <= 0) return false;
      if (post.status != RideStatus.scheduled) return false;
      if (travelDate != null) {
        final postLocal = post.departureTime.toLocal();
        final travelLocal = travelDate.toLocal();
        final sameDay = postLocal.year == travelLocal.year &&
            postLocal.month == travelLocal.month &&
            postLocal.day == travelLocal.day;
        if (!sameDay) return false;
      }
      // Check if pickup and drop-off fall within the rider's selected routes & corridors
      return post.matchesPassengerRoute(pickup, dropoff);
    }).toList();
    matches.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return matches;
  }

  // Passenger: Search matching rides along the corridor on upcoming/other dates
  List<RidePost> searchMatchingRidesOtherDates(LatLng pickup, LatLng dropoff, {required DateTime travelDate}) {
    final matches = _ridePosts.where((post) {
      if (isRiderOf(post)) return false;
      if (post.availableSeats <= 0) return false;
      if (post.status != RideStatus.scheduled) return false;
      final postLocal = post.departureTime.toLocal();
      final travelLocal = travelDate.toLocal();
      final sameDay = postLocal.year == travelLocal.year &&
          postLocal.month == travelLocal.month &&
          postLocal.day == travelLocal.day;
      if (sameDay) return false;
      return post.matchesPassengerRoute(pickup, dropoff);
    }).toList();
    matches.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return matches;
  }

  // Passenger: Send broadcast / group request to matching riders
  void sendGroupRequest({
    required LocationPoint pickup,
    required LocationPoint dropoff,
    required DateTime scheduledDeparture,
    required List<RidePost> targetRides,
    int requestedSeats = 1,
  }) {
    if (targetRides.isEmpty) return;

    // Filter out rides that are already completed, full, or already booked by this passenger in active trips
    final bookedRidePostIds = _bookings
        .where((b) =>
            b.passenger.id == _currentUser.id &&
            b.tripStatus != TripLifecycleStatus.cancelled &&
            b.tripStatus != TripLifecycleStatus.completed)
        .map((b) => b.ridePostId)
        .toSet();

    // Deduplicate rides and avoid rides already booked
    final uniqueTargetRides = <RidePost>[];
    final seenRideIds = <String>{};
    for (final ride in targetRides) {
      if (!bookedRidePostIds.contains(ride.id) &&
          ride.status == RideStatus.scheduled &&
          ride.availableSeats >= requestedSeats &&
          !seenRideIds.contains(ride.id)) {
        seenRideIds.add(ride.id);
        uniqueTargetRides.add(ride);
      }
    }

    if (uniqueTargetRides.isEmpty) return;

    // Cancel any previous active pending requests from this passenger
    for (final gr in _allGroupRequests) {
      if (gr.passenger.id == _currentUser.id && gr.status == GroupRequestStatus.pending) {
        gr.status = GroupRequestStatus.cancelled;
        for (final sub in gr.subRequests) {
          if (sub.status == SubRequestStatus.pending) {
            sub.status = SubRequestStatus.autoCancelled;
            sub.cancellationReason = 'Superceded by updated broadcast';
            sub.updatedAt = DateTime.now();
          }
        }
      }
    }

    final subRequests = uniqueTargetRides.map((ride) {
      return SubRequestItem(
        ridePostId: ride.id,
        riderName: ride.rider.name,
        riderPhone: ride.rider.phone,
        vehicleType: ride.vehicleType,
        vehicleModel: ride.vehicleModel,
        fare: ride.farePerSeat,
        status: SubRequestStatus.pending,
      );
    }).toList();

    final groupRequest = GroupTripRequest(
      id: 'greq_${_uuid.v4().substring(0, 8)}',
      passenger: _currentUser,
      pickup: pickup,
      dropoff: dropoff,
      scheduledDeparture: scheduledDeparture,
      requestedSeats: requestedSeats,
      status: GroupRequestStatus.pending,
      subRequests: subRequests,
    );

    _activeGroupRequest = groupRequest;
    _allGroupRequests.insert(0, groupRequest);

    // 1. Notification for passenger
    _addNotification(
      'Ride Request Sent',
      'Request sent for ${pickup.name} → ${dropoff.name} to ${uniqueTargetRides.length} matching rider(s).',
      category: NotificationCategory.ride,
    );

    // 2. Notification for driver(s) / riders
    for (final ride in uniqueTargetRides) {
      _addNotification(
        'New Ride Booking Request',
        '${_currentUser.name} requested $requestedSeats seat(s) on your ride (${ride.origin.name} → ${ride.destination.name})',
        category: NotificationCategory.ride,
      );
    }
    _latestBookingAlert = '🚨 New Booking: ${_currentUser.name} requested $requestedSeats seat(s) (${pickup.name} → ${dropoff.name})';

    notifyListeners();
    _saveLocalCache();

    // Sync broadcast request to NeonDB API
    _apiService.broadcastRequest(
      passengerId: _currentUser.id,
      passengerEmail: _currentUser.email,
      passengerName: _currentUser.name,
      passengerPhone: _currentUser.phone,
      pickup: pickup,
      dropoff: dropoff,
      scheduledDeparture: scheduledDeparture,
      requestedSeats: requestedSeats,
      targetRideIds: uniqueTargetRides.map((r) => r.id).toList(),
    );
  }

  // Rider: Get pending requests directed to this rider's posts
  List<Map<String, dynamic>> getPendingRequestsForRider(String riderId) {
    final List<Map<String, dynamic>> result = [];
    final myRides = _ridePosts.where((r) => isRiderOf(r)).toList();
    final myRideIds = myRides.map((r) => r.id).toSet();
    final allRideIds = _ridePosts.map((r) => r.id).toSet();

    for (final groupReq in _allGroupRequests) {
      if (groupReq.status != GroupRequestStatus.pending) continue;

      for (final sub in groupReq.subRequests) {
        if (sub.status == SubRequestStatus.pending) {
          // Check if this sub-request's passenger already has an active or confirmed booking on this specific ride
          final isAlreadyBooked = _bookings.any((b) =>
              b.ridePostId == sub.ridePostId &&
              b.tripStatus != TripLifecycleStatus.cancelled &&
              b.tripStatus != TripLifecycleStatus.completed &&
              (b.passenger.id == groupReq.passenger.id ||
                  (b.passenger.phone.isNotEmpty && b.passenger.phone == groupReq.passenger.phone) ||
                  (b.passenger.name.isNotEmpty &&
                      groupReq.passenger.name.isNotEmpty &&
                      b.passenger.name.trim().toLowerCase() == groupReq.passenger.name.trim().toLowerCase())));

          if (isAlreadyBooked) continue;

          final isMyRide = myRideIds.contains(sub.ridePostId);
          final matchesRider = (sub.riderPhone.isNotEmpty && sub.riderPhone == _currentUser.phone) ||
              (sub.riderName.isNotEmpty && sub.riderName.trim().toLowerCase() == _currentUser.name.trim().toLowerCase()) ||
              allRideIds.contains(sub.ridePostId);

          if (isMyRide || matchesRider) {
            RidePost ridePost;
            if (allRideIds.contains(sub.ridePostId)) {
              ridePost = _ridePosts.firstWhere((r) => r.id == sub.ridePostId);
            } else {
              ridePost = RidePost(
                id: sub.ridePostId,
                rider: _currentUser,
                origin: groupReq.pickup,
                destination: groupReq.dropoff,
                departureTime: groupReq.scheduledDeparture,
                primaryRoute: RouteOption(
                  id: 'route_main',
                  name: 'Direct Route',
                  viaRoadName: 'Direct Corridor',
                  distanceKm: 20.0,
                  durationMinutes: 40,
                  polyline: const [],
                ),
                alternateRoutes: const [],
                detourToleranceKm: 2.0,
                totalSeats: 2,
                availableSeats: 2,
                farePerSeat: sub.fare,
                vehicleType: sub.vehicleType,
                vehiclePlate: _currentUser.vehiclePlate ?? 'Dhaka Metro',
                vehicleModel: sub.vehicleModel,
                status: RideStatus.scheduled,
              );
            }

            result.add({
              'groupRequest': groupReq,
              'subRequest': sub,
              'ridePost': ridePost,
            });
          }
        }
      }
    }
    return result;
  }

  // Core Feature: Rider Accepts -> ATOMIC AUTO-CANCELLATION of all other requests
  void acceptRideRequest({
    required String groupRequestId,
    required String ridePostId,
    required UserModel acceptingRider,
  }) {
    final groupIndex = _allGroupRequests.indexWhere((g) => g.id == groupRequestId);
    if (groupIndex == -1) return;

    final groupReq = _allGroupRequests[groupIndex];
    if (groupReq.status != GroupRequestStatus.pending) return;

    // Find the RidePost
    final rideIndex = _ridePosts.indexWhere((r) => r.id == ridePostId);
    if (rideIndex == -1) return;
    final ride = _ridePosts[rideIndex];

    if (ride.availableSeats < groupReq.requestedSeats) {
      _addNotification(
        'Request Error',
        'Not enough seats available on this ride.',
        category: NotificationCategory.ride,
      );
      return;
    }

    // 1. Lock and decrement seat
    ride.availableSeats -= groupReq.requestedSeats;

    // 2. Mark Group Request as ACCEPTED
    groupReq.status = GroupRequestStatus.accepted;
    groupReq.acceptedRidePostId = ridePostId;
    groupReq.acceptedRiderId = acceptingRider.id;

    // 3. ATOMIC CASCADE: Mark accepted sub-request and AUTO-CANCEL all sibling requests in this group
    for (final sub in groupReq.subRequests) {
      if (sub.ridePostId == ridePostId) {
        sub.status = SubRequestStatus.accepted;
        sub.updatedAt = DateTime.now();
      } else {
        // Auto-cancel other riders
        sub.status = SubRequestStatus.autoCancelled;
        sub.cancellationReason = 'Passenger ride confirmed with ${acceptingRider.name}';
        sub.updatedAt = DateTime.now();
      }
    }

    // 4. AUTO-CANCEL ALL OTHER PENDING GROUP REQUESTS FOR THIS PASSENGER
    for (final gr in _allGroupRequests) {
      if (gr.passenger.id == groupReq.passenger.id && gr.id != groupReq.id && gr.status == GroupRequestStatus.pending) {
        gr.status = GroupRequestStatus.cancelled;
        for (final sub in gr.subRequests) {
          if (sub.status == SubRequestStatus.pending) {
            sub.status = SubRequestStatus.autoCancelled;
            sub.cancellationReason = 'Passenger ride confirmed with ${acceptingRider.name}';
            sub.updatedAt = DateTime.now();
          }
        }
      }
    }

    // Clear active broadcast for passenger
    if (_activeGroupRequest?.passenger.id == groupReq.passenger.id) {
      _activeGroupRequest = null;
    }

    // 5. Generate Confirmed Booking with 4-digit Security PIN
    final booking = ConfirmedBooking(
      id: 'book_${_uuid.v4().substring(0, 8)}',
      ridePostId: ridePostId,
      rider: acceptingRider,
      passenger: groupReq.passenger,
      pickup: groupReq.pickup,
      dropoff: groupReq.dropoff,
      scheduledTime: groupReq.scheduledDeparture,
      fare: ride.farePerSeat * groupReq.requestedSeats,
      pinCode: '${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}',
      tripStatus: TripLifecycleStatus.confirmed,
    );

    // Check if booking already exists for this ride and passenger
    final alreadyBooked = _bookings.any((b) =>
        b.ridePostId == ridePostId &&
        b.tripStatus != TripLifecycleStatus.cancelled &&
        (b.passenger.id == groupReq.passenger.id ||
            (b.passenger.phone.isNotEmpty && b.passenger.phone == groupReq.passenger.phone) ||
            (b.passenger.name.isNotEmpty &&
                groupReq.passenger.name.isNotEmpty &&
                b.passenger.name.trim().toLowerCase() == groupReq.passenger.name.trim().toLowerCase())));

    if (!alreadyBooked) {
      _bookings.insert(0, booking);
    }
    _deduplicateBookings();

    // Notification for passenger
    _addNotification(
      'Ride Confirmed with ${acceptingRider.name}! (PIN: ${booking.pinCode})',
      'Your ride from ${booking.pickup.name} to ${booking.dropoff.name} is confirmed. Driver: ${acceptingRider.name} (${acceptingRider.phone}).',
      category: NotificationCategory.ride,
    );

    // Notification for driver
    _addNotification(
      'Passenger Confirmed! (PIN: ${booking.pinCode})',
      '${groupReq.passenger.name} booked a seat on your ride from ${groupReq.pickup.name} to ${groupReq.dropoff.name}. Contact: ${groupReq.passenger.phone}',
      category: NotificationCategory.ride,
    );

    notifyListeners();
    _saveLocalCache();

    // Sync acceptance & atomic auto-cancellation to NeonDB API
    _apiService.acceptRequest(
      groupRequestId: groupRequestId,
      ridePostId: ridePostId,
      riderId: acceptingRider.id,
    ).then((remoteBooking) {
      if (remoteBooking != null && remoteBooking['id'] != null) {
        final backendId = remoteBooking['id'].toString();
        final localIdx = _bookings.indexWhere((b) => b.id == booking.id);
        if (localIdx != -1) {
          _bookings[localIdx] = _bookings[localIdx].copyWith(id: backendId);
          _saveLocalCache();
        }
      }
    });
  }

  // Rider: Decline single request
  void declineRideRequest({
    required String groupRequestId,
    required String ridePostId,
  }) {
    final groupIndex = _allGroupRequests.indexWhere((g) => g.id == groupRequestId);
    if (groupIndex == -1) return;

    final groupReq = _allGroupRequests[groupIndex];
    for (final sub in groupReq.subRequests) {
      if (sub.ridePostId == ridePostId) {
        sub.status = SubRequestStatus.declined;
        sub.updatedAt = DateTime.now();
      }
    }

    // If all declined, mark group request expired
    if (groupReq.subRequests.every((s) => s.status == SubRequestStatus.declined)) {
      groupReq.status = GroupRequestStatus.expired;
    }

    _addNotification('Request Declined', 'Ride request was declined.', category: NotificationCategory.ride);
    notifyListeners();
  }

  // Passenger: Cancel their active broadcast
  void cancelGroupRequest(String groupRequestId) {
    final groupIndex = _allGroupRequests.indexWhere((g) => g.id == groupRequestId);
    if (groupIndex == -1) return;

    final groupReq = _allGroupRequests[groupIndex];
    groupReq.status = GroupRequestStatus.cancelled;
    for (final sub in groupReq.subRequests) {
      if (sub.status == SubRequestStatus.pending) {
        sub.status = SubRequestStatus.autoCancelled;
        sub.cancellationReason = 'Cancelled by passenger';
      }
    }

    if (_activeGroupRequest?.id == groupRequestId) {
      _activeGroupRequest = null;
    }

    _addNotification('Broadcast Cancelled', 'Your ride broadcast has been cancelled.', category: NotificationCategory.ride);
    notifyListeners();
    _saveLocalCache();
  }

  // Trip Progress Updates
  void updateTripStatus(String bookingId, TripLifecycleStatus newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].tripStatus = newStatus;
      if (newStatus == TripLifecycleStatus.completed) {
        // Mark corresponding RidePost as completed so it is no longer shown in active lists
        final rideIndex = _ridePosts.indexWhere((r) => r.id == _bookings[index].ridePostId);
        if (rideIndex != -1) {
          _ridePosts[rideIndex].status = RideStatus.completed;
        }
      }
      final notifMsg = newStatus == TripLifecycleStatus.inProgress
          ? 'Ride In Progress! Driver is en route to destination.'
          : (newStatus == TripLifecycleStatus.completed
              ? 'Ride Completed! Passenger will be prompted for fuel payment.'
              : 'Trip status is now ${newStatus.name.toUpperCase()}');
      _addNotification(
        'Trip Status Update',
        notifMsg,
        category: NotificationCategory.ride,
      );
      notifyListeners();
      _saveLocalCache();

      // Synchronize trip status with backend API / NeonDB
      _apiService.updateBookingStatus(
        bookingId: bookingId,
        status: newStatus.name,
      );
    }
  }

  // Payment Processing (bKash, Nagad, Cash)
  void processPayment(String bookingId, PaymentMethod method) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].paymentMethod = method;
      _bookings[index].paymentStatus = PaymentStatus.paid;
      _bookings[index].tripStatus = TripLifecycleStatus.completed;

      final fareStr = _bookings[index].fare.toStringAsFixed(0);
      _addNotification(
        'Payment Received',
        'Payment of ৳$fareStr received via ${method.name.toUpperCase()}',
        category: NotificationCategory.payment,
      );
      _addNotification(
        'Ride Completed & Saved to History',
        'Your trip from ${_bookings[index].pickup.name} to ${_bookings[index].dropoff.name} has ended successfully.',
        category: NotificationCategory.ride,
      );
      notifyListeners();
      _saveLocalCache();

      // Sync payment to NeonDB API
      _apiService.payBooking(
        bookingId: bookingId,
        paymentMethod: method.name,
      );
    }
  }

  // Submit Rating and Review
  void submitRating({
    required String bookingId,
    required double rating,
    required String review,
    required List<String> tags,
  }) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index].passengerGivenRating = rating;
      _bookings[index].passengerGivenReview = review;
      _bookings[index].passengerGivenTags = tags;
      _bookings[index].tripStatus = TripLifecycleStatus.completed;
      _addNotification('Feedback Received', 'Thank you for rating your ride! (★ $rating)', category: NotificationCategory.system);
      notifyListeners();
      _saveLocalCache();
    }
  }

  void _addNotification(
    String title,
    String message, {
    NotificationCategory category = NotificationCategory.system,
  }) {
    _notifications.insert(
      0,
      VroomNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 5)}',
        title: title,
        message: message,
        timestamp: DateTime.now(),
        category: category,
        isRead: false,
      ),
    );
    if (_notifications.length > 30) {
      _notifications.removeLast();
    }
    _saveLocalCache();
  }
}
