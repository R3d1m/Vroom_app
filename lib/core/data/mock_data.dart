import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/route_model.dart';
import '../models/ride_post.dart';
import '../models/booking_model.dart';

class VroomMockData {
  // Common Location Points in Chittagong & Campus corridors
  static const LocationPoint cuetCampus = LocationPoint(
    id: 'loc_cuet',
    name: 'CUET Campus (Main Gate)',
    description: 'Chittagong University of Engineering and Technology, Raozan',
    coordinates: LatLng(22.4601, 91.9711),
  );

  static const LocationPoint gecCircle = LocationPoint(
    id: 'loc_gec',
    name: 'GEC Circle',
    description: 'GEC Intersection, Nasirabad, Chattogram',
    coordinates: LatLng(22.3592, 91.8215),
  );

  static const LocationPoint no2Gate = LocationPoint(
    id: 'loc_2nogate',
    name: '2 No. Gate (Sholoshohor)',
    description: 'Sholoshohor 2 No. Gate, CDA Avenue',
    coordinates: LatLng(22.3685, 91.8266),
  );

  static const LocationPoint agrabad = LocationPoint(
    id: 'loc_agrabad',
    name: 'Agrabad Commercial Area',
    description: 'Badamtoli Mor, Agrabad C/A',
    coordinates: LatLng(22.3275, 91.8123),
  );

  static const LocationPoint oxygen = LocationPoint(
    id: 'loc_oxygen',
    name: 'Oxygen Intersection',
    description: 'Oxygen Mor, Hathazari Road',
    coordinates: LatLng(22.3995, 91.8152),
  );

  static const LocationPoint cuCampus = LocationPoint(
    id: 'loc_cu',
    name: 'Chittagong University (Zero Point)',
    description: 'University of Chittagong, Hathazari',
    coordinates: LatLng(22.4716, 91.7877),
  );

  static const LocationPoint muradpur = LocationPoint(
    id: 'loc_muradpur',
    name: 'Muradpur Mor',
    description: 'Muradpur Intersection, Arakan Road',
    coordinates: LatLng(22.3654, 91.8412),
  );

  static const LocationPoint newMarket = LocationPoint(
    id: 'loc_newmarket',
    name: 'New Market Mor',
    description: 'Kotwali, Chattogram',
    coordinates: LatLng(22.3352, 91.8324),
  );

  static const LocationPoint pahartali = LocationPoint(
    id: 'loc_pahartali',
    name: 'Pahartali Railway Station',
    description: 'Pahartali, Chattogram',
    coordinates: LatLng(22.3580, 91.7770),
  );

  static List<LocationPoint> get allLocations => [
    cuetCampus,
    gecCircle,
    no2Gate,
    agrabad,
    oxygen,
    cuCampus,
    muradpur,
    newMarket,
    pahartali,
  ];

  // Stakeholder Users (synced with NeonDB UUIDs)
  static const UserModel currentUser = UserModel(
    id: 'a1111111-1111-1111-1111-111111111111',
    name: 'Md. Redwan Mahmud',
    phone: '+880 1712-345678',
    email: 'redwan@cuet.ac.bd',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    universityOrOrg: 'CSE, CUET (ID: 2204055)',
    nidStatus: NidStatus.verified,
    studentIdStatus: StudentIdStatus.verified,
    rating: 4.95,
    totalTrips: 42,
    activeMode: UserRoleMode.passenger,
    vehiclePlate: null,
    vehicleModel: null,
    vehicleType: null,
  );

  static const UserModel riderImtiaj = UserModel(
    id: 'b2222222-2222-2222-2222-222222222222',
    name: 'Imtiaj Uddin',
    phone: '+880 1819-223344',
    email: 'imtiaj@premieruniv.edu',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    universityOrOrg: 'Premier University (PU)',
    nidStatus: NidStatus.verified,
    studentIdStatus: StudentIdStatus.verified,
    rating: 4.88,
    totalTrips: 56,
    activeMode: UserRoleMode.rider,
    vehiclePlate: 'Chatto Metro-Ha 139396',
    vehicleModel: 'Honda CB Hornet 160R',
    vehicleType: 'Motorcycle',
  );

  static const UserModel riderAnas = UserModel(
    id: 'c3333333-3333-3333-3333-333333333333',
    name: 'Mobtasim Islam Anas',
    phone: '+880 1911-556677',
    email: 'anas@cu.ac.bd',
    avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    universityOrOrg: 'University of Chittagong (CU)',
    nidStatus: NidStatus.verified,
    studentIdStatus: StudentIdStatus.verified,
    rating: 4.92,
    totalTrips: 84,
    activeMode: UserRoleMode.rider,
    vehiclePlate: 'Chatta Metro-Ha 188841',
    vehicleModel: 'Suzuki Gixxer SF',
    vehicleType: 'Motorcycle',
  );

