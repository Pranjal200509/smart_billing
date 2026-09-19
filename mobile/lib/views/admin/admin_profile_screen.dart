import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/session_manager.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String _name = 'Administrator';
  String _email = 'admin@gmail.com';
  String _role = 'ROLE_ADMIN';

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final name = await SessionManager.getFullName();
    final email = await SessionManager.getEmail();
    final role = await SessionManager.getRole();
    if (mounted) {
      setState(() {
        if (name != null) _name = name;
        if (email != null) _email = email;
        if (role != null) _role = role;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Exit administrative portal?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      _role,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.security, 'Security Clearance', 'Full Administrative Privileges'),
                  const Divider(color: AppColors.border, height: 18),
                  _infoRow(Icons.lan, 'Connected Backend', 'Spring Boot 3.x REST API'),
                  const Divider(color: AppColors.border, height: 18),
                  _infoRow(Icons.dns, 'Database Engine', 'MySQL InnoDB (8.0+)'),
                  const Divider(color: AppColors.border, height: 18),
                  _infoRow(Icons.token, 'Token Authentication', 'Stateless JJWT (24-Hour Expiry)'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Sign Out Admin Session',
              icon: Icons.logout,
              color: AppColors.danger,
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
