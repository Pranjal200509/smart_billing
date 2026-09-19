import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/service_request_model.dart';
import '../../services/admin_service.dart';

class AdminServiceRequestsScreen extends StatefulWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  State<AdminServiceRequestsScreen> createState() => _AdminServiceRequestsScreenState();
}

class _AdminServiceRequestsScreenState extends State<AdminServiceRequestsScreen> {
  List<ServiceRequestModel> _requests = [];
  List<ServiceRequestModel> _filteredRequests = [];
  String _selectedStatus = 'ALL'; // ALL, PENDING, IN_PROGRESS, COMPLETED
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _searchController.addListener(_filterRequests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminService.getAllServiceRequests();
      if (mounted) {
        setState(() {
          _requests = list;
          _filterRequests();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterRequests() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredRequests = _requests.where((r) {
        final matchesStatus = _selectedStatus == 'ALL' ||
            r.status.toUpperCase() == _selectedStatus.toUpperCase();

        if (!matchesStatus) return false;

        if (query.isEmpty) return true;

        final reqId = r.requestId.toLowerCase();
        final type = r.requestType.toLowerCase();
        final details = r.details.toLowerCase();
        final name = (r.userFullName ?? '').toLowerCase();

        return reqId.contains(query) || type.contains(query) || details.contains(query) || name.contains(query);
      }).toList();
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await AdminService.updateServiceRequestStatus(id: id, status: status);
      _fetchRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
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
                  hintText: 'Search service requests by ID, type, or user...',
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
                    _statusFilterChip('ALL', 'All (${_requests.length})'),
                    const SizedBox(width: 8),
                    _statusFilterChip('PENDING', 'Pending'),
                    const SizedBox(width: 8),
                    _statusFilterChip('IN_PROGRESS', 'In Progress'),
                    const SizedBox(width: 8),
                    _statusFilterChip('COMPLETED', 'Completed'),
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
                          title: 'Error Loading Service Requests',
                          message: _errorMessage!,
                          actionText: 'Retry',
                          onAction: _fetchRequests,
                        )
                      : _filteredRequests.isEmpty
                          ? EmptyState(
                              icon: Icons.miscellaneous_services_outlined,
                              title: 'Queue Empty',
                              message: _selectedStatus == 'ALL'
                                  ? 'No consumer service requests in the queue.'
                                  : 'No requests in $_selectedStatus status.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredRequests.length,
                              itemBuilder: (context, index) {
                                final item = _filteredRequests[index];
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
                                            'Req #${item.requestId}',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          StatusBadge(status: item.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.requestType,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.details,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      if (item.userFullName != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Requested by: ${item.userFullName} (${item.userEmail ?? ""})',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (item.status != 'COMPLETED')
                                            ElevatedButton(
                                              onPressed: () => _updateStatus(item.id, 'COMPLETED'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.success,
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Mark Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                          if (item.status != 'IN_PROGRESS' && item.status != 'COMPLETED') ...[
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () => _updateStatus(item.id, 'IN_PROGRESS'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.warning,
                                                side: const BorderSide(color: AppColors.warning),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('In Progress', style: TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ],
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
          _filterRequests();
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
