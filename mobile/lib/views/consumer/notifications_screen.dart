import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/notification_model.dart';
import '../../services/consumer_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ConsumerService.getNotifications();
      if (mounted) setState(() => _notifications = list);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ConsumerService.markNotificationAsRead(id);
      _fetchNotifications();
    } catch (_) {}
  }

  IconData _getIconForType(String type) {
    if (type.contains('Bill')) return Icons.receipt_long;
    if (type.contains('Payment')) return Icons.check_circle_outline;
    if (type.contains('Due')) return Icons.warning_amber_rounded;
    if (type.contains('Power')) return Icons.power;
    return Icons.notifications;
  }

  Color _getColorForType(String type) {
    if (type.contains('Bill')) return AppColors.primary;
    if (type.contains('Payment')) return AppColors.success;
    if (type.contains('Due')) return AppColors.danger;
    if (type.contains('Power')) return AppColors.accent;
    return AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage != null
                ? EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error Loading Notifications',
                    message: _errorMessage!,
                    actionText: 'Retry',
                    onAction: _fetchNotifications,
                  )
                : _notifications.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_off_outlined,
                        title: 'No Notifications',
                        message: 'You are all caught up!',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final color = _getColorForType(item.type);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: item.isRead ? AppColors.cardBg : AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color.withValues(alpha: 0.18),
                                  child: Icon(_getIconForType(item.type), color: color, size: 22),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    item.subtitle,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ),
                                onTap: () {
                                  if (!item.isRead) _markRead(item.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
