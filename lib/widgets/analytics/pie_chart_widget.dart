import 'package:fl_chart/fl_chart.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class PieChartWidget extends StatelessWidget {
  /// Category name → total amount. Built from real expense data.
  final Map<String, double> categoryData;

  const PieChartWidget({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No expense data yet.\nStart chatting to log expenses!',
            textAlign: TextAlign.center,
            style: AppTheme.caption.copyWith(color: AppTheme.muted),
          ),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (a, b) => a + b);

    // Sort by value descending, take top 5 for chart readability.
    final sorted = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(5).toList();

    final sections = topEntries.map((entry) {
      final color = AppTheme.categoryColors[entry.key] ?? AppTheme.purple;
      final value = entry.value / total * 100;
      return PieChartSectionData(
        color: color,
        value: value,
        title: '',
        radius: 35,
      );
    }).toList();

    final sym = context.read<AuthProvider>().currencySymbol;
    final totalLabel = total >= 1000
        ? '$sym${(total / 1000).toStringAsFixed(1)}k'
        : '$sym${total.toStringAsFixed(0)}';

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                startDegreeOffset: 270,
                sections: sections,
              )),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalLabel,
                    style: AppTheme.titleLarge.copyWith(fontSize: 16),
                  ),
                  const Gap(4),
                  Text('Total', style: AppTheme.caption.copyWith(fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
        const Gap(24),
        // Legend — up to 5 categories in a 2-column grid.
        _buildLegend(context, topEntries, total),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<MapEntry<String, double>> entries,
    double total,
  ) {
    final half = (entries.length / 2).ceil();
    final left = entries.take(half).toList();
    final right = entries.skip(half).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: left
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _legendItem(
                        context,
                        AppTheme.categoryColors[e.key] ?? AppTheme.purple,
                        e.key,
                        e.value,
                        total,
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: right
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _legendItem(
                        context,
                        AppTheme.categoryColors[e.key] ?? AppTheme.purple,
                        e.key,
                        e.value,
                        total,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(
    BuildContext context,
    Color color,
    String label,
    double amount,
    double total,
  ) {
    final pct = (amount / total * 100).toStringAsFixed(0);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(6),
        Expanded(
          child: Text(
            '$label $pct%',
            style: AppTheme.caption.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
