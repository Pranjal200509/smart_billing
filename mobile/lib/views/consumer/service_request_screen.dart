import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/service_request_model.dart';
import '../../services/consumer_service.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _detailsController = TextEditingController();
  String _selectedService = 'Meter Replacement';
  bool _isSubmitting = false;
  bool _isLoadingList = true;
  List<ServiceRequestModel> _requests = [];
  String? _errorMessage;

  final List<String> _services = [
    'New Connection',
    'Meter Replacement',
    'Address Change',
    'Load Change',
    'Disconnection / Reconnection'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoadingList = true;
      _errorMessage = null;
    });

    try {
      final list = await ConsumerService.getServiceRequests();
      if (mounted) setState(() => _requests = list);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter request details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await ConsumerService.submitServiceRequest(
        requestType: _selectedService,
        details: _detailsController.text,
      );

      if (!mounted) return;

      _detailsController.clear();
      _fetchRequests();
      _tabController.animateTo(1);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Service Request Registered', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Request ID #${created.requestId} has been submitted for utility engineer review.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Service Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Service Category',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: _services.map((service) {
              final isSelected = _selectedService == service;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedService = service),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          service,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: _detailsController,
            label: 'Additional Information & Justification',
            hint: 'Specify details (e.g. change load from 5kW to 10kW)...',
            maxLines: 4,
          ),
          const SizedBox(height: 28),

          CustomButton(
            text: 'Submit Service Request',
            onPressed: _handleSubmit,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: AppColors.primary,
      child: _isLoadingList
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Requests',
                  message: _errorMessage!,
                  actionText: 'Retry',
                  onAction: _fetchRequests,
                )
              : _requests.isEmpty
                  ? const EmptyState(
                      icon: Icons.miscellaneous_services_outlined,
                      title: 'No Service Requests',
                      message: 'You have not submitted any technical requests yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final item = _requests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${item.requestId}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.requestType,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.details,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
