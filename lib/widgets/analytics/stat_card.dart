import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String amount;
  final String? badge;
  final bool isPositive;

  const StatCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.amount,
    this.badge,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        fillColor: AppTheme.bgCard,
        borderColor: Colors.white.withValues(alpha: 0.08),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const Gap(12),
            Text(label, style: AppTheme.caption.copyWith(fontSize: 12)),
            const Gap(4),
            Text(
              amount,
              style: AppTheme.bodyText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (badge != null) ...[
              const Gap(8),
              SecondaryBadge(
                child: Text(
                  badge!,
                  style: AppTheme.caption.copyWith(
                    color: isPositive ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

