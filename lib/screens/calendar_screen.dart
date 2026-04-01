import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  bool _isExpenseListExpanded = false;

  static const _weekdayLabels = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      if (!_isInVisibleMonth(_selectedDate)) {
        _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
        _isExpenseListExpanded = false;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      if (!_isInVisibleMonth(_selectedDate)) {
        _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
        _isExpenseListExpanded = false;
      }
    });
  }

  bool _isInVisibleMonth(DateTime date) {
    return date.year == _visibleMonth.year && date.month == _visibleMonth.month;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<ExpenseModel> _expensesForDay(List<ExpenseModel> expenses, DateTime day) {
    final filtered = expenses.where((expense) {
      final local = expense.date.toLocal();
      return _isSameDay(local, day);
    }).toList();
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  }

  double _totalForDay(List<ExpenseModel> expenses, DateTime day) {
    return _expensesForDay(expenses, day).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  List<_CalendarCellData> _buildCalendarCells() {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final firstWeekdayOffset = firstOfMonth.weekday - 1;
    final gridStart = firstOfMonth.subtract(Duration(days: firstWeekdayOffset));

    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      return _CalendarCellData(
        date: date,
        isCurrentMonth: date.month == _visibleMonth.month,
      );
    });
  }

  IconData _iconForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('food') || normalized.contains('drink') || normalized.contains('snack')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('transport') || normalized.contains('travel') || normalized.contains('fuel')) {
      return Icons.directions_car_filled_rounded;
    }
    if (normalized.contains('grocery')) {
      return Icons.shopping_basket_rounded;
    }
    if (normalized.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }
    if (normalized.contains('entertainment')) {
      return Icons.movie_creation_outlined;
    }
    if (normalized.contains('house') || normalized.contains('rent') || normalized.contains('home')) {
      return Icons.home_rounded;
    }
    return Icons.wallet_rounded;
  }

  Color _accentForCategory(String category) {
    const palette = <Color>[
      Color(0xFF6AA9FF),
      Color(0xFFFF8A65),
      Color(0xFF53E5A1),
      Color(0xFFB388FF),
      Color(0xFFFF6E8A),
      Color(0xFFFFC857),
    ];
    return palette[category.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final background = colorScheme.background;
    final surface = colorScheme.card;
    final surfaceHigh = colorScheme.secondary;
    final surfaceLowest = isDark ? const Color(0xFF090909) : colorScheme.accent;
    final border = colorScheme.border;
    final textPrimary = colorScheme.foreground;
    final textMuted = colorScheme.mutedForeground;
    final expenseProvider = context.watch<ExpenseProvider>();
    final currencySymbol = context.watch<AuthProvider>().currencySymbol;
    final expenses = expenseProvider.expenses;
    final selectedDayExpenses = _expensesForDay(expenses, _selectedDate);
    final selectedDayTotal = _totalForDay(expenses, _selectedDate);
    final visibleExpenses =
        _isExpenseListExpanded ? selectedDayExpenses : selectedDayExpenses.take(3).toList();
    final hiddenExpenseCount =
        selectedDayExpenses.length > 3 ? selectedDayExpenses.length - 3 : 0;
    final monthTitle = DateFormat('MMMM').format(_visibleMonth);
    final fullMonthTitle = DateFormat('MMMM yyyy').format(_visibleMonth);
    final selectedDayLabel = DateFormat('MMMM d,\nyyyy').format(_selectedDate);
    final cells = _buildCalendarCells();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: expenseProvider.isLoading && expenses.isEmpty
            ? Center(child: CircularProgressIndicator(color: textPrimary))
            : RefreshIndicator(
                color: textPrimary,
                backgroundColor: surface,
                onRefresh: context.read<ExpenseProvider>().loadExpenses,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.arrow_back_rounded, size: 28, color: textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        monthTitle,
                        style: AppTheme.titleLarge.copyWith(
                          fontSize: 40,
                          height: 1,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Manage your monthly commitments and daily spending.',
                        style: AppTheme.bodyText.copyWith(
                          color: textMuted,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fullMonthTitle,
                                    style: AppTheme.titleLarge.copyWith(
                                      fontSize: 18,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                _MonthNavButton(
                                  icon: Icons.chevron_left_rounded,
                                  onTap: _goToPreviousMonth,
                                ),
                                const SizedBox(width: 8),
                                _MonthNavButton(
                                  icon: Icons.chevron_right_rounded,
                                  onTap: _goToNextMonth,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: _weekdayLabels
                                  .map(
                                    (label) => Expanded(
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: AppTheme.caption.copyWith(
                                            color: textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cells.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.98,
                              ),
                              itemBuilder: (context, index) {
                                final cell = cells[index];
                                final dayExpenses = _expensesForDay(expenses, cell.date);
                                final isSelected = _isSameDay(cell.date, _selectedDate);
                                final textColor = !cell.isCurrentMonth
                                    ? textMuted.withValues(alpha: 0.35)
                                    : isSelected
                                        ? background
                                        : textPrimary;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _visibleMonth = DateTime(cell.date.year, cell.date.month);
                                      _selectedDate = _dateOnly(cell.date);
                                      _isExpenseListExpanded = false;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? textPrimary
                                          : cell.isCurrentMonth
                                              ? surfaceHigh
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : border,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: textPrimary.withValues(alpha: 0.14),
                                                blurRadius: 22,
                                                offset: Offset(0, 8),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: ClipRect(
                                      child: SizedBox.expand(
                                        child: Stack(
                                          children: [
                                            Align(
                                              alignment: dayExpenses.isNotEmpty
                                                  ? const Alignment(0, -0.12)
                                                  : Alignment.center,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '${cell.date.day}',
                                                  style: AppTheme.bodyText.copyWith(
                                                    color: textColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (dayExpenses.isNotEmpty)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: _CalendarDotsPainter(
                                                      colors: dayExpenses
                                                          .take(3)
                                                          .map((expense) => _accentForCategory(expense.category))
                                                          .toList(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY SUMMARY',
                              style: AppTheme.caption.copyWith(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.8,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedDayLabel,
                                    style: AppTheme.titleLarge.copyWith(
                                      fontSize: 28,
                                      height: 1.1,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'TOTAL',
                                      style: AppTheme.caption.copyWith(
                                        color: textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$currencySymbol${selectedDayTotal.toStringAsFixed(2)}',
                                      style: AppTheme.titleLarge.copyWith(
                                        fontSize: 26,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            if (selectedDayExpenses.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                                decoration: BoxDecoration(
                                  color: surfaceLowest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'No expenses were recorded on this date.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.bodyText.copyWith(
                                    color: textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  ...visibleExpenses.map((expense) {
                                    final accent = _accentForCategory(expense.category);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: surfaceLowest,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: accent.withValues(alpha: 0.16),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Icon(
                                                _iconForCategory(expense.category),
                                                color: accent,
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    expense.description,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTheme.bodyText.copyWith(
                                                      color: textPrimary,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    expense.category,
                                                    style: AppTheme.bodyText.copyWith(
                                                      color: textMuted,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '-$currencySymbol${expense.amount.toStringAsFixed(2)}',
                                                  style: AppTheme.titleLarge.copyWith(
                                                    fontSize: 16,
                                                    color: textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  DateFormat('hh:mm a').format(expense.date.toLocal()),
                                                  style: AppTheme.bodyText.copyWith(
                                                    color: textMuted,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (hiddenExpenseCount > 0 && !_isExpenseListExpanded)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpenseListExpanded = true;
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: surfaceHigh,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          '+$hiddenExpenseCount more',
                                          textAlign: TextAlign.center,
                                          style: AppTheme.bodyText.copyWith(
                                            color: textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.foreground, size: 22),
      ),
    );
  }
}

class _CalendarDotsPainter extends CustomPainter {
  final List<Color> colors;

  const _CalendarDotsPainter({
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    const dotRadius = 2.0;
    const spacing = 3.0;
    final totalWidth = (colors.length * dotRadius * 2) + ((colors.length - 1) * spacing);
    var startX = (size.width - totalWidth) / 2;
    final centerY = size.height - 6;

    for (final color in colors) {
      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(startX + dotRadius, centerY), dotRadius, paint);
      startX += (dotRadius * 2) + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarDotsPainter oldDelegate) {
    if (oldDelegate.colors.length != colors.length) return true;
    for (var i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i] != colors[i]) return true;
    }
    return false;
  }
}

class _CalendarCellData {
  final DateTime date;
  final bool isCurrentMonth;

  const _CalendarCellData({
    required this.date,
    required this.isCurrentMonth,
  });
}
