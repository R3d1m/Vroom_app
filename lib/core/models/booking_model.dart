import 'user_model.dart';
import 'route_model.dart';

enum PaymentStatus { unpaid, paid, refunded }
enum PaymentMethod { bKash, nagad, cash }
enum TripLifecycleStatus { confirmed, riderArrived, inProgress, completed, cancelled }

class ConfirmedBooking {
  final String id;
  final String ridePostId;
  final UserModel rider;
  final UserModel passenger;
  final LocationPoint pickup;
  final LocationPoint dropoff;
  final DateTime scheduledTime;
  final double fare;
  final String pinCode; // 4-digit PIN for passenger verification
  PaymentStatus paymentStatus;
  PaymentMethod paymentMethod;
  TripLifecycleStatus tripStatus;
  double? passengerGivenRating;
  String? passengerGivenReview;
  List<String> passengerGivenTags;
  DateTime createdAt;

  ConfirmedBooking({
    required this.id,
    required this.ridePostId,
    required this.rider,
    required this.passenger,
    required this.pickup,
    required this.dropoff,
    required this.scheduledTime,
    required this.fare,
    required this.pinCode,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.bKash,
    this.tripStatus = TripLifecycleStatus.confirmed,
    this.passengerGivenRating,
    this.passengerGivenReview,
    this.passengerGivenTags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ConfirmedBooking copyWith({
    String? id,
    String? ridePostId,
    UserModel? rider,
    UserModel? passenger,
    LocationPoint? pickup,
    LocationPoint? dropoff,
    DateTime? scheduledTime,
    double? fare,
    String? pinCode,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    TripLifecycleStatus? tripStatus,
    double? passengerGivenRating,
    String? passengerGivenReview,
    List<String>? passengerGivenTags,
    DateTime? createdAt,
  }) {
    return ConfirmedBooking(
      id: id ?? this.id,
      ridePostId: ridePostId ?? this.ridePostId,
      rider: rider ?? this.rider,
      passenger: passenger ?? this.passenger,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      fare: fare ?? this.fare,
      pinCode: pinCode ?? this.pinCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      tripStatus: tripStatus ?? this.tripStatus,
      passengerGivenRating: passengerGivenRating ?? this.passengerGivenRating,
      passengerGivenReview: passengerGivenReview ?? this.passengerGivenReview,
      passengerGivenTags: passengerGivenTags ?? this.passengerGivenTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ridePostId': ridePostId,
    'rider': rider.toJson(),
    'passenger': passenger.toJson(),
    'pickup': pickup.toJson(),
    'dropoff': dropoff.toJson(),
    'scheduledTime': scheduledTime.toIso8601String(),
    'fare': fare,
    'pinCode': pinCode,
    'paymentStatus': paymentStatus.name,
    'paymentMethod': paymentMethod.name,
    'tripStatus': tripStatus.name,
    'passengerGivenRating': passengerGivenRating,
    'passengerGivenReview': passengerGivenReview,
    'passengerGivenTags': passengerGivenTags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ConfirmedBooking.fromJson(Map<String, dynamic> json) {
    PaymentStatus pStatus = PaymentStatus.unpaid;
    if (json['paymentStatus'] == 'paid') pStatus = PaymentStatus.paid;
    if (json['paymentStatus'] == 'refunded') pStatus = PaymentStatus.refunded;

    PaymentMethod pMethod = PaymentMethod.bKash;
    if (json['paymentMethod'] == 'nagad') pMethod = PaymentMethod.nagad;
    if (json['paymentMethod'] == 'cash') pMethod = PaymentMethod.cash;

    TripLifecycleStatus tStatus = TripLifecycleStatus.confirmed;
    final st = json['tripStatus']?.toString();
    if (st == 'inProgress' || st == 'in_progress') tStatus = TripLifecycleStatus.inProgress;
    if (st == 'completed') tStatus = TripLifecycleStatus.completed;
    if (st == 'cancelled') tStatus = TripLifecycleStatus.cancelled;
    if (st == 'riderArrived' || st == 'rider_arrived') tStatus = TripLifecycleStatus.riderArrived;

    return ConfirmedBooking(
      id: json['id']?.toString() ?? 'book_${DateTime.now().millisecondsSinceEpoch}',
      ridePostId: json['ridePostId']?.toString() ?? '',
      rider: UserModel.fromJson(Map<String, dynamic>.from(json['rider'] ?? {})),
      passenger: UserModel.fromJson(Map<String, dynamic>.from(json['passenger'] ?? {})),
      pickup: LocationPoint.fromJson(Map<String, dynamic>.from(json['pickup'] ?? {})),
      dropoff: LocationPoint.fromJson(Map<String, dynamic>.from(json['dropoff'] ?? {})),
      scheduledTime: DateTime.tryParse(json['scheduledTime']?.toString() ?? '') ?? DateTime.now(),
      fare: json['fare'] is num ? (json['fare'] as num).toDouble() : double.tryParse(json['fare']?.toString() ?? '') ?? 0.0,
      pinCode: json['pinCode']?.toString() ?? '1234',
      paymentStatus: pStatus,
      paymentMethod: pMethod,
      tripStatus: tStatus,
      passengerGivenRating: json['passengerGivenRating'] is num ? (json['passengerGivenRating'] as num).toDouble() : null,
      passengerGivenReview: json['passengerGivenReview']?.toString(),
      passengerGivenTags: (json['passengerGivenTags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
