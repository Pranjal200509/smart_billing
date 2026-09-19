class NotificationModel {
  final int id;
  final String title;
  final String subtitle;
  final String type;
  final bool isRead;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      type: json['type'] ?? 'General',
      isRead: json['isRead'] ?? json['read'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}
