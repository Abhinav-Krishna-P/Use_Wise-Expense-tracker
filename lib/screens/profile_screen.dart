import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _confirmLogout(BuildContext context) async {
    final colorScheme = context.colorScheme;
    final confirmed = await showDialog<bool>(
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
                      onTap: () => Navigator.of(ctx).pop(false),
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
                      onTap: () => Navigator.of(ctx).pop(true),
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

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().signOut();
      Navigator.of(context).pop();
    }
  }

  String _formatAmount(double amount) {
    final sym = context.read<AuthProvider>().currencySymbol;
    if (amount >= 100000) return '$sym${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '$sym${(amount / 1000).toStringAsFixed(1)}k';
    return '$sym${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final expProv = context.watch<ExpenseProvider>();
    final user = authProv.user;
    final colorScheme = context.colorScheme;

    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;
    final joined = user?.metadata.creationTime;

    final now = DateTime.now();
    final monthlyExpenses = expProv.expenses.where((e) {
      final local = e.date.toLocal();
      return local.year == now.year && local.month == now.month;
    });
    final monthlyTotal = monthlyExpenses.fold(0.0, (s, e) => s + e.amount);
    final monthlyCount = monthlyExpenses.length;
    final todayTotal = expProv.totalToday;
    final todayCount = expProv.todayCount;

    return Scaffold(
      child: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.border),
                      ),
                      child: Center(
                        child: Icon(Icons.arrow_back_rounded, size: 18, color: colorScheme.foreground),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Text('Profile', style: AppTheme.titleLarge.copyWith(fontSize: 20)),
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Gap(8),

                    // ── Profile card ─────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.border),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.border, width: 2),
                              image: photoUrl != null && photoUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                  : null,
                              color: photoUrl == null || photoUrl.isEmpty
                                  ? colorScheme.foreground.withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: AppTheme.titleLarge.copyWith(fontSize: 32),
                                    ),
                                  )
                                : null,
                          ),
                          const Gap(16),

                          // Name
                          Text(
                            displayName,
                            style: AppTheme.titleLarge.copyWith(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(4),

                          // Email
                          Text(
                            email,
                            style: AppTheme.bodyText.copyWith(
                              color: colorScheme.mutedForeground,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (joined != null) ...[
                            const Gap(4),
                            Text(
                              'Joined ${DateFormat('MMM d, yyyy').format(joined)}',
                              style: AppTheme.caption.copyWith(
                                color: colorScheme.mutedForeground,
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const Gap(24),

                          // ── Stats row ──────────────────────────────────
                          Row(
                            children: [
                              _StatTile(
                                label: "Today's Spend",
                                value: _formatAmount(todayTotal),
                                subLabel: '$todayCount expenses',
                                color: AppTheme.chartOrange,
                                colorScheme: colorScheme,
                              ),
                              const Gap(12),
                              _StatTile(
                                label: 'Monthly Total Spend',
                                value: _formatAmount(monthlyTotal),
                                subLabel: '$monthlyCount expenses',
                                color: AppTheme.teal,
                                colorScheme: colorScheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(24),

                    // ── Logout button ────────────────────────────────────
                    GestureDetector(
                      onTap: () => _confirmLogout(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.red.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: AppTheme.red),
                            const Gap(10),
                            Text(
                              'Log Out',
                              style: AppTheme.bodyText.copyWith(
                                color: AppTheme.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color color;
  final ColorScheme colorScheme;

  const _StatTile({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: colorScheme.mutedForeground,
                fontSize: 11,
              ),
            ),
            const Gap(6),
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(fontSize: 20, color: color),
            ),
            const Gap(2),
            Text(
              subLabel,
              style: AppTheme.caption.copyWith(
                color: colorScheme.mutedForeground,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
