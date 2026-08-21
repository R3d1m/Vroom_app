import 'user_model.dart';
import 'route_model.dart';

enum GroupRequestStatus { pending, accepted, cancelled, expired }
enum SubRequestStatus { pending, accepted, declined, autoCancelled }

class SubRequestItem {
  final String ridePostId;
  final String riderName;
  final String riderPhone;
  final String vehicleType;
  final String vehicleModel;
  final double fare;
  SubRequestStatus status;
  String? cancellationReason;
  DateTime updatedAt;

  SubRequestItem({
    required this.ridePostId,
    required this.riderName,
    required this.riderPhone,
    required this.vehicleType,
    required this.vehicleModel,
    required this.fare,
    this.status = SubRequestStatus.pending,
    this.cancellationReason,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'ridePostId': ridePostId,
    'riderName': riderName,
    'riderPhone': riderPhone,
    'vehicleType': vehicleType,
    'vehicleModel': vehicleModel,
    'fare': fare,
    'status': status.name,
    'cancellationReason': cancellationReason,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SubRequestItem.fromJson(Map<String, dynamic> json) {
    SubRequestStatus s = SubRequestStatus.pending;
    final st = json['status']?.toString();
    if (st == 'accepted') s = SubRequestStatus.accepted;
    if (st == 'declined') s = SubRequestStatus.declined;
    if (st == 'autoCancelled' || st == 'auto_cancelled') s = SubRequestStatus.autoCancelled;
    return SubRequestItem(
      ridePostId: json['ridePostId']?.toString() ?? '',
      riderName: json['riderName']?.toString() ?? '',
      riderPhone: json['riderPhone']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleModel: json['vehicleModel']?.toString() ?? '',
      fare: json['fare'] is num ? (json['fare'] as num).toDouble() : double.tryParse(json['fare']?.toString() ?? '') ?? 0.0,
      status: s,
      cancellationReason: json['cancellationReason']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class GroupTripRequest {
  final String id;
  final UserModel passenger;
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final DateTime scheduledDeparture;
  final int requestedSeats;
  GroupRequestStatus status;
  String? acceptedRidePostId;
  String? acceptedRiderId;
  final List<SubRequestItem> subRequests;
  final DateTime createdAt;

  GroupTripRequest({
    required this.id,
    required this.passenger,
    required this.pickup,
    required this.dropoff,
    required this.scheduledDeparture,
    this.requestedSeats = 1,
    this.status = GroupRequestStatus.pending,
    this.acceptedRidePostId,
    this.acceptedRiderId,
    required this.subRequests,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'passenger': passenger.toJson(),
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'scheduledDeparture': scheduledDeparture.toIso8601String(),
    'requestedSeats': requestedSeats,
    'status': status.name,
    'acceptedRidePostId': acceptedRidePostId,
    'acceptedRiderId': acceptedRiderId,
    'subRequests': subRequests.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory GroupTripRequest.fromJson(Map<String, dynamic> json) {
    GroupRequestStatus s = GroupRequestStatus.pending;
    final st = json['status']?.toString();
    if (st == 'accepted') s = GroupRequestStatus.accepted;
    if (st == 'cancelled') s = GroupRequestStatus.cancelled;
    if (st == 'expired') s = GroupRequestStatus.expired;

    List<SubRequestItem> subs = [];
    if (json['subRequests'] is List) {
      for (final item in json['subRequests']) {
        if (item is Map) {
          subs.add(SubRequestItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return GroupTripRequest(
      id: json['id']?.toString() ?? 'greq_${DateTime.now().millisecondsSinceEpoch}',
      passenger: UserModel.fromJson(Map<String, dynamic>.from(json['passenger'] ?? {})),
      pickup: LocationPoint.fromJson(Map<String, dynamic>.from(json['pickup'] ?? {})),
      dropoff: LocationPoint.fromJson(Map<String, dynamic>.from(json['dropoff'] ?? {})),
      scheduledDeparture: DateTime.tryParse(json['scheduledDeparture']?.toString() ?? '') ?? DateTime.now(),
      requestedSeats: json['requestedSeats'] is int ? json['requestedSeats'] as int : int.tryParse(json['requestedSeats']?.toString() ?? '') ?? 1,
      status: s,
      acceptedRidePostId: json['acceptedRidePostId']?.toString(),
      acceptedRiderId: json['acceptedRiderId']?.toString(),
      subRequests: subs,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // Helper to check if broadcast is still active
  bool get isStillPending => status == GroupRequestStatus.pending;
  
  // Count how many riders are currently pending
  int get pendingCount => subRequests.where((s) => s.status == SubRequestStatus.pending).length;
  int get totalRidersTargeted => subRequests.length;
}
