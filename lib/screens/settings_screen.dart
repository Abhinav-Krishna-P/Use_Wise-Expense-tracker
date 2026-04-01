import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/country_selection_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _widgetChannel = MethodChannel('com.expensetracker/widget');

  bool _loading = true;
  bool _widgetEnabled = false;
  bool _notificationsEnabled = false;
  bool _upiAutoCapture = false;
  String _upiCaptureMode = 'manual'; // 'auto' | 'manual'
  bool _savingWidget = false;
  bool _savingNotifications = false;
  bool _savingCurrency = false;
  bool _savingUpi = false;
  bool _savingUpiMode = false;
  CountryInfo? _selectedCountry;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ApiService.get('/auth/me');
      final user = data['user'] as Map<String, dynamic>?;
      final settings = user?['settings'] as Map<String, dynamic>?;
      final countryName = settings?['country'] as String?;
      final currencyCode = settings?['currencyCode'] as String?;

      CountryInfo? matchedCountry;
      if (countryName != null) {
        for (final country in kCountries) {
          if (country.name == countryName) {
            matchedCountry = country;
            break;
          }
        }
      }
      matchedCountry ??= kCountries.cast<CountryInfo?>().firstWhere(
            (country) => country?.currencyCode == currencyCode,
            orElse: () => null,
          );

      if (!mounted) return;
      setState(() {
        _widgetEnabled = settings?['homeScreenWidget'] == true;
        _notificationsEnabled = settings?['pushNotifications'] == true;
        _upiAutoCapture = settings?['upiAutoCapture'] == true;
        _upiCaptureMode = (settings?['upiCaptureMode'] as String?) ?? 'manual';
        _selectedCountry = matchedCountry;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[SettingsScreen] loadSettings error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleWidget(bool value) async {
    if (_savingWidget) return;

    setState(() {
      _savingWidget = true;
      _widgetEnabled = value;
    });

    try {
      await ApiService.patch('/auth/settings', {'homeScreenWidget': value});

      if (value) {
        final started = await _widgetChannel.invokeMethod<bool>('startFloatingWidget');
        if (started != true) {
          await ApiService.patch('/auth/settings', {'homeScreenWidget': false});
          if (!mounted) return;
          setState(() => _widgetEnabled = false);
        }
      } else {
        await _widgetChannel.invokeMethod<bool>('stopFloatingWidget');
      }
    } catch (e) {
      debugPrint('[SettingsScreen] toggleWidget error: $e');
      if (mounted) setState(() => _widgetEnabled = !value);
    } finally {
      if (mounted) setState(() => _savingWidget = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (_savingNotifications) return;

    final previous = _notificationsEnabled;
    setState(() => _savingNotifications = true);

    try {
      if (value) {
        final granted = await NotificationService.instance.enablePushNotifications();
        if (!granted) {
          if (!mounted) return;
          material.ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const material.SnackBar(
              content: Text('Notification permission is required to enable alerts.'),
            ),
          );
          setState(() => _notificationsEnabled = false);
          return;
        }
      } else {
        await NotificationService.instance.unregisterCurrentToken();
      }

      await ApiService.patch('/auth/settings', {'pushNotifications': value});
      if (!mounted) return;
      context.read<AuthProvider>().setPushNotificationsEnabled(value);
      setState(() => _notificationsEnabled = value);
    } catch (e) {
      debugPrint('[SettingsScreen] toggleNotifications error: $e');
      if (mounted) setState(() => _notificationsEnabled = previous);
      if (!value && previous) {
        NotificationService.instance.setPushNotificationsEnabled(true);
        await NotificationService.instance.syncTokenWithBackend();
      }
    } finally {
      if (mounted) setState(() => _savingNotifications = false);
    }
  }

  Future<void> _setUpiMode(String mode) async {
    if (_savingUpiMode || mode == _upiCaptureMode) return;
    final previous = _upiCaptureMode;
    setState(() {
      _savingUpiMode = true;
      _upiCaptureMode = mode;
    });
    try {
      await ApiService.patch('/auth/settings', {'upiCaptureMode': mode});
      if (!mounted) return;
      context.read<AuthProvider>().setUpiCaptureMode(mode);
    } catch (e) {
      debugPrint('[SettingsScreen] setUpiMode error: $e');
      if (mounted) setState(() => _upiCaptureMode = previous);
    } finally {
      if (mounted) setState(() => _savingUpiMode = false);
    }
  }

  Future<void> _toggleUpiCapture(bool value) async {
    if (_savingUpi) return;

    final previous = _upiAutoCapture;
    setState(() {
      _savingUpi = true;
      _upiAutoCapture = value;
    });

    try {
      await ApiService.patch('/auth/settings', {'upiAutoCapture': value});
      if (!mounted) return;
      context.read<AuthProvider>().setUpiAutoCapture(value);
    } catch (e) {
      debugPrint('[SettingsScreen] toggleUpiCapture error: $e');
      if (mounted) setState(() => _upiAutoCapture = previous);
    } finally {
      if (mounted) setState(() => _savingUpi = false);
    }
  }

  Future<void> _changeCurrency() async {
    final picked = await material.showModalBottomSheet<CountryInfo>(
      context: context,
      backgroundColor: context.colorScheme.card,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _CurrencyPickerSheet(selected: _selectedCountry),
    );

    if (picked == null || !mounted) return;

    final auth = context.read<AuthProvider>();

    setState(() => _savingCurrency = true);
    try {
      await ApiService.patch('/auth/settings', {
        'country': picked.name,
        'currencyCode': picked.currencyCode,
        'currencySymbol': picked.currencySymbol,
        'currencyName': picked.currencyName,
      });
      auth.setCurrency(code: picked.currencyCode, symbol: picked.currencySymbol);
      if (!mounted) return;
      setState(() => _selectedCountry = picked);
    } catch (e) {
      debugPrint('[SettingsScreen] changeCurrency error: $e');
    } finally {
      if (mounted) setState(() => _savingCurrency = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = context.colorScheme;
    final isDark = themeProvider.isDarkMode;
    final selectedCountry = _selectedCountry;
    final currencyLabel = selectedCountry != null
        ? '${selectedCountry.currencyCode} (${selectedCountry.currencySymbol})'
        : '${context.watch<AuthProvider>().currencyCode} (${context.watch<AuthProvider>().currencySymbol})';

    return material.Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: _loading
            ? Center(child: material.CircularProgressIndicator(color: colorScheme.foreground))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
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
                          child: Icon(Icons.arrow_back_rounded, size: 28, color: colorScheme.foreground),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Appearance',
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 21,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize how SpendWise looks on your device.',
                      style: AppTheme.bodyText.copyWith(
                        color: colorScheme.mutedForeground,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.border),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ThemeSegment(
                              label: 'Light',
                              icon: Icons.light_mode_outlined,
                              isSelected: themeProvider.themeMode == ThemeMode.light,
                              isDarkTheme: isDark,
                              onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.light),
                            ),
                          ),
                          Expanded(
                            child: _ThemeSegment(
                              label: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              isSelected: themeProvider.themeMode == ThemeMode.dark,
                              isDarkTheme: isDark,
                              onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Preferences',
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 21,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          _SettingsToggleRow(
                            icon: Icons.widgets_rounded,
                            title: 'Enable HomeScreen Widgets',
                            subtitle: 'Quick access to your budget at a glance',
                            value: _widgetEnabled,
                            isLoading: _savingWidget,
                            onChanged: _toggleWidget,
                          ),
                          _SettingsDivider(),
                          _SettingsToggleRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Push Notifications',
                            subtitle: 'Manage daily summaries and alerts',
                            value: _notificationsEnabled,
                            isLoading: _savingNotifications,
                            onChanged: _toggleNotifications,
                          ),
                          _SettingsDivider(),
                          _SettingsActionRow(
                            icon: Icons.payments_outlined,
                            title: 'Default Currency',
                            subtitle: currencyLabel,
                            isLoading: _savingCurrency,
                            onTap: _changeCurrency,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Integrations',
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 21,
                        color: colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect SpendWise with other apps on your device.',
                      style: AppTheme.bodyText.copyWith(
                        color: colorScheme.mutedForeground,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: colorScheme.border),
                      ),
                      child: Column(
                        children: [
                          _SettingsToggleRow(
                            icon: Icons.account_balance_rounded,
                            title: 'Accept payments from UPI apps',
                            subtitle: 'Share UPI screenshots to auto-log expenses via AI',
                            value: _upiAutoCapture,
                            isLoading: _savingUpi,
                            onChanged: _toggleUpiCapture,
                          ),
                          // Expanding sub-options
                          AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            child: _upiAutoCapture
                                ? Column(
                                    children: [
                                      _SettingsDivider(),
                                      _UpiModePicker(
                                        mode: _upiCaptureMode,
                                        saving: _savingUpiMode,
                                        onChanged: _setUpiMode,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDarkTheme;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDarkTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkTheme ? const Color(0xFF262626) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: context.colorScheme.border)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: context.colorScheme.foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                color: context.colorScheme.foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: colorScheme.foreground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    color: colorScheme.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodyText.copyWith(
                    color: colorScheme.mutedForeground,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isLoading)
            const SizedBox(
              width: 26,
              height: 26,
              child: material.CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            GestureDetector(
              onTap: () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value
                      ? (isDark ? Colors.white : colorScheme.foreground)
                      : colorScheme.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: value
                          ? (isDark ? const Color(0xFF121212) : Colors.white)
                          : colorScheme.foreground,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _SettingsActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: colorScheme.foreground),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    color: colorScheme.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodyText.copyWith(
                    color: colorScheme.mutedForeground,
                    fontSize: 11,
                  ),
                ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: material.CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.foreground,
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: colorScheme.mutedForeground, size: 26),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: context.colorScheme.border,
    );
  }
}

// ── UPI capture mode picker ──────────────────────────────────────────────────

class _UpiModePicker extends StatelessWidget {
  final String mode;
  final bool saving;
  final ValueChanged<String> onChanged;

  const _UpiModePicker({
    required this.mode,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CAPTURE MODE',
                style: AppTheme.bodyText.copyWith(
                  color: colorScheme.mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              if (saving) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 11,
                  height: 11,
                  child: material.CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colorScheme.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // IntrinsicHeight ensures both cards are always the same height
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _UpiModeOption(
                    label: 'Auto',
                    icon: Icons.bolt_rounded,
                    description: 'Instantly log without any confirmation',
                    isSelected: mode == 'auto',
                    onTap: saving ? null : () => onChanged('auto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _UpiModeOption(
                    label: 'Manual',
                    icon: Icons.touch_app_rounded,
                    description: 'Preview the image before logging',
                    isSelected: mode == 'manual',
                    onTap: saving ? null : () => onChanged('manual'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpiModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback? onTap;

  const _UpiModeOption({
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFF4F4F4))
              : colorScheme.secondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.foreground : colorScheme.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + label + indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? colorScheme.foreground
                      : colorScheme.mutedForeground,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.foreground
                          : colorScheme.mutedForeground,
                    ),
                  ),
                ),
                // Clean check indicator
                _ModeIndicator(isSelected: isSelected),
              ],
            ),
            const SizedBox(height: 6),
            // Description — same text length avoids height mismatch
            Text(
              description,
              style: AppTheme.bodyText.copyWith(
                fontSize: 10,
                color: colorScheme.mutedForeground,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A crisp radio-style indicator: gradient filled circle + white check when
/// selected, plain outlined circle when not.
class _ModeIndicator extends StatelessWidget {
  final bool isSelected;
  const _ModeIndicator({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    const size = 20.0;

    if (isSelected) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, size: 13, color: Colors.white),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: context.colorScheme.mutedForeground,
          width: 1.5,
        ),
      ),
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final CountryInfo? selected;

  const _CurrencyPickerSheet({this.selected});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<CountryInfo> _visibleCountries;

  @override
  void initState() {
    super.initState();
    _visibleCountries = List<CountryInfo>.from(kCountries);
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterCountries)
      ..dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _visibleCountries = kCountries.where((country) {
        if (query.isEmpty) return true;
        return country.name.toLowerCase().contains(query) ||
            country.currencyCode.toLowerCase().contains(query) ||
            country.currencyName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose Currency',
              style: AppTheme.titleLarge.copyWith(
                color: colorScheme.foreground,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 14),
            material.TextField(
              controller: _searchController,
              style: TextStyle(color: colorScheme.foreground),
              decoration: material.InputDecoration(
                hintText: 'Search country or currency',
                hintStyle: TextStyle(color: colorScheme.mutedForeground),
                filled: true,
                fillColor: colorScheme.secondary,
                border: material.OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.mutedForeground),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _visibleCountries.length,
                separatorBuilder: (context, index) => Container(
                  height: 1,
                  color: colorScheme.border,
                ),
                itemBuilder: (context, index) {
                  final country = _visibleCountries[index];
                  final isSelected = widget.selected?.currencyCode == country.currencyCode &&
                      widget.selected?.name == country.name;

                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(country),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Text(country.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  country.name,
                                  style: AppTheme.bodyText.copyWith(
                                    color: colorScheme.foreground,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${country.currencyName} • ${country.currencyCode} (${country.currencySymbol})',
                                  style: AppTheme.bodyText.copyWith(
                                    color: colorScheme.mutedForeground,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_rounded, color: colorScheme.foreground),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
