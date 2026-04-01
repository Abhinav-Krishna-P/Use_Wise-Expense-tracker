import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/auth_provider.dart';

class BudgetOnboardingScreen extends StatefulWidget {
  const BudgetOnboardingScreen({super.key});

  @override
  State<BudgetOnboardingScreen> createState() =>
      _BudgetOnboardingScreenState();
}

class _BudgetOnboardingScreenState extends State<BudgetOnboardingScreen> {
  int _currentStep = 0;
  static const _totalSteps = 9;

  final _incomeController = TextEditingController();
  final List<FixedExpense> _fixedExpenses = [];
  final _expTitleCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController();
  bool _showAddExpenseForm = false;
  final _additionalInfoCtrl = TextEditingController();
  final Map<int, int> _selectedAnswers = {};

  // Step 8: AI plans
  int? _selectedPlanIndex;
  List<Map<String, dynamic>>? _aiPlans;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _errorMessage;

  // ── Question bank ─────────────────────────────────────────────────────────

  static final _questions = <Map<String, dynamic>>[
    {
      'stepLabel': 'Step 03 — Psychology',
      'topicLabel': 'Spending Impulse Control',
      'question':
          '1. When you see something you want but don\'t need, what do you usually do?',
      'subtitle': null,
      'options': [
        {'letter': 'A', 'text': 'Buy it immediately', 'desc': ''},
        {'letter': 'B', 'text': 'Think about it for a day', 'desc': ''},
        {'letter': 'C', 'text': 'Add it to a wishlist', 'desc': ''},
        {'letter': 'D', 'text': 'Almost never buy it', 'desc': ''},
      ],
    },
    {
      'stepLabel': 'Question 02',
      'topicLabel': 'Savings Attitude',
      'question': '2. How would you describe your current savings habit?',
      'subtitle': null,
      'options': [
        {
          'letter': 'A',
          'text': 'I don\'t save',
          'desc': 'Live paycheck to paycheck with no reserves.'
        },
        {
          'letter': 'B',
          'text': 'I save whatever is left',
          'desc': 'Savings happen sporadically at the end of the month.'
        },
        {
          'letter': 'C',
          'text': 'I try to save a fixed amount',
          'desc': 'Aim for a specific goal every month.'
        },
        {
          'letter': 'D',
          'text': 'I save first, then spend',
          'desc': 'Prioritize savings immediately after receiving income.'
        },
      ],
    },
    {
      'stepLabel': 'Question 03',
      'topicLabel': 'Tracking Habits',
      'question': '3. How do you typically track your daily spending?',
      'subtitle': null,
      'options': [
        {
          'letter': 'A',
          'text': 'I don\'t track at all',
          'desc': 'Money comes and goes without oversight.'
        },
        {
          'letter': 'B',
          'text': 'I check my bank app occasionally',
          'desc': 'Maybe once or twice a week at most.'
        },
        {
          'letter': 'C',
          'text': 'I use a budgeting app regularly',
          'desc': 'Track most purchases daily or weekly.'
        },
        {
          'letter': 'D',
          'text': 'I maintain detailed records',
          'desc': 'Every transaction is accounted for.'
        },
      ],
    },
    {
      'stepLabel': 'Question 04',
      'topicLabel': 'Windfall Management',
      'question':
          '4. If you received a surprise bonus of one month\'s salary, what would you do?',
      'subtitle':
          'Your behavior with unexpected windfalls helps us determine your risk profile and automatic savings priority.',
      'options': [
        {
          'letter': 'A',
          'text': 'Treat myself',
          'desc': 'Splurge on a vacation or luxury item.'
        },
        {
          'letter': 'B',
          'text': 'Split it half-half',
          'desc': '50% for fun, 50% for savings or debt.'
        },
        {
          'letter': 'C',
          'text': 'Pay off bills/debts',
          'desc': 'Prioritize clearing high-interest obligations.'
        },
        {
          'letter': 'D',
          'text': 'Invest/save almost all',
          'desc': '90%+ into long-term investments.'
        },
      ],
    },
    {
      'stepLabel': 'Question 05',
      'topicLabel': 'Month End Feeling',
      'question':
          '5. How do you usually feel about your finances at the end of the month?',
      'subtitle': null,
      'options': [
        {
          'letter': 'A',
          'text': 'Often broke',
          'desc': 'Struggling to cover basics until the next paycheck.'
        },
        {
          'letter': 'B',
          'text': 'Manage but tight',
          'desc': 'Covers everything but very little left for savings.'
        },
        {
          'letter': 'C',
          'text': 'Comfortable',
          'desc': 'Able to save and spend on some extras with confidence.'
        },
        {
          'letter': 'D',
          'text': 'Very secure',
          'desc': 'Finances are optimized and growing month over month.'
        },
      ],
    },
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, String> _buildQuestionAnswers() {
    final answers = <String, String>{};
    _selectedAnswers.forEach((qIdx, aIdx) {
      final options = _questions[qIdx]['options'] as List;
      answers['q${qIdx + 1}'] = (options[aIdx] as Map)['letter'] as String;
    });
    return answers;
  }

  static const _planTagColors = {
    'Balanced': AppTheme.green,
    'Growth': AppTheme.chartBlue,
    'Strict': AppTheme.red,
  };

  static const _planIcons = {
    '50_30_20': Icons.balance_rounded,
    'pay_yourself_first': Icons.trending_up_rounded,
    'remaining_budget': Icons.lock_rounded,
  };

  static const _breakdownColors = [
    AppTheme.green,
    AppTheme.chartOrange,
    AppTheme.chartBlue,
    AppTheme.purple,
    AppTheme.red,
  ];

  // ── Navigation ────────────────────────────────────────────────────────────

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        final val = _incomeController.text.replaceAll(',', '');
        return val.isNotEmpty && (double.tryParse(val) ?? 0) > 0;
      case 1:
      case 2:
        return true;
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        return _selectedAnswers.containsKey(_currentStep - 3);
      case 8:
        return _selectedPlanIndex != null;
      default:
        return false;
    }
  }

  void _next() {
    if (_currentStep < _totalSteps - 1 && _canProceed) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  /// Called when the user taps "Build your plans with AI" on step 8.
  Future<void> _buildWithAI() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    final income =
        double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0;

    try {
      final plans = await context.read<BudgetProvider>().generatePlans(
            monthlyIncome: income,
            fixedExpenses: _fixedExpenses,
            questionAnswers: _buildQuestionAnswers(),
            additionalInfo: _additionalInfoCtrl.text,
          );

      if (mounted) {
        setState(() {
          _aiPlans = plans;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate plans. Please try again.';
        });
      }
    }
  }

  /// Called when the user taps "Implement this plan" on step 8.
  Future<void> _implementPlan() async {
    if (_selectedPlanIndex == null || _isSaving || _aiPlans == null) return;

    setState(() => _isSaving = true);

    try {
      final selectedPlan = _aiPlans![_selectedPlanIndex!];
      await context.read<BudgetProvider>().implementPlan(selectedPlan);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save plan. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expTitleCtrl.dispose();
    _expAmountCtrl.dispose();
    _additionalInfoCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final progress = (_currentStep + 1) / _totalSteps;

    return material.Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            _progressBar(cs, progress),
            _topBar(cs),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey('$_currentStep-${_aiPlans != null}'),
                  child: _buildStep(cs),
                ),
              ),
            ),
            _bottomNav(cs),
          ],
        ),
      ),
    );
  }

  Widget _progressBar(ColorScheme cs, double progress) {
    return Container(
      width: double.infinity,
      height: 2,
      color: cs.secondary,
      alignment: Alignment.centerLeft,
      child: _AnimatedBar(
        widthFactor: progress,
        color: cs.foreground,
      ),
    );
  }

  Widget _topBar(ColorScheme cs) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            GestureDetector(
              onTap: _back,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_rounded,
                    color: cs.foreground, size: 22),
              ),
            ),
            const Gap(12),
          ],
          Text(
            'New Budget',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: cs.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(ColorScheme cs) {
    switch (_currentStep) {
      case 0:
        return _incomeStep(cs);
      case 1:
        return _fixedExpensesStep(cs);
      case 2:
        return _additionalInfoStep(cs);
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        return _questionStep(cs, _currentStep - 3);
      case 8:
        return _aiPlans != null ? _planSelectionStep(cs) : _buildWithAIStep(cs);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _bottomNav(ColorScheme cs) {
    // Step 8 with plans loaded: "Implement this plan"
    if (_currentStep == 8 && _aiPlans != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.background.withValues(alpha: 0), cs.background],
          ),
        ),
        child: GestureDetector(
          onTap: _canProceed && !_isSaving ? _implementPlan : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _canProceed ? cs.foreground : cs.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: material.CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.background,
                      ),
                    )
                  : Text(
                      'Implement this plan',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color:
                            _canProceed ? cs.background : cs.mutedForeground,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // Step 8 without plans: no nav (the "Build with AI" button is in the body)
    if (_currentStep == 8) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: _currentStep == 0
            ? MainAxisAlignment.end
            : MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            GestureDetector(
              onTap: _back,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 16, color: cs.mutedForeground),
                    const Gap(8),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onTap: _canProceed ? _next : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: _canProceed ? cs.foreground : cs.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          _canProceed ? cs.background : cs.mutedForeground,
                    ),
                  ),
                  const Gap(8),
                  Icon(Icons.east_rounded,
                      size: 18,
                      color:
                          _canProceed ? cs.background : cs.mutedForeground),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 0 — Monthly Income
  // ══════════════════════════════════════════════════════════════════════════

  Widget _incomeStep(ColorScheme cs) {
    final sym = context.read<AuthProvider>().currencySymbol;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Gap(48),
          Text(
            'What is your average\nmonthly income?',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 1.1,
              color: cs.foreground,
            ),
          ),
          const Gap(16),
          Text(
            'We use this to calculate your daily spending\nlimits and savings potential.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: cs.mutedForeground,
              height: 1.5,
            ),
          ),
          const Gap(48),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: material.TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.manrope(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: cs.foreground,
              ),
              cursorColor: cs.foreground,
              decoration: material.InputDecoration(
                prefixText: '$sym ',
                prefixStyle: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: cs.mutedForeground,
                ),
                hintText: '0,000.00',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: cs.secondary,
                ),
                filled: true,
                fillColor: cs.secondary,
                border: material.OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: material.OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: cs.foreground.withValues(alpha: 0.2)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Fixed Expenses
  // ══════════════════════════════════════════════════════════════════════════

  Widget _fixedExpensesStep(ColorScheme cs) {
    final sym = context.read<AuthProvider>().currencySymbol;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(32),
          Text(
            'Enter your monthly\nfixed expenses',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.1,
              color: cs.foreground,
            ),
          ),
          const Gap(12),
          Text(
            'These are recurring costs like EMI, Rent, or utilities that stay consistent every month.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: cs.mutedForeground,
              height: 1.5,
            ),
          ),
          const Gap(28),
          ..._fixedExpenses.asMap().entries.map((entry) {
            final e = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.receipt_long_rounded,
                          size: 20, color: cs.mutedForeground),
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.foreground,
                          ),
                        ),
                        Text(
                          'Fixed Expense',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: cs.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$sym${e.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.foreground,
                    ),
                  ),
                  const Gap(8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _fixedExpenses.removeAt(entry.key)),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: cs.mutedForeground),
                  ),
                ],
              ),
            );
          }),
          if (_showAddExpenseForm)
            _addExpenseForm(cs, sym)
          else
            GestureDetector(
              onTap: () => setState(() => _showAddExpenseForm = true),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cs.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_rounded,
                        size: 22, color: cs.foreground),
                    const Gap(12),
                    Text(
                      'Add new fixed expense',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Gap(32),
        ],
      ),
    );
  }

  Widget _addExpenseForm(ColorScheme cs, String sym) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_rounded, size: 20, color: cs.foreground),
              const Gap(10),
              Text(
                'Add new fixed expense',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.foreground,
                ),
              ),
            ],
          ),
          const Gap(20),
          Text(
            'TITLE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cs.mutedForeground,
            ),
          ),
          const Gap(6),
          material.TextField(
            controller: _expTitleCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: cs.foreground),
            cursorColor: cs.foreground,
            decoration: material.InputDecoration(
              hintText: 'e.g. Netflix',
              hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.mutedForeground.withValues(alpha: 0.5)),
              filled: true,
              fillColor: cs.secondary,
              border: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: cs.foreground.withValues(alpha: 0.15)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const Gap(16),
          Text(
            'AMOUNT',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cs.mutedForeground,
            ),
          ),
          const Gap(6),
          material.TextField(
            controller: _expAmountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            style: GoogleFonts.inter(fontSize: 14, color: cs.foreground),
            cursorColor: cs.foreground,
            decoration: material.InputDecoration(
              prefixText: '$sym ',
              prefixStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.mutedForeground,
                  fontWeight: FontWeight.w500),
              hintText: '0.00',
              hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.mutedForeground.withValues(alpha: 0.5)),
              filled: true,
              fillColor: cs.secondary,
              border: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: cs.foreground.withValues(alpha: 0.15)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  _expTitleCtrl.clear();
                  _expAmountCtrl.clear();
                  setState(() => _showAddExpenseForm = false);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.mutedForeground,
                    ),
                  ),
                ),
              ),
              const Gap(8),
              GestureDetector(
                onTap: _saveFixedExpense,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.foreground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.background,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveFixedExpense() {
    final title = _expTitleCtrl.text.trim();
    final amount = double.tryParse(_expAmountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;

    setState(() {
      _fixedExpenses.add(FixedExpense(title: title, amount: amount));
      _expTitleCtrl.clear();
      _expAmountCtrl.clear();
      _showAddExpenseForm = false;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Additional Info
  // ══════════════════════════════════════════════════════════════════════════

  Widget _additionalInfoStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(32),
          Text(
            'Add your additional\naddons and your needs',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.1,
              color: cs.foreground,
            ),
          ),
          const Gap(12),
          Text(
            'Tell us about any specific financial goals, upcoming large expenses, or anything else that might help us create a better budget for you.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: cs.mutedForeground,
              height: 1.5,
            ),
          ),
          const Gap(32),
          material.TextField(
            controller: _additionalInfoCtrl,
            maxLines: 8,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.foreground,
              height: 1.6,
            ),
            cursorColor: cs.foreground,
            decoration: material.InputDecoration(
              hintText:
                  'e.g. Planning a vacation in 3 months, want to save for a new laptop, need to pay off credit card debt...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: cs.mutedForeground.withValues(alpha: 0.5),
                height: 1.6,
              ),
              filled: true,
              fillColor: cs.secondary,
              border: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: material.OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: cs.foreground.withValues(alpha: 0.15)),
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEPS 3–7 — Psychology Questions
  // ══════════════════════════════════════════════════════════════════════════

  Widget _questionStep(ColorScheme cs, int questionIndex) {
    final q = _questions[questionIndex];
    final options = q['options'] as List;
    final selectedIdx = _selectedAnswers[questionIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(24),
          Text(
            (q['stepLabel'] as String).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: cs.mutedForeground,
            ),
          ),
          const Gap(4),
          Text(
            (q['topicLabel'] as String).toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: cs.mutedForeground,
            ),
          ),
          const Gap(20),
          Text(
            q['question'] as String,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.2,
              color: cs.foreground,
            ),
          ),
          if (q['subtitle'] != null) ...[
            const Gap(12),
            Text(
              q['subtitle'] as String,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: cs.mutedForeground,
                height: 1.5,
              ),
            ),
          ],
          const Gap(28),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value as Map;
            final isSelected = selectedIdx == idx;
            final desc = (opt['desc'] as String?) ?? '';

            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedAnswers[questionIndex] = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? cs.accent : cs.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? cs.foreground : cs.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? cs.foreground : cs.secondary,
                      ),
                      child: Center(
                        child: Text(
                          opt['letter'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? cs.background
                                : cs.foreground,
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
                            opt['text'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: cs.foreground,
                            ),
                          ),
                          if (desc.isNotEmpty) ...[
                            const Gap(3),
                            Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: cs.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Icon(Icons.check_circle_rounded,
                          size: 22, color: cs.foreground),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Gap(20),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 8a — "Build your plans with AI" CTA
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWithAIStep(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isGenerating
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: material.CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: cs.foreground,
                        ),
                      )
                    : Icon(Icons.auto_awesome_rounded,
                        size: 36, color: cs.foreground),
              ),
            ),
            const Gap(32),
            Text(
              _isGenerating
                  ? 'Analyzing your profile...'
                  : 'Ready to build your\npersonalized budget',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.1,
                color: cs.foreground,
              ),
            ),
            const Gap(14),
            Text(
              _isGenerating
                  ? 'Our AI is creating 3 tailored budget plans based on your income, expenses, and spending psychology.'
                  : 'We\'ll send your data to our AI to generate 3 personalized budget strategies that match your financial profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: cs.mutedForeground,
                height: 1.5,
              ),
            ),
            if (_errorMessage != null) ...[
              const Gap(16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const Gap(40),
            if (!_isGenerating)
              GestureDetector(
                onTap: _buildWithAI,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    color: cs.foreground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 20, color: cs.background),
                      const Gap(12),
                      Text(
                        'Build your plans with AI',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.background,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 8b — Plan Selection (after AI returns plans)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _planSelectionStep(ColorScheme cs) {
    final sym = context.read<AuthProvider>().currencySymbol;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(24),
          Text(
            'RECOMMENDED FOR YOU',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppTheme.chartBlue,
            ),
          ),
          const Gap(12),
          Text(
            'Choose your\nfinancial path.',
            style: GoogleFonts.manrope(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              height: 0.95,
              color: cs.foreground,
            ),
          ),
          const Gap(14),
          Text(
            'Our AI analyzed your inputs to curate three strategies that align with your goals and lifestyle.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: cs.mutedForeground,
              height: 1.5,
            ),
          ),
          const Gap(28),
          ...(_aiPlans ?? []).asMap().entries.map((entry) {
            final idx = entry.key;
            final plan = entry.value;
            final isSelected = _selectedPlanIndex == idx;
            final tag = plan['tag'] as String? ?? '';
            final tagColor = _planTagColors[tag] ?? AppTheme.muted;
            final planType = plan['type'] as String? ?? '';
            final icon = _planIcons[planType] ?? Icons.account_balance_rounded;
            final breakdown =
                (plan['breakdown'] as List<dynamic>? ?? [])
                    .map((b) => Map<String, dynamic>.from(b as Map))
                    .toList();
            final budget =
                (plan['monthlyBudget'] as num?)?.toDouble() ?? 0;
            final description = plan['description'] as String? ?? '';

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isSelected ? cs.card : cs.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? tagColor.withValues(alpha: 0.5)
                        : cs.border.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tagColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: tagColor,
                                ),
                              ),
                            ),
                            const Gap(10),
                            Text(
                              plan['name'] as String? ?? '',
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: cs.foreground,
                              ),
                            ),
                          ],
                        ),
                        Icon(icon, size: 28, color: tagColor),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const Gap(8),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const Gap(6),
                    Text(
                      'Monthly Budget: $sym${budget.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.mutedForeground,
                      ),
                    ),
                    const Gap(20),
                    ...breakdown.asMap().entries.map((bEntry) {
                      final b = bEntry.value;
                      final pct =
                          (b['percent'] as num?)?.toInt() ?? 0;
                      final color = _breakdownColors[
                          bEntry.key % _breakdownColors.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (b['label'] as String?) ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: cs.mutedForeground
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: cs.mutedForeground
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(6),
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: cs.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: pct / 100,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (isSelected) ...[
                      const Gap(4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: tagColor),
                          const Gap(6),
                          Text(
                            'Selected',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const Gap(80),
        ],
      ),
    );
  }
}

/// Animates the progress bar width factor.
class _AnimatedBar extends StatelessWidget {
  final double widthFactor;
  final Color color;

  const _AnimatedBar({required this.widthFactor, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widthFactor),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      builder: (_, value, child) => FractionallySizedBox(
        widthFactor: value,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: Container(color: color),
    );
  }
}
