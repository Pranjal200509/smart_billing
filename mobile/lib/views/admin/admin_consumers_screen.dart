import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/user_profile_model.dart';
import '../../services/admin_service.dart';

class AdminConsumersScreen extends StatefulWidget {
  final void Function(String consumerNumber)? onLogReading;
  final void Function(int userId)? onGenerateBill;

  const AdminConsumersScreen({
    super.key,
    this.onLogReading,
    this.onGenerateBill,
  });

  @override
  State<AdminConsumersScreen> createState() => _AdminConsumersScreenState();
}

class _AdminConsumersScreenState extends State<AdminConsumersScreen> {
  List<UserProfileModel> _users = [];
  List<UserProfileModel> _filteredUsers = [];
  String _selectedType = 'ALL'; // ALL, Residential, Commercial, Industrial
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchConsumers();
    _searchController.addListener(_filterConsumers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConsumers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = list.where((u) => u.email != 'admin@gmail.com').toList();
          _filterConsumers();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterConsumers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = _users.where((u) {
        final matchesType = _selectedType == 'ALL' ||
            (u.connectionType != null && u.connectionType!.toLowerCase() == _selectedType.toLowerCase());

        if (!matchesType) return false;

        if (query.isEmpty) return true;

        final name = u.fullName.toLowerCase();
        final email = u.email.toLowerCase();
        final custId = (u.customerId ?? '').toLowerCase();
        final consumerNo = (u.consumerNumber ?? '').toLowerCase();
        final meterNo = (u.meterNumber ?? '').toLowerCase();
        final mobile = u.mobileNumber.toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            custId.contains(query) ||
            consumerNo.contains(query) ||
            meterNo.contains(query) ||
            mobile.contains(query);
      }).toList();
    });
  }

  void _showUserDetails(UserProfileModel user) {
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
                    user.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  StatusBadge(status: user.status ?? 'VERIFIED'),
                ],
              ),
              const Divider(color: AppColors.border, height: 20),
              _row('Customer ID', user.customerId ?? 'N/A'),
              _row('Consumer Number', user.consumerNumber ?? 'N/A'),
              _row('Meter Number', user.meterNumber ?? 'N/A'),
              _row('Current Reading', '${user.currentReadingKwh.toStringAsFixed(1)} kWh'),
              _row('Email Address', user.email),
              _row('Phone Number', user.mobileNumber),
              _row('Connection Type', user.connectionType ?? 'Residential'),
              _row('Sanctioned Load', '${user.loadCapacityKw.toStringAsFixed(1)} kW'),
              _row('Address', user.address ?? 'N/A'),
              _row('City / State', '${user.city ?? ""}, ${user.state ?? ""} - ${user.pinCode ?? ""}'),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (user.consumerNumber != null && widget.onLogReading != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogReading!(user.consumerNumber!);
                        },
                        icon: const Icon(Icons.speed, size: 16),
                        label: const Text('Log Reading'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (user.consumerNumber != null && widget.onLogReading != null)
                    const SizedBox(width: 10),
                  if (widget.onGenerateBill != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onGenerateBill!(user.id);
                        },
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('Generate Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
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
      body: RefreshIndicator(
        onRefresh: _fetchConsumers,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name, Consumer No, Meter No, ID...',
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

            // Connection Type Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _typeFilterChip('ALL', 'All Consumers (${_users.length})'),
                    const SizedBox(width: 8),
                    _typeFilterChip('Residential', 'Residential'),
                    const SizedBox(width: 8),
                    _typeFilterChip('Commercial', 'Commercial'),
                    const SizedBox(width: 8),
                    _typeFilterChip('Industrial', 'Industrial'),
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
                          title: 'Error Loading Registry',
                          message: _errorMessage!,
                          actionText: 'Retry',
                          onAction: _fetchConsumers,
                        )
                      : _filteredUsers.isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outline,
                              title: 'No Consumers Found',
                              message: 'No registered consumer matches your search query or filter.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final u = _filteredUsers[index];
                                final consumerNo = u.consumerNumber ?? u.customerId ?? "No ID";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    children: [
                                      Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                                            child: Text(
                                              u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'C',
                                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  u.fullName,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              StatusBadge(status: u.status ?? 'VERIFIED'),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 2),
                                              Text(
                                                'Consumer #: $consumerNo • ${u.connectionType ?? "Residential"}',
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                              Text(
                                                'Meter: ${u.meterNumber ?? "N/A"} • Last: ${u.currentReadingKwh.toStringAsFixed(0)} kWh (${u.loadCapacityKw.toStringAsFixed(1)} kW)',
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          onTap: () => _showUserDetails(u),
                                        ),
                                      ),
                                      const Divider(color: AppColors.border, height: 1),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (u.consumerNumber != null && widget.onLogReading != null)
                                              TextButton.icon(
                                                onPressed: () => widget.onLogReading!(u.consumerNumber!),
                                                icon: const Icon(Icons.speed, size: 15, color: AppColors.primary),
                                                label: const Text('Log Reading', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                              ),
                                            if (widget.onGenerateBill != null) ...[
                                              const SizedBox(width: 4),
                                              TextButton.icon(
                                                onPressed: () => widget.onGenerateBill!(u.id),
                                                icon: const Icon(Icons.receipt_long, size: 15, color: Colors.purpleAccent),
                                                label: const Text('Generate Bill', style: TextStyle(color: Colors.purpleAccent, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
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

  Widget _typeFilterChip(String type, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          _filterConsumers();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
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
