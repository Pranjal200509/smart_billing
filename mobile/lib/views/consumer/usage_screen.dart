import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/metric_card.dart';
import '../../models/usage_model.dart';
import '../../services/consumer_service.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  UsageOverviewModel? _overview;
  List<UsageChartPoint> _chartPoints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final overviewFuture = ConsumerService.getUsageOverview();
      final chartFuture = ConsumerService.getUsageChartData();

      final results = await Future.wait([overviewFuture, chartFuture]);

      if (mounted) {
        setState(() {
          _overview = results[0] as UsageOverviewModel;
          _chartPoints = results[1] as List<UsageChartPoint>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Electricity Consumption', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsageData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
                  ),
                )
              else ...[
                // Metric Cards Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    MetricCard(
                      title: 'Current Meter Reading',
                      value: '${_overview?.currentReadingKwh.toStringAsFixed(0) ?? "0"} kWh',
                      icon: Icons.speed,
                      color: AppColors.primary,
                    ),
                    MetricCard(
                      title: 'Previous Month Reading',
                      value: '${_overview?.previousReadingKwh.toStringAsFixed(0) ?? "0"} kWh',
                      icon: Icons.history,
                      color: AppColors.accent,
                    ),
                    MetricCard(
                      title: 'Units Used This Cycle',
                      value: '${_overview?.unitsUsed.toStringAsFixed(0) ?? "0"} kWh',
                      icon: Icons.flash_on,
                      color: AppColors.success,
                    ),
                    MetricCard(
                      title: '6-Month Average Usage',
                      value: '${_overview?.averageUnits.toStringAsFixed(0) ?? "0"} kWh',
                      icon: Icons.auto_graph,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Chart Container
                const Text(
                  'Monthly Usage Trends',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 280,
                  padding: const EdgeInsets.fromLTRB(16, 24, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _chartPoints.isEmpty
                      ? const Center(
                          child: Text('No chart records available', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 50,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Colors.white.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 100,
                                  getTitlesWidget: (val, _) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    final index = val.toInt();
                                    if (index >= 0 && index < _chartPoints.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _chartPoints[index].month,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                                spots: _chartPoints.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value.units);
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
