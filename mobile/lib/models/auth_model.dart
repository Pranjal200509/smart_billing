class JwtResponse {
  final String token;
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? customerId;

  JwtResponse({
    required this.token,
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.customerId,
  });

  factory JwtResponse.fromJson(Map<String, dynamic> json) {
    return JwtResponse(
      token: json['token'] ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'ROLE_USER',
      customerId: json['customerId'],
    );
  }
}
