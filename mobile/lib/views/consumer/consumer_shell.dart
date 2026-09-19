import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/session_manager.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'bills_screen.dart';
import 'complaints_screen.dart';
import 'consumer_home_tab.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'service_request_screen.dart';
import 'usage_screen.dart';

class ConsumerShell extends StatefulWidget {
  final int initialIndex;
  const ConsumerShell({super.key, this.initialIndex = 0});

  @override
  State<ConsumerShell> createState() => _ConsumerShellState();
}

class _ConsumerShellState extends State<ConsumerShell> {
  late int _currentIndex;
  String _userName = 'Consumer';
  String? _customerId;
  late final List<Widget?> _loadedTabs;

  final List<String> _titles = const [
    'PowerGrid Utility',
    'Bills & Payments',
    'Usage Analytics',
    'Complaints & Grievances',
    'Service Requests',
    'Notifications',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadedTabs = List<Widget?>.filled(7, null);
    _loadedTabs[_currentIndex] = _getTabWidget(_currentIndex);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await SessionManager.getFullName();
    final custId = await SessionManager.getCustomerId();
    if (mounted) {
      setState(() {
        if (name != null) _userName = name;
        if (custId != null) _customerId = custId;
      });
    }
  }

  Widget _getTabWidget(int index) {
    switch (index) {
      case 0:
        return const ConsumerHomeTab();
      case 1:
        return const BillsScreen();
      case 2:
        return const UsageScreen();
      case 3:
        return const ComplaintsScreen();
      case 4:
        return const ServiceRequestScreen();
      case 5:
        return const NotificationsScreen();
      case 6:
        return const ProfileScreen();
      default:
        return const ConsumerHomeTab();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _loadedTabs[index] ??= _getTabWidget(index);
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
            // Angular-style Left Sidebar (260px)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 22,
                          ),
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
                              'Utility Portal',
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      children: [
                        _buildNavItem(
                          0,
                          Icons.dashboard_outlined,
                          Icons.dashboard,
                          'Dashboard',
                        ),
                        _buildNavItem(
                          1,
                          Icons.receipt_long_outlined,
                          Icons.receipt_long,
                          'Bills & Payments',
                        ),
                        _buildNavItem(
                          2,
                          Icons.bar_chart_outlined,
                          Icons.bar_chart,
                          'Usage Analytics',
                        ),
                        _buildNavItem(
                          3,
                          Icons.support_agent_outlined,
                          Icons.support_agent,
                          'Complaints Desk',
                        ),
                        _buildNavItem(
                          4,
                          Icons.settings_suggest_outlined,
                          Icons.settings_suggest,
                          'Service Requests',
                        ),
                        _buildNavItem(
                          5,
                          Icons.notifications_outlined,
                          Icons.notifications,
                          'Notifications',
                        ),
                        _buildNavItem(
                          6,
                          Icons.person_outline,
                          Icons.person,
                          'My Profile',
                        ),
                      ],
                    ),
                  ),
                  // User Profile Pill at Bottom
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
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_customerId != null)
                                  Text(
                                    'ID: $_customerId',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.danger,
                              size: 18,
                            ),
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
            // Right Main Content Area + Topbar
            Expanded(
              child: Column(
                children: [
                  // Angular-style Topbar (64px)
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBg,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border, width: 1),
                      ),
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
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.textSecondary,
                                size: 22,
                              ),
                              tooltip: 'Notifications',
                              onPressed: () => _onTabTapped(5),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.account_circle_outlined,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              tooltip: 'Profile',
                              onPressed: () => _onTabTapped(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Page Body
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List.generate(
                        7,
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

    // Mobile Layout (< 800px)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: Text(
          _titles[_currentIndex >= 5 ? _currentIndex : _currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => _onTabTapped(5),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 22),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          7,
          (i) => _loadedTabs[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= 5 ? 0 : _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Bills',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Usage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_suggest_outlined),
              activeIcon: Icon(Icons.settings_suggest),
              label: 'Service',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String title,
  ) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          onTap: () => _onTabTapped(index),
        ),
      ),
    );
  }
}
