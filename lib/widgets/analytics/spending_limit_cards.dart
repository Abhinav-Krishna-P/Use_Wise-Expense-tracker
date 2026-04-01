import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/spending_limit_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spending_limit_provider.dart';
import '../../theme/app_theme.dart';

/// Displays 1–3 spending limit cards showing category, spent/limit, and
/// a visual progress bar. Replaces the old "Top Expenses" section.
class SpendingLimitCards extends StatelessWidget {
  const SpendingLimitCards({super.key});

  @override
  Widget build(BuildContext context) {
    final limProv = context.watch<SpendingLimitProvider>();
    final colorScheme = context.colorScheme;

    if (!limProv.hasLimits) {
      return const SizedBox.shrink();
    }

    final sym = context.read<AuthProvider>().currencySymbol;
    final limits = limProv.limits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Limits',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${limits.length} ${limits.length == 1 ? 'category' : 'categories'}',
                style: AppTheme.caption.copyWith(
                  color: colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
        ...limits.map((limit) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _LimitCard(limit: limit, currencySymbol: sym, colorScheme: colorScheme),
            )),
      ],
    );
  }
}

class _LimitCard extends StatelessWidget {
  final SpendingLimitItem limit;
  final String currencySymbol;
  final ColorScheme colorScheme;

  const _LimitCard({
    required this.limit,
    required this.currencySymbol,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = AppTheme.categoryEmojis[limit.category] ?? '💰';
    final catColor = AppTheme.categoryColors[limit.category] ?? AppTheme.teal;
    final progressColor = limit.isExceeded ? AppTheme.red : catColor;
    final remaining = limit.remaining;
    final periodLabel = _formatPeriod(limit.period);

    final spentLabel = _formatAmount(limit.spent);
    final limitLabel = _formatAmount(limit.limitAmount);
    final remainingLabel = _formatAmount(remaining);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: limit.isExceeded
              ? AppTheme.red.withValues(alpha: 0.3)
              : colorScheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      limit.category,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'Limit: $currencySymbol$limitLabel',
                      style: AppTheme.caption.copyWith(
                        fontSize: 10,
                        color: colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      periodLabel,
                      style: AppTheme.caption.copyWith(
                        color: catColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Gap(6),
                  Text(
                    limit.isExceeded ? 'Exceeded!' : '$currencySymbol$remainingLabel left',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: limit.isExceeded ? AppTheme.red : AppTheme.green,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    'Spent: $currencySymbol$spentLabel',
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      color: colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(12),
          // Progress bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.border,
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: limit.usedPercent.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(limit.usedPercent * 100).toStringAsFixed(0)}% used',
                style: AppTheme.caption.copyWith(
                  fontSize: 9,
                  color: colorScheme.mutedForeground,
                ),
              ),
              if (limit.isExceeded)
                Text(
                  'Over by $currencySymbol${_formatAmount(limit.spent - limit.limitAmount)}',
                  style: AppTheme.caption.copyWith(
                    fontSize: 9,
                    color: AppTheme.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  String _formatPeriod(String period) {
    switch (period) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
      default:
        return 'Monthly';
    }
  }
}
