import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/complaint_model.dart';
import '../../services/consumer_service.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _descriptionController = TextEditingController();
  String _complaintType = 'Power Failure';
  bool _isSubmitting = false;
  bool _isLoadingList = true;
  List<ComplaintModel> _complaints = [];
  String? _errorMessage;

  final List<String> _types = ['Power Failure', 'Meter Issue', 'Wrong Bill', 'Voltage Fluctuation', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoadingList = true;
      _errorMessage = null;
    });

    try {
      final list = await ConsumerService.getComplaints();
      if (mounted) setState(() => _complaints = list);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _handleSubmitComplaint() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final created = await ConsumerService.submitComplaint(
        complaintType: _complaintType,
        description: _descriptionController.text,
      );

      if (!mounted) return;

      _descriptionController.clear();
      _fetchComplaints();
      _tabController.animateTo(1); // switch to history tab

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Complaint Logged', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Ticket ID #${created.complaintId} has been registered with the technical department.',
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
        title: const Text('Support & Complaints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'File Complaint'),
            Tab(text: 'My Tickets'),
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
            'Select Issue Category',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: _types.map((type) {
              final isSelected = _complaintType == type;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _complaintType = type),
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
                          type,
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
            controller: _descriptionController,
            label: 'Issue Details & Landmark',
            hint: 'Describe the problem in detail...',
            maxLines: 4,
          ),
          const SizedBox(height: 28),

          CustomButton(
            text: 'Submit Support Ticket',
            onPressed: _handleSubmitComplaint,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      color: AppColors.primary,
      child: _isLoadingList
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Tickets',
                  message: _errorMessage!,
                  actionText: 'Retry',
                  onAction: _fetchComplaints,
                )
              : _complaints.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Active Tickets',
                      message: 'You have not registered any support complaints yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _complaints.length,
                      itemBuilder: (context, index) {
                        final item = _complaints[index];
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
                                    '#${item.complaintId}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  StatusBadge(status: item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.complaintType,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              if (item.resolutionDetails != null && item.resolutionDetails!.isNotEmpty) ...[
                                const Divider(color: AppColors.border, height: 18),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Resolution: ${item.resolutionDetails}',
                                        style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
