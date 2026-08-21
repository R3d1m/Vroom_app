import 'package:latlong2/latlong.dart';
import 'user_model.dart';
import 'route_model.dart';

enum RideStatus { scheduled, inProgress, completed, cancelled }

class RidePost {
  final String id;
  final UserModel rider;
  final LocationPoint origin;
  final LocationPoint destination;
  final RouteOption primaryRoute;
  final List<RouteOption> alternateRoutes;
  final double detourToleranceKm;
  final DateTime departureTime;
  final int totalSeats;
  int availableSeats;
  final double farePerSeat;
  final String vehicleType; // 'Motorcycle' or 'Car'
  final String vehiclePlate;
  final String vehicleModel;
  RideStatus status;

  RidePost({
    required this.id,
    required this.rider,
    required this.origin,
    required this.destination,
    required this.primaryRoute,
    required this.alternateRoutes,
    this.detourToleranceKm = 1.5,
    required this.departureTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.farePerSeat,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.vehicleModel,
    this.status = RideStatus.scheduled,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'rider': rider.toJson(),
    'origin': origin.toJson(),
    'destination': destination.toJson(),
    'primaryRoute': primaryRoute.toJson(),
    'alternateRoutes': alternateRoutes.map((r) => r.toJson()).toList(),
    'detourToleranceKm': detourToleranceKm,
    'departureTime': departureTime.toIso8601String(),
    'totalSeats': totalSeats,
    'availableSeats': availableSeats,
    'farePerSeat': farePerSeat,
    'vehicleType': vehicleType,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'status': status.name,
  };

  factory RidePost.fromJson(Map<String, dynamic> json) {
    RideStatus s = RideStatus.scheduled;
    final st = json['status']?.toString();
    if (st == 'inProgress' || st == 'in_progress') s = RideStatus.inProgress;
    if (st == 'completed') s = RideStatus.completed;
    if (st == 'cancelled') s = RideStatus.cancelled;

    List<RouteOption> alts = [];
    if (json['alternateRoutes'] is List) {
      for (final a in json['alternateRoutes']) {
        if (a is Map) alts.add(RouteOption.fromJson(Map<String, dynamic>.from(a)));
      }
    }

    return RidePost(
      id: json['id']?.toString() ?? 'ride_${DateTime.now().millisecondsSinceEpoch}',
      rider: UserModel.fromJson(Map<String, dynamic>.from(json['rider'] ?? {})),
      origin: LocationPoint.fromJson(Map<String, dynamic>.from(json['origin'] ?? {})),
      destination: LocationPoint.fromJson(Map<String, dynamic>.from(json['destination'] ?? {})),
      primaryRoute: RouteOption.fromJson(Map<String, dynamic>.from(json['primaryRoute'] ?? {})),
      alternateRoutes: alts,
      detourToleranceKm: json['detourToleranceKm'] is num ? (json['detourToleranceKm'] as num).toDouble() : double.tryParse(json['detourToleranceKm']?.toString() ?? '') ?? 2.0,
      departureTime: DateTime.tryParse(json['departureTime']?.toString() ?? '') ?? DateTime.now(),
      totalSeats: json['totalSeats'] is int ? json['totalSeats'] as int : int.tryParse(json['totalSeats']?.toString() ?? '') ?? 1,
      availableSeats: json['availableSeats'] is int ? json['availableSeats'] as int : int.tryParse(json['availableSeats']?.toString() ?? '') ?? 1,
      farePerSeat: json['farePerSeat'] is num ? (json['farePerSeat'] as num).toDouble() : double.tryParse(json['farePerSeat']?.toString() ?? '') ?? 120.0,
      vehicleType: json['vehicleType']?.toString() ?? 'Motorcycle',
      vehiclePlate: json['vehiclePlate']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      status: s,
    );
  }

  // Check if passenger's pickup and drop-off match this ride's selected corridors
  bool matchesPassengerRoute(LatLng pickup, LatLng dropoff) {
    const Distance distance = Distance();
    final originDist = distance.as(LengthUnit.Kilometer, origin.coordinates, pickup);
    final destDist = distance.as(LengthUnit.Kilometer, destination.coordinates, dropoff);

    // Direct origin-destination proximity match (within 2.5 km or detourTolerance)
    final directTolerance = detourToleranceKm < 2.5 ? 2.5 : detourToleranceKm;
    if (originDist <= directTolerance && destDist <= directTolerance) {
      return true;
    }

    // Collect all routes the rider is willing to take
    final activeRoutes = <RouteOption>[
      primaryRoute,
      ...alternateRoutes.where((r) => r.isSelected),
    ];

    final effectiveTolerance = detourToleranceKm < 1.5 ? 1.5 : detourToleranceKm;

    for (final route in activeRoutes) {
      final pickupDist = route.minDistanceToPointKm(pickup);
      final dropoffDist = route.minDistanceToPointKm(dropoff);

      if (pickupDist <= effectiveTolerance && dropoffDist <= effectiveTolerance) {
        return true;
      }
    }
    return false;
  }

  // Get minimum detour required for this passenger across active routes
  double calculateDetourForPassenger(LatLng pickup, LatLng dropoff) {
    final activeRoutes = <RouteOption>[
      primaryRoute,
      ...alternateRoutes.where((r) => r.isSelected),
    ];

    double minDetour = double.infinity;
    for (final route in activeRoutes) {
      final pickupDist = route.minDistanceToPointKm(pickup);
      final dropoffDist = route.minDistanceToPointKm(dropoff);
      final totalDetour = pickupDist + dropoffDist;
      if (totalDetour < minDetour) {
        minDetour = totalDetour;
      }
    }
    return minDetour;
  }
}
