import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/complaint_model.dart';
import '../../services/admin_service.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<ComplaintModel> _complaints = [];
  List<ComplaintModel> _filteredComplaints = [];
  String _selectedStatus = 'ALL'; // ALL, SUBMITTED, IN_PROGRESS, RESOLVED, REJECTED
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
    _searchController.addListener(_filterComplaints);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminService.getAllComplaints();
      if (mounted) {
        setState(() {
          _complaints = list;
          _filterComplaints();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterComplaints() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredComplaints = _complaints.where((c) {
        final matchesStatus = _selectedStatus == 'ALL' ||
            c.status.toUpperCase() == _selectedStatus.toUpperCase();

        if (!matchesStatus) return false;

        if (query.isEmpty) return true;

        final ticket = c.complaintId.toLowerCase();
        final type = c.complaintType.toLowerCase();
        final desc = c.description.toLowerCase();
        final name = (c.userFullName ?? '').toLowerCase();

        return ticket.contains(query) || type.contains(query) || desc.contains(query) || name.contains(query);
      }).toList();
    });
  }

  void _showResolveModal(ComplaintModel complaint) {
    final resolutionController = TextEditingController(text: complaint.resolutionDetails ?? '');
    String selectedStatus = complaint.status == 'SUBMITTED' ? 'IN_PROGRESS' : (complaint.status == 'REJECTED' ? 'REJECTED' : 'RESOLVED');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolve Ticket #${complaint.complaintId}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${complaint.complaintType} • ${complaint.userFullName ?? "Consumer"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const Divider(color: AppColors.border, height: 24),

                  const Text('Update Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['IN_PROGRESS', 'RESOLVED', 'REJECTED'].map((st) {
                      final isSel = selectedStatus == st;
                      return ChoiceChip(
                        label: Text(st, style: TextStyle(color: isSel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardBgLight,
                        onSelected: (_) => setModalState(() => selectedStatus = st),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: resolutionController,
                    label: 'Technical Resolution Notes',
                    hint: 'Details of action taken by field line technicians...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Save Ticket Update',
                    isLoading: isSaving,
                    onPressed: () async {
                      if (resolutionController.text.trim().isEmpty) return;
                      setModalState(() => isSaving = true);
                      try {
                        await AdminService.resolveComplaint(
                          id: complaint.id,
                          resolutionDetails: resolutionController.text,
                          status: selectedStatus,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _fetchComplaints();
                      } catch (e) {
                        setModalState(() => isSaving = false);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search complaints by Ticket #, user, or topic...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),

            // Status Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusFilterChip('ALL', 'All (${_complaints.length})'),
                    const SizedBox(width: 8),
                    _statusFilterChip('SUBMITTED', 'Submitted'),
                    const SizedBox(width: 8),
                    _statusFilterChip('IN_PROGRESS', 'In Progress'),
                    const SizedBox(width: 8),
                    _statusFilterChip('RESOLVED', 'Resolved'),
                    const SizedBox(width: 8),
                    _statusFilterChip('REJECTED', 'Rejected'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _errorMessage != null
                      ? EmptyState(
                          icon: Icons.error_outline,
                          title: 'Error Loading Helpdesk',
                          message: _errorMessage!,
                          actionText: 'Retry',
                          onAction: _fetchComplaints,
                        )
                      : _filteredComplaints.isEmpty
                          ? EmptyState(
                              icon: Icons.support_agent_outlined,
                              title: 'Helpdesk Clear',
                              message: _selectedStatus == 'ALL'
                                  ? 'No consumer complaints filed in the system.'
                                  : 'No complaints in $_selectedStatus state.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredComplaints.length,
                              itemBuilder: (context, index) {
                                final item = _filteredComplaints[index];
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
                                            'Ticket #${item.complaintId}',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.complaintType,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      if (item.userFullName != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Filed by: ${item.userFullName} (${item.userEmail ?? ""})',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                      ],
                                      if (item.resolutionDetails != null && item.resolutionDetails!.isNotEmpty) ...[
                                        const Divider(color: AppColors.border, height: 16),
                                        Text(
                                          'Resolution Notes: ${item.resolutionDetails}',
                                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showResolveModal(item),
                                          icon: const Icon(Icons.edit_note, size: 16),
                                          label: const Text('Update Status', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          ),
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

  Widget _statusFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _filterComplaints();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
