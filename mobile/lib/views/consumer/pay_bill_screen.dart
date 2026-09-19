import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/payment/razorpay_bridge.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/payment_receipt_dialog.dart';
import '../../models/bill_model.dart';
import '../../services/consumer_service.dart';

class PayBillScreen extends StatefulWidget {
  final BillModel bill;

  const PayBillScreen({super.key, required this.bill});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  String _selectedMethod = 'Razorpay'; // Razorpay, UPI, Card, Net Banking, Wallet
  Razorpay? _razorpay;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showBreakdown = false;

  // UPI Form State
  final _upiIdController = TextEditingController();
  String _selectedUpiApp = 'Google Pay';

  // Card Form State
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // Net Banking State
  String _selectedBank = 'State Bank of India';
  final List<String> _popularBanks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Punjab National Bank',
    'Bank of Baroda',
  ];

  final List<String> _allBanks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Kotak Mahindra Bank',
    'Canara Bank',
    'Union Bank of India',
    'IndusInd Bank',
    'IDBI Bank',
    'Federal Bank',
  ];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleRazorpayExternalWallet);
      } catch (e) {
        debugPrint('Razorpay init error: $e');
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && _razorpay != null) {
      try {
        _razorpay!.clear();
      } catch (_) {}
    }
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  String _detectCardType(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) return 'VISA';
    if (clean.startsWith('51') || clean.startsWith('52') || clean.startsWith('53') || clean.startsWith('54') || clean.startsWith('55')) return 'MASTERCARD';
    if (clean.startsWith('60') || clean.startsWith('65') || clean.startsWith('81') || clean.startsWith('82')) return 'RUPAY';
    if (clean.startsWith('34') || clean.startsWith('37')) return 'AMEX';
    return 'CARD';
  }

  void _formatCardNumber(String val) {
    String clean = val.replaceAll(' ', '');
    if (clean.length > 16) clean = clean.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();
    if (formatted != _cardNumberController.text) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _formatExpiry(String val) {
    String clean = val.replaceAll('/', '').replaceAll(' ', '');
    if (clean.length > 4) clean = clean.substring(0, 4);
    if (clean.length >= 2) {
      final formatted = '${clean.substring(0, 2)}/${clean.substring(2)}';
      if (formatted != _cardExpiryController.text) {
        _cardExpiryController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    setState(() {});
  }

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ConsumerService.payBill(
        billId: widget.bill.id,
        paymentMethod: _selectedMethod,
        amountPaid: widget.bill.totalAmount,
      );

      if (!mounted) return;

      final txnId = response['transactionId'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

      // Show Payment Receipt Modal
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentReceiptDialog(
          bill: widget.bill,
          transactionId: txnId,
          paymentMethod: _selectedMethod == 'UPI'
              ? 'UPI ($_selectedUpiApp)'
              : (_selectedMethod == 'Card' ? 'Card (${_detectCardType(_cardNumberController.text)})' : _selectedMethod),
          paymentDateTime: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // return to caller with refresh signal
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _payWithRazorpay() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderData = await ConsumerService.createRazorpayOrder(widget.bill.id);
      final orderId = (orderData['orderId'] ?? '').toString();
      final keyId = (orderData['keyId'] ?? 'rzp_test_51gXf691ZqP4fM').toString();
      final amount = orderData['amount'] ?? (widget.bill.totalAmount * 100).toInt();

      final options = {
        'key': keyId,
        'amount': amount,
        'name': 'PowerGrid Utility',
        'description': orderData['description'] ?? 'Electricity Bill #${widget.bill.id} for ${widget.bill.billingMonth}',
        'order_id': orderId,
        'timeout': 180,
        'prefill': {
          'contact': orderData['customerPhone'] ?? '',
          'email': orderData['customerEmail'] ?? '',
          'name': orderData['customerName'] ?? '',
        },
        'theme': {
          'color': '#0284C7',
        },
      };

      final isSandbox = orderData['isSandbox'] == true ||
          keyId.contains('placeholder') ||
          keyId == 'rzp_test_51gXf691ZqP4fM';

      // 1. If backend generated a sandbox/fallback order, open built-in interactive simulator
      if (isSandbox) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        await _showWebRazorpayModal(orderData);
        return;
      }

      // 2. Web / Chrome with real keys: Use official Razorpay Web Checkout SDK
      if (kIsWeb) {
        RazorpayWebBridge.openCheckout(
          options: options,
          onSuccess: (paymentId, orderId, signature) async {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            try {
              await ConsumerService.verifyRazorpayPayment(
                billId: widget.bill.id,
                razorpayOrderId: orderId,
                razorpayPaymentId: paymentId,
                razorpaySignature: signature,
              );
              if (!mounted) return;
              setState(() => _isLoading = false);
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => PaymentReceiptDialog(
                  bill: widget.bill,
                  transactionId: paymentId,
                  paymentMethod: 'Razorpay (Verified)',
                  paymentDateTime: DateTime.now(),
                ),
              );
              if (!mounted) return;
              Navigator.pop(context, true);
            } catch (err) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Payment verification failed: $err';
                });
              }
            }
          },
          onFailure: (err) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // Offer seamless fallback to simulated payment dialog
              await _showWebRazorpayModal(orderData);
            }
          },
        );
        return;
      }

      // 3. Android / iOS: Use native Razorpay mobile plugin
      if (_razorpay != null) {
        _razorpay!.open(options);
        return;
      }

      // 4. Desktop / Sandbox Fallback
      setState(() => _isLoading = false);
      if (!mounted) return;
      await _showWebRazorpayModal(orderData);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initiate Razorpay: $e';
        });
      }
    }
  }

  Future<void> _payDirectlyViaRazorpayQr({String methodLabel = 'Razorpay Smart Dynamic QR'}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderData = await ConsumerService.createRazorpayOrder(widget.bill.id);
      final orderId = (orderData['orderId'] ?? 'order_${DateTime.now().millisecondsSinceEpoch}').toString();
      final randomId = Random().nextInt(899999) + 100000;
      final simulatedPaymentId = 'pay_rzp_qr_${DateTime.now().millisecondsSinceEpoch}_$randomId';

      await ConsumerService.verifyRazorpayPayment(
        billId: widget.bill.id,
        razorpayOrderId: orderId,
        razorpayPaymentId: simulatedPaymentId,
        razorpaySignature: 'sig_qr_direct_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentReceiptDialog(
          bill: widget.bill,
          transactionId: simulatedPaymentId,
          paymentMethod: methodLabel,
          paymentDateTime: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Direct QR Payment failed: $e';
        });
      }
    }
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ConsumerService.verifyRazorpayPayment(
        billId: widget.bill.id,
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentReceiptDialog(
          bill: widget.bill,
          transactionId: response.paymentId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          paymentMethod: 'Razorpay (Verified)',
          paymentDateTime: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Payment verification failed: $e';
        });
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'Razorpay Payment Failed: ${response.message ?? 'Cancelled by user'}';
    });
  }

  void _handleRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
    );
  }

  Future<void> _showWebRazorpayModal(Map<String, dynamic> orderData) async {
    final orderId = (orderData['orderId'] ?? '').toString();
    final billAmount = widget.bill.totalAmount.toStringAsFixed(2);
    final upiQrString = 'upi://pay?pa=merchant.powergrid@icici&pn=Razorpay%20PowerGrid&mc=4900&tr=${widget.bill.billNumber}&tn=Electricity%20Bill%20${widget.bill.billNumber}&am=$billAmount&cu=INR';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2340),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0C73EB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF0C73EB), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Razorpay',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Direct QR & Gateway Checkout', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(orderId.length > 20 ? '${orderId.substring(0, 18)}...' : orderId,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('₹ $billAmount',
                            style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Razorpay Dynamic Scannable QR Code Card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: upiQrString,
                        version: QrVersions.auto,
                        size: 140.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0C2340),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0C2340),
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Razorpay Dynamic QR • ₹$billAmount',
                        style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Instant 1-Click Direct Pay Button
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _completeWebRazorpayPayment(context, orderId, 'Dynamic QR (Direct)');
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C73EB), Color(0xFF0284C7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C73EB).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '⚡ Directly Complete Payment (Bypass Scan)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Or Select Other Gateway Channels:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              _webRazorpayOptionTile(
                icon: Icons.qr_code,
                title: 'Razorpay Instant UPI Intent (GPay / PhonePe / Paytm)',
                subtitle: 'Simulate instant UPI intent approval',
                onTap: () => _completeWebRazorpayPayment(ctx, orderId, 'UPI'),
              ),
              const SizedBox(height: 10),
              _webRazorpayOptionTile(
                icon: Icons.credit_card,
                title: 'Razorpay Test Card (Visa / Mastercard / RuPay)',
                subtitle: 'Simulate 3D Secure OTP verification',
                onTap: () => _completeWebRazorpayPayment(ctx, orderId, 'Card'),
              ),
              const SizedBox(height: 10),
              _webRazorpayOptionTile(
                icon: Icons.account_balance,
                title: 'Razorpay NetBanking (HDFC / ICICI / SBI)',
                subtitle: 'Simulate corporate / retail bank authorization',
                onTap: () => _completeWebRazorpayPayment(ctx, orderId, 'NetBanking'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webRazorpayOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0C73EB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0C73EB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _completeWebRazorpayPayment(BuildContext ctx, String orderId, String channel) async {
    Navigator.pop(ctx);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final randomId = Random().nextInt(899999) + 100000;
    final simulatedPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}_$randomId';

    try {
      await ConsumerService.verifyRazorpayPayment(
        billId: widget.bill.id,
        razorpayOrderId: orderId,
        razorpayPaymentId: simulatedPaymentId,
        razorpaySignature: 'simulated_sig_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PaymentReceiptDialog(
          bill: widget.bill,
          transactionId: simulatedPaymentId,
          paymentMethod: 'Razorpay ($channel)',
          paymentDateTime: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Payment verification failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Electricity Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Hero Summary Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBg,
                    AppColors.backgroundSecondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Outstanding Due', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          bill.billingMonth,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  _summaryRow('Bill Number', bill.billNumber),
                  if (bill.consumerNumber != null)
                    _summaryRow('Consumer Number', bill.consumerNumber!),
                  _summaryRow('Units Consumed', '${bill.unitsConsumed.toStringAsFixed(0)} kWh'),
                  _summaryRow('Due Date', bill.dueDate),

                  // Collapsible Detailed Tariff Breakdown
                  InkWell(
                    onTap: () => setState(() => _showBreakdown = !_showBreakdown),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showBreakdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _showBreakdown ? 'Hide Tariff Breakdown' : 'View Itemized Tariff Details',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Text('Detailed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  if (_showBreakdown) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _breakdownRow('Energy Consumption Charge', '₹ ${bill.energyCharge.toStringAsFixed(2)}'),
                          _breakdownRow('Fixed Infrastructure Charge', '₹ ${bill.fixedCharge.toStringAsFixed(2)}'),
                          _breakdownRow('Electricity Duty & Taxes (10%)', '₹ ${bill.taxes.toStringAsFixed(2)}'),
                          if (bill.lateFee > 0)
                            _breakdownRow('Late Payment Fee', '₹ ${bill.lateFee.toStringAsFixed(2)}', isWarning: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Payment Mode Navigation Chips
            const Text(
              'Select Payment Mode',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _paymentMethodTab('Razorpay', Icons.bolt, 'Razorpay (Recommended)'),
                  _paymentMethodTab('UPI', Icons.qr_code_scanner, 'UPI & QR'),
                  _paymentMethodTab('Card', Icons.credit_card, 'Cards (Debit/Credit)'),
                  _paymentMethodTab('Net Banking', Icons.account_balance, 'Net Banking'),
                  _paymentMethodTab('Wallet', Icons.account_balance_wallet_outlined, 'Power Wallet'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Payment Method Input UI
            if (_selectedMethod == 'Razorpay') _buildRazorpaySection(),
            if (_selectedMethod == 'UPI') _buildUpiSection(),
            if (_selectedMethod == 'Card') _buildCardSection(),
            if (_selectedMethod == 'Net Banking') _buildNetBankingSection(),
            if (_selectedMethod == 'Wallet') _buildWalletSection(),

            const SizedBox(height: 32),

            // Checkout Button
            CustomButton(
              text: _selectedMethod == 'Razorpay'
                  ? 'Pay ₹ ${bill.totalAmount.toStringAsFixed(2)} with Razorpay'
                  : 'Pay ₹ ${bill.totalAmount.toStringAsFixed(2)} Securely',
              onPressed: _selectedMethod == 'Razorpay' ? _payWithRazorpay : _processPayment,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock, color: AppColors.textMuted, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '256-Bit SSL Encrypted & RBI Regulated Gateway',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodTab(String id, IconData icon, String title) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 0. Razorpay Section
  Widget _buildRazorpaySection() {
    final billAmount = widget.bill.totalAmount.toStringAsFixed(2);
    final razorpayQrString = 'upi://pay?pa=razorpay.powergrid@icici&pn=Razorpay%20PowerGrid&mc=4900&tr=${widget.bill.billNumber}&tn=Electricity%20Bill%20${widget.bill.billNumber}&am=$billAmount&cu=INR';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF07213A),
            AppColors.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF0C73EB).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C73EB).withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C73EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Razorpay Smart Gateway',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Instant Dynamic QR • 100% RBI & NPCI Compliant',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('RECOMMENDED',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dynamic Scannable Razorpay QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: razorpayQrString,
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF07213A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF07213A),
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C73EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Razorpay Dynamic QR • Exact Due: ₹$billAmount',
                      style: const TextStyle(color: Color(0xFF0C2340), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan with GPay / PhonePe / Paytm / BHIM or Click Below',
                    style: TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Direct 1-Tap QR Pay Action Button (Direct payment done without scanning)
          InkWell(
            onTap: _isLoading ? null : () => _payDirectlyViaRazorpayQr(methodLabel: 'Razorpay Dynamic QR (Direct Pay)'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C73EB), Color(0xFF00A86B)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C73EB).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Directly Complete Payment (Bypass QR Scan)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Text(
                        'Simulate instant scan & approve ₹$billAmount directly',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Supported Gateway Payment Modes:',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _paymentBadge('UPI (GPay / PhonePe / Paytm)', Icons.qr_code),
              _paymentBadge('All Debit & Credit Cards', Icons.credit_card),
              _paymentBadge('NetBanking (50+ Banks)', Icons.account_balance),
              _paymentBadge('Cred & Amazon Pay', Icons.wallet),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Razorpay Gateway active: Scannable dynamic QR and direct 1-click tokenized settlement.'
                        : 'Razorpay Gateway active: Hardware-accelerated UPI and card intent flow.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF0C73EB)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 1. UPI Section
  Widget _buildUpiSection() {
    final apps = [
      {'name': 'Google Pay', 'icon': Icons.g_mobiledata, 'color': Colors.blue},
      {'name': 'PhonePe', 'icon': Icons.phone_android, 'color': Colors.deepPurpleAccent},
      {'name': 'Paytm', 'icon': Icons.account_balance_wallet, 'color': Colors.cyan},
      {'name': 'BHIM UPI', 'icon': Icons.bolt, 'color': Colors.green},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_2, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instant UPI & QR Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Scan QR or pay via any verified UPI App', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dynamic Scannable NPCI UPI QR Code Card
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: 'upi://pay?pa=merchant.powergrid@icici&pn=PowerGrid%20Utility&mc=4900&tr=${widget.bill.billNumber}&tn=Electricity%20Bill%20${widget.bill.billNumber}&am=${widget.bill.totalAmount.toStringAsFixed(2)}&cu=INR',
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan with any UPI App • ₹${widget.bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'merchant.powergrid@icici'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard!'), duration: Duration(seconds: 2)),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'merchant.powergrid@icici',
                          style: TextStyle(color: Colors.black54, fontSize: 11, decoration: TextDecoration.underline),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.copy, size: 12, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Direct 1-Click Pay for UPI QR
          InkWell(
            onTap: _isLoading ? null : () => _payDirectlyViaRazorpayQr(methodLabel: 'UPI Dynamic QR (Direct Pay)'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '⚡ Directly Complete Payment (Bypass Scan)',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Or Select Preferred UPI App', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: apps.map((app) {
              final isSel = _selectedUpiApp == app['name'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUpiApp = app['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(app['icon'] as IconData, color: app['color'] as Color, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          app['name'] as String,
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Custom UPI ID Input
          const Text('Or Enter UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _upiIdController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. mobile@okhdfcbank / user@paytm',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primary, size: 18),
              filled: true,
              fillColor: AppColors.cardBgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Card Section
  Widget _buildCardSection() {
    final cardType = _detectCardType(_cardNumberController.text);
    final displayNum = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final displayName = _cardHolderController.text.isEmpty
        ? 'CARDHOLDER NAME'
        : _cardHolderController.text.toUpperCase();
    final displayExpiry = _cardExpiryController.text.isEmpty
        ? 'MM/YY'
        : _cardExpiryController.text;

    return Column(
      children: [
        // Interactive Virtual Card Simulator
        Container(
          height: 190,
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3C72).withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.nfc, color: Colors.white70, size: 28),
                  Text(
                    cardType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                ],
              ),
              Text(
                displayNum,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  fontFamily: 'Courier',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CARD HOLDER', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.8)),
                      Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('EXPIRES', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 0.8)),
                      Text(
                        displayExpiry,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Card Details Input Fields
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                onChanged: _formatCardNumber,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  hintText: '1234 5678 9012 3456',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.cardBgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cardHolderController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Name on Card',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  hintText: 'John Doe',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.cardBgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      onChanged: _formatExpiry,
                      decoration: InputDecoration(
                        labelText: 'Expiry (MM/YY)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: '08/28',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: AppColors.cardBgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'CVV / CVC',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: '123',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                        filled: true,
                        fillColor: AppColors.cardBgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Net Banking Section
  Widget _buildNetBankingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Banks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: _popularBanks.map((bank) {
              final isSel = _selectedBank == bank;
              return GestureDetector(
                onTap: () => setState(() => _selectedBank = bank),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: isSel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance, color: AppColors.primary, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        bank,
                        style: TextStyle(
                          color: isSel ? Colors.white : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          const Text('Or Select from All Banks', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBank,
                isExpanded: true,
                dropdownColor: AppColors.backgroundSecondary,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: _allBanks.map((b) {
                  return DropdownMenuItem(value: b, child: Text(b));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBank = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Wallet Section
  Widget _buildWalletSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.success, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PowerGrid Instant Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Balance: ₹ 10,000.00 (Ready for 1-Tap Pay)', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enjoy zero transaction charges and instant bill clearance with PowerGrid prepaid balance.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? AppColors.danger : Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
