import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/user_profile_model.dart';
import '../../services/admin_service.dart';

class AdminMeterReadingScreen extends StatefulWidget {
  final String? initialConsumerNumber;
  final VoidCallback? onReadingLogged;

  const AdminMeterReadingScreen({
    super.key,
    this.initialConsumerNumber,
    this.onReadingLogged,
  });

  @override
  State<AdminMeterReadingScreen> createState() => _AdminMeterReadingScreenState();
}

class _AdminMeterReadingScreenState extends State<AdminMeterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _consumerNumberController = TextEditingController();
  final _readingController = TextEditingController();

  List<UserProfileModel> _consumers = [];
  UserProfileModel? _selectedConsumer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialConsumerNumber != null) {
      _consumerNumberController.text = widget.initialConsumerNumber!;
    }
    _fetchConsumers();
    _readingController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AdminMeterReadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConsumerNumber != null &&
        widget.initialConsumerNumber != oldWidget.initialConsumerNumber) {
      _consumerNumberController.text = widget.initialConsumerNumber!;
      _matchSelectedConsumer();
    }
  }

  @override
  void dispose() {
    _consumerNumberController.dispose();
    _readingController.dispose();
    super.dispose();
  }

  Future<void> _fetchConsumers() async {
    try {
      final list = await AdminService.getAllUsers();
      final validConsumers = list.where((u) => u.email != 'admin@gmail.com').toList();
      if (mounted) {
        setState(() {
          _consumers = validConsumers;
          _matchSelectedConsumer();
        });
      }
    } catch (_) {
    }
  }

  void _matchSelectedConsumer() {
    final curNo = _consumerNumberController.text.trim();
    if (curNo.isNotEmpty) {
      final found = _consumers.where((c) => c.consumerNumber == curNo || c.customerId == curNo).toList();
      if (found.isNotEmpty) {
        setState(() => _selectedConsumer = found.first);
      }
    }
  }

  void _onConsumerSelected(UserProfileModel consumer) {
    setState(() {
      _selectedConsumer = consumer;
      _consumerNumberController.text = consumer.consumerNumber ?? consumer.customerId ?? '';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final reading = double.tryParse(_readingController.text.trim());
    if (reading == null || reading < 0) {
      setState(() => _errorMessage = 'Enter a valid positive reading value');
      return;
    }

    if (_selectedConsumer != null && reading < _selectedConsumer!.currentReadingKwh) {
      setState(() => _errorMessage =
          'New reading ($reading kWh) cannot be lower than previous reading (${_selectedConsumer!.currentReadingKwh} kWh)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msg = await AdminService.submitMeterReading(
        consumerNumber: _consumerNumberController.text,
        readingValue: reading,
      );

      if (!mounted) return;

      _readingController.clear();
      widget.onReadingLogged?.call();
      _fetchConsumers(); // refresh latest readings

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reading Recorded Successfully', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '$msg\nLogged Value: $reading kWh',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? enteredReading = double.tryParse(_readingController.text.trim());
    final double prevReading = _selectedConsumer?.currentReadingKwh ?? 0.0;
    final double? deltaUnits = (enteredReading != null) ? (enteredReading - prevReading) : null;

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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.speed, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log Meter Reading',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Record physical meter kWh readings for billing cycles',
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

                    // Consumer Fast-Select Dropdown
                    if (_consumers.isNotEmpty) ...[
                      const Text('Quick Select Registered Consumer', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserProfileModel>(
                            value: _selectedConsumer,
                            isExpanded: true,
                            hint: const Text('Choose consumer from directory...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            dropdownColor: AppColors.backgroundSecondary,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                            items: _consumers.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.fullName} • ${c.consumerNumber ?? c.customerId ?? "No ID"} (${c.currentReadingKwh.toStringAsFixed(0)} kWh)'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) _onConsumerSelected(val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    CustomTextField(
                      controller: _consumerNumberController,
                      label: 'Consumer Number',
                      hint: 'e.g. 987654321012',
                      prefixIcon: Icons.confirmation_number_outlined,
                      onChanged: (_) => _matchSelectedConsumer(),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Consumer number is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Consumer Info / Previous Reading Indicator
                    if (_selectedConsumer != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedConsumer!.fullName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Meter: ${_selectedConsumer!.meterNumber ?? "N/A"} • ${_selectedConsumer!.connectionType ?? "Residential"}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Last Recorded', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                Text(
                                  '${_selectedConsumer!.currentReadingKwh.toStringAsFixed(1)} kWh',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _readingController,
                      label: 'New Cumulative Reading (kWh)',
                      hint: 'e.g. 2750.0',
                      prefixIcon: Icons.electric_bolt,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Reading value is required' : null,
                    ),

                    // Real-Time Units Consumed Delta Preview
                    if (deltaUnits != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: deltaUnits >= 0
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: deltaUnits >= 0
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              deltaUnits >= 0 ? 'Calculated Consumption:' : 'Invalid Reading:',
                              style: TextStyle(
                                color: deltaUnits >= 0 ? AppColors.success : AppColors.danger,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              deltaUnits >= 0 ? '+ ${deltaUnits.toStringAsFixed(1)} kWh' : '${deltaUnits.toStringAsFixed(1)} kWh (Lower than previous)',
                              style: TextStyle(
                                color: deltaUnits >= 0 ? AppColors.success : AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    CustomButton(
                      text: 'Record Reading to Grid',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
