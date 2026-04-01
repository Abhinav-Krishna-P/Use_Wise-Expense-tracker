import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class HeroSpendCard extends StatefulWidget {
  final double amount;
  final int transactions;
  final int categories;
  final String periodLabel;

  const HeroSpendCard({
    super.key,
    required this.amount,
    required this.transactions,
    required this.categories,
    this.periodLabel = 'Total Spent Today',
  });

  @override
  State<HeroSpendCard> createState() => _HeroSpendCardState();
}

class _HeroSpendCardState extends State<HeroSpendCard> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      surfaceBlur: 12,
      surfaceOpacity: 0.6,
      fillColor: AppTheme.bgCard,
      borderColor: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(24),
      child: _loaded
          ? _Content(
              amount: widget.amount,
              transactions: widget.transactions,
              categories: widget.categories,
              periodLabel: widget.periodLabel,
            )
          : _ShimmerPlaceholder(),
    );
  }
}

class _Content extends StatelessWidget {
  final double amount;
  final int transactions;
  final int categories;
  final String periodLabel;

  const _Content({
    required this.amount,
    required this.transactions,
    required this.categories,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(periodLabel, style: AppTheme.caption.copyWith(fontSize: 13)),
        const Gap(4),
        Text('${context.read<AuthProvider>().currencySymbol}${amount.toStringAsFixed(0)}', style: AppTheme.displayAmount),
        const Gap(4),
        Text(
          '$transactions transactions · $categories categories',
          style: AppTheme.caption.copyWith(fontSize: 12),
        ),
        const Gap(16),
        SecondaryBadge(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 14, color: AppTheme.green),
              const Gap(4),
              Text(
                '+${context.read<AuthProvider>().currencySymbol}340 since yesterday',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgGlass,
      highlightColor: AppTheme.bgCard.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const Gap(8),
          Container(width: 180, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const Gap(8),
          Container(width: 200, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const Gap(16),
          Container(width: 150, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}

