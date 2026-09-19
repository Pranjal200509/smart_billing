class UsageOverviewModel {
  final double currentReadingKwh;
  final double previousReadingKwh;
  final double unitsUsed;
  final double averageUnits;

  UsageOverviewModel({
    required this.currentReadingKwh,
    required this.previousReadingKwh,
    required this.unitsUsed,
    required this.averageUnits,
  });

  factory UsageOverviewModel.fromJson(Map<String, dynamic> json) {
    return UsageOverviewModel(
      currentReadingKwh: (json['currentReadingKwh'] as num?)?.toDouble() ?? 0.0,
      previousReadingKwh: (json['previousReadingKwh'] as num?)?.toDouble() ?? 0.0,
      unitsUsed: (json['unitsUsed'] as num?)?.toDouble() ?? 0.0,
      averageUnits: (json['averageUnits'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UsageChartPoint {
  final String month;
  final double units;

  UsageChartPoint({required this.month, required this.units});

  factory UsageChartPoint.fromJson(Map<String, dynamic> json) {
    return UsageChartPoint(
      month: json['month'] ?? '',
      units: (json['units'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
