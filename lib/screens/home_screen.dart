import 'dart:typed_data';
import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/spending_limit_provider.dart';
import '../services/upi_share_service.dart';
import 'chat_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initUpiShare();
  }

  Future<void> _initUpiShare() async {
    UpiShareService.onImageReceived = _handleUpiImage;
    await UpiShareService.init();
  }

  @override
  void dispose() {
    UpiShareService.dispose();
    super.dispose();
  }

  /// Called when Android delivers a shared image from a UPI app.
  /// Only processes it if the user has enabled upiAutoCapture in settings.
  Future<void> _handleUpiImage(Uint8List bytes) async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    if (!auth.upiAutoCapture) {
      // Feature not enabled — show a gentle hint
      _showUpiDisabledBanner();
      return;
    }

    // Switch to Chat tab so the user sees the processing
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }

    await Future.delayed(const Duration(milliseconds: 200)); // let tab settle
    if (!mounted) return;

    final chatProv = context.read<ChatProvider>();
    final xfile = XFile.fromData(
      bytes,
      mimeType: 'image/jpeg',
      name: 'upi_payment.jpg',
    );

    if (auth.upiCaptureMode == 'auto') {
      // ── AUTO: send directly to LLM, no confirmation needed ──────────────
      chatProv.sendImageMessage(xfile, 'Payment screenshot from UPI app');
    } else {
      // ── MANUAL: show preview sheet first ────────────────────────────────
      final confirmed = await _showUpiConfirmSheet(bytes);
      if (confirmed != true || !mounted) return;
      chatProv.sendImageMessage(xfile, 'Payment screenshot from UPI app');
    }
  }

  void _showUpiDisabledBanner() {
    final colorScheme = context.colorScheme;
    material.ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      material.SnackBar(
        content: const Text('Enable "Accept payments from UPI apps" in Settings to auto-log expenses.'),
        backgroundColor: colorScheme.card,
        behavior: material.SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: material.SnackBarAction(
          label: 'Settings',
          textColor: AppTheme.teal,
          onPressed: () {
            // Settings is reachable from the sidebar in ChatScreen
          },
        ),
      ),
    );
  }

  Future<bool?> _showUpiConfirmSheet(Uint8List bytes) async {
    final colorScheme = context.colorScheme;
    return material.showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colorScheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _UpiConfirmSheet(imageBytes: bytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(
        currentTab: _currentIndex,
        onTabChange: _handleTabChange,
      ),
      AnalyticsScreen(
        currentTab: _currentIndex,
        onTabChange: _handleTabChange,
      ),
    ];

    return Scaffold(
      backgroundColor: context.colorScheme.background,
      child: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }

  void _handleTabChange(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      context.read<ExpenseProvider>().loadExpenses();
      context.read<BudgetProvider>().loadActivePlan();
      context.read<SpendingLimitProvider>().loadLimits();
    }
  }
}

// ── UPI image confirmation sheet ─────────────────────────────────────────────

class _UpiConfirmSheet extends StatelessWidget {
  final Uint8List imageBytes;

  const _UpiConfirmSheet({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // Force white text inside the sheet regardless of Material theme
    final textColor       = isDark ? Colors.white : const Color(0xFF0F0F0F);
    final subtitleColor   = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF6B7280);
    final bgColor         = colorScheme.card;
    final borderColor     = colorScheme.border;

    return material.Theme(
      data: material.Theme.of(context).copyWith(
        textTheme: material.Theme.of(context).textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 24 + material.MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPI Payment Detected',
                          style: AppTheme.titleLarge.copyWith(
                            fontSize: 17,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI will scan and log this as an expense',
                          style: AppTheme.bodyText.copyWith(
                            color: subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: material.Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 220,
                  fit: material.BoxFit.cover,
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Scan & Log Expense',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w700,
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
}


