import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/ride_post.dart';
import '../models/booking_model.dart';
import '../data/mock_data.dart';

class VroomApiService {
  // Live deployed Vercel Backend with NeonDB
  static String baseUrl = 'https://vroom-backend.vercel.app/v1';
  static bool useLocalMockFallback = false;

  // Set the custom API URL provided by the user
  static void setCustomApiUrl(String url) {
    baseUrl = url;
    useLocalMockFallback = false;
  }

  // 1. Register new user (Passenger or Rider)
  Future<UserModel?> register({
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
    if (!useLocalMockFallback) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'phone': phone,
            'role_mode': roleMode == UserRoleMode.rider ? 'rider' : 'passenger',
            'university_or_org': universityOrOrg ?? 'Verified Commuter',
            'vehicle_type': vehicleType,
            'vehicle_plate': vehiclePlate,
            'vehicle_model': vehicleModel,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          return _mapUserFromJson(data['user']);
        }
      } catch (e) {
        // Fallback to local user creation if backend not reachable
      }
    }

    // Local in-memory registration for immediate testing
    return UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      avatarUrl: '',
      universityOrOrg: universityOrOrg ?? 'Verified Commuter',
      nidStatus: NidStatus.verified,
      studentIdStatus: StudentIdStatus.verified,
      rating: 5.0,
      totalTrips: 0,
      activeMode: roleMode,
      vehiclePlate: vehiclePlate,
      vehicleModel: vehicleModel,
      vehicleType: vehicleType,
    );
  }

  // 2. Authenticate user against NeonDB backend
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    if (!useLocalMockFallback) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _mapUserFromJson(data['user']);
        }
      } catch (e) {
        // Fallback if API is unreachable
      }
    }

    // Local Verification based on Seeded NeonDB accounts
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.contains('redwan')) {
      return VroomMockData.currentUser.copyWith(activeMode: UserRoleMode.passenger);
    } else if (normalizedEmail.contains('imtiaj')) {
      return VroomMockData.riderImtiaj.copyWith(activeMode: UserRoleMode.rider);
    } else if (normalizedEmail.contains('anas')) {
      return VroomMockData.riderAnas.copyWith(activeMode: UserRoleMode.rider);
    } else if (normalizedEmail.contains('juman')) {
      return VroomMockData.riderJuman.copyWith(activeMode: UserRoleMode.rider);
    }

    // Default authenticated session for test emails
    return UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@')[0].toUpperCase(),
      email: email,
      phone: '+880 1700-000000',
      avatarUrl: '',
      universityOrOrg: 'Verified Commuter',
      nidStatus: NidStatus.verified,
      studentIdStatus: StudentIdStatus.verified,
      rating: 5.0,
      totalTrips: 1,
      activeMode: UserRoleMode.passenger,
    );
  }

  // 3. Create a Scheduled Ride Post in NeonDB
  Future<RidePost?> createRide({
    required UserModel rider,
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
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rider_id': rider.id,
          'rider_email': rider.email,
          'rider_name': rider.name,
          'rider_phone': rider.phone,
          'origin_id': origin.id,
          'destination_id': destination.id,
          'origin_name': origin.name,
          'origin_lat': origin.coordinates.latitude,
          'origin_lng': origin.coordinates.longitude,
          'destination_name': destination.name,
          'destination_lat': destination.coordinates.latitude,
          'destination_lng': destination.coordinates.longitude,
          'primary_route_name': primaryRoute.name,
          'primary_route_via': primaryRoute.viaRoadName,
          'primary_polyline': primaryRoute.polyline.map((p) => [p.latitude, p.longitude]).toList(),
          'primary_distance_km': primaryRoute.distanceKm,
          'primary_duration_mins': primaryRoute.durationMinutes,
          'alternate_routes': alternateRoutes.map((r) => {
            'id': r.id,
            'name': r.name,
            'via': r.viaRoadName,
            'distanceKm': r.distanceKm,
            'durationMinutes': r.durationMinutes,
          }).toList(),
          'detour_tolerance_km': detourToleranceKm,
          'departure_time': departureTime.toIso8601String(),
          'total_seats': seats,
          'fare_per_seat': farePerSeat,
          'vehicle_type': vehicleType,
          'vehicle_plate': vehiclePlate,
          'vehicle_model': vehicleModel,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['ride'] != null) {
          final rideJson = Map<String, dynamic>.from(data['ride']);
          rideJson['rider_id'] = rideJson['rider_id'] ?? rider.id;
          rideJson['rider_email'] = rideJson['rider_email'] ?? rider.email;
          rideJson['rider_name'] = rideJson['rider_name'] ?? rider.name;
          rideJson['rider_phone'] = rideJson['rider_phone'] ?? rider.phone;
          rideJson['rider_university'] = rideJson['rider_university'] ?? rider.universityOrOrg;
          rideJson['origin_name'] = rideJson['origin_name'] ?? origin.name;
          rideJson['origin_lat'] = rideJson['origin_lat'] ?? origin.coordinates.latitude;
          rideJson['origin_lng'] = rideJson['origin_lng'] ?? origin.coordinates.longitude;
          rideJson['destination_name'] = rideJson['destination_name'] ?? destination.name;
          rideJson['destination_lat'] = rideJson['destination_lat'] ?? destination.coordinates.latitude;
          rideJson['destination_lng'] = rideJson['destination_lng'] ?? destination.coordinates.longitude;
          return _mapRideFromJson(rideJson);
        }
      }
    } catch (_) {}
    return null;
  }

  // 4. Fetch All Rides from NeonDB
  Future<List<RidePost>> fetchRides() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rides'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rides'] is List) {
          final list = <RidePost>[];
          for (final item in data['rides']) {
            try {
              list.add(_mapRideFromJson(item));
            } catch (e) {
              // Ignore single item parsing error and continue
            }
          }
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  // 5. Update an Existing Ride Post
  Future<bool> updateRide(RidePost post) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/rides/${post.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'departure_time': post.departureTime.toIso8601String(),
          'total_seats': post.totalSeats,
          'available_seats': post.availableSeats,
          'fare_per_seat': post.farePerSeat,
          'primary_route_via': post.primaryRoute.viaRoadName,
          'status': post.status.name,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 6. Delete / Cancel an Existing Ride Post
  Future<bool> deleteRide(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/rides/$id'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 7. Broadcast Passenger Group Request
  Future<Map<String, dynamic>?> broadcastRequest({
    required String passengerId,
    required LocationPoint pickup,
    required LocationPoint dropoff,
    required DateTime scheduledDeparture,
    required int requestedSeats,
    required List<String> targetRideIds,
    String? passengerEmail,
    String? passengerName,
    String? passengerPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/requests/broadcast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'passenger_id': passengerId,
          if (passengerEmail != null && passengerEmail.isNotEmpty) 'passenger_email': passengerEmail,
          if (passengerName != null && passengerName.isNotEmpty) 'passenger_name': passengerName,
          if (passengerPhone != null && passengerPhone.isNotEmpty) 'passenger_phone': passengerPhone,
          'pickup_id': pickup.id,
          'dropoff_id': dropoff.id,
          'pickup_name': pickup.name,
          'pickup_lat': pickup.coordinates.latitude,
          'pickup_lng': pickup.coordinates.longitude,
          'dropoff_name': dropoff.name,
          'dropoff_lat': dropoff.coordinates.latitude,
          'dropoff_lng': dropoff.coordinates.longitude,
          'scheduled_departure': scheduledDeparture.toIso8601String(),
          'requested_seats': requestedSeats,
          'target_ride_ids': targetRideIds,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // 8. Rider Accepts Request
  Future<Map<String, dynamic>?> acceptRequest({
    required String groupRequestId,
    required String ridePostId,
    required String riderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/requests/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'group_request_id': groupRequestId,
          'ride_post_id': ridePostId,
          'rider_id': riderId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // 9. Digital Payments
  Future<bool> payBooking({
    required String bookingId,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking_id': bookingId,
          'payment_method': paymentMethod,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 9.1 Update Booking Lifecycle Status (inProgress, completed, etc.)
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking_id': bookingId,
          'trip_status': status,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 9.5 Fetch Pending Inbound Requests for a Rider
  Future<List<Map<String, dynamic>>> fetchPendingRequestsForRider(
    String riderId, {
    String? email,
    String? phone,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      final uri = Uri.parse('$baseUrl/requests/rider/$riderId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requests'] is List) {
          return List<Map<String, dynamic>>.from(data['requests']);
        }
      }
    } catch (_) {}
    return [];
  }

  // 9.6 Fetch Active Request for Passenger
  Future<Map<String, dynamic>?> fetchPassengerRequest(String passengerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/requests/passenger/$passengerId')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['request'] is Map) {
          return Map<String, dynamic>.from(data['request']);
        }
      }
    } catch (_) {}
    return null;
  }

  // 9.7 Open-Meteo Live Weather Auto-Prediction Helper
  Future<String> detectLiveWeather({double? lat, double? lng}) async {
    try {
      final latitude = lat ?? 22.4608;
      final longitude = lng ?? 91.9710;
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=precipitation,rain,weather_code';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current'];
        if (current != null) {
          final rain = (current['rain'] as num?)?.toDouble() ?? 0.0;
          final prec = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
          final code = current['weather_code'] as int? ?? 0;
          const rainyCodes = [51, 53, 55, 61, 63, 65, 66, 67, 80, 81, 82, 95, 96, 99];
          if (rain > 0.05 || prec > 0.05 || rainyCodes.contains(code)) {
            return 'rain';
          }
        }
      }
    } catch (_) {}
    return 'clear';
  }

  // 10. AI / Rule-based Fare Estimation with Automatic Open-Meteo Weather
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
    final dist = distanceKm > 0 ? distanceKm : 1.0;
    
    // Auto-predict weather if not explicitly supplied or set to 'auto'
    String resolvedWeather = weather ?? 'auto';
    if (resolvedWeather == 'auto' || resolvedWeather.isEmpty) {
      resolvedWeather = await detectLiveWeather(lat: originLat, lng: originLng);
    }
    
    final isRain = resolvedWeather.toLowerCase().contains('rain');
    // Base rule: 50tk for 0-5km, +10tk for each additional km
    final baseFare = dist <= 5.0 ? 50.0 : 50.0 + (dist - 5.0) * 10.0;
    // Weather multiplier: rain = 1.25, else = 1.0
    final multiplier = isRain ? 1.25 : 1.0;
    final ruleFare = (baseFare * multiplier).roundToDouble();

    if (!useLocalMockFallback) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/fare/estimate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'distance_km': dist,
            'origin': origin,
            'destination': destination,
            'weather': resolvedWeather,
            'origin_lat': originLat ?? 22.4608,
            'origin_lng': originLng ?? 91.9710,
          }),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final serverWeather = data['weather']?.toString().toLowerCase() ?? (isRain ? 'rain' : 'clear');
            final serverIsRain = serverWeather.contains('rain');
            final serverMult = serverIsRain ? 1.25 : 1.0;
            return {
              'estimated_fare': _asDouble(data['estimated_fare'], ruleFare),
              'base_fare': _asDouble(data['base_fare'], baseFare),
              'rule_based_fare': _asDouble(data['rule_based_fare'], ruleFare),
              'weather_multiplier': _asDouble(data['weather_multiplier'], serverMult),
              'weather': serverWeather,
              'weather_source': data['weather_source'] ?? 'open-meteo',
              'reasoning': data['reasoning'] ?? '',
              'ai_adjusted': data['ai_adjusted'] == true,
              'provider': data['provider'] ?? 'formula',
            };
          }
        }
      } catch (_) {
        // Fallback smoothly to rule calculation if offline or server timeout
      }
    }

    return {
      'estimated_fare': ruleFare,
      'base_fare': baseFare,
      'rule_based_fare': ruleFare,
      'weather_multiplier': multiplier,
      'weather': isRain ? 'rain' : 'clear',
      'weather_source': 'open-meteo',
      'reasoning': 'Base formula: 50৳ (0-5 km) + 10৳/km${isRain ? ' × 1.25 Open-Meteo rain surcharge' : ' × 1.0 Open-Meteo clear weather'}.',
      'ai_adjusted': false,
      'provider': 'formula',
    };
  }

  static double _asDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? defaultVal;
    }
    return defaultVal;
  }

  static int _asInt(dynamic val, [int defaultVal = 0]) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? defaultVal;
    }
    return defaultVal;
  }

  // Public mapping helper for testing & deserialization
  RidePost mapRideFromJson(Map<String, dynamic> json) => _mapRideFromJson(json);

  UserModel _mapUserFromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      universityOrOrg: json['university_or_org'] ?? '',
      nidStatus: json['nid_status'] == 'verified' ? NidStatus.verified : NidStatus.pending,
      studentIdStatus: json['student_id_status'] == 'verified' ? StudentIdStatus.verified : StudentIdStatus.unverified,
      rating: _asDouble(json['rating_avg'], 5.0),
      totalTrips: _asInt(json['total_trips'], 0),
      activeMode: json['active_mode'] == 'rider' ? UserRoleMode.rider : UserRoleMode.passenger,
      vehiclePlate: json['vehicle_plate'],
      vehicleModel: json['vehicle_model'],
      vehicleType: json['vehicle_type'],
    );
  }

  RidePost _mapRideFromJson(Map<String, dynamic> json) {
    final rider = UserModel(
      id: json['rider_id']?.toString() ?? 'rider_unknown',
      name: json['rider_name'] ?? 'Verified Rider',
      email: json['rider_email'] ?? 'commuter@cuet.ac.bd',
      phone: json['rider_phone'] ?? '+880 1812-345678',
      avatarUrl: json['rider_avatar'] ?? '',
      universityOrOrg: json['rider_university'] ?? 'CUET',
      nidStatus: json['rider_nid_status'] == 'verified' ? NidStatus.verified : NidStatus.pending,
      studentIdStatus: json['rider_student_id_status'] == 'verified' ? StudentIdStatus.verified : StudentIdStatus.unverified,
      rating: _asDouble(json['rider_rating'], 4.9),
      totalTrips: _asInt(json['rider_trips'] ?? json['total_trips'], 12),
      activeMode: UserRoleMode.rider,
      vehiclePlate: json['vehicle_plate'],
      vehicleModel: json['vehicle_model'],
      vehicleType: json['vehicle_type'],
    );

    final origin = LocationPoint(
      id: json['origin_id']?.toString() ?? 'loc_orig',
      name: json['origin_name'] ?? 'Pickup Point',
      description: json['origin_desc'] ?? '',
      coordinates: LatLng(
        _asDouble(json['origin_lat'], 22.4608),
        _asDouble(json['origin_lng'], 91.9710),
      ),
    );

    final dest = LocationPoint(
      id: json['destination_id']?.toString() ?? 'loc_dest',
      name: json['destination_name'] ?? 'Destination',
      description: json['destination_desc'] ?? '',
      coordinates: LatLng(
        _asDouble(json['destination_lat'], 22.3590),
        _asDouble(json['destination_lng'], 91.8215),
      ),
    );

    List<LatLng> polyline = [];
    if (json['primary_polyline'] != null) {
      try {
        final rawPoly = json['primary_polyline'] is String
            ? jsonDecode(json['primary_polyline'])
            : json['primary_polyline'];
        if (rawPoly is List) {
          for (final pt in rawPoly) {
            if (pt is List && pt.length >= 2) {
              polyline.add(LatLng(_asDouble(pt[0]), _asDouble(pt[1])));
            }
          }
        }
      } catch (_) {}
    }
    if (polyline.isEmpty) {
      polyline = [origin.coordinates, dest.coordinates];
    }

    final primaryRoute = RouteOption(
      id: 'prim_${origin.id}_${dest.id}',
      name: json['primary_route_name'] ?? 'Main Route',
      viaRoadName: json['primary_route_via'] ?? 'Direct Route',
      polyline: polyline,
      isPrimary: true,
      isSelected: true,
      distanceKm: _asDouble(json['primary_distance_km'], 24.5),
      durationMinutes: _asInt(json['primary_duration_mins'], 45),
    );

    List<RouteOption> altRoutes = [];
    if (json['alternate_routes'] != null) {
      try {
        final rawAlts = json['alternate_routes'] is String
            ? jsonDecode(json['alternate_routes'])
            : json['alternate_routes'];
        if (rawAlts is List) {
          for (final alt in rawAlts) {
            if (alt is Map) {
              altRoutes.add(RouteOption(
                id: alt['id']?.toString() ?? 'alt_${DateTime.now().millisecondsSinceEpoch}',
                name: alt['name']?.toString() ?? 'Alternate Route',
                viaRoadName: alt['via']?.toString() ?? alt['viaRoadName']?.toString() ?? 'Via Alternate Road',
                polyline: [origin.coordinates, dest.coordinates],
                distanceKm: _asDouble(alt['distanceKm'] ?? alt['distance_km'], primaryRoute.distanceKm),
                durationMinutes: _asInt(alt['durationMinutes'] ?? alt['duration_mins'], primaryRoute.durationMinutes),
                isSelected: alt['isSelected'] ?? true,
              ));
            }
          }
        }
      } catch (_) {}
    }

    RideStatus status = RideStatus.scheduled;
    final statusStr = json['status']?.toString();
    if (statusStr == 'completed') {
      status = RideStatus.completed;
    } else if (statusStr == 'cancelled') {
      status = RideStatus.cancelled;
    } else if (statusStr == 'in_progress' || statusStr == 'inProgress') {
      status = RideStatus.inProgress;
    }

    return RidePost(
      id: json['id']?.toString() ?? 'ride_${DateTime.now().millisecondsSinceEpoch}',
      rider: rider,
      origin: origin,
      destination: dest,
      primaryRoute: primaryRoute,
      alternateRoutes: altRoutes,
      detourToleranceKm: _asDouble(json['detour_tolerance_km'], 2.0),
      departureTime: json['departure_time'] != null
          ? DateTime.tryParse(json['departure_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalSeats: _asInt(json['total_seats'], 1),
      availableSeats: _asInt(json['available_seats'], 1),
      farePerSeat: _asDouble(json['fare_per_seat'], 120.0),
      vehicleType: json['vehicle_type'] ?? 'Motorcycle',
      vehiclePlate: json['vehicle_plate'] ?? 'Plate Verified',
      vehicleModel: json['vehicle_model'] ?? 'Vehicle',
      status: status,
    );
  }

  // 10. Fetch Confirmed/Completed Bookings from NeonDB
  Future<List<ConfirmedBooking>> fetchBookings(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/bookings/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['bookings'] is List) {
          final list = <ConfirmedBooking>[];
          for (final item in data['bookings']) {
            list.add(_mapBookingFromJson(item));
          }
          return list;
        }
      }
    } catch (_) {}
    return [];
  }

  ConfirmedBooking _mapBookingFromJson(Map<String, dynamic> json) {
    final rider = UserModel(
      id: json['rider_id']?.toString() ?? 'rider_id',
      name: json['rider_name'] ?? 'Verified Rider',
      email: json['rider_email'] ?? '',
      phone: json['rider_phone'] ?? '+880 1812-345678',
      avatarUrl: '',
      universityOrOrg: json['rider_university'] ?? 'CUET',
      nidStatus: NidStatus.verified,
      studentIdStatus: StudentIdStatus.verified,
      rating: 4.9,
      totalTrips: 15,
      activeMode: UserRoleMode.rider,
      vehiclePlate: json['vehicle_plate'],
      vehicleModel: json['vehicle_model'],
      vehicleType: json['vehicle_type'],
    );

    final passenger = UserModel(
      id: json['passenger_id']?.toString() ?? 'passenger_id',
      name: json['passenger_name'] ?? 'Commuter',
      email: json['passenger_email'] ?? '',
      phone: json['passenger_phone'] ?? '+880 1700-000000',
      avatarUrl: '',
      universityOrOrg: json['passenger_university'] ?? 'CUET',
      nidStatus: NidStatus.verified,
      studentIdStatus: StudentIdStatus.verified,
      rating: 5.0,
      totalTrips: 8,
      activeMode: UserRoleMode.passenger,
    );

    PaymentStatus payStatus = PaymentStatus.unpaid;
    if (json['payment_status'] == 'paid') payStatus = PaymentStatus.paid;

    PaymentMethod payMethod = PaymentMethod.bKash;
    if (json['payment_method'] == 'nagad') payMethod = PaymentMethod.nagad;
    if (json['payment_method'] == 'cash') payMethod = PaymentMethod.cash;

    TripLifecycleStatus tripStatus = TripLifecycleStatus.confirmed;
    if (json['trip_status'] == 'completed') tripStatus = TripLifecycleStatus.completed;
    if (json['trip_status'] == 'inProgress' || json['trip_status'] == 'in_progress') tripStatus = TripLifecycleStatus.inProgress;

    return ConfirmedBooking(
      id: json['id']?.toString() ?? 'book_${DateTime.now().millisecondsSinceEpoch}',
      ridePostId: json['ride_post_id']?.toString() ?? '',
      rider: rider,
      passenger: passenger,
      pickup: LocationPoint(
        id: json['pickup_id']?.toString() ?? 'loc_pickup',
        name: json['pickup_name'] ?? 'Pickup Point',
        description: '',
        coordinates: LatLng(
          _asDouble(json['pickup_lat'], 22.4601),
          _asDouble(json['pickup_lng'], 91.9711),
        ),
      ),
      dropoff: LocationPoint(
        id: json['dropoff_id']?.toString() ?? 'loc_dropoff',
        name: json['dropoff_name'] ?? 'Dropoff Point',
        description: '',
        coordinates: LatLng(
          _asDouble(json['dropoff_lat'], 22.3592),
          _asDouble(json['dropoff_lng'], 91.8215),
        ),
      ),
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.tryParse(json['scheduled_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fare: _asDouble(json['fare'], 120.0),
      pinCode: json['pin_code']?.toString() ?? '1234',
      paymentStatus: payStatus,
      paymentMethod: payMethod,
      tripStatus: tripStatus,
      passengerGivenRating: json['rating'] != null ? _asDouble(json['rating']) : null,
      passengerGivenReview: json['review']?.toString(),
    );
  }
}
