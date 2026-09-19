import 'package:electricity_billing/views/admin/admin_service_requests_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/metric_card.dart';
import '../../models/admin_stats_model.dart';
import '../../services/admin_service.dart';
import 'admin_bill_generation_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_consumers_screen.dart';
import 'admin_meter_reading_screen.dart';

class AdminDashboardTab extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const AdminDashboardTab({super.key, this.onNavigateTab});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  AdminStatsModel? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await AdminService.getOverview();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(int tabIndex, Widget fallbackScreen) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tabIndex);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => fallbackScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _stats?.totalRevenueCollected ?? 0.0;
    final billed = _stats?.totalBilledAmount ?? 0.0;
    final collectionRatio = billed > 0
        ? (revenue / billed * 100).clamp(0.0, 100.0)
        : 0.0;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.primary,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? EmptyState(
              icon: Icons.error_outline,
              title: 'Failed to Load Statistics',
              message: _errorMessage!,
              actionText: 'Retry',
              onAction: _fetchStats,
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Utility Revenue Collected',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${collectionRatio.toStringAsFixed(1)}% Realized',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹ ${revenue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (collectionRatio / 100.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Billed Amount: ₹ ${billed.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metrics 2x2 Grid
                  const Text(
                    'Operations Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      MetricCard(
                        title: 'Active Consumers',
                        value: '${_stats?.totalCustomers ?? 0}',
                        icon: Icons.people,
                        color: AppColors.accent,
                        onTap: () =>
                            _navigateTo(1, const AdminConsumersScreen()),
                      ),
                      MetricCard(
                        title: 'Pending Bills',
                        value: '${_stats?.pendingBillsCount ?? 0}',
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                        onTap: () =>
                            _navigateTo(3, const AdminBillGenerationScreen()),
                      ),
                      MetricCard(
                        title: 'Overdue Accounts',
                        value: '${_stats?.overdueBillsCount ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        onTap: () =>
                            _navigateTo(3, const AdminBillGenerationScreen()),
                      ),
                      MetricCard(
                        title: 'Resolved Complaints',
                        value: _stats?.complaintsStatus ?? '0/0',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                        onTap: () =>
                            _navigateTo(4, const AdminComplaintsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Quick Operations Section
                  const Text(
                    'Administrative Tasks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _adminActionTile(
                    icon: Icons.speed,
                    color: AppColors.primary,
                    title: 'Log Meter Reading',
                    subtitle:
                        'Input monthly kWh consumption by consumer number',
                    onTap: () =>
                        _navigateTo(2, const AdminMeterReadingScreen()),
                  ),
                  _adminActionTile(
                    icon: Icons.receipt_long,
                    color: Colors.purpleAccent,
                    title: 'Generate Monthly Bills',
                    subtitle:
                        'Calculate tariffs and dispatch consumer bill statements',
                    onTap: () =>
                        _navigateTo(3, const AdminBillGenerationScreen()),
                  ),
                  _adminActionTile(
                    icon: Icons.people_alt_outlined,
                    color: AppColors.accent,
                    title: 'Consumer Registry & Meters',
                    subtitle:
                        'Inspect meter numbers, addresses, and load capacities',
                    onTap: () => _navigateTo(1, const AdminConsumersScreen()),
                  ),
                  _adminActionTile(
                    icon: Icons.support_agent,
                    color: AppColors.success,
                    title: 'Resolve Complaints Helpdesk',
                    subtitle:
                        'Review reported power issues and update ticket statuses',
                    onTap: () => _navigateTo(4, const AdminComplaintsScreen()),
                  ),
                  _adminActionTile(
                    icon: Icons.miscellaneous_services_outlined,
                    color: Colors.tealAccent,
                    title: 'Service Requests Queue',
                    subtitle:
                        'Process meter installations and load change requests',
                    onTap: () =>
                        _navigateTo(5, const AdminServiceRequestsScreen()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _adminActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textMuted,
            size: 14,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
