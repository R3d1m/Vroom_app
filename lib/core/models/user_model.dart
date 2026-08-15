enum NidStatus { unverified, pending, verified, rejected }
enum StudentIdStatus { unverified, verified }
enum UserRoleMode { passenger, rider }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final String universityOrOrg;
  final NidStatus nidStatus;
  final StudentIdStatus studentIdStatus;
  final double rating;
  final int totalTrips;
  final UserRoleMode activeMode;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleType; // 'Bike' or 'Car'

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.universityOrOrg,
    this.nidStatus = NidStatus.verified,
    this.studentIdStatus = StudentIdStatus.verified,
    this.rating = 4.9,
    this.totalTrips = 38,
    this.activeMode = UserRoleMode.passenger,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleType,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? universityOrOrg,
    NidStatus? nidStatus,
    StudentIdStatus? studentIdStatus,
    double? rating,
    int? totalTrips,
    UserRoleMode? activeMode,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleType,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      universityOrOrg: universityOrOrg ?? this.universityOrOrg,
      nidStatus: nidStatus ?? this.nidStatus,
      studentIdStatus: studentIdStatus ?? this.studentIdStatus,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      activeMode: activeMode ?? this.activeMode,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'universityOrOrg': universityOrOrg,
      'nidStatus': nidStatus.name,
      'studentIdStatus': studentIdStatus.name,
      'rating': rating,
      'totalTrips': totalTrips,
      'activeMode': activeMode.name,
      'vehiclePlate': vehiclePlate,
      'vehicleModel': vehicleModel,
      'vehicleType': vehicleType,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      universityOrOrg: json['universityOrOrg'] ?? '',
      nidStatus: NidStatus.values.firstWhere(
        (e) => e.name == json['nidStatus'],
        orElse: () => NidStatus.verified,
      ),
      studentIdStatus: StudentIdStatus.values.firstWhere(
        (e) => e.name == json['studentIdStatus'],
        orElse: () => StudentIdStatus.verified,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalTrips: json['totalTrips'] ?? 0,
      activeMode: UserRoleMode.values.firstWhere(
        (e) => e.name == json['activeMode'],
        orElse: () => UserRoleMode.passenger,
      ),
      vehiclePlate: json['vehiclePlate'],
      vehicleModel: json['vehicleModel'],
      vehicleType: json['vehicleType'],
    );
  }
}
