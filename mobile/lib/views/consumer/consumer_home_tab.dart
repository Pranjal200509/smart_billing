import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/session_manager.dart';
import '../../core/widgets/payment_receipt_dialog.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/bill_model.dart';
import '../../services/consumer_service.dart';
import 'bills_screen.dart';
import 'complaints_screen.dart';
import 'notifications_screen.dart';
import 'pay_bill_screen.dart';
import 'service_request_screen.dart';
import 'usage_screen.dart';

class ConsumerHomeTab extends StatefulWidget {
  const ConsumerHomeTab({super.key});

  @override
  State<ConsumerHomeTab> createState() => _ConsumerHomeTabState();
}

class _ConsumerHomeTabState extends State<ConsumerHomeTab> {
  String _userName = 'Consumer';
  String? _customerId;
  BillModel? _currentBill;
  List<BillModel> _recentBills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final name = await SessionManager.getFullName();
      final custId = await SessionManager.getCustomerId();
      if (name != null) _userName = name;
      if (custId != null) _customerId = custId;

      BillModel? currentBill;
      try {
        currentBill = await ConsumerService.getCurrentBill();
      } catch (_) {}

      List<BillModel> history = [];
      try {
        history = await ConsumerService.getBillsHistory();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _currentBill = currentBill;
          _recentBills = history.take(3).toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello 👋',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_customerId != null)
                          Text(
                            'Consumer ID: $_customerId',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else ...[
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Current Bill Hero Banner
                  _buildCurrentBillCard(),
                  const SizedBox(height: 28),

                  // Quick Actions Grid
                  const Text(
                    'Quick Utility Services',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  _buildQuickActions(),
                  const SizedBox(height: 28),

                  // Recent Billing Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions & Bills',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BillsScreen()),
                          );
                        },
                        child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentActivityList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBillCard() {
    if (_currentBill == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No Outstanding Bills',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'All your electricity dues are fully settled.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isPaid = _currentBill!.paymentStatus == 'PAID';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [const Color(0xFF00796B), const Color(0xFF004D40)]
              : [const Color(0xFFFF9800), const Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPaid ? Colors.teal : AppColors.primary).withValues(alpha: 0.35),
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
              Text(
                'Current Invoice (${_currentBill!.billingMonth})',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              StatusBadge(status: _currentBill!.paymentStatus),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹ ${_currentBill!.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Due Date', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(_currentBill!.dueDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Units Consumed', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('${_currentBill!.unitsConsumed.toStringAsFixed(0)} kWh', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isPaid)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PayBillScreen(bill: _currentBill!)),
                  );
                  if (result == true) _loadDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Pay Bill Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => PaymentReceiptDialog.show(context, bill: _currentBill!),
                icon: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
                label: const Text(
                  'View Official E-Receipt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _quickActionBtn(
          icon: Icons.receipt_long,
          label: 'Bills',
          color: Colors.blueAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen())),
        ),
        _quickActionBtn(
          icon: Icons.bar_chart,
          label: 'Usage',
          color: Colors.greenAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageScreen())),
        ),
        _quickActionBtn(
          icon: Icons.report_problem_outlined,
          label: 'Helpdesk',
          color: Colors.orangeAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsScreen())),
        ),
        _quickActionBtn(
          icon: Icons.miscellaneous_services_outlined,
          label: 'Services',
          color: Colors.purpleAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceRequestScreen())),
        ),
      ],
    );
  }

  Widget _quickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    if (_recentBills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No recent activity records', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      );
    }

    return Column(
      children: _recentBills.map((b) {
        final isPaid = b.paymentStatus == 'PAID';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                child: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.receipt_long_outlined,
                  color: isPaid ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.billingMonth,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.unitsConsumed.toStringAsFixed(0)} units • Bill #${b.billNumber}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹ ${b.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  if (isPaid)
                    GestureDetector(
                      onTap: () => PaymentReceiptDialog.show(context, bill: b),
                      child: const Text('Receipt >', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    )
                  else
                    StatusBadge(status: b.paymentStatus),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
