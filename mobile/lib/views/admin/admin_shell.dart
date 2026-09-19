import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/session_manager.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'admin_bill_generation_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_consumers_screen.dart';
import 'admin_dashboard_tab.dart';
import 'admin_meter_reading_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_service_requests_screen.dart';

class AdminShell extends StatefulWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _currentIndex;
  String _adminName = 'Administrator';
  late final List<Widget?> _loadedTabs;

  // Prefill state when transitioning between tabs (e.g., from Consumer to Log Reading or Bill Gen)
  String? _prefilledConsumerNumber;
  int? _prefilledUserId;

  final List<String> _titles = const [
    'Admin Command Center',
    'Consumer Registry & Meters',
    'Log Meter Reading',
    'Monthly Bill Generation',
    'Complaint Helpdesk',
    'Service Requests Queue',
    'Payments & Transactions',
    'Admin Profile & Settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadedTabs = List<Widget?>.filled(8, null);
    _loadedTabs[_currentIndex] = _getTabWidget(_currentIndex);
    _loadAdminName();
  }

  Widget _getTabWidget(int index) {
    switch (index) {
      case 0:
        return AdminDashboardTab(onNavigateTab: _onTabSelected);
      case 1:
        return AdminConsumersScreen(
          onLogReading: (consumerNumber) {
            setState(() {
              _prefilledConsumerNumber = consumerNumber;
              _loadedTabs[2] = null; // force reload with prefill
            });
            _onTabSelected(2);
          },
          onGenerateBill: (userId) {
            setState(() {
              _prefilledUserId = userId;
              _loadedTabs[3] = null; // force reload with prefill
            });
            _onTabSelected(3);
          },
        );
      case 2:
        return AdminMeterReadingScreen(
          initialConsumerNumber: _prefilledConsumerNumber,
          onReadingLogged: () {
            // refresh consumer list tab
            setState(() => _loadedTabs[1] = null);
          },
        );
      case 3:
        return AdminBillGenerationScreen(
          initialUserId: _prefilledUserId,
        );
      case 4:
        return const AdminComplaintsScreen();
      case 5:
        return const AdminServiceRequestsScreen();
      case 6:
        return const AdminPaymentsScreen();
      case 7:
        return const AdminProfileScreen();
      default:
        return AdminDashboardTab(onNavigateTab: _onTabSelected);
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs[index] = _getTabWidget(index);
    });
  }

  Future<void> _loadAdminName() async {
    final name = await SessionManager.getFullName();
    if (name != null && mounted) setState(() => _adminName = name);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Exit administrative portal securely?', style: TextStyle(color: AppColors.textSecondary)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left Admin Sidebar (270px)
            Container(
              width: 270,
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border(right: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PowerGrid',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Admin Portal',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  // Nav Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      children: [
                        _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Command Center'),
                        _buildNavItem(1, Icons.people_outline, Icons.people, 'Consumer Registry'),
                        _buildNavItem(2, Icons.speed_outlined, Icons.speed, 'Log Meter Reading'),
                        _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long, 'Bill Generation'),
                        _buildNavItem(4, Icons.support_agent_outlined, Icons.support_agent, 'Complaints Desk'),
                        _buildNavItem(5, Icons.miscellaneous_services_outlined, Icons.miscellaneous_services, 'Service Requests'),
                        _buildNavItem(6, Icons.payments_outlined, Icons.payments, 'Payments & Transactions'),
                        _buildNavItem(7, Icons.person_outline, Icons.person, 'Admin Profile'),
                      ],
                    ),
                  ),
                  // Bottom Profile & Logout Pill
                  const Divider(color: AppColors.border, height: 1),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.shield, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _adminName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'ROLE_ADMIN',
                                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
                            tooltip: 'Sign Out',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _handleLogout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right Main Content + Topbar
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _titles[_currentIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: AppColors.success, size: 8),
                                  SizedBox(width: 6),
                                  Text('System Online', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List.generate(
                        8,
                        (i) => _loadedTabs[i] ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View (< 800px)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: Text(_titles[_currentIndex], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 22),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          8,
          (i) => _loadedTabs[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex >= 4 ? 0 : _currentIndex,
        onTap: (idx) {
          if (idx == 4) {
            // Open drawer for extra tabs
            Scaffold.of(context).openDrawer();
          } else {
            _onTabSelected(idx);
          }
        },
        backgroundColor: AppColors.cardBg,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _currentIndex >= 4 ? AppColors.textMuted : AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Consumers'),
          BottomNavigationBarItem(icon: Icon(Icons.speed_outlined), activeIcon: Icon(Icons.speed), label: 'Meter Log'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Generate'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String title) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          dense: true,
          leading: Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () => _onTabSelected(index),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundSecondary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.cardBg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  _adminName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ROLE_ADMIN • System Manager',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _drawerItem(0, Icons.dashboard_outlined, 'Dashboard & Metrics'),
          _drawerItem(1, Icons.people_outline, 'Consumer Registry & Meters'),
          _drawerItem(2, Icons.speed, 'Log Meter Reading'),
          _drawerItem(3, Icons.receipt_long_outlined, 'Generate Monthly Bill'),
          _drawerItem(4, Icons.support_agent_outlined, 'Complaint Helpdesk'),
          _drawerItem(5, Icons.miscellaneous_services_outlined, 'Service Requests Queue'),
          _drawerItem(6, Icons.payments_outlined, 'Payments & Transactions'),
          _drawerItem(7, Icons.person_outline, 'Admin Profile'),
          const Divider(color: AppColors.border, height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onTap: () {
        _onTabSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