  static const UserModel riderJuman = UserModel(
    id: 'd4444444-4444-4444-4444-444444444444',
    name: 'Syed Juman Al Mahmoud',
    phone: '+880 1622-778899',
    email: 'juman@cuet.ac.bd',
    avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
    universityOrOrg: 'CSE, CUET (ID: 2204060)',
    nidStatus: NidStatus.verified,
    studentIdStatus: StudentIdStatus.verified,
    rating: 4.96,
    totalTrips: 31,
    activeMode: UserRoleMode.rider,
    vehiclePlate: 'Chatto Metro-Ga 112233',
    vehicleModel: 'Toyota Corolla Axio',
    vehicleType: 'Car',
  );

  // Sample Ride Posts with Primary + Alternate Routes
  static List<RidePost> getInitialRidePosts() {
    final now = DateTime.now();
    // Advance scheduled trips for today and tomorrow
    final tripTime1 = DateTime(now.year, now.month, now.day, 17, 30);
    final tripTime2 = DateTime(now.year, now.month, now.day + 1, 9, 00);
    final tripTime3 = DateTime(now.year, now.month, now.day + 1, 9, 15);

    // Polyline 1: CUET to GEC Circle via Kaptai Highway -> Muradpur -> 2 No Gate
    final primaryPolyline1 = [
      const LatLng(22.4601, 91.9711), // CUET
      const LatLng(22.4350, 91.9300), // Raozan Pahartali
      const LatLng(22.4050, 91.8850), // Kaptai Road / Kuwaiash
      const LatLng(22.3820, 91.8540), // Bahaddarhat
      const LatLng(22.3654, 91.8412), // Muradpur
      const LatLng(22.3685, 91.8266), // 2 No Gate
      const LatLng(22.3592, 91.8215), // GEC Circle
    ];

    // Alternate Corridor 1: via Bayezid Link Road
    final alternatePolyline1 = [
      const LatLng(22.4601, 91.9711), // CUET
      const LatLng(22.4350, 91.9300), 
      const LatLng(22.3995, 91.8152), // Oxygen Mor
      const LatLng(22.3810, 91.7980), // Bayezid Bostami Road
      const LatLng(22.3592, 91.8215), // GEC Circle
    ];

    // Polyline 2: Oxygen to Agrabad via 2 No Gate & Tigerpass
    final primaryPolyline2 = [
      const LatLng(22.3995, 91.8152), // Oxygen
      const LatLng(22.3685, 91.8266), // 2 No Gate
      const LatLng(22.3592, 91.8215), // GEC
      const LatLng(22.3480, 91.8160), // Wasa / Lalkhan Bazar
      const LatLng(22.3390, 91.8140), // Tigerpass
      const LatLng(22.3275, 91.8123), // Agrabad
    ];

    // Alternate Corridor 2: via Port Connecting Road
    final alternatePolyline2 = [
      const LatLng(22.3995, 91.8152), // Oxygen
      const LatLng(22.3580, 91.7770), // Pahartali
      const LatLng(22.3410, 91.7820), // Port Connecting Road
      const LatLng(22.3275, 91.8123), // Agrabad
    ];

    // Polyline 3: CU to New Market via Oxygen & Muradpur
    final primaryPolyline3 = [
      const LatLng(22.4716, 91.7877), // CU Zero Point
      const LatLng(22.4400, 91.8020), // Hathazari Bus Stand
      const LatLng(22.3995, 91.8152), // Oxygen
      const LatLng(22.3654, 91.8412), // Muradpur
      const LatLng(22.3500, 91.8380), // Chawkbazar
      const LatLng(22.3352, 91.8324), // New Market
    ];

    return [
      RidePost(
        id: 'ride_post_001',
        rider: riderImtiaj,
        origin: cuetCampus,
        destination: gecCircle,
        primaryRoute: RouteOption(
          id: 'route_cuet_gec_main',
          name: 'Kaptai Highway → Muradpur → 2 No Gate',
          viaRoadName: 'Via Kaptai Rd & CDA Ave',
          polyline: primaryPolyline1,
          isPrimary: true,
          isSelected: true,
          distanceKm: 24.5,
          durationMinutes: 45,
        ),
        alternateRoutes: [
          RouteOption(
            id: 'route_cuet_gec_alt',
            name: 'Via Oxygen & Bayezid Bypass',
            viaRoadName: 'Via Oxygen - Bayezid Link',
            polyline: alternatePolyline1,
            isPrimary: false,
            isSelected: true, // Rider enabled this alternate corridor!
            distanceKm: 26.2,
            durationMinutes: 48,
          ),
        ],
        detourToleranceKm: 2.0,
        departureTime: tripTime1,
        totalSeats: 1,
        availableSeats: 1,
        farePerSeat: 120.0,
        vehicleType: 'Motorcycle',
        vehiclePlate: 'Chatto Metro-Ha 139396',
        vehicleModel: 'Honda CB Hornet',
      ),
      RidePost(
        id: 'ride_post_002',
        rider: riderAnas,
        origin: oxygen,
        destination: agrabad,
        primaryRoute: RouteOption(
          id: 'route_oxygen_agrabad_main',
          name: '2 No Gate → GEC → Tigerpass',
          viaRoadName: 'Via CDA Avenue & Tigerpass',
          polyline: primaryPolyline2,
          isPrimary: true,
          isSelected: true,
          distanceKm: 12.8,
          durationMinutes: 30,
        ),
        alternateRoutes: [
          RouteOption(
            id: 'route_oxygen_agrabad_alt',
            name: 'Via Pahartali & Port Connecting Road',
            viaRoadName: 'Via Port Connecting Road',
            polyline: alternatePolyline2,
            isPrimary: false,
            isSelected: true,
            distanceKm: 14.1,
            durationMinutes: 32,
          ),
        ],
        detourToleranceKm: 1.5,
        departureTime: tripTime2,
        totalSeats: 1,
        availableSeats: 1,
        farePerSeat: 80.0,
        vehicleType: 'Motorcycle',
        vehiclePlate: 'Chatta Metro-Ha 188841',
        vehicleModel: 'Suzuki Gixxer SF',
      ),
      RidePost(
        id: 'ride_post_003',
        rider: riderJuman,
        origin: cuCampus,
        destination: newMarket,
        primaryRoute: RouteOption(
          id: 'route_cu_newmarket_main',
          name: 'Hathazari → Oxygen → Muradpur → Chawkbazar',
          viaRoadName: 'Via Hathazari & Chawkbazar',
          polyline: primaryPolyline3,
          isPrimary: true,
          isSelected: true,
          distanceKm: 21.0,
          durationMinutes: 40,
        ),
        alternateRoutes: [],
        detourToleranceKm: 2.0,
        departureTime: tripTime3,
        totalSeats: 3,
        availableSeats: 3,
        farePerSeat: 95.0,
        vehicleType: 'Car',
        vehiclePlate: 'Chatto Metro-Ga 112233',
        vehicleModel: 'Toyota Axio (AC)',
      ),
    ];
  }

