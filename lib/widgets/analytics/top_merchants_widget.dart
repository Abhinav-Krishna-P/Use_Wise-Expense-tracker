import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class TopMerchantsWidget extends StatelessWidget {
  /// List of (description → total amount), sorted descending, max 4 items.
  final List<MapEntry<String, double>> merchants;

  const TopMerchantsWidget({super.key, required this.merchants});

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No expenses logged yet.',
          style: AppTheme.caption.copyWith(color: AppTheme.muted),
        ),
      );
    }

    final maxAmount = merchants.first.value;
    final colors = [
      AppTheme.chartOrange,
      AppTheme.teal,
      AppTheme.chartBlue,
      AppTheme.chartYellow,
    ];

    return Column(
      children: merchants.asMap().entries.map((entry) {
        final idx = entry.key;
        final name = entry.value.key;
        final amount = entry.value.value;
        final progress = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
        final color = colors[idx % colors.length];
        final sym = context.read<AuthProvider>().currencySymbol;
        final amountLabel = amount >= 1000
            ? '$sym${(amount / 1000).toStringAsFixed(1)}k'
            : '$sym${amount.toStringAsFixed(0)}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _MerchantRow(name, amountLabel, color, progress),
        );
      }).toList(),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  final String name;
  final String amount;
  final Color color;
  final double progress;

  const _MerchantRow(this.name, this.amount, this.color, this.progress);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: context.colorScheme.foreground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(8),
            Text(
              amount,
              style: AppTheme.bodyText.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.foreground,
              ),
            ),
          ],
        ),
        const Gap(8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.colorScheme.border,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
