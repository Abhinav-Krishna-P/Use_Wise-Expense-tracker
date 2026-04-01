import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material show Dialog, MaterialPageRoute, showModalBottomSheet, DraggableScrollableSheet, SnackBar, ScaffoldMessenger;
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/spending_limit_provider.dart';
import '../models/expense_model.dart';
import '../theme/app_theme.dart';
import '../widgets/analytics/line_chart_widget.dart';
import '../widgets/analytics/pie_chart_widget.dart';
import '../widgets/analytics/spending_limit_cards.dart';
import '../widgets/analytics/set_limits_sheet.dart';
import '../widgets/shared/expense_list_item.dart';
import 'profile_screen.dart';
import 'budget_onboarding_screen.dart';
import 'budget_plan_details_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  final int currentTab;
  final ValueChanged<int> onTabChange;

  const AnalyticsScreen({
    super.key,
    required this.currentTab,
    required this.onTabChange,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _chartPeriod = 'Weekly';
  bool _isSidebarOpen = false;

  // ── Data computation helpers ────────────────────────────────────────────────

  /// Total spending for the selected period.
  double _totalForPeriod(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    switch (_chartPeriod) {
      case 'Weekly':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        return expenses
            .where((e) => e.date.toLocal().isAfter(startDay.subtract(const Duration(seconds: 1))))
            .fold(0.0, (s, e) => s + e.amount);
      case 'Monthly':
        return expenses
            .where((e) {
              final local = e.date.toLocal();
              return local.year == now.year && local.month == now.month;
            })
            .fold(0.0, (s, e) => s + e.amount);
      case 'Yearly':
        return expenses
            .where((e) => e.date.toLocal().year == now.year)
            .fold(0.0, (s, e) => s + e.amount);
      default:
        return 0;
    }
  }

  /// Yesterday's total for delta comparison.
  double _totalYesterday(List<ExpenseModel> expenses) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return expenses
        .where((e) {
          final local = e.date.toLocal();
          return local.year == yesterday.year &&
              local.month == yesterday.month &&
              local.day == yesterday.day;
        })
        .fold(0.0, (s, e) => s + e.amount);
  }

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// Returns (amounts, labels) for the chart. The data is always aligned to
  /// real calendar boundaries so the labels match the actual spending days.
  ({List<double> amounts, List<String> labels}) _buildChartData(List<ExpenseModel> expenses) {
    final now = DateTime.now();

    if (_chartPeriod == 'Weekly') {
      // Current week: Monday → Sunday
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      final amounts = List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        return expenses
            .where((e) {
              final l = e.date.toLocal();
              return l.year == day.year && l.month == day.month && l.day == day.day;
            })
            .fold(0.0, (s, e) => s + e.amount);
      });
      final labels = List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        return '${_dayNames[i]}\n${day.day}';
      });
      return (amounts: amounts, labels: labels);
    }

    if (_chartPeriod == 'Monthly') {
      // Current month: day 1 → today
      final daysInMonth = now.day;
      final amounts = List.generate(daysInMonth, (i) {
        final day = DateTime(now.year, now.month, i + 1);
        return expenses
            .where((e) {
              final l = e.date.toLocal();
              return l.year == day.year && l.month == day.month && l.day == day.day;
            })
            .fold(0.0, (s, e) => s + e.amount);
      });
      final labels = List.generate(daysInMonth, (i) => '${i + 1}');
      return (amounts: amounts, labels: labels);
    }

    // Yearly: Jan → Dec of current year
    final amounts = List.generate(12, (i) {
      final month = i + 1;
      return expenses
          .where((e) {
            final l = e.date.toLocal();
            return l.year == now.year && l.month == month;
          })
          .fold(0.0, (s, e) => s + e.amount);
    });
    final labels = List.generate(12, (i) => _monthNames[i]);
    return (amounts: amounts, labels: labels);
  }

  /// Human-readable date span for the current period.
  String _periodDateSpan() {
    final now = DateTime.now();
    switch (_chartPeriod) {
      case 'Weekly':
        final monday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${monday.day} ${_monthNames[monday.month - 1]} – ${sunday.day} ${_monthNames[sunday.month - 1]} ${sunday.year}';
      case 'Monthly':
        return '${_monthNames[now.month - 1]} ${now.year}';
      case 'Yearly':
        return '${now.year}';
      default:
        return '';
    }
  }

  /// Category → total amount, for the current period.
  Map<String, double> _buildCategoryData(List<ExpenseModel> expenses) {
    final filtered = _filterByPeriod(expenses);
    final map = <String, double>{};
    for (final e in filtered) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  /// Top 3 categories for quick-view chips.
  List<MapEntry<String, double>> _topCategories(List<ExpenseModel> expenses) {
    final data = _buildCategoryData(expenses);
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  List<ExpenseModel> _filterByPeriod(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    switch (_chartPeriod) {
      case 'Weekly':
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDay = DateTime(start.year, start.month, start.day);
        return expenses
            .where((e) => e.date.toLocal().isAfter(startDay.subtract(const Duration(seconds: 1))))
            .toList();
      case 'Monthly':
        return expenses
            .where((e) {
              final local = e.date.toLocal();
              return local.year == now.year && local.month == now.month;
            })
            .toList();
      case 'Yearly':
        return expenses.where((e) => e.date.toLocal().year == now.year).toList();
      default:
        return expenses;
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => material.Dialog(
        backgroundColor: colorScheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.logout_rounded, size: 24, color: AppTheme.red),
                ),
              ),
              const Gap(16),
              Text(
                'Log Out',
                style: AppTheme.titleLarge.copyWith(fontSize: 18, color: colorScheme.foreground),
              ),
              const Gap(8),
              Text(
                'Are you sure you want to log out of your account?',
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  color: colorScheme.mutedForeground,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.border),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.foreground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.read<AuthProvider>().signOut();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Log Out',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    final sym = context.read<AuthProvider>().currencySymbol;
    if (amount >= 100000) return '$sym${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '$sym${(amount / 1000).toStringAsFixed(1)}k';
    return '$sym${amount.toStringAsFixed(0)}';
  }

  void _toggleSidebar() {
    setState(() => _isSidebarOpen = !_isSidebarOpen);
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() => _isSidebarOpen = false);
    }
  }

  void _handleDrawerItemTap(String item) {
    _closeSidebar();

    if (item == 'Profile') {
      Navigator.of(context).push(
        material.MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    if (item == 'Calendar') {
      Navigator.of(context).push(
        material.MaterialPageRoute(builder: (_) => const CalendarScreen()),
      );
      return;
    }

    if (item == 'Analytics') {
      widget.onTabChange(1);
      return;
    }

    if (item == 'Budgeting') {
      final budgetProv = context.read<BudgetProvider>();
      final activePlan = budgetProv.activePlan;
      Navigator.of(context).push(
        material.MaterialPageRoute(
          builder: (_) => activePlan != null
              ? BudgetPlanDetailsScreen(plan: activePlan)
              : const BudgetOnboardingScreen(),
        ),
      );
      return;
    }

    if (item == 'Chat') {
      widget.onTabChange(0);
      return;
    }

    if (item == 'Logout') {
      _showLogoutConfirmation(context);
      return;
    }

    if (item == 'Settings') {
      Navigator.of(context).push(
        material.MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }

    final messenger = material.ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(
        material.SnackBar(content: Text('$item coming soon')),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final locale = Localizations.localeOf(context);
    final country = locale.countryCode ?? 'Unknown';
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'SpendWise User';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;
    final currencySymbol = auth.currencySymbol;
    final expenses = expProv.expenses.toList();
    final colorScheme = context.colorScheme;

    final periodTotal = _totalForPeriod(expenses);
    final todayTotal = expProv.totalToday;
    final yesterdayTotal = _totalYesterday(expenses);
    final chart = _buildChartData(expenses);
    final categoryData = _buildCategoryData(expenses);
    final topCats = _topCategories(expenses);

    return SafeArea(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeSidebar,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Gap(6),
                      _buildHeader(context, colorScheme),
                      const Gap(68),
                      _buildHeroRow(context, colorScheme, todayTotal, yesterdayTotal),
                      const Gap(16),
                      _buildCategoryQuickView(context, colorScheme, topCats),
                      const Gap(24),
                      _buildSpendingLimitsSection(context, colorScheme),
                      const Gap(24),
                      _buildInsightsHeader(context, colorScheme),
                      const Gap(16),
                      _buildSpendingTrendsCard(context, colorScheme, chart.amounts, chart.labels, periodTotal),
                      const Gap(16),
                      _buildCategoryDistributionCard(context, colorScheme, categoryData),
                      const Gap(32),
                      _buildRecentExpenses(context, expProv, colorScheme),
                      const Gap(120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 66,
            left: 0,
            right: 0,
            child: Center(
              child: _TopTabToggle(
                currentTab: widget.currentTab,
                onChanged: widget.onTabChange,
              ),
            ),
          ),
          if (_isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeSidebar,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  color: Colors.black.withValues(alpha: 0.34),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            left: _isSidebarOpen ? 0 : -292,
            top: 0,
            bottom: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: 280,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(26),
                    bottomRight: Radius.circular(26),
                  ),
                  border: Border.all(color: colorScheme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 36,
                      offset: Offset(10, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (photoUrl != null && photoUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    photoUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: colorScheme.border),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: AppTheme.titleLarge.copyWith(
                                        fontSize: 22,
                                        color: colorScheme.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              const Gap(14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.titleLarge.copyWith(
                                        fontSize: 18,
                                        color: colorScheme.foreground,
                                      ),
                                    ),
                                    const Gap(4),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.bodyText.copyWith(
                                      color: colorScheme.mutedForeground,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Gap(2),
                                    Text(
                                      country,
                                      style: AppTheme.bodyText.copyWith(
                                        color: colorScheme.mutedForeground,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL SPEND TODAY',
                                  style: AppTheme.caption.copyWith(
                                    color: colorScheme.mutedForeground,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  '$currencySymbol${todayTotal.toStringAsFixed(2)}',
                                  style: AppTheme.titleLarge.copyWith(
                                    fontSize: 22,
                                    color: colorScheme.foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(22),
                    _AnalyticsDrawerNavItem(
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                      onTap: () => _handleDrawerItemTap('Profile'),
                    ),
                    const Gap(6),
                    _AnalyticsDrawerNavItem(
                      label: 'Calendar',
                      icon: Icons.calendar_month_outlined,
                      onTap: () => _handleDrawerItemTap('Calendar'),
                    ),
                    const Gap(6),
                    _AnalyticsDrawerNavItem(
                      label: 'Budgeting',
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => _handleDrawerItemTap('Budgeting'),
                    ),
                    const Spacer(),
                    _AnalyticsDrawerNavItem(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () => _handleDrawerItemTap('Settings'),
                    ),
                    const Gap(6),
                    _AnalyticsDrawerNavItem(
                      label: 'Logout',
                      icon: Icons.logout_rounded,
                      isDestructive: true,
                      onTap: () => _handleDrawerItemTap('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.border),
              ),
              child: Center(
                child: Icon(Icons.menu_rounded, size: 18, color: colorScheme.foreground),
              ),
            ),
          ),
          const Gap(10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.foreground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(Icons.account_balance_wallet_rounded,
                  size: 20, color: colorScheme.foreground),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpendWise AI', style: AppTheme.titleLarge.copyWith(fontSize: 18)),
                Text(
                  'FINANCIAL ASSISTANT',
                  style: AppTheme.caption.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroRow(
    BuildContext context,
    ColorScheme colorScheme,
    double todayTotal,
    double yesterdayTotal,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildTodaySpendCard(context, colorScheme, todayTotal, yesterdayTotal),
          ),
          const Gap(12),
          Expanded(
            child: _buildBudgetPlanCard(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySpendCard(
    BuildContext context,
    ColorScheme colorScheme,
    double todayTotal,
    double yesterdayTotal,
  ) {
    String deltaLabel;
    Color deltaColor;
    if (yesterdayTotal == 0) {
      deltaLabel = 'No spend yesterday';
      deltaColor = colorScheme.mutedForeground;
    } else {
      final pct = ((todayTotal - yesterdayTotal) / yesterdayTotal * 100).abs();
      final sign = todayTotal <= yesterdayTotal ? '↓' : '↑';
      deltaColor = todayTotal <= yesterdayTotal ? AppTheme.green : AppTheme.red;
      deltaLabel = '$sign ${pct.toStringAsFixed(0)}% vs yesterday';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Spend",
            style: AppTheme.bodyText
                .copyWith(color: colorScheme.mutedForeground, fontSize: 12),
          ),
          const Gap(10),
          Text(
            _formatAmount(todayTotal),
            style: AppTheme.titleLarge.copyWith(fontSize: 26),
          ),
          const Gap(8),
          Text(
            deltaLabel,
            style: AppTheme.caption.copyWith(
              color: deltaColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPlanCard(BuildContext context, ColorScheme colorScheme) {
    final budgetProv = context.watch<BudgetProvider>();
    final plan = budgetProv.activePlan;

    if (plan != null) {
      final sym = context.read<AuthProvider>().currencySymbol;
      final afterFixed = plan.monthlyIncome - plan.totalFixedExpenses;

      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            material.MaterialPageRoute(
              builder: (_) => BudgetPlanDetailsScreen(plan: plan),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.selectedPlanName,
                style: AppTheme.bodyText.copyWith(
                  color: colorScheme.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                '$sym${afterFixed.toStringAsFixed(0)}',
                style: AppTheme.titleLarge.copyWith(fontSize: 22),
              ),
              const Gap(2),
              Text(
                'After fixed expenses',
                style: AppTheme.caption.copyWith(
                  color: colorScheme.mutedForeground,
                  fontSize: 10,
                ),
              ),
              const Gap(6),
              Text(
                'Income: $sym${plan.monthlyIncome.toStringAsFixed(0)}',
                style: AppTheme.caption.copyWith(
                  color: colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          material.MaterialPageRoute(
              builder: (_) => const BudgetOnboardingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.foreground.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: 22, color: colorScheme.foreground),
            ),
            const Gap(10),
            Text(
              'Add your\nbudgeting plan',
              textAlign: TextAlign.center,
              style: AppTheme.bodyText.copyWith(
                color: colorScheme.mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryQuickView(
    BuildContext context,
    ColorScheme colorScheme,
    List<MapEntry<String, double>> topCats,
  ) {
    // Pad with placeholders if fewer than 3 categories have been logged.
    final padded = List<MapEntry<String, double>?>.from(topCats);
    while (padded.length < 3) {
      padded.add(null);
    }

    return Row(
      children: padded.asMap().entries.map((entry) {
        final cat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: entry.key == 0 ? 0 : 12),
            child: _quickStatsCard(
              colorScheme,
              cat?.key ?? '—',
              cat != null ? _formatAmount(cat.value) : '${context.read<AuthProvider>().currencySymbol}0',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _quickStatsCard(ColorScheme colorScheme, String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTheme.caption.copyWith(fontSize: 12)),
          const Gap(6),
          Text(amount,
              style:
                  AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInsightsHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Spending Insights', style: AppTheme.titleLarge.copyWith(fontSize: 18)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _periodBtn(colorScheme, 'Weekly'),
            _periodBtn(colorScheme, 'Monthly'),
            _periodBtn(colorScheme, 'Yearly'),
          ],
        ),
      ],
    );
  }

  Widget _periodBtn(ColorScheme colorScheme, String label) {
    final isActive = _chartPeriod == label;
    return GestureDetector(
      onTap: () => setState(() => _chartPeriod = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTheme.caption.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colorScheme.background : colorScheme.mutedForeground,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingTrendsCard(
    BuildContext context,
    ColorScheme colorScheme,
    List<double> chartData,
    List<String> chartLabels,
    double periodTotal,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spending Trends',
                      style: AppTheme.bodyText
                          .copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
                  const Gap(2),
                  Text(
                    _periodDateSpan(),
                    style: AppTheme.caption.copyWith(
                      fontSize: 10,
                      color: colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
              Text(
                _formatAmount(periodTotal),
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.chartOrange,
                ),
              ),
            ],
          ),
          const Gap(24),
          SizedBox(
            height: 180,
            child: LineChartWidget(
              dailyAmounts: chartData,
              labels: chartLabels,
              period: _chartPeriod,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionCard(
    BuildContext context,
    ColorScheme colorScheme,
    Map<String, double> categoryData,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Distribution',
              style:
                  AppTheme.bodyText.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
          const Gap(24),
          PieChartWidget(categoryData: categoryData),
        ],
      ),
    );
  }

  Widget _buildSpendingLimitsSection(BuildContext context, ColorScheme colorScheme) {
    final limProv = context.watch<SpendingLimitProvider>();

    if (limProv.hasLimits) {
        return Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.border),
            ),
            child: const SpendingLimitCards(),
          ),
          Positioned(
            top: 16,
            right: 12,
            child: GestureDetector(
              onTap: () => showSetLimitsSheet(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.edit_outlined, size: 14, color: colorScheme.mutedForeground),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // No limits set — show a card with a "+" button
    return GestureDetector(
      onTap: () => showSetLimitsSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.add_rounded, size: 24, color: AppTheme.teal),
              ),
            ),
            const Gap(12),
            Text(
              'Set Spending Limits',
              style: AppTheme.bodyText.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.foreground,
              ),
            ),
            const Gap(4),
            Text(
              'Track daily, weekly, or monthly budgets\nfor up to 3 categories',
              textAlign: TextAlign.center,
              style: AppTheme.caption.copyWith(
                fontSize: 11,
                color: colorScheme.mutedForeground,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(
    BuildContext context,
    ExpenseProvider expProv,
    ColorScheme colorScheme,
  ) {
    final recentExpenses = expProv.expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final visible = recentExpenses.take(5).toList();
    final extraCount = recentExpenses.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Expenses", style: AppTheme.titleLarge.copyWith(fontSize: 18)),
        const Gap(16),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No expenses yet — chat to log your first one!',
              style: AppTheme.caption.copyWith(color: AppTheme.muted),
            ),
          )
        else ...[
          ...visible.map((expense) => ExpenseListItem(expense: expense)),
          if (extraCount > 0)
            GestureDetector(
              onTap: () => _showAllRecentExpenses(context, recentExpenses, colorScheme),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colorScheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.border),
                ),
                child: Center(
                  child: Text(
                    '+$extraCount more',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.teal,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _showAllRecentExpenses(
    BuildContext context,
    List<ExpenseModel> recentExpenses,
    ColorScheme colorScheme,
  ) {
    material.showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => material.DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colorScheme.border),
          ),
          child: Column(
            children: [
              const Gap(12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Expenses",
                      style: AppTheme.titleLarge.copyWith(fontSize: 18),
                    ),
                    Text(
                      '${recentExpenses.length} items',
                      style: AppTheme.caption.copyWith(
                        color: colorScheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recentExpenses.length,
                  itemBuilder: (_, i) =>
                      ExpenseListItem(expense: recentExpenses[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopTabToggle extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onChanged;

  const _TopTabToggle({
    required this.currentTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopTabItem(
            label: 'CHAT',
            isActive: currentTab == 0,
            onTap: () => onChanged(0),
          ),
          _TopTabItem(
            label: 'ANALYTICS',
            isActive: currentTab == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TopTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TopTabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.foreground : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isActive ? colorScheme.background : colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsDrawerNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const _AnalyticsDrawerNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textColor = isDestructive
        ? AppTheme.red
        : colorScheme.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const Gap(14),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyText.copyWith(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