  // Initial Sample Completed Trips for Ride History
  static List<ConfirmedBooking> getInitialBookings() {
    final now = DateTime.now();
    return [
      ConfirmedBooking(
        id: 'hist_book_001',
        ridePostId: 'ride_hist_001',
        rider: riderImtiaj,
        passenger: currentUser,
        pickup: cuetCampus,
        dropoff: gecCircle,
        scheduledTime: now.subtract(const Duration(days: 2, hours: 4)),
        fare: 120.0,
        pinCode: '7429',
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.bKash,
        tripStatus: TripLifecycleStatus.completed,
        passengerGivenRating: 5.0,
        passengerGivenReview: 'Very smooth ride along Kaptai Highway. On time and safe rider!',
        passengerGivenTags: ['On Time', 'Safe Driving', 'Clean Vehicle'],
        createdAt: now.subtract(const Duration(days: 2, hours: 6)),
      ),
      ConfirmedBooking(
        id: 'hist_book_002',
        ridePostId: 'ride_hist_002',
        rider: riderAnas,
        passenger: currentUser,
        pickup: oxygen,
        dropoff: agrabad,
        scheduledTime: now.subtract(const Duration(days: 4, hours: 2)),
        fare: 80.0,
        pinCode: '3182',
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.nagad,
        tripStatus: TripLifecycleStatus.completed,
        passengerGivenRating: 4.8,
        passengerGivenReview: 'Great detour management and very friendly conversation.',
        passengerGivenTags: ['Friendly', 'Polite Commuter', 'Great Route'],
        createdAt: now.subtract(const Duration(days: 4, hours: 4)),
      ),
      ConfirmedBooking(
        id: 'hist_book_003',
        ridePostId: 'ride_hist_003',
        rider: riderJuman,
        passenger: currentUser,
        pickup: cuCampus,
        dropoff: newMarket,
        scheduledTime: now.subtract(const Duration(days: 6, hours: 5)),
        fare: 95.0,
        pinCode: '5521',
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
        tripStatus: TripLifecycleStatus.completed,
        passengerGivenRating: 5.0,
        passengerGivenReview: 'AC was comfortable and reached New Market before exam schedule!',
        passengerGivenTags: ['On Time', 'Clean Vehicle'],
        createdAt: now.subtract(const Duration(days: 6, hours: 7)),
      ),
      ConfirmedBooking(
        id: 'hist_book_004',
        ridePostId: 'ride_hist_004',
        rider: currentUser,
        passenger: riderImtiaj,
        pickup: gecCircle,
        dropoff: cuetCampus,
        scheduledTime: now.subtract(const Duration(days: 1, hours: 3)),
        fare: 120.0,
        pinCode: '6102',
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.bKash,
        tripStatus: TripLifecycleStatus.completed,
        passengerGivenRating: 5.0,
        passengerGivenReview: 'Excellent rider! Shared route safely and reached campus smoothly.',
        passengerGivenTags: ['On Time', 'Safe Driving', 'Clean Helmet'],
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      ),
      ConfirmedBooking(
        id: 'hist_book_005',
        ridePostId: 'ride_hist_005',
        rider: riderAnas,
        passenger: currentUser,
        pickup: oxygen,
        dropoff: gecCircle,
        scheduledTime: now.subtract(const Duration(hours: 3)),
        fare: 60.0,
        pinCode: '4819',
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.bKash,
        tripStatus: TripLifecycleStatus.completed,
        passengerGivenRating: null,
        passengerGivenReview: null,
        passengerGivenTags: const [],
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
