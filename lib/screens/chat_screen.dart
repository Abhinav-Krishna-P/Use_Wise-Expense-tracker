import 'package:shadcn_flutter/shadcn_flutter.dart' hide ChatBubble;
import 'package:flutter/material.dart' as material;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/spending_limit_provider.dart';
import '../models/expense_model.dart';
import '../models/spending_limit_model.dart';
import '../theme/app_theme.dart';
import 'budget_onboarding_screen.dart';
import 'budget_plan_details_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/input_bar.dart';
import '../widgets/chat/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final int currentTab;
  final ValueChanged<int> onTabChange;

  const ChatScreen({
    super.key,
    required this.currentTab,
    required this.onTabChange,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProv = context.read<ChatProvider>();
      final expProv = context.read<ExpenseProvider>();
      final limProv = context.read<SpendingLimitProvider>();

      chatProv.onExpenseAdded = (expense) {
        expProv.addExpenseLocally(expense);
        expProv.loadExpenses();
        limProv.loadLimits(); // Reload limits since backend updated spent
      };
      chatProv.onExpenseUpdated = (expense) {
        expProv.updateExpenseLocally(expense);
        expProv.loadExpenses();
        limProv.loadLimits(); // Reload limits since amount/category may have changed
      };
      chatProv.onExpenseDeleted = (id) {
        expProv.removeExpenseLocally(id);
        expProv.loadExpenses();
        limProv.loadLimits(); // Reload limits since backend reversed spend
      };
      chatProv.onSpendingLimitIntent = _handleSpendingLimitIntent;
    });
  }

  void _sendQuickAction(String text) {
    context.read<ChatProvider>().sendMessage(text);
  }

  Future<void> _saveExpense(ExpenseModel expense, String description, double amount) {
    return context.read<ChatProvider>().updateExpenseCard(
          expense,
          description: description,
          amount: amount,
        );
  }

  Future<void> _deleteExpense(ExpenseModel expense) {
    return context.read<ChatProvider>().deleteExpenseCard(expense);
  }

  Future<void> _editSpendingLimit(
    String originalCategory,
    String updatedCategory,
    double amount,
    String period,
  ) async {
    final messenger = material.ScaffoldMessenger.maybeOf(context);
    final limProv = context.read<SpendingLimitProvider>();
    final chatProv = context.read<ChatProvider>();
    final normalizedCategory = _normalizeCategory(updatedCategory);

    if (normalizedCategory == null) {
      messenger?.showSnackBar(
        const material.SnackBar(
          content: Text('Please choose a valid category.'),
        ),
      );
      return;
    }

    if (amount <= 0) {
      messenger?.showSnackBar(
        const material.SnackBar(
          content: Text('Limit amount must be greater than 0.'),
        ),
      );
      return;
    }

    if (!['daily', 'weekly', 'monthly'].contains(period)) {
      messenger?.showSnackBar(
        const material.SnackBar(
          content: Text('Please choose a valid renewal period.'),
        ),
      );
      return;
    }

    await limProv.loadLimits();
    final config = limProv.config;
    if (config == null) return;

    final duplicateExists = config.limits.any(
      (limit) =>
          limit.category.toLowerCase() == normalizedCategory.toLowerCase() &&
          limit.category.toLowerCase() != originalCategory.toLowerCase(),
    );
    if (duplicateExists) {
      messenger?.showSnackBar(
        const material.SnackBar(
          content: Text('That category already has a spending limit.'),
        ),
      );
      return;
    }

      final updatedLimits = config.limits.map((limit) {
        if (limit.category.toLowerCase() != originalCategory.toLowerCase()) {
          return limit;
        }
        return limit.copyWith(
          category: normalizedCategory,
          limitAmount: amount,
          period: period,
        );
      }).toList();

      await limProv.updateLimits(
        limits: updatedLimits
            .map((limit) => {
                  'category': limit.category,
                  'limitAmount': limit.limitAmount,
                  'period': limit.period,
                })
            .toList(),
      );

    chatProv.syncSpendingLimitMessages(
      limProv.config,
      text: 'Here are your current spending limits.',
    );
  }

  Future<void> _deleteSpendingLimit(String category) async {
    final limProv = context.read<SpendingLimitProvider>();
    final chatProv = context.read<ChatProvider>();

    await limProv.loadLimits();
    final config = limProv.config;
    if (config == null) return;

    final remainingLimits = config.limits
        .where((limit) => limit.category.toLowerCase() != category.toLowerCase())
        .toList();

    if (remainingLimits.length == config.limits.length) return;

    if (remainingLimits.isEmpty) {
      await limProv.deleteLimits();
      chatProv.syncSpendingLimitMessages(
        null,
        text: 'No spending limits created till now.',
        action: 'spending_limits_empty',
      );
      return;
    }

      await limProv.updateLimits(
        limits: remainingLimits
            .map((limit) => {
                  'category': limit.category,
                  'limitAmount': limit.limitAmount,
                  'period': limit.period,
                })
            .toList(),
      );

      chatProv.syncSpendingLimitMessages(
        limProv.config,
        text: 'Here are your current spending limits.',
      );
    }

  Future<ChatSpendingLimitResult> _handleSpendingLimitIntent(
    ChatSpendingLimitIntent intent,
  ) async {
    final limProv = context.read<SpendingLimitProvider>();
    final auth = context.read<AuthProvider>();
    final currencySymbol = auth.currencySymbol;

    switch (intent.type) {
      case ChatSpendingLimitIntentType.show:
        await limProv.loadLimits();
        if (!limProv.hasLimits) {
          return ChatSpendingLimitResult(
            reply: 'No spending limits created till now.',
            action: 'spending_limits_empty',
          );
        }
        return ChatSpendingLimitResult(
          reply: 'Here are your current spending limits.',
          action: 'spending_limits_show',
          config: limProv.config,
        );

      case ChatSpendingLimitIntentType.delete:
        await limProv.loadLimits();

        if (!limProv.hasLimits) {
          return const ChatSpendingLimitResult(
            reply: 'No spending limits created till now.',
            action: 'spending_limits_empty',
          );
        }

        if (intent.deleteAll) {
          await limProv.deleteLimits();
          return const ChatSpendingLimitResult(
            reply: 'I removed all of your spending limits.',
            action: 'spending_limits_empty',
          );
        }

        final category = intent.category!;
        final existingConfig = limProv.config!;
        final remainingLimits = existingConfig.limits
            .where((limit) => limit.category.toLowerCase() != category.toLowerCase())
            .toList();

        if (remainingLimits.length == existingConfig.limits.length) {
          return ChatSpendingLimitResult(
            reply: 'I could not find a spending limit for $category.',
            action: 'spending_limits_empty',
          );
        }

        if (remainingLimits.isEmpty) {
          await limProv.deleteLimits();
          return ChatSpendingLimitResult(
            reply: 'I removed your $category spending limit. No spending limits created till now.',
            action: 'spending_limits_empty',
          );
        }

        await limProv.updateLimits(
          limits: remainingLimits
              .map((limit) => {
                    'category': limit.category,
                    'limitAmount': limit.limitAmount,
                    'period': limit.period,
                  })
              .toList(),
        );
        return ChatSpendingLimitResult(
          reply: 'I removed your $category spending limit.',
          action: 'spending_limits_show',
          config: limProv.config,
        );

      case ChatSpendingLimitIntentType.createOrUpdate:
        await limProv.loadLimits();

        final category = intent.category!;
        final amount = intent.amount!;
        final existingConfig = limProv.config;
        final existingLimits = existingConfig?.limits.toList() ?? <SpendingLimitItem>[];
        final existingIndex = existingLimits.indexWhere(
          (limit) => limit.category.toLowerCase() == category.toLowerCase(),
        );
        final isUpdatingExisting = existingIndex != -1;
        final resolvedPeriod = intent.period ??
            (isUpdatingExisting ? existingLimits[existingIndex].period : 'monthly');

        if (!isUpdatingExisting && existingLimits.length >= 3) {
          return const ChatSpendingLimitResult(
            reply: 'You can only track up to 3 spending limit categories at once. Remove one first or update an existing category.',
            action: 'spending_limits_empty',
          );
        }

        final updatedPayload = <Map<String, dynamic>>[
          for (final limit in existingLimits)
              {
                'category': limit.category,
                'limitAmount': limit.limitAmount,
                'period': limit.period,
              },
          ];

        if (isUpdatingExisting) {
          updatedPayload[existingIndex] = {
            'category': category,
            'limitAmount': amount,
            'period': resolvedPeriod,
          };
        } else {
          updatedPayload.add({
            'category': category,
            'limitAmount': amount,
            'period': resolvedPeriod,
          });
        }

        if (existingConfig == null) {
          await limProv.createLimits(
            limits: updatedPayload,
          );
        } else {
          await limProv.updateLimits(
            limits: updatedPayload,
          );
        }

        final actionWord = isUpdatingExisting ? 'updated' : 'created';
        return ChatSpendingLimitResult(
          reply: 'I $actionWord your $category spending limit to $currencySymbol${amount.toStringAsFixed(0)} for the ${_formatLimitPeriod(resolvedPeriod)} period.',
          action: 'spending_limits_show',
          config: limProv.config,
        );
    }
  }

  String _formatLimitPeriod(String period) {
    switch (period) {
      case 'daily':
        return 'daily';
      case 'weekly':
        return 'weekly';
      case 'monthly':
      default:
        return 'monthly';
    }
  }

  String? _normalizeCategory(String rawCategory) {
    final normalized = rawCategory.trim().toLowerCase();
    for (final category in AppTheme.categoryEmojis.keys) {
      if (category.toLowerCase() == normalized) {
        return category;
      }
    }
    return null;
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
      _showLogoutConfirmation();
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

  void _showLogoutConfirmation() {
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
                  color: AppTheme.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.logout_rounded, size: 24, color: AppTheme.red),
                ),
              ),
              const Gap(16),
              Text(
                'Log Out',
                style: AppTheme.titleLarge.copyWith(
                  fontSize: 18,
                  color: colorScheme.foreground,
                ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final locale = Localizations.localeOf(context);
    final country = locale.countryCode ?? 'Unknown';
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : 'SpendWise User';
    final email = user?.email ?? 'No email';
    final photoUrl = user?.photoURL;
    final totalToday = context.watch<ExpenseProvider>().totalToday;
    final currencySymbol = auth.currencySymbol;

    return Stack(
      children: [
        GestureDetector(
          onTap: _closeSidebar,
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Container(
                      color: colorScheme.background,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colorScheme.card,
                              borderRadius: BorderRadius.circular(12),
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
                                Text(
                                  'SpendWise AI',
                                  style: AppTheme.titleLarge.copyWith(
                                    fontSize: 18,
                                    color: colorScheme.foreground,
                                  ),
                                ),
                                Text(
                                  'FINANCIAL ASSISTANT',
                                  style: AppTheme.caption.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Consumer<ChatProvider>(
                      builder: (context, chatProv, _) {
                        final messages = chatProv.messages;

                        if (messages.isEmpty && !chatProv.isLoading) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 68),
                            child: _EmptyStateView(onQuickAction: _sendQuickAction),
                          );
                        }

                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(16, 68, 16, 10),
                          itemCount: messages.length + (chatProv.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (chatProv.isLoading && index == 0) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: TypingIndicator(),
                              );
                            }

                            final msgIndex = chatProv.isLoading ? index - 1 : index;
                            final msg = messages[msgIndex];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: ChatBubble(
                                message: msg,
                                onEditExpense: _saveExpense,
                                onDeleteExpense: _deleteExpense,
                                onEditSpendingLimit: _editSpendingLimit,
                                onDeleteSpendingLimit: _deleteSpendingLimit,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _TopTabToggle(
                          currentTab: widget.currentTab,
                          onChanged: widget.onTabChange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Consumer<ChatProvider>(
                  builder: (context, chatProv, _) {
                    return InputBar(
                      onSend: (text) => chatProv.sendMessage(text),
                      onImageSend: (image, caption) =>
                          chatProv.sendImageMessage(image, caption),
                    );
                  },
                ),
              ),
            ],
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
                                '$currencySymbol${totalToday.toStringAsFixed(2)}',
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
                  _DrawerNavItem(
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    onTap: () => _handleDrawerItemTap('Profile'),
                  ),
                  const Gap(6),
                  _DrawerNavItem(
                    label: 'Calendar',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _handleDrawerItemTap('Calendar'),
                  ),
                  const Gap(6),
                  _DrawerNavItem(
                    label: 'Budgeting',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => _handleDrawerItemTap('Budgeting'),
                  ),
                  const Spacer(),
                  _DrawerNavItem(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    onTap: () => _handleDrawerItemTap('Settings'),
                  ),
                  const Gap(6),
                  _DrawerNavItem(
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
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final Function(String) onQuickAction;

  const _EmptyStateView({required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          // Large Wallet icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colorScheme.border, width: 2),
            ),
            child: Center(
              child: Icon(Icons.account_balance_wallet_rounded, size: 40, color: context.colorScheme.foreground),
            ),
          ),
          const Gap(24),
          // Heading
          Text(
            'How can I help with\nyour expenses?',
            textAlign: TextAlign.center,
            style: AppTheme.titleLarge.copyWith(fontSize: 28),
          ),
          const Gap(16),
          // Subtitle
          Text(
            'Ask me to log a receipt, categorize a\ntransaction, or show your spending\ntrends for the month.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyText.copyWith(color: context.colorScheme.mutedForeground, height: 1.5, fontSize: 15),
          ),
          const Gap(40),
          // Action Buttons
          ..._buildQuickActions(context),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActions(BuildContext context) {
    final sym = context.read<AuthProvider>().currencySymbol;
    final actions = [
      {'icon': Icons.receipt_long_rounded, 'text': "Analyze last week's spending"},
      {'icon': Icons.credit_card_rounded, 'text': 'Log ${sym}45 for grocery store'},
      {'icon': Icons.pie_chart_rounded, 'text': 'Compare month over month'},
      {'icon': Icons.savings_rounded, 'text': 'Set a ${sym}500 budget goal'},
    ];

    return actions.map((action) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => onQuickAction(action['text'] as String),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.colorScheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorScheme.border),
            ),
            child: Row(
              children: [
                Icon(action['icon'] as IconData, size: 20, color: context.colorScheme.foreground),
                const Gap(16),
                Expanded(
                  child: Text(
                    action['text'] as String,
                    style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
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

class _DrawerNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerNavItem({
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
