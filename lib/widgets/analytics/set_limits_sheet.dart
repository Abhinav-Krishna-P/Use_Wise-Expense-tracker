import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material show showModalBottomSheet, CircularProgressIndicator;
import 'package:provider/provider.dart';
import '../../providers/spending_limit_provider.dart';
import '../../theme/app_theme.dart';

/// 10 common expense categories for the limit picker.
const List<String> _kCategories = [
  'Food',
  'Transport',
  'Bills',
  'Shopping',
  'Entertainment',
  'Health',
  'Education',
  'Subscriptions',
  'Other',
  'Transit',
];

/// Shows the spending limit setup/edit bottom sheet.
void showSetLimitsSheet(BuildContext context) {
  final limProv = context.read<SpendingLimitProvider>();
  final existing = limProv.config;

  material.showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SetLimitsSheet(
      initialLimits: existing?.limits
              .map((l) => _LimitField(
                    category: l.category,
                    amount: l.limitAmount,
                    period: l.period,
                  ))
              .toList() ??
          [_LimitField()],
      isEditing: existing != null,
    ),
  );
}

class _LimitField {
  String? category;
  double? amount;
  String period;
  final TextEditingController controller;

  _LimitField({this.category, this.amount, this.period = 'monthly'})
      : controller = TextEditingController(
          text: amount != null ? amount.toStringAsFixed(0) : '',
        );
}

class _SetLimitsSheet extends StatefulWidget {
  final List<_LimitField> initialLimits;
  final bool isEditing;

  const _SetLimitsSheet({
    required this.initialLimits,
    required this.isEditing,
  });

  @override
  State<_SetLimitsSheet> createState() => _SetLimitsSheetState();
}

class _SetLimitsSheetState extends State<_SetLimitsSheet> {
  late List<_LimitField> _fields;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fields = widget.initialLimits;
  }

  void _addField() {
    if (_fields.length >= 3) return;
    setState(() {
      _fields.add(_LimitField());
    });
  }

  void _removeField(int index) {
    if (_fields.length <= 1) return;
    setState(() {
      _fields.removeAt(index);
    });
  }

  List<String> _availableCategories(int currentIndex) {
    final selected = <String>{};
    for (int i = 0; i < _fields.length; i++) {
      if (i != currentIndex && _fields[i].category != null) {
        selected.add(_fields[i].category!);
      }
    }
    return _kCategories.where((c) => !selected.contains(c)).toList();
  }

  bool get _isValid {
    for (final f in _fields) {
      if (f.category == null || f.category!.isEmpty) return false;
      final amount = double.tryParse(f.controller.text);
      if (amount == null || amount <= 0) return false;
      if (!['daily', 'weekly', 'monthly'].contains(f.period)) return false;
    }
    return true;
  }

  Future<void> _publish() async {
    if (!_isValid || _isSaving) return;

    setState(() => _isSaving = true);

    final limProv = context.read<SpendingLimitProvider>();
    final limits = _fields.map((f) => {
          'category': f.category!,
          'limitAmount': double.parse(f.controller.text),
          'period': f.period,
        }).toList();

    try {
      if (widget.isEditing) {
        await limProv.updateLimits(limits: limits);
      } else {
        await limProv.createLimits(limits: limits);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteLimits() async {
    final limProv = context.read<SpendingLimitProvider>();
    await limProv.deleteLimits();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colorScheme.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.savings_outlined, size: 20, color: AppTheme.teal),
                    ),
                  ),
                  const Gap(14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? 'Edit Spending Limits' : 'Set Spending Limits',
                        style: AppTheme.titleLarge.copyWith(fontSize: 18),
                      ),
                      const Gap(2),
                      Text(
                        'Track & control your budget',
                        style: AppTheme.caption.copyWith(
                          color: colorScheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(24),
              // ── Limit fields ──
              Text(
                'CATEGORY LIMITS',
                style: AppTheme.caption.copyWith(
                  color: colorScheme.mutedForeground,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Gap(4),
              Text(
                'Add up to 3 categories and choose a renewal period for each one',
                style: AppTheme.caption.copyWith(
                  color: colorScheme.mutedForeground,
                  fontSize: 11,
                ),
              ),
              const Gap(14),
              ..._fields.asMap().entries.map((entry) {
                final idx = entry.key;
                final field = entry.value;
                return _buildLimitRow(colorScheme, idx, field);
              }),

              // Add field button
              if (_fields.length < 3)
                GestureDetector(
                  onTap: _addField,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.border,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: colorScheme.mutedForeground),
                        const Gap(6),
                        Text(
                          'Add Category',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Gap(20),

              // ── Publish button ──
              GestureDetector(
                onTap: _isValid && !_isSaving ? _publish : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isValid
                        ? colorScheme.foreground
                        : colorScheme.foreground.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: material.CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.background,
                            ),
                          )
                        : Text(
                            widget.isEditing ? 'Update Limits' : 'Publish',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.background,
                            ),
                          ),
                  ),
                ),
              ),

              // ── Delete button (edit mode only) ──
              if (widget.isEditing) ...[
                const Gap(10),
                GestureDetector(
                  onTap: _deleteLimits,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Remove Limits',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.red,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitRow(ColorScheme colorScheme, int index, _LimitField field) {
    final available = _availableCategories(index);
    final emoji = field.category != null
        ? (AppTheme.categoryEmojis[field.category!] ?? '💰')
        : '📂';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCategoryPicker(index, available),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              field.category ?? 'Category',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: field.category != null
                                    ? colorScheme.foreground
                                    : colorScheme.mutedForeground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.unfold_more_rounded,
                              size: 14, color: colorScheme.mutedForeground),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_fields.length > 1) ...[
                  const Gap(8),
                  GestureDetector(
                    onTap: () => _removeField(index),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.close_rounded, size: 14, color: AppTheme.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: field.controller,
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.foreground,
                ),
                placeholder: Text(
                  'Amount',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.mutedForeground,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Gap(10),
            Text(
              'Renewal Period',
              style: AppTheme.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colorScheme.mutedForeground,
              ),
            ),
            const Gap(8),
            Row(
              children: ['daily', 'weekly', 'monthly'].map((period) {
                final isActive = field.period == period;
                final label = period[0].toUpperCase() + period.substring(1);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: period == 'daily' ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => field.period = period),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive ? colorScheme.foreground : colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? colorScheme.background
                                  : colorScheme.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(int fieldIndex, List<String> available) {
    final colorScheme = context.colorScheme;

    material.showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: colorScheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Text(
              'Select Category',
              style: AppTheme.titleLarge.copyWith(fontSize: 16),
            ),
            const Gap(14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((cat) {
                final emoji = AppTheme.categoryEmojis[cat] ?? '💰';
                final catColor = AppTheme.categoryColors[cat] ?? AppTheme.teal;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _fields[fieldIndex].category = cat;
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: catColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const Gap(8),
                        Text(
                          cat,
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
