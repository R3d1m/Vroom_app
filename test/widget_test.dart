import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vroom_app/main.dart';
import 'package:vroom_app/views/rider/create_ride_screen.dart';
import 'package:vroom_app/views/rider/rider_home_screen.dart';
import 'package:vroom_app/views/passenger/passenger_home_screen.dart';
import 'package:vroom_app/views/passenger/search_results_screen.dart';
import 'package:vroom_app/core/providers/vroom_provider.dart';
import 'package:vroom_app/core/services/api_service.dart';
import 'package:vroom_app/core/models/trip_request.dart';
import 'package:vroom_app/core/models/route_model.dart';
import 'package:vroom_app/core/models/ride_post.dart';
import 'package:vroom_app/core/models/booking_model.dart';
import 'package:vroom_app/core/models/user_model.dart';
import 'package:vroom_app/core/data/mock_data.dart';

void main() {
  group('VROOM Core Business Logic Tests', () {
    test('Multi-route corridor matching test', () {
      final provider = VroomProvider();

      // Search from CUET to GEC Circle
      final matching = provider.searchMatchingRides(
        VroomMockData.cuetCampus.coordinates,
        VroomMockData.gecCircle.coordinates,
      );

      // Should find Rider Imtiaj's ride which has primary & alternate Bayezid bypass
      expect(matching.isNotEmpty, isTrue);
      final ride = matching.first;
      expect(ride.primaryRoute.name.contains('Kaptai'), isTrue);
      expect(ride.alternateRoutes.any((r) => r.isSelected), isTrue);
    });

    test('Passenger search by pickup, destination, and date (no time needed) test', () {
      final provider = VroomProvider();
      final now = DateTime.now();

      // Search for today's date (no time specified)
      final todayMatches = provider.searchMatchingRides(
        VroomMockData.cuetCampus.coordinates,
        VroomMockData.gecCircle.coordinates,
        travelDate: DateTime(now.year, now.month, now.day),
      );
      expect(todayMatches.isNotEmpty, isTrue);

      // Search for tomorrow's date
      final tomorrowMatches = provider.searchMatchingRides(
        VroomMockData.oxygen.coordinates,
        VroomMockData.agrabad.coordinates,
        travelDate: DateTime(now.year, now.month, now.day + 1),
      );
      expect(tomorrowMatches.isNotEmpty, isTrue);
    });

    test('Broadcast Group Request & Atomic Auto-Cancellation Test', () {
      final provider = VroomProvider();
      final targetRides = provider.ridePosts.take(2).toList();
      expect(targetRides.length, equals(2));

      // 1. Passenger sends group broadcast request
      provider.sendGroupRequest(
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 2)),
        targetRides: targetRides,
      );

      final groupReq = provider.activeGroupRequest;
      expect(groupReq, isNotNull);
      expect(groupReq!.status, equals(GroupRequestStatus.pending));
      expect(groupReq.subRequests.length, equals(2));
      expect(groupReq.subRequests[0].status, equals(SubRequestStatus.pending));
      expect(groupReq.subRequests[1].status, equals(SubRequestStatus.pending));

      // 2. Rider 1 accepts the request
      final acceptingRide = targetRides[0];
      provider.acceptRideRequest(
        groupRequestId: groupReq.id,
        ridePostId: acceptingRide.id,
        acceptingRider: acceptingRide.rider,
      );

      // 3. Verify Atomic Transition:
      // Group request is accepted
      expect(groupReq.status, equals(GroupRequestStatus.accepted));
      // Sub-request 1 is accepted
      expect(groupReq.subRequests[0].status, equals(SubRequestStatus.accepted));
      // Sub-request 2 is AUTO-CANCELLED
      expect(groupReq.subRequests[1].status, equals(SubRequestStatus.autoCancelled));
      expect(groupReq.subRequests[1].cancellationReason, isNotNull);

      // 4. Booking created
      expect(provider.bookings.isNotEmpty, isTrue);
      final booking = provider.bookings.first;
      expect(booking.rider.id, equals(acceptingRide.rider.id));
      expect(booking.pinCode.length, equals(4));
    });

    test('Login and Logout Auth Flow Test', () async {
      final provider = VroomProvider();

      // Test Login as Rider (Imtiaj)
      final success = await provider.login(
        email: 'imtiaj@premieruniv.edu',
        password: 'password123',
      );
      expect(success, isTrue);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.currentUser.name, equals('Imtiaj Uddin'));
      expect(provider.activeMode, equals(UserRoleMode.rider));

      // Test Logout
      provider.logout();
      expect(provider.isAuthenticated, isFalse);
    });

    test('Notification Panel & Vehicle Visibility Logic', () {
      final provider = VroomProvider();

      // Notifications should be initialized
      expect(provider.notifications.isNotEmpty, isTrue);
      final initialUnread = provider.unreadNotificationsCount;
      expect(initialUnread, greaterThan(0));

      // Mark all read
      provider.markAllNotificationsAsRead();
      expect(provider.unreadNotificationsCount, equals(0));

      // Passenger default vehicle should be null (Redwan is passenger, has no vehicle)
      expect(VroomMockData.currentUser.vehicleModel, isNull);
      expect(VroomMockData.currentUser.vehiclePlate, isNull);

      // Rider Imtiaj has vehicle
      expect(VroomMockData.riderImtiaj.vehicleModel, isNotNull);

      // Clear notifications
      provider.clearAllNotifications();
      expect(provider.notifications.isEmpty, isTrue);
    });

    test('Ride deletion and edit test', () {
      final provider = VroomProvider();
      final initialCount = provider.ridePosts.length;
      final target = provider.ridePosts.first;

      // Edit ride
      final updated = RidePost(
        id: target.id,
        rider: target.rider,
        origin: target.origin,
        destination: target.destination,
        primaryRoute: target.primaryRoute,
        alternateRoutes: target.alternateRoutes,
        departureTime: target.departureTime,
        totalSeats: target.totalSeats,
        availableSeats: target.availableSeats,
        farePerSeat: 250.0,
        vehicleType: target.vehicleType,
        vehiclePlate: target.vehiclePlate,
        vehicleModel: target.vehicleModel,
      );
      provider.updateRidePost(updated);
      expect(provider.ridePosts.firstWhere((r) => r.id == target.id).farePerSeat, equals(250.0));

      // Delete ride
      provider.deleteRidePost(target.id);
      expect(provider.ridePosts.length, equals(initialCount - 1));
      expect(provider.ridePosts.any((r) => r.id == target.id), isFalse);
    });

    test('Broadcast deduplication and cross-request auto-cancel test', () {
      final provider = VroomProvider();
      final targetRides = provider.ridePosts.take(2).toList();

      // Passenger sends broadcast
      provider.sendGroupRequest(
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 1)),
        targetRides: targetRides,
      );
      final firstReqId = provider.activeGroupRequest!.id;

      // Passenger exits and broadcasts again -> first should be superseded/cancelled!
      provider.sendGroupRequest(
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 1)),
        targetRides: targetRides,
      );

      final secondReq = provider.activeGroupRequest!;
      expect(secondReq.id, isNot(equals(firstReqId)));

      final oldReq = provider.allGroupRequests.firstWhere((g) => g.id == firstReqId);
      expect(oldReq.status, equals(GroupRequestStatus.cancelled));

      // Rider accepts second request
      provider.acceptRideRequest(
        groupRequestId: secondReq.id,
        ridePostId: targetRides[0].id,
        acceptingRider: targetRides[0].rider,
      );

      // Active broadcast should now be cleared
      expect(provider.activeGroupRequest, isNull);
      // All other sibling requests cancelled
      expect(secondReq.subRequests[1].status, equals(SubRequestStatus.autoCancelled));
    });

    test('Completed ride filtering, ride history, and pending payment test', () {
      final provider = VroomProvider();
      final targetRides = provider.ridePosts.take(1).toList();

      provider.sendGroupRequest(
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 1)),
        targetRides: targetRides,
      );

      provider.acceptRideRequest(
        groupRequestId: provider.activeGroupRequest!.id,
        ridePostId: targetRides[0].id,
        acceptingRider: targetRides[0].rider,
      );

      final booking = provider.bookings.first;
      expect(provider.activeBooking, isNotNull);
      expect(provider.pendingPaymentBooking, isNull);

      // Rider marks trip completed
      provider.updateTripStatus(booking.id, TripLifecycleStatus.completed);

      // RidePost should be marked completed
      expect(provider.ridePosts.firstWhere((r) => r.id == booking.ridePostId).status, equals(RideStatus.completed));
      // Active booking is now cleared
      expect(provider.activeBooking, isNull);
      // Pending payment is now active for passenger!
      expect(provider.pendingPaymentBooking, isNotNull);
      expect(provider.pendingPaymentBooking!.id, equals(booking.id));

      // Ride history contains this completed ride
      expect(provider.rideHistory.any((b) => b.id == booking.id), isTrue);
    });

    test('NeonDB PostgreSQL numeric string deserialization test', () {
      // Simulate raw JSON from NeonDB PostgreSQL where numbers are serialized as strings
      final rawRideJson = {
        'id': '1206fe70-37ec-47af-b426-1285fce44015',
        'rider_id': '818b2393-1ad5-42ae-89d0-4fc83ba8d4a3',
        'rider_name': 'KMI Albab',
        'rider_email': 'u2204059@student.cuet.ac.bd',
        'rider_phone': '01891780447',
        'rider_rating': '5.00',
        'origin_id': 'loc_cuet',
        'origin_name': 'CUET Campus (Main Gate)',
        'origin_lat': '22.4601000',
        'origin_lng': '91.9711000',
        'destination_id': 'loc_2nogate',
        'destination_name': '2 No. Gate (Sholoshohor)',
        'destination_lat': '22.3685000',
        'destination_lng': '91.8266000',
        'primary_route_name': 'Via Kaptai Highway & Bayezid Bypass',
        'primary_route_via': 'Via Kaptai Highway & Bayezid Bypass',
        'primary_distance_km': '24.50',
        'primary_duration_mins': 45,
        'detour_tolerance_km': '2.00',
        'departure_time': '2026-11-19T20:19:20.187Z',
        'total_seats': 1,
        'available_seats': 1,
        'fare_per_seat': '120.00',
        'vehicle_type': 'Motorcycle',
        'vehicle_plate': 'Dhaka Metro-Ka 1234',
        'vehicle_model': 'TVS XL',
        'status': 'scheduled',
      };

      final apiService = VroomApiService();
      // Should not throw TypeError: type 'String' is not a subtype of type 'num?'
      expect(() {
        final ride = apiService.mapRideFromJson(rawRideJson);
        expect(ride.rider.name, equals('KMI Albab'));
        expect(ride.farePerSeat, equals(120.0));
        expect(ride.primaryRoute.distanceKm, equals(24.5));
        expect(ride.origin.coordinates.latitude, closeTo(22.4601, 0.0001));
        expect(ride.destination.coordinates.latitude, closeTo(22.3685, 0.0001));
      }, returnsNormally);
    });

    test('Driver booking notifications and homepage bookings visibility test', () {
      final provider = VroomProvider();
      final targetRides = provider.ridePosts.take(1).toList();
      final targetRide = targetRides.first;

      // 1. Passenger requests booking
      provider.sendGroupRequest(
        pickup: targetRide.origin,
        dropoff: targetRide.destination,
        scheduledDeparture: targetRide.departureTime,
        targetRides: [targetRide],
      );

      // Verify driver gets notification about the new booking request
      expect(
        provider.notifications.any((n) => n.title.contains('New Ride Request') || n.title.contains('Ride Request Sent')),
        isTrue,
      );

      // Verify driver's pending requests list has this request
      final pendingRequests = provider.getPendingRequestsForRider(targetRide.rider.id);
      expect(pendingRequests.isNotEmpty, isTrue);

      // 2. Rider accepts request
      provider.acceptRideRequest(
        groupRequestId: provider.activeGroupRequest!.id,
        ridePostId: targetRide.id,
        acceptingRider: targetRide.rider,
      );

      // Switch active user to rider to verify driver homepage visibility
      provider.switchModeTo(UserRoleMode.rider);

      // Verify driver gets notification about confirmed passenger
      expect(
        provider.notifications.any((n) => n.title.contains('Passenger Confirmed') || n.title.contains('Ride Confirmed')),
        isTrue,
      );

      // Verify confirmed bookings are visible to the driver
      expect(provider.bookings.any((b) => b.ridePostId == targetRide.id), isTrue);
    });

    test('Passenger pending booking and active requests visibility test', () {
      final provider = VroomProvider();
      final targetRides = provider.ridePosts.take(1).toList();

      // Before request: no pending request
      expect(provider.pendingPassengerRequest, isNull);

      // Passenger sends request
      provider.sendGroupRequest(
        pickup: VroomMockData.cuetCampus,
        dropoff: VroomMockData.gecCircle,
        scheduledDeparture: DateTime.now().add(const Duration(hours: 3)),
        targetRides: targetRides,
      );

      // After request: pending request is visible on passenger homepage!
      expect(provider.pendingPassengerRequest, isNotNull);
      expect(provider.pendingPassengerRequest!.status, equals(GroupRequestStatus.pending));

      // Once accepted, booking is confirmed and in passengerActiveBookings
      provider.acceptRideRequest(
        groupRequestId: provider.pendingPassengerRequest!.id,
        ridePostId: targetRides[0].id,
        acceptingRider: targetRides[0].rider,
      );

      expect(provider.pendingPassengerRequest, isNull);
      expect(provider.passengerActiveBookings.isNotEmpty, isTrue);
      expect(provider.passengerActiveBookings.first.tripStatus, equals(TripLifecycleStatus.confirmed));
    });

    test('Offline cache serialization test for RidePost and ConfirmedBooking', () {
      final sampleRide = VroomMockData.getInitialRidePosts().first;
      final rideJson = sampleRide.toJson();
      final restoredRide = RidePost.fromJson(rideJson);

      expect(restoredRide.id, equals(sampleRide.id));
      expect(restoredRide.rider.name, equals(sampleRide.rider.name));
      expect(restoredRide.farePerSeat, equals(sampleRide.farePerSeat));
      expect(restoredRide.primaryRoute.polyline.length, equals(sampleRide.primaryRoute.polyline.length));

      final sampleBooking = VroomMockData.getInitialBookings().first;
      final bookingJson = sampleBooking.toJson();
      final restoredBooking = ConfirmedBooking.fromJson(bookingJson);

      expect(restoredBooking.id, equals(sampleBooking.id));
      expect(restoredBooking.rider.name, equals(sampleBooking.rider.name));
      expect(restoredBooking.pinCode, equals(sampleBooking.pinCode));
      expect(restoredBooking.fare, equals(sampleBooking.fare));
    });

    test('UserModel session JSON serialization test', () {
      final user = VroomMockData.currentUser;
      final json = user.toJson();
      expect(json['id'], equals(user.id));
      expect(json['name'], equals(user.name));
      expect(json['activeMode'], equals('passenger'));

      final restored = UserModel.fromJson(json);
      expect(restored.id, equals(user.id));
      expect(restored.name, equals(user.name));
      expect(restored.activeMode, equals(UserRoleMode.passenger));
      expect(restored.vehicleModel, isNull);
    });

    test('AI and Rule-based Fare Estimation formula test (50tk 0-5km, +10tk/km, rain 1.25x)', () async {
      final api = VroomApiService();
      // Ensure we test the formula logic directly
      VroomApiService.useLocalMockFallback = true;

      // 1. Distance <= 5km, clear weather
      final res3kmClear = await api.estimateFare(
        distanceKm: 3.0,
        origin: 'Point A',
        destination: 'Point B',
        weather: 'clear',
      );
      expect(res3kmClear['estimated_fare'], equals(50.0));
      expect(res3kmClear['weather_multiplier'], equals(1.0));

      // 2. Distance <= 5km, rainy weather (50 * 1.25 = 62.5 -> 63)
      final res3kmRain = await api.estimateFare(
        distanceKm: 3.0,
        origin: 'Point A',
        destination: 'Point B',
        weather: 'rain',
      );
      expect(res3kmRain['estimated_fare'], equals(63.0));
      expect(res3kmRain['weather_multiplier'], equals(1.25));

      // 3. Distance 10km, clear weather: 50 + (10-5)*10 = 100
      final res10kmClear = await api.estimateFare(
        distanceKm: 10.0,
        origin: 'Point A',
        destination: 'Point B',
        weather: 'clear',
      );
      expect(res10kmClear['estimated_fare'], equals(100.0));

      // 4. Distance 10km, rainy weather: 100 * 1.25 = 125
      final res10kmRain = await api.estimateFare(
        distanceKm: 10.0,
        origin: 'Point A',
        destination: 'Point B',
        weather: 'rain',
      );
      expect(res10kmRain['estimated_fare'], equals(125.0));

      // 5. Distance 24.5km (CUET to GEC), clear weather: 50 + 19.5*10 = 245
      final res24kmClear = await api.estimateFare(
        distanceKm: 24.5,
        origin: 'CUET Campus',
        destination: 'GEC Circle',
        weather: 'clear',
      );
      expect(res24kmClear['estimated_fare'], equals(245.0));

      // 6. Distance 24.5km, rainy weather: 245 * 1.25 = 306.25 -> 306
      final res24kmRain = await api.estimateFare(
        distanceKm: 24.5,
        origin: 'CUET Campus',
        destination: 'GEC Circle',
        weather: 'heavy rain',
      );
      expect(res24kmRain['estimated_fare'], equals(306.0));

      // Reset fallback flag
      VroomApiService.useLocalMockFallback = false;
    });
  });

  group('VROOM Widget Tests', () {
    testWidgets('VroomApp renders brand top bar and mode toggle', (WidgetTester tester) async {
      await tester.pumpWidget(const VroomApp());
      await tester.pump();

      // Verify VROOM logo text exists
      expect(find.text('VROOM'), findsWidgets);
    });

    testWidgets('CreateRideScreen renders single AI fare estimation box with Open-Meteo auto-prediction and auto-applied fare', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = VroomProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<VroomProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CreateRideScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify single prediction box elements
      expect(find.text('AI FARE ESTIMATE'), findsOneWidget);
      expect(find.textContaining('Open-Meteo'), findsWidgets);
      expect(find.text('Auto-Applied'), findsOneWidget);
    });

    testWidgets('PassengerHomeScreen renders read-only estimated fair fare reference card (no input)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = VroomProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<VroomProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: PassengerHomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify the read-only AI fare reference card is shown
      expect(find.text('AI Estimated Fair Fare'), findsOneWidget);
      expect(find.text('Idea / Reference'), findsOneWidget);
      expect(find.textContaining('Base ৳50 + ৳10/km'), findsOneWidget);
    });

    testWidgets('SearchResultsScreen renders read-only fair fare idea banner', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = VroomProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<VroomProvider>.value(
          value: provider,
          child: MaterialApp(
            home: SearchResultsScreen(
              pickup: VroomMockData.cuetCampus,
              dropoff: VroomMockData.gecCircle,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify corridor fair fare idea banner
      expect(find.textContaining('AI Fair Fare Idea'), findsOneWidget);
      expect(find.textContaining('route'), findsWidgets);
    });

    testWidgets('RiderHomeScreen renders real-time incoming booking request cards and accepts booking directly from homepage', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = VroomProvider();
      provider.switchModeTo(UserRoleMode.rider);
      provider.createRidePost(
        origin: VroomMockData.cuetCampus,
        destination: VroomMockData.gecCircle,
        primaryRoute: RouteOption(
          id: 'route_cuet_gec',
          name: 'Direct Highway',
          viaRoadName: 'Kaptai Highway',
          polyline: const [],
          distanceKm: 25.0,
          durationMinutes: 45,
        ),
        alternateRoutes: const [],
        detourToleranceKm: 2.0,
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        seats: 2,
        farePerSeat: 150.0,
        vehicleType: 'Motorcycle',
        vehiclePlate: 'Dhaka Metro-Ha 12-3456',
        vehicleModel: 'Yamaha FZ',
      );
      final myRide = provider.ridePosts.firstWhere((r) => provider.isRiderOf(r));

      // Simulate a passenger booking request directed to this driver's ride
      provider.sendGroupRequest(
        pickup: myRide.origin,
        dropoff: myRide.destination,
        scheduledDeparture: myRide.departureTime,
        targetRides: [myRide],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<VroomProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: RiderHomeScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify incoming booking requests section is visible on driver's homepage
      expect(find.text('Incoming Booking Requests'), findsOneWidget);
      expect(find.text('Accept Request'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);

      // Tap Accept Request directly on homepage
      await tester.tap(find.text('Accept Request'));
      await tester.pumpAndSettle();

      // Verify the booking is now confirmed under Passenger Bookings
      expect(find.textContaining('Passenger Bookings'), findsOneWidget);
    });

    test('Booking deduplication and pending request removal workflow test', () {
      final provider = VroomProvider();
      provider.switchModeTo(UserRoleMode.rider);

      provider.createRidePost(
        origin: VroomMockData.cuetCampus,
        destination: VroomMockData.gecCircle,
        primaryRoute: RouteOption(
          id: 'route_cuet_gec_test1',
          name: 'Direct Route',
          viaRoadName: 'Kaptai Highway',
          polyline: const [],
          distanceKm: 25.0,
          durationMinutes: 45,
        ),
        alternateRoutes: const [],
        detourToleranceKm: 2.0,
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        seats: 3,
        farePerSeat: 120.0,
        vehicleType: 'Motorcycle',
        vehiclePlate: 'Chatto Metro-Ha 11-2233',
        vehicleModel: 'Yamaha FZS',
      );
      final ride = provider.ridePosts.firstWhere((r) => provider.isRiderOf(r));

      final passengerUser = UserModel(
        id: 'user_pass_test_101',
        name: 'Sadia Jahan',
        phone: '+880 1888-112233',
        email: 'sadia@cuet.ac.bd',
        avatarUrl: '',
        universityOrOrg: 'CUET',
        rating: 4.9,
        totalTrips: 8,
        activeMode: UserRoleMode.passenger,
      );

      // Create group request for this ride
      final groupReq = GroupTripRequest(
        id: 'greq_test_dedup_001',
        passenger: passengerUser,
        pickup: ride.origin,
        dropoff: ride.destination,
        scheduledDeparture: ride.departureTime,
        requestedSeats: 1,
        status: GroupRequestStatus.pending,
        subRequests: [
          SubRequestItem(
            ridePostId: ride.id,
            riderName: provider.currentUser.name,
            riderPhone: provider.currentUser.phone,
            vehicleType: ride.vehicleType,
            vehicleModel: ride.vehicleModel,
            fare: ride.farePerSeat,
            status: SubRequestStatus.pending,
          ),
        ],
      );
      provider.allGroupRequests.insert(0, groupReq);

      // 1. Pending request is visible to the rider
      final pendingBefore = provider.getPendingRequestsForRider(provider.currentUser.id);
      expect(pendingBefore.any((req) => (req['groupRequest'] as GroupTripRequest).id == groupReq.id), isTrue);

      // 2. Rider accepts the booking
      provider.acceptRideRequest(
        groupRequestId: groupReq.id,
        ridePostId: ride.id,
        acceptingRider: provider.currentUser,
      );

      // 3. Exactly 1 confirmed booking exists for this passenger and ride (no duplicate!)
      final matchingBookings = provider.riderConfirmedBookings
          .where((b) => b.ridePostId == ride.id && b.passenger.id == passengerUser.id)
          .toList();
      expect(matchingBookings.length, equals(1));

      // 4. Booking is no longer in pending requests!
      final pendingAfter = provider.getPendingRequestsForRider(provider.currentUser.id);
      expect(pendingAfter.any((req) => (req['groupRequest'] as GroupTripRequest).id == groupReq.id), isFalse);

      // 5. Rider sees ongoing active ride
      expect(provider.activeBooking, isNotNull);
      expect(provider.activeBooking!.ridePostId, equals(ride.id));
    });

    test('Full Trip Lifecycle: confirmed -> inProgress -> completed -> paid -> moved to rideHistory', () {
      final provider = VroomProvider();
      provider.switchModeTo(UserRoleMode.rider);

      provider.createRidePost(
        origin: VroomMockData.cuetCampus,
        destination: VroomMockData.gecCircle,
        primaryRoute: RouteOption(
          id: 'route_cuet_gec_test2',
          name: 'Direct Route',
          viaRoadName: 'Kaptai Highway',
          polyline: const [],
          distanceKm: 25.0,
          durationMinutes: 45,
        ),
        alternateRoutes: const [],
        detourToleranceKm: 2.0,
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        seats: 2,
        farePerSeat: 100.0,
        vehicleType: 'Car',
        vehiclePlate: 'Dhaka Metro-Ga 44-5566',
        vehicleModel: 'Toyota Aqua',
      );
      final ride = provider.ridePosts.firstWhere((r) => provider.isRiderOf(r));

      final passengerUser = UserModel(
        id: 'user_pass_lifecycle_102',
        name: 'Tanvir Hossain',
        phone: '+880 1777-998877',
        email: 'tanvir@cuet.ac.bd',
        avatarUrl: '',
        universityOrOrg: 'CUET',
        rating: 5.0,
        totalTrips: 12,
        activeMode: UserRoleMode.passenger,
      );

      final groupReq = GroupTripRequest(
        id: 'greq_lifecycle_002',
        passenger: passengerUser,
        pickup: ride.origin,
        dropoff: ride.destination,
        scheduledDeparture: ride.departureTime,
        requestedSeats: 1,
        status: GroupRequestStatus.pending,
        subRequests: [
          SubRequestItem(
            ridePostId: ride.id,
            riderName: provider.currentUser.name,
            riderPhone: provider.currentUser.phone,
            vehicleType: ride.vehicleType,
            vehicleModel: ride.vehicleModel,
            fare: ride.farePerSeat,
            status: SubRequestStatus.pending,
          ),
        ],
      );
      provider.allGroupRequests.insert(0, groupReq);

      // 1. Rider accepts booking
      provider.acceptRideRequest(
        groupRequestId: groupReq.id,
        ridePostId: ride.id,
        acceptingRider: provider.currentUser,
      );

      final booking = provider.riderConfirmedBookings.firstWhere((b) => b.ridePostId == ride.id);
      expect(booking.tripStatus, equals(TripLifecycleStatus.confirmed));

      // 2. Driver starts the ride
      provider.updateTripStatus(booking.id, TripLifecycleStatus.inProgress);
      expect(booking.tripStatus, equals(TripLifecycleStatus.inProgress));
      expect(provider.activeBooking!.tripStatus, equals(TripLifecycleStatus.inProgress));

      // 3. Driver completes the ride
      provider.updateTripStatus(booking.id, TripLifecycleStatus.completed);
      expect(booking.tripStatus, equals(TripLifecycleStatus.completed));

      // 4. Passenger pays via bKash & reviews
      provider.processPayment(booking.id, PaymentMethod.bKash);
      provider.submitRating(
        bookingId: booking.id,
        rating: 5.0,
        review: 'Excellent smooth ride!',
        tags: ['Punctual', 'Safe Driving'],
      );

      // 5. Booking is marked paid and completed
      expect(booking.paymentStatus, equals(PaymentStatus.paid));
      expect(booking.tripStatus, equals(TripLifecycleStatus.completed));

      // 6. Booking is no longer in active bookings
      expect(provider.riderConfirmedBookings.any((b) => b.id == booking.id), isFalse);

      // 7. Booking has moved to Ride History!
      expect(provider.rideHistory.any((b) => b.id == booking.id), isTrue);
    });
  });
}
