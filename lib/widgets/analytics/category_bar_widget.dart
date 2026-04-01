import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../mock/mock_data_service.dart';

class CategoryBarWidget extends StatefulWidget {
  const CategoryBarWidget({super.key});

  @override
  State<CategoryBarWidget> createState() => _CategoryBarWidgetState();
}

class _CategoryBarWidgetState extends State<CategoryBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = MockDataService.categoryBreakdown;
    final total = data.values.fold(0.0, (a, b) => a + b);
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);

    return Card(
      fillColor: AppTheme.bgCard,
      borderColor: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where Your Money Goes', style: AppTheme.sectionTitle),
          const Gap(16),
          ...data.entries.map((entry) {
            final pct =
                total > 0 ? (entry.value / total * 100).toStringAsFixed(0) : '0';
            final barFraction = maxVal > 0 ? entry.value / maxVal : 0.0;
            final color =
                AppTheme.categoryColors[entry.key] ?? AppTheme.purple;
            final emoji =
                AppTheme.categoryEmojis[entry.key] ?? '💰';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const Gap(8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key,
                      style: AppTheme.caption.copyWith(
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _AnimBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return LinearProgressIndicator(
                          value: barFraction * _controller.value,
                          backgroundColor:
                              AppTheme.bgGlass.withValues(alpha: 0.5),
                          color: color,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${context.read<AuthProvider>().currencySymbol}${entry.value.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: AppTheme.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const Gap(6),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$pct%',
                      textAlign: TextAlign.right,
                      style: AppTheme.caption.copyWith(
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AnimBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const _AnimBuilder({
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}

