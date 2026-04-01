import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message_model.dart';
import '../../models/expense_model.dart';
import '../../models/spending_limit_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final Future<void> Function(
    ExpenseModel expense,
    String description,
    double amount,
  )? onEditExpense;
  final Future<void> Function(ExpenseModel expense)? onDeleteExpense;
  final Future<void> Function(
    String originalCategory,
    String updatedCategory,
    double amount,
    String period,
  )? onEditSpendingLimit;
  final Future<void> Function(String category)? onDeleteSpendingLimit;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEditExpense,
    this.onDeleteExpense,
    this.onEditSpendingLimit,
    this.onDeleteSpendingLimit,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(message.timestamp);

    if (message.isUser) {
      return _UserBubble(text: message.text, time: time, imageBytes: message.imageBytes);
    }
    return _AiBubble(
      message: message,
      time: time,
      onEditExpense: onEditExpense,
      onDeleteExpense: onDeleteExpense,
      onEditSpendingLimit: onEditSpendingLimit,
      onDeleteSpendingLimit: onDeleteSpendingLimit,
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  final String time;
  final dynamic imageBytes;

  const _UserBubble({required this.text, required this.time, this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.colorScheme.foreground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (imageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          imageBytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        text,
                        style: AppTheme.bodyText.copyWith(color: context.colorScheme.background),
                      ),
                    ),
                ],
              ),
            ),
            const Gap(4),
            Text(time, style: AppTheme.caption.copyWith(color: context.colorScheme.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMessageModel message;
  final String time;
  final Future<void> Function(
    ExpenseModel expense,
    String description,
    double amount,
  )? onEditExpense;
  final Future<void> Function(ExpenseModel expense)? onDeleteExpense;
  final Future<void> Function(
    String originalCategory,
    String updatedCategory,
    double amount,
    String period,
  )? onEditSpendingLimit;
  final Future<void> Function(String category)? onDeleteSpendingLimit;

  const _AiBubble({
    required this.message,
    required this.time,
    this.onEditExpense,
    this.onDeleteExpense,
    this.onEditSpendingLimit,
    this.onDeleteSpendingLimit,
  });

  @override
  Widget build(BuildContext context) {
    final hasExpenseCard = message.expense != null &&
        (message.action == 'create' || message.action == 'update');
    final cardExpenses = message.expenses.isNotEmpty
        ? message.expenses
        : (message.expense != null ? [message.expense!] : const <ExpenseModel>[]);
    final hasSpendingLimitCard = message.spendingLimitConfig != null &&
        message.action.startsWith('spending_limits');

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 22),
            child: Avatar(
              initials: 'AI',
              size: 28,
              backgroundColor: context.colorScheme.card,
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasExpenseCard)
                  _ExpenseActionCard(
                    expenses: cardExpenses,
                    label: message.action == 'update'
                        ? 'Updated Expense'
                        : 'Categorized Expense',
                    onEdit: onEditExpense,
                    onDelete: onDeleteExpense,
                  )
                else if (hasSpendingLimitCard)
                  _SpendingLimitActionCard(
                    config: message.spendingLimitConfig!,
                    summary: message.text,
                    onEdit: onEditSpendingLimit,
                    onDelete: onDeleteSpendingLimit,
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.colorScheme.card,
                      border: Border.all(color: context.colorScheme.border),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: AppTheme.bodyText.copyWith(color: context.colorScheme.foreground),
                    ),
                  ),
                const Gap(4),
                Text(time, style: AppTheme.caption.copyWith(color: context.colorScheme.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingLimitActionCard extends StatefulWidget {
  final SpendingLimitConfig config;
  final String summary;
  final Future<void> Function(
    String originalCategory,
    String updatedCategory,
    double amount,
    String period,
  )? onEdit;
  final Future<void> Function(String category)? onDelete;

  const _SpendingLimitActionCard({
    required this.config,
    required this.summary,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_SpendingLimitActionCard> createState() => _SpendingLimitActionCardState();
}

class _SpendingLimitActionCardState extends State<_SpendingLimitActionCard> {
  String? _editingCategory;
  String? _selectedCategory;
  String? _selectedPeriod;
  late final TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _startEditing(SpendingLimitItem limit) {
    setState(() {
      _editingCategory = limit.category;
      _selectedCategory = limit.category;
      _selectedPeriod = limit.period;
      _amountController.text = limit.limitAmount.toStringAsFixed(0);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCategory = null;
      _selectedCategory = null;
      _selectedPeriod = null;
      _amountController.clear();
      _isSaving = false;
    });
  }

  Future<void> _saveEditing(SpendingLimitItem limit) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_selectedCategory == null || _selectedPeriod == null || amount == null || amount <= 0) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.onEdit?.call(limit.category, _selectedCategory!, amount, _selectedPeriod!);
    if (!mounted) return;
    setState(() {
      _editingCategory = null;
      _selectedCategory = null;
      _selectedPeriod = null;
      _amountController.clear();
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.read<AuthProvider>().currencySymbol;
    final summaryText = widget.summary.trim().isEmpty
        ? 'Here are your active spending limits.'
        : widget.summary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT LIMITS',
                style: AppTheme.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${widget.config.limits.length} ${widget.config.limits.length == 1 ? 'category' : 'categories'}',
                style: AppTheme.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(10),
          Text(
            summaryText,
            style: AppTheme.bodyText.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const Gap(16),
          ...widget.config.limits.asMap().entries.map((entry) {
            final limit = entry.value;
            final isEditing = _editingCategory == limit.category;
            final catColor = AppTheme.categoryColors[limit.category] ?? AppTheme.teal;
            final emoji = AppTheme.categoryEmojis[limit.category] ?? '💰';
            final remaining = (limit.limitAmount - limit.spent).clamp(0, limit.limitAmount);
            final periodLabel = _periodLabel(limit.period);

            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == widget.config.limits.length - 1 ? 0 : 10,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131313),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          material.DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            dropdownColor: const Color(0xFF1A1A1A),
                            iconEnabledColor: Colors.white.withValues(alpha: 0.7),
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            decoration: material.InputDecoration(
                              isDense: true,
                              labelText: 'Category',
                              labelStyle: AppTheme.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.42),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              enabledBorder: material.OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              focusedBorder: material.OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            items: AppTheme.categoryEmojis.keys.map((category) {
                              return material.DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                          ),
                          const Gap(10),
                          _InlineEditField(
                            controller: _amountController,
                            label: 'Limit',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            prefixText: currencySymbol,
                          ),
                          const Gap(10),
                          Row(
                            children: ['daily', 'weekly', 'monthly'].map((period) {
                              final isActive = _selectedPeriod == period;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: period == 'daily' ? 0 : 8),
                                  child: material.Material(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    child: material.InkWell(
                                      onTap: () => setState(() => _selectedPeriod = period),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Center(
                                          child: Text(
                                            _periodLabel(period),
                                            style: AppTheme.bodyText.copyWith(
                                              color: isActive
                                                  ? const Color(0xFF131313)
                                                  : Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _InlineActionButton(
                                label: 'Cancel',
                                onTap: _isSaving ? null : _cancelEditing,
                              ),
                              const Gap(8),
                              _InlineActionButton(
                                label: _isSaving ? 'Saving...' : 'OK',
                                isPrimary: true,
                                onTap: _isSaving ? null : () => _saveEditing(limit),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    periodLabel,
                                    style: AppTheme.caption.copyWith(
                                      color: catColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  'Limit ${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(limit.limitAmount)} • Spent ${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(limit.spent)}',
                                  style: AppTheme.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                                const Gap(10),
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: limit.usedPercent.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: limit.isExceeded ? AppTheme.red : catColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(6),
                                Text(
                                  limit.isExceeded
                                      ? 'Exceeded by ${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(limit.spent - limit.limitAmount)}'
                                      : '${NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0).format(remaining)} left',
                                  style: AppTheme.caption.copyWith(
                                    color: limit.isExceeded
                                        ? const Color(0xFFFF9C92)
                                        : Colors.white.withValues(alpha: 0.72),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _ActionIconButton(
                                icon: Icons.edit_outlined,
                                color: Colors.white.withValues(alpha: 0.72),
                                onTap: widget.onEdit == null ? null : () => _startEditing(limit),
                              ),
                              const Gap(8),
                              _ActionIconButton(
                                icon: Icons.delete_outline_rounded,
                                color: const Color(0xFFFF9C92),
                                onTap: widget.onDelete == null
                                    ? null
                                    : () => widget.onDelete!(limit.category),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _periodLabel(String period) {
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

class _ExpenseActionCard extends StatefulWidget {
  final List<ExpenseModel> expenses;
  final String label;
  final Future<void> Function(
    ExpenseModel expense,
    String description,
    double amount,
  )? onEdit;
  final Future<void> Function(ExpenseModel expense)? onDelete;

  const _ExpenseActionCard({
    required this.expenses,
    required this.label,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ExpenseActionCard> createState() => _ExpenseActionCardState();
}

class _ExpenseActionCardState extends State<_ExpenseActionCard> {
  String? _editingExpenseId;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _startEditing(ExpenseModel expense) {
    setState(() {
      _editingExpenseId = expense.id;
      _titleController.text = expense.description;
      _amountController.text = expense.amount.toStringAsFixed(0);
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingExpenseId = null;
      _isSaving = false;
    });
  }

  Future<void> _saveEditing(ExpenseModel expense) async {
    final description = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (description.isEmpty || amount == null || amount <= 0) return;

    setState(() => _isSaving = true);
    await widget.onEdit?.call(expense, description, amount);
    if (!mounted) return;
    setState(() {
      _editingExpenseId = null;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.read<AuthProvider>().currencySymbol;
    final entryCountLabel =
        '${widget.expenses.length} ${widget.expenses.length == 1 ? 'entry' : 'entries'} found';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: AppTheme.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                entryCountLabel,
                style: AppTheme.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Gap(16),
          ...widget.expenses.asMap().entries.map((entry) {
            final expense = entry.value;
            final formattedAmount =
                NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2)
                    .format(expense.amount);
            final formattedDate =
                DateFormat('MMM dd, yyyy').format(expense.date.toLocal());
            final isEditing = _editingExpenseId == expense.id;

            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == widget.expenses.length - 1 ? 0 : 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131313),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    AppTheme.categoryEmojis[expense.category] ?? '💰',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InlineEditField(
                                      controller: _titleController,
                                      label: 'Title',
                                      keyboardType: TextInputType.text,
                                    ),
                                    const Gap(10),
                                    _InlineEditField(
                                      controller: _amountController,
                                      label: 'Price',
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      prefixText: currencySymbol,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Gap(12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _InlineActionButton(
                                label: 'Cancel',
                                onTap: _isSaving ? null : _cancelEditing,
                              ),
                              const Gap(8),
                              _InlineActionButton(
                                label: _isSaving ? 'Saving...' : 'OK',
                                isPrimary: true,
                                onTap: _isSaving ? null : () => _saveEditing(expense),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                AppTheme.categoryEmojis[expense.category] ?? '💰',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${expense.category} (${expense.description})',
                                        style: AppTheme.bodyText.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                      ),
                                      const Gap(5),
                                      Text(
                                        formattedDate,
                                        style: AppTheme.bodyText.copyWith(
                                          color: Colors.white.withValues(alpha: 0.42),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Gap(10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      formattedAmount,
                                      style: AppTheme.bodyText.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Gap(8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ActionIconButton(
                                          icon: Icons.edit_outlined,
                                          color: Colors.white.withValues(alpha: 0.72),
                                          onTap: widget.onEdit == null
                                              ? null
                                              : () => _startEditing(expense),
                                        ),
                                        const Gap(8),
                                        _ActionIconButton(
                                          icon: Icons.delete_outline_rounded,
                                          color: const Color(0xFFFF9C92),
                                          onTap: widget.onDelete == null
                                              ? null
                                              : () => widget.onDelete!(expense),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InlineEditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? prefixText;

  const _InlineEditField({
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return material.TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTheme.bodyText.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      decoration: material.InputDecoration(
        isDense: true,
        labelText: label,
        prefixText: prefixText,
        labelStyle: AppTheme.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.42),
        ),
        prefixStyle: AppTheme.bodyText.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: material.OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _InlineActionButton({
    required this.label,
    this.isPrimary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: material.InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              color: isPrimary ? const Color(0xFF131313) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return material.Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: material.InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
