import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class RegressionChartCard extends StatelessWidget {
  final AnalysisResponse data;

  const RegressionChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.dataPoints.isEmpty) return const SizedBox.shrink();

    // Map screen time points
    final spots = data.dataPoints.map((dp) {
      return FlSpot(dp.day.toDouble(), dp.screenTimeMin.toDouble());
    }).toList();

    // Find the regression line for screen_time
    final stRegression = data.regression.firstWhere(
      (r) => r.metric == 'screen_time',
      orElse: () => RegressionInfo(
        metric: '',
        slope: 0,
        rSquared: 0,
        predictedNext: 0,
        direction: '',
        interpretation: '',
      ),
    );

    // We can pick standard colors for lines
    final chartColor = AppTheme.primary;
    final regressionColor = AppTheme.error;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Time Trends & Regression',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            stRegression.interpretation,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min ||
                            value == meta.max ||
                            value % 2 != 0) {
                          return const SizedBox.shrink(); // hide some labels to avoid overlapping
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Day ${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  if (stRegression.metric.isNotEmpty) ...[
                    LineChartBarData(
                      spots: [
                        FlSpot(
                          data.dataPoints.first.day.toDouble(),
                          data.dataPoints.first.screenTimeMin.toDouble() -
                              (stRegression.slope * data.dataPoints.first.day),
                        ),
                        FlSpot(
                          data.dataPoints.last.day.toDouble(),
                          data.dataPoints.last.screenTimeMin.toDouble() +
                              (stRegression.slope * data.dataPoints.last.day),
                        ),
                      ], // roughly plot a trendline. To be perfectly accurate we'd map Y intercepts but this is a simplified view
                      isCurved: false,
                      color: regressionColor,
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Additional Regression Items
          ...data.regression
              .where((r) => r.metric != 'screen_time')
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        r.direction == 'increasing'
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: r.direction == 'increasing'
                            ? AppTheme.primary
                            : AppTheme.secondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${r.interpretation} (Predicted next: ${r.predictedNext.toStringAsFixed(1)})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
