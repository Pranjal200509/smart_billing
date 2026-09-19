class UserProfileModel {
  final int id;
  final String? customerId;
  final String fullName;
  final String email;
  final String mobileNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? connectionType;
  final double loadCapacityKw;
  final String? status;
  final String? meterNumber;
  final String? consumerNumber;
  final double currentReadingKwh;
  final String? meterStatus;

  UserProfileModel({
    required this.id,
    this.customerId,
    required this.fullName,
    required this.email,
    required this.mobileNumber,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.connectionType,
    required this.loadCapacityKw,
    this.status,
    this.meterNumber,
    this.consumerNumber,
    required this.currentReadingKwh,
    this.meterStatus,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      customerId: json['customerId'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pinCode: json['pinCode'],
      connectionType: json['connectionType'],
      loadCapacityKw: (json['loadCapacityKw'] is num)
          ? (json['loadCapacityKw'] as num).toDouble()
          : double.tryParse(json['loadCapacityKw'].toString()) ?? 5.0,
      status: json['status'] ?? 'VERIFIED',
      meterNumber: json['meterNumber'],
      consumerNumber: json['consumerNumber'],
      currentReadingKwh: (json['currentReadingKwh'] is num)
          ? (json['currentReadingKwh'] as num).toDouble()
          : double.tryParse(json['currentReadingKwh'].toString()) ?? 0.0,
      meterStatus: json['meterStatus'] ?? 'ACTIVE',
    );
  }
}
