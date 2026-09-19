import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/payment_receipt_dialog.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/bill_model.dart';
import '../../services/consumer_service.dart';
import 'pay_bill_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  List<BillModel> _bills = [];
  List<BillModel> _filteredBills = [];
  String _selectedFilter = 'ALL'; // ALL, UNPAID, PAID
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bills = await ConsumerService.getBillsHistory();
      if (mounted) {
        setState(() {
          _bills = bills;
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
    setState(() {
      if (_selectedFilter == 'PAID') {
        _filteredBills = _bills.where((b) => b.paymentStatus == 'PAID').toList();
      } else if (_selectedFilter == 'UNPAID') {
        _filteredBills = _bills.where((b) => b.paymentStatus != 'PAID').toList();
      } else {
        _filteredBills = _bills;
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  void _showBillDetails(BillModel bill) {
    final isPaid = bill.paymentStatus == 'PAID';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill Details - ${bill.billingMonth}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  StatusBadge(status: bill.paymentStatus),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              _detailRow('Bill Number', bill.billNumber),
              if (bill.consumerNumber != null)
                _detailRow('Consumer Number', bill.consumerNumber!),
              _detailRow('Units Consumed', '${bill.unitsConsumed.toStringAsFixed(0)} kWh'),
              _detailRow('Previous Reading', '${bill.previousReadingKwh.toStringAsFixed(0)} kWh'),
              _detailRow('Current Reading', '${bill.currentReadingKwh.toStringAsFixed(0)} kWh'),
              _detailRow('Energy Charge', '₹ ${bill.energyCharge.toStringAsFixed(2)}'),
              _detailRow('Fixed Infrastructure Charge', '₹ ${bill.fixedCharge.toStringAsFixed(2)}'),
              _detailRow('Taxes & Surcharges', '₹ ${bill.taxes.toStringAsFixed(2)}'),
              if (bill.lateFee > 0)
                _detailRow('Late Payment Fee', '₹ ${bill.lateFee.toStringAsFixed(2)}', isDanger: true),
              _detailRow('Due Date', bill.dueDate),
              const Divider(color: AppColors.border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '₹ ${bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isPaid)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      PaymentReceiptDialog.show(context, bill: bill);
                    },
                    icon: const Icon(Icons.receipt_long, color: Colors.black, size: 20),
                    label: const Text('View Official E-Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PayBillScreen(bill: bill)),
                      );
                      if (res == true) _fetchBills();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isDanger ? AppColors.danger : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Billing & Receipts History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBills,
        color: AppColors.primary,
        child: Column(
          children: [
            // Filter Tabs Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _filterChip('ALL', 'All Statements (${_bills.length})'),
                  const SizedBox(width: 8),
                  _filterChip('UNPAID', 'Pending (${_bills.where((b) => b.paymentStatus != 'PAID').length})'),
                  const SizedBox(width: 8),
                  _filterChip('PAID', 'Receipts (${_bills.where((b) => b.paymentStatus == 'PAID').length})'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _errorMessage != null
                      ? EmptyState(
                          icon: Icons.error_outline,
                          title: 'Failed to Load Bills',
                          message: _errorMessage!,
                          actionText: 'Retry',
                          onAction: _fetchBills,
                        )
                      : _filteredBills.isEmpty
                          ? EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: _selectedFilter == 'PAID'
                                  ? 'No Payment Receipts'
                                  : (_selectedFilter == 'UNPAID' ? 'No Pending Invoices' : 'No Bills Available'),
                              message: _selectedFilter == 'PAID'
                                  ? 'You haven\'t completed any electricity payments yet.'
                                  : (_selectedFilter == 'UNPAID' ? 'All your electricity bills are cleared!' : 'No billing history has been generated yet.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _filteredBills.length,
                              itemBuilder: (context, index) {
                                final bill = _filteredBills[index];
                                final isPaid = bill.paymentStatus == 'PAID';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                          onTap: () => _showBillDetails(bill),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                                                  child: Icon(
                                                    isPaid ? Icons.check_circle : Icons.receipt_long,
                                                    color: isPaid ? AppColors.success : AppColors.warning,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        bill.billingMonth,
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Due: ${bill.dueDate} • ${bill.unitsConsumed.toStringAsFixed(0)} kWh',
                                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '₹ ${bill.totalAmount.toStringAsFixed(2)}',
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    StatusBadge(status: bill.paymentStatus),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Divider(color: AppColors.border, height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Bill #${bill.billNumber}',
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                            ),
                                            if (isPaid)
                                              TextButton.icon(
                                                onPressed: () => PaymentReceiptDialog.show(context, bill: bill),
                                                icon: const Icon(Icons.receipt_long, size: 16, color: AppColors.success),
                                                label: const Text('View E-Receipt', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                              )
                                            else
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final res = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (_) => PayBillScreen(bill: bill)),
                                                  );
                                                  if (res == true) _fetchBills();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.black,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
