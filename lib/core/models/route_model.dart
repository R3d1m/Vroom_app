import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class LocationPoint {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;

  const LocationPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPoint &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'lat': coordinates.latitude,
    'lng': coordinates.longitude,
  };

  static double _asDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'] ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coordinates: LatLng(
        _asDouble(json['lat'] ?? json['latitude'], 22.3569),
        _asDouble(json['lng'] ?? json['longitude'], 91.7832),
      ),
    );
  }
}

class RouteOption {
  final String id;
  final String name;
  final String viaRoadName;
  final List<LatLng> polyline;
  final bool isPrimary;
  bool isSelected;
  final double distanceKm;
  final int durationMinutes;

  RouteOption({
    required this.id,
    required this.name,
    required this.viaRoadName,
    required this.polyline,
    this.isPrimary = false,
    this.isSelected = true,
    required this.distanceKm,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'viaRoadName': viaRoadName,
    'polyline': polyline.map((p) => [p.latitude, p.longitude]).toList(),
    'isPrimary': isPrimary,
    'isSelected': isSelected,
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
  };

  factory RouteOption.fromJson(Map<String, dynamic> json) {
    List<LatLng> pts = [];
    if (json['polyline'] is List) {
      for (final pt in json['polyline']) {
        if (pt is List && pt.length >= 2) {
          final lat = pt[0] is num ? (pt[0] as num).toDouble() : double.tryParse(pt[0].toString()) ?? 0.0;
          final lng = pt[1] is num ? (pt[1] as num).toDouble() : double.tryParse(pt[1].toString()) ?? 0.0;
          pts.add(LatLng(lat, lng));
        }
      }
    }
    return RouteOption(
      id: json['id']?.toString() ?? 'route_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Route',
      viaRoadName: json['viaRoadName']?.toString() ?? json['via']?.toString() ?? 'Direct Route',
      polyline: pts,
      isPrimary: json['isPrimary'] == true,
      isSelected: json['isSelected'] != false,
      distanceKm: json['distanceKm'] is num ? (json['distanceKm'] as num).toDouble() : double.tryParse(json['distanceKm']?.toString() ?? '') ?? 0.0,
      durationMinutes: json['durationMinutes'] is int ? json['durationMinutes'] as int : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
    );
  }

  // Calculate minimum distance from a given point to this route's polyline
  double minDistanceToPointKm(LatLng point) {
    if (polyline.isEmpty) return double.infinity;
    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      double d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance;
  }

  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    const Distance distance = Distance();
    double l2 = math.pow(distance.as(LengthUnit.Meter, a, b), 2).toDouble();
    if (l2 == 0) return distance.as(LengthUnit.Kilometer, p, a);
    
    // Vector projection
    double t = ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
                (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
               (math.pow(b.latitude - a.latitude, 2) + math.pow(b.longitude - a.longitude, 2));
    t = math.max(0, math.min(1, t));
    
    LatLng projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
    return distance.as(LengthUnit.Kilometer, p, projection);
  }
}
