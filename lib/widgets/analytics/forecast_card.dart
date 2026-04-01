import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../mock/mock_data_service.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    const spent = MockDataService.totalMonthly;
    const forecast = MockDataService.forecastTotal;
    const progress = spent / forecast;
    const remaining = forecast - spent;

    return SurfaceCard(
      surfaceBlur: 10,
      surfaceOpacity: 0.5,
      fillColor: AppTheme.bgCard,
      borderColor: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You're on track to spend",
            style: AppTheme.caption.copyWith(fontSize: 13),
          ),
          const Gap(4),
          Text(
            '${context.read<AuthProvider>().currencySymbol}${forecast.toStringAsFixed(0)}',
            style: AppTheme.displayAmount.copyWith(fontSize: 36),
          ),
          const Gap(2),
          Text(
            'this month',
            style: AppTheme.caption.copyWith(fontSize: 13),
          ),
          const Gap(20),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.bgGlass,
            color: AppTheme.purple,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const Gap(10),
          Text(
            '${context.read<AuthProvider>().currencySymbol}${spent.toStringAsFixed(0)} spent · ${context.read<AuthProvider>().currencySymbol}${remaining.toStringAsFixed(0)} to projected limit',
            style: AppTheme.caption.copyWith(fontSize: 12),
          ),
          const Gap(12),
          DestructiveBadge(
            child: Text(
              '🔴 12% over last month pace',
              style: AppTheme.caption.copyWith(
                color: AppTheme.red,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


