import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/bill_model.dart';
import '../../models/user_profile_model.dart';
import '../../services/admin_service.dart';

class AdminBillGenerationScreen extends StatefulWidget {
  final int? initialUserId;

  const AdminBillGenerationScreen({super.key, this.initialUserId});

  @override
  State<AdminBillGenerationScreen> createState() => _AdminBillGenerationScreenState();
}

class _AdminBillGenerationScreenState extends State<AdminBillGenerationScreen> {
  List<UserProfileModel> _users = [];
  UserProfileModel? _selectedUser;
  late String _selectedMonth;
  bool _isLoadingUsers = true;
  bool _isGenerating = false;
  String? _errorMessage;

  late final List<Map<String, String>> _dynamicMonths;

  @override
  void initState() {
    super.initState();
    _buildDynamicMonths();
    _fetchUsers();
  }

  @override
  void didUpdateWidget(covariant AdminBillGenerationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUserId != null && widget.initialUserId != oldWidget.initialUserId) {
      _selectUserById(widget.initialUserId!);
    }
  }

  void _buildDynamicMonths() {
    final now = DateTime.now();
    _dynamicMonths = [];

    // Generate past 3 months, current month, and next month
    for (int offset = -3; offset <= 1; offset++) {
      final dt = DateTime(now.year, now.month + offset, 1);
      final monthName = _getMonthName(dt.month);
      final iso = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-01';
      _dynamicMonths.add({
        'label': '$monthName ${dt.year}',
        'val': iso,
      });
    }

    // Default to current month or previous month
    final curIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    _selectedMonth = curIso;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final list = await AdminService.getAllUsers();
      final filtered = list.where((u) => u.email != 'admin@gmail.com').toList();
      if (mounted) {
        setState(() {
          _users = filtered;
          if (widget.initialUserId != null) {
            _selectUserById(widget.initialUserId!);
          } else if (filtered.isNotEmpty) {
            _selectedUser = filtered.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _selectUserById(int id) {
    final found = _users.where((u) => u.id == id).toList();
    if (found.isNotEmpty) {
      setState(() => _selectedUser = found.first);
    }
  }

  Future<void> _handleGenerateBill() async {
    if (_selectedUser == null) {
      setState(() => _errorMessage = 'Please select a consumer');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final bill = await AdminService.generateBill(
        userId: _selectedUser!.id,
        billingMonthIso: _selectedMonth,
      );

      if (!mounted) return;

      _showGeneratedBillModal(bill);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showGeneratedBillModal(BillModel bill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Text('Bill Generated', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Bill Number', bill.billNumber),
            _row('Billing Month', bill.billingMonth),
            if (bill.consumerNumber != null) _row('Consumer Number', bill.consumerNumber!),
            _row('Units Consumed', '${bill.unitsConsumed.toStringAsFixed(0)} kWh'),
            _row('Energy Charge', '₹ ${bill.energyCharge.toStringAsFixed(2)}'),
            _row('Fixed Load Charge', '₹ ${bill.fixedCharge.toStringAsFixed(2)}'),
            _row('Taxes & Levies', '₹ ${bill.taxes.toStringAsFixed(2)}'),
            _row('Payment Due Date', bill.dueDate),
            const Divider(color: AppColors.border, height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Bill Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '₹ ${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.purpleAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generate Monthly Bill',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Calculates tiered energy rates, load charge, and duties',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_isLoadingUsers)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else ...[
                    const Text('Select Consumer Account', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UserProfileModel>(
                          value: _selectedUser,
                          isExpanded: true,
                          dropdownColor: AppColors.backgroundSecondary,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          items: _users.map((u) {
                            final cNum = u.consumerNumber ?? u.customerId ?? "No ID";
                            return DropdownMenuItem(
                              value: u,
                              child: Text('${u.fullName} • $cNum (${u.connectionType ?? "Residential"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUser = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Consumer Meter Profile Card
                    if (_selectedUser != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Meter #: ${_selectedUser!.meterNumber ?? "N/A"}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Load: ${_selectedUser!.loadCapacityKw.toStringAsFixed(1)} kW',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tariff: ${_selectedUser!.connectionType ?? "Residential"}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                Text(
                                  'Current Reading: ${_selectedUser!.currentReadingKwh.toStringAsFixed(1)} kWh',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    const Text('Billing Cycle Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          isExpanded: true,
                          dropdownColor: AppColors.backgroundSecondary,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                          items: _dynamicMonths.map((m) {
                            return DropdownMenuItem(
                              value: m['val'],
                              child: Text(m['label']!),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMonth = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    CustomButton(
                      text: 'Calculate & Dispatch Bill',
                      color: Colors.purpleAccent,
                      onPressed: _handleGenerateBill,
                      isLoading: _isGenerating,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
