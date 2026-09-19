import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/consumer_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await ConsumerService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out of your account?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Consumer Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // User Avatar & Name
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  _profile!.fullName.isNotEmpty ? _profile!.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile!.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Customer ID: ${_profile!.customerId ?? "N/A"}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              StatusBadge(status: _profile!.status ?? 'VERIFIED'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Meter & Connection Info Card
                        _buildSectionHeader('Electricity Connection Details'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _infoRow(Icons.electric_meter_outlined, 'Meter Number', _profile!.meterNumber ?? 'N/A'),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.confirmation_number_outlined, 'Consumer Number', _profile!.consumerNumber ?? 'N/A'),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.power_outlined, 'Connection Type', _profile!.connectionType ?? 'Residential'),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.flash_on_outlined, 'Load Sanctioned', '${_profile!.loadCapacityKw.toStringAsFixed(1)} kW'),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.speed, 'Current Meter Reading', '${_profile!.currentReadingKwh.toStringAsFixed(0)} kWh'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Contact & Address Details
                        _buildSectionHeader('Contact & Billing Address'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _infoRow(Icons.email_outlined, 'Email Address', _profile!.email),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.phone_outlined, 'Phone Number', _profile!.mobileNumber),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.location_on_outlined, 'Premises Address', _profile!.address ?? 'N/A'),
                              const Divider(color: AppColors.border, height: 18),
                              _infoRow(Icons.location_city_outlined, 'City & PIN', '${_profile!.city ?? ""}, ${_profile!.state ?? ""} - ${_profile!.pinCode ?? ""}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        CustomButton(
                          text: 'Edit Profile Information',
                          icon: Icons.edit_outlined,
                          isOutlined: true,
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile!)),
                            );
                            if (updated == true) _fetchProfile();
                          },
                        ),
                        const SizedBox(height: 14),

                        CustomButton(
                          text: 'Sign Out Account',
                          icon: Icons.logout,
                          color: AppColors.danger,
                          onPressed: _handleLogout,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
