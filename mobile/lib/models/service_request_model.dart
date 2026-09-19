class ServiceRequestModel {
  final int id;
  final String requestId;
  final String requestType;
  final String details;
  final String status;
  final String? createdAt;
  final String? userFullName;
  final String? userEmail;

  ServiceRequestModel({
    required this.id,
    required this.requestId,
    required this.requestType,
    required this.details,
    required this.status,
    this.createdAt,
    this.userFullName,
    this.userEmail,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? email;
    if (json['user'] is Map) {
      name = json['user']['fullName'];
      email = json['user']['email'];
    }

    return ServiceRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      requestId: json['requestId'] ?? '',
      requestType: json['requestType'] ?? '',
      details: json['details'] ?? '',
      status: json['status'] ?? 'SUBMITTED',
      createdAt: json['createdAt'],
      userFullName: name,
      userEmail: email,
    );
  }
}
