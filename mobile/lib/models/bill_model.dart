class BillModel {
  final int id;
  final String billNumber;
  final String billingMonth;
  final double previousReadingKwh;
  final double currentReadingKwh;
  final double unitsConsumed;
  final double energyCharge;
  final double fixedCharge;
  final double taxes;
  final double lateFee;
  final double totalAmount;
  final String dueDate;
  final String paymentStatus;
  final String? consumerNumber;

  BillModel({
    required this.id,
    required this.billNumber,
    required this.billingMonth,
    required this.previousReadingKwh,
    required this.currentReadingKwh,
    required this.unitsConsumed,
    required this.energyCharge,
    required this.fixedCharge,
    required this.taxes,
    required this.lateFee,
    required this.totalAmount,
    required this.dueDate,
    required this.paymentStatus,
    this.consumerNumber,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      billNumber: json['billNumber'] ?? '',
      billingMonth: json['billingMonth'] ?? '',
      previousReadingKwh: (json['previousReadingKwh'] as num?)?.toDouble() ?? 0.0,
      currentReadingKwh: (json['currentReadingKwh'] as num?)?.toDouble() ?? 0.0,
      unitsConsumed: (json['unitsConsumed'] as num?)?.toDouble() ?? 0.0,
      energyCharge: (json['energyCharge'] as num?)?.toDouble() ?? 0.0,
      fixedCharge: (json['fixedCharge'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      consumerNumber: json['consumerNumber'],
    );
  }
}
