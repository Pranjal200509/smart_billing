class AdminStatsModel {
  final int totalCustomers;
  final double totalBilledAmount;
  final double totalRevenueCollected;
  final int pendingBillsCount;
  final int overdueBillsCount;
  final String complaintsStatus;
  final int totalServiceRequests;

  AdminStatsModel({
    required this.totalCustomers,
    required this.totalBilledAmount,
    required this.totalRevenueCollected,
    required this.pendingBillsCount,
    required this.overdueBillsCount,
    required this.complaintsStatus,
    required this.totalServiceRequests,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalBilledAmount: (json['totalBilledAmount'] as num?)?.toDouble() ?? 0.0,
      totalRevenueCollected: (json['totalRevenueCollected'] as num?)?.toDouble() ?? 0.0,
      pendingBillsCount: (json['pendingBillsCount'] as num?)?.toInt() ?? 0,
      overdueBillsCount: (json['overdueBillsCount'] as num?)?.toInt() ?? 0,
      complaintsStatus: json['complaintsStatus'] ?? '0/0',
      totalServiceRequests: (json['totalServiceRequests'] as num?)?.toInt() ?? 0,
    );
  }
}
