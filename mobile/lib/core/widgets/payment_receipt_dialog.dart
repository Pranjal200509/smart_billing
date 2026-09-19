import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../../models/bill_model.dart';

class PaymentReceiptDialog extends StatelessWidget {
  final BillModel bill;
  final String transactionId;
  final String paymentMethod;
  final DateTime? paymentDateTime;

  const PaymentReceiptDialog({
    super.key,
    required this.bill,
    required this.transactionId,
    this.paymentMethod = 'UPI',
    this.paymentDateTime,
  });

  static void show(
    BuildContext context, {
    required BillModel bill,
    String? transactionId,
    String paymentMethod = 'UPI',
    DateTime? paymentDateTime,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PaymentReceiptDialog(
        bill: bill,
        transactionId: transactionId ?? 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}',
        paymentMethod: paymentMethod,
        paymentDateTime: paymentDateTime ?? DateTime.now(),
      ),
    );
  }

  void _handleShare(BuildContext context) {
    final text = '''
======================================
  POWERGRID ELECTRICITY PAYMENT RECEIPT
======================================
Receipt No    : REC-${bill.billNumber}
Transaction ID: $transactionId
Billing Month : ${bill.billingMonth}
Consumer No   : ${bill.consumerNumber ?? "N/A"}
Units Consumed: ${bill.unitsConsumed.toStringAsFixed(0)} kWh
Total Amount  : ₹ ${bill.totalAmount.toStringAsFixed(2)}
Payment Mode  : $paymentMethod
Status        : PAID (SUCCESS)
Date & Time   : ${_formatDateTime(paymentDateTime ?? DateTime.now())}
======================================
Verified Electronic Receipt - PowerGrid Corporation
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment receipt summary copied to clipboard!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDownload(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt REC-${bill.billNumber}.pdf saved to Downloads',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final paidDate = paymentDateTime ?? DateTime.now();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Header with Branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PowerGrid Corp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'E-Payment Tax Invoice',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: AppColors.success, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PAID',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),

                  // Amount Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00796B).withValues(alpha: 0.3),
                          const Color(0xFF004D40).withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL AMOUNT PAID',
                          style: TextStyle(
                            color: Color(0xFF80CBC4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹ ${bill.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settled on ${_formatDateTime(paidDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Metadata Key-Value pairs
                  _sectionTitle('Transaction Information'),
                  const SizedBox(height: 8),
                  _row('Receipt Number', 'REC-${bill.billNumber}'),
                  _row('Transaction ID', transactionId, isHighlighted: true),
                  _row('Payment Mode', paymentMethod),
                  _row('Billing Cycle', bill.billingMonth),
                  if (bill.consumerNumber != null) _row('Consumer Number', bill.consumerNumber!),
                  _row('Bill Number', bill.billNumber),

                  const SizedBox(height: 14),
                  _sectionTitle('Meter & Energy Consumption'),
                  const SizedBox(height: 8),
                  _row('Previous Reading', '${bill.previousReadingKwh.toStringAsFixed(0)} kWh'),
                  _row('Current Reading', '${bill.currentReadingKwh.toStringAsFixed(0)} kWh'),
                  _row('Billed Consumption', '${bill.unitsConsumed.toStringAsFixed(0)} kWh', isHighlighted: true),

                  const SizedBox(height: 14),
                  _sectionTitle('Financial Breakdown'),
                  const SizedBox(height: 8),
                  _row('Energy Consumption Charge', '₹ ${bill.energyCharge.toStringAsFixed(2)}'),
                  _row('Fixed Infrastructure Charge', '₹ ${bill.fixedCharge.toStringAsFixed(2)}'),
                  _row('Electricity Duty & Taxes', '₹ ${bill.taxes.toStringAsFixed(2)}'),
                  if (bill.lateFee > 0)
                    _row('Late Payment Surcharge', '₹ ${bill.lateFee.toStringAsFixed(2)}', isWarning: true),

                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleShare(context),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleDownload(context),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _row(String label, String value, {bool isHighlighted = false, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          Text(
            value,
            style: TextStyle(
              color: isWarning
                  ? AppColors.danger
                  : (isHighlighted ? Colors.white : Colors.white70),
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
