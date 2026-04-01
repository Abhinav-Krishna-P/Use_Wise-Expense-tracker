import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../theme/app_theme.dart';

class LineChartWidget extends StatelessWidget {
  final List<double> dailyAmounts;
  final List<String> labels;
  final String period;

  const LineChartWidget({
    super.key,
    required this.dailyAmounts,
    required this.labels,
    this.period = 'Weekly',
  });

  @override
  Widget build(BuildContext context) {
    final spots = dailyAmounts.isEmpty
        ? [const FlSpot(0, 0)]
        : dailyAmounts
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();

    final maxY = dailyAmounts.isEmpty
        ? 1.0
        : (dailyAmounts.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, double.infinity);

    final int count = labels.length;

    // Decide how many labels to skip so the axis doesn't get cluttered.
    double interval;
    if (period == 'Weekly' || period == 'Yearly') {
      interval = 1;
    } else {
      // Monthly: show every 5th day
      interval = 5;
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: period == 'Weekly' ? 32 : 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= count) return const SizedBox.shrink();

                if (period == 'Monthly') {
                  // Show 1st, every 5th, and last day
                  if (idx != 0 && idx != count - 1 && idx % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: AppTheme.caption.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
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
            curveSmoothness: 0.35,
            color: AppTheme.chartOrange,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: period != 'Monthly',
              getDotPainter: (spot, p1, p2, p3) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.chartOrange,
                strokeWidth: 1.5,
                strokeColor: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.chartOrange.withValues(alpha: 0.25),
                  AppTheme.chartOrange.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
