import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/budget_model.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class BudgetPlanDetailsScreen extends StatelessWidget {
  final BudgetPlan plan;

  const BudgetPlanDetailsScreen({
    super.key,
    required this.plan,
  });

  static const _questionOptionLabels = <String, Map<String, String>>{
    'q1': {
      'A': 'Buy immediately',
      'B': 'Think for a day',
      'C': 'Add to wishlist',
      'D': 'Almost never buy it',
    },
    'q2': {
      'A': 'Do not save',
      'B': 'Save what is left',
      'C': 'Save a fixed amount',
      'D': 'Save first',
    },
    'q3': {
      'A': 'No tracking',
      'B': 'Check bank app',
      'C': 'Track in an app',
      'D': 'Detailed records',
    },
    'q4': {
      'A': 'Treat myself',
      'B': 'Split half-half',
      'C': 'Paying off debts',
      'D': 'Invest/save almost all',
    },
    'q5': {
      'A': 'Often broke',
      'B': 'Manage but tight',
      'C': 'Comfortable',
      'D': 'Very secure',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final background = colorScheme.background;
    final surface = colorScheme.card;
    final surfaceHigh = isDark ? const Color(0xFF121212) : colorScheme.secondary;
    final textPrimary = colorScheme.foreground;
    final textMuted = colorScheme.mutedForeground;
    final barTrack = isDark ? const Color(0xFF2A2A2A) : colorScheme.secondary;
    final barFill = isDark ? const Color(0xFF7E7E82) : colorScheme.foreground.withValues(alpha: 0.55);
    final currencySymbol = context.read<AuthProvider>().currencySymbol;
    final totalFixed = plan.totalFixedExpenses;
    final behaviorTags = _buildBehaviorTags(plan.questionAnswers);

    return material.Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'TOTAL LIQUIDITY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$currencySymbol${plan.monthlyIncome.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.8,
                  color: textPrimary,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monthly recurring income after taxes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 44),
              _DetailCard(
                title: 'Fixed Expenses',
                icon: Icons.account_balance_wallet_outlined,
                surfaceColor: surface,
                titleColor: textPrimary,
                iconColor: textMuted,
                child: Column(
                  children: [
                    ...plan.fixedExpenses.asMap().entries.map((entry) {
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: entry.key == plan.fixedExpenses.length - 1 ? 12 : 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$currencySymbol${item.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (entry.key != plan.fixedExpenses.length - 1) ...[
                              const SizedBox(height: 14),
                              Container(height: 1, color: colorScheme.border),
                            ],
                          ],
                        ),
                      );
                    }),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'TOTAL COMMITMENT',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: textMuted,
                              ),
                            ),
                          ),
                          Text(
                            '$currencySymbol${totalFixed.toStringAsFixed(2)}',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _DetailCard(
                title: 'Behavioral Profile',
                icon: Icons.psychology_alt_outlined,
                surfaceColor: surface,
                titleColor: textPrimary,
                iconColor: textMuted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: behaviorTags.map((tag) => _BehaviorChip(label: tag)).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _buildBehaviorSummary(plan),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.selectedPlanName,
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Selected AI Allocation Strategy',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 22,
                          color: textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ...plan.planBreakdown.entries.map((entry) {
                      final percent = entry.value;
                      final amount = plan.monthlyIncome * (percent / 100);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.key} (${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 1)}%)',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$currencySymbol${amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (percent / 100).clamp(0, 1),
                                minHeight: 10,
                                backgroundColor: barTrack,
                                valueColor: AlwaysStoppedAnimation(barFill),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildBehaviorTags(Map<String, String> answers) {
    final tags = <String>[];
    for (final entry in answers.entries) {
      final label = _questionOptionLabels[entry.key]?[entry.value];
      if (label != null && label.isNotEmpty) {
        tags.add(label);
      }
    }
    return tags;
  }

  String _buildBehaviorSummary(BudgetPlan plan) {
    final planName = plan.selectedPlanName.replaceAll('_', ' ');
    final keywords = _buildBehaviorTags(plan.questionAnswers).take(2).join(' and ');
    if (keywords.isEmpty) {
      return 'Your plan is tuned to a "$planName" mindset based on your saved budgeting profile.';
    }
    return 'Your plan is tuned to a "$planName" mindset with focus on $keywords.';
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color surfaceColor;
  final Color titleColor;
  final Color iconColor;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.surfaceColor,
    required this.titleColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _BehaviorChip extends StatelessWidget {
  final String label;

  const _BehaviorChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isHighlighted = label == 'Comfortable' || label == 'Save first';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.foreground.withValues(alpha: colorScheme.brightness == Brightness.dark ? 0.42 : 0.14)
            : colorScheme.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.foreground,
        ),
      ),
    );
  }
}
