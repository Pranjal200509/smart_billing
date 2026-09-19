class ComplaintModel {
  final int id;
  final String complaintId;
  final String complaintType;
  final String description;
  final String status;
  final String? resolutionDetails;
  final String? createdAt;
  final String? userFullName;
  final String? userEmail;

  ComplaintModel({
    required this.id,
    required this.complaintId,
    required this.complaintType,
    required this.description,
    required this.status,
    this.resolutionDetails,
    this.createdAt,
    this.userFullName,
    this.userEmail,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? email;
    if (json['user'] is Map) {
      name = json['user']['fullName'];
      email = json['user']['email'];
    }

    return ComplaintModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      complaintId: json['complaintId'] ?? '',
      complaintType: json['complaintType'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'SUBMITTED',
      resolutionDetails: json['resolutionDetails'],
      createdAt: json['createdAt'],
      userFullName: name,
      userEmail: email,
    );
  }
}
