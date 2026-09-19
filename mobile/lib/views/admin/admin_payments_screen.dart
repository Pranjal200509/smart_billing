import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../services/admin_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterMethod = 'ALL'; // ALL, UPI, Card, Net Banking, Wallet
  final TextEditingController _searchController = TextEditingController();

  final List<String> _methods = ['ALL', 'UPI', 'Card', 'Net Banking', 'Wallet'];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final payments = await AdminService.getPayments();
      if (mounted) {
        setState(() {
          _payments = payments;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _payments.where((p) {
        final matchesMethod = _filterMethod == 'ALL' ||
            (p['paymentMethod'] ?? '').toString().toLowerCase().contains(_filterMethod.toLowerCase());
        final name = (p['consumerName'] ?? '').toString().toLowerCase();
        final txn = (p['transactionId'] ?? '').toString().toLowerCase();
        final bill = (p['billNumber'] ?? '').toString().toLowerCase();
        final consumer = (p['consumerNumber'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty ||
            name.contains(query) ||
            txn.contains(query) ||
            bill.contains(query) ||
            consumer.contains(query);
        return matchesMethod && matchesSearch;
      }).toList();
    });
  }

  double get _totalRevenue => _filtered.fold(
      0.0, (sum, p) => sum + ((p['amountPaid'] as num?)?.toDouble() ?? 0.0));

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $ampm';
    } catch (_) {
      return dateStr;
    }
  }

  Color _methodColor(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'upi':
        return const Color(0xFF4CAF50);
      case 'card':
      case 'credit card':
      case 'debit card':
        return const Color(0xFF2196F3);
      case 'net banking':
        return const Color(0xFFFF9800);
      case 'wallet':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.textMuted;
    }
  }

  IconData _methodIcon(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'upi':
        return Icons.currency_rupee_rounded;
      case 'card':
      case 'credit card':
      case 'debit card':
        return Icons.credit_card_rounded;
      case 'net banking':
        return Icons.account_balance_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchPayments,
      color: AppColors.primary,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Failed to Load Payments',
                  message: _errorMessage!,
                  actionText: 'Retry',
                  onAction: _fetchPayments,
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      decoration: const BoxDecoration(color: AppColors.backgroundSecondary),
                      child: Column(
                        children: [
                          // Revenue stat banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded,
                                      color: Colors.white, size: 26),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_filtered.length} Transactions',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      Text(
                                        '₹${_totalRevenue.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Filtered Revenue',
                                        style: TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _miniStat('UPI', _payments
                                        .where((p) => (p['paymentMethod'] ?? '').toString().toLowerCase() == 'upi')
                                        .length.toString()),
                                    const SizedBox(height: 6),
                                    _miniStat('Card', _payments
                                        .where((p) => (p['paymentMethod'] ?? '').toString().toLowerCase().contains('card'))
                                        .length.toString()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by name, transaction ID, bill…',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                              filled: true,
                              fillColor: AppColors.cardBg,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Method filter chips
                          SizedBox(
                            height: 34,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _methods.map((method) {
                                final isSelected = _filterMethod == method;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _filterMethod = method);
                                      _applyFilter();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : AppColors.cardBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primary : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        method,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    // Payments list
                    Expanded(
                      child: _filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.payment_outlined,
                              title: 'No Payments Found',
                              message: 'No transactions match your current filters.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final p = _filtered[index];
                                final method = p['paymentMethod']?.toString() ?? 'Unknown';
                                final amount = (p['amountPaid'] as num?)?.toDouble() ?? 0.0;
                                final status = (p['status'] ?? 'SUCCESS').toString();
                                final isSuccess = status.toUpperCase() == 'SUCCESS';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _methodColor(method).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(_methodIcon(method),
                                            color: _methodColor(method), size: 22),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['consumerName']?.toString() ?? 'Consumer',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${amount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: isSuccess
                                                  ? const Color(0xFF4CAF50)
                                                  : AppColors.danger,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _methodColor(method).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(method,
                                                    style: TextStyle(
                                                        color: _methodColor(method),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isSuccess
                                                      ? Colors.green.withValues(alpha: 0.1)
                                                      : Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(status,
                                                    style: TextStyle(
                                                        color: isSuccess ? Colors.green : Colors.red,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Bill: ${p['billNumber'] ?? '—'} • ${p['consumerNumber'] ?? '—'}',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                          Text(
                                            _formatDate(p['paymentDate']?.toString()),
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showPaymentDetail(p),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showPaymentDetail(Map<String, dynamic> p) {
    final method = p['paymentMethod']?.toString() ?? 'Unknown';
    final amount = (p['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final status = (p['status'] ?? 'SUCCESS').toString();
    final isSuccess = status.toUpperCase() == 'SUCCESS';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _methodColor(method).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_methodIcon(method), color: _methodColor(method), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['consumerName']?.toString() ?? 'Consumer',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        p['customerId']?.toString() ?? '',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                'Amount Paid via $method',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            _detailRow('Transaction ID', p['transactionId']?.toString() ?? '—'),
            _detailRow('Bill Number', p['billNumber']?.toString() ?? '—'),
            _detailRow('Billing Month', p['billingMonth']?.toString() ?? '—'),
            _detailRow('Consumer No.', p['consumerNumber']?.toString() ?? '—'),
            _detailRow('Payment Date', _formatDate(p['paymentDate']?.toString())),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
