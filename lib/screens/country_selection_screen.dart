import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CountryInfo {
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final String flag;

  const CountryInfo({
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
    required this.flag,
  });
}

const List<CountryInfo> kCountries = [
  CountryInfo(name: 'India', currencyCode: 'INR', currencySymbol: '₹', currencyName: 'Indian Rupee', flag: '🇮🇳'),
  CountryInfo(name: 'United States', currencyCode: 'USD', currencySymbol: '\$', currencyName: 'United States Dollar', flag: '🇺🇸'),
  CountryInfo(name: 'United Kingdom', currencyCode: 'GBP', currencySymbol: '£', currencyName: 'British Pound Sterling', flag: '🇬🇧'),
  CountryInfo(name: 'European Union', currencyCode: 'EUR', currencySymbol: '€', currencyName: 'Euro', flag: '🇪🇺'),
  CountryInfo(name: 'Canada', currencyCode: 'CAD', currencySymbol: 'C\$', currencyName: 'Canadian Dollar', flag: '🇨🇦'),
  CountryInfo(name: 'Australia', currencyCode: 'AUD', currencySymbol: 'A\$', currencyName: 'Australian Dollar', flag: '🇦🇺'),
  CountryInfo(name: 'Japan', currencyCode: 'JPY', currencySymbol: '¥', currencyName: 'Japanese Yen', flag: '🇯🇵'),
  CountryInfo(name: 'China', currencyCode: 'CNY', currencySymbol: '¥', currencyName: 'Chinese Yuan', flag: '🇨🇳'),
  CountryInfo(name: 'South Korea', currencyCode: 'KRW', currencySymbol: '₩', currencyName: 'South Korean Won', flag: '🇰🇷'),
  CountryInfo(name: 'Brazil', currencyCode: 'BRL', currencySymbol: 'R\$', currencyName: 'Brazilian Real', flag: '🇧🇷'),
  CountryInfo(name: 'Mexico', currencyCode: 'MXN', currencySymbol: 'MX\$', currencyName: 'Mexican Peso', flag: '🇲🇽'),
  CountryInfo(name: 'South Africa', currencyCode: 'ZAR', currencySymbol: 'R', currencyName: 'South African Rand', flag: '🇿🇦'),
  CountryInfo(name: 'Singapore', currencyCode: 'SGD', currencySymbol: 'S\$', currencyName: 'Singapore Dollar', flag: '🇸🇬'),
  CountryInfo(name: 'United Arab Emirates', currencyCode: 'AED', currencySymbol: 'د.إ', currencyName: 'UAE Dirham', flag: '🇦🇪'),
  CountryInfo(name: 'Saudi Arabia', currencyCode: 'SAR', currencySymbol: '﷼', currencyName: 'Saudi Riyal', flag: '🇸🇦'),
  CountryInfo(name: 'Indonesia', currencyCode: 'IDR', currencySymbol: 'Rp', currencyName: 'Indonesian Rupiah', flag: '🇮🇩'),
  CountryInfo(name: 'Malaysia', currencyCode: 'MYR', currencySymbol: 'RM', currencyName: 'Malaysian Ringgit', flag: '🇲🇾'),
  CountryInfo(name: 'Thailand', currencyCode: 'THB', currencySymbol: '฿', currencyName: 'Thai Baht', flag: '🇹🇭'),
  CountryInfo(name: 'Nigeria', currencyCode: 'NGN', currencySymbol: '₦', currencyName: 'Nigerian Naira', flag: '🇳🇬'),
  CountryInfo(name: 'Pakistan', currencyCode: 'PKR', currencySymbol: '₨', currencyName: 'Pakistani Rupee', flag: '🇵🇰'),
  CountryInfo(name: 'Bangladesh', currencyCode: 'BDT', currencySymbol: '৳', currencyName: 'Bangladeshi Taka', flag: '🇧🇩'),
  CountryInfo(name: 'Sri Lanka', currencyCode: 'LKR', currencySymbol: 'Rs', currencyName: 'Sri Lankan Rupee', flag: '🇱🇰'),
  CountryInfo(name: 'Nepal', currencyCode: 'NPR', currencySymbol: 'रू', currencyName: 'Nepalese Rupee', flag: '🇳🇵'),
  CountryInfo(name: 'Philippines', currencyCode: 'PHP', currencySymbol: '₱', currencyName: 'Philippine Peso', flag: '🇵🇭'),
  CountryInfo(name: 'Vietnam', currencyCode: 'VND', currencySymbol: '₫', currencyName: 'Vietnamese Dong', flag: '🇻🇳'),
  CountryInfo(name: 'Turkey', currencyCode: 'TRY', currencySymbol: '₺', currencyName: 'Turkish Lira', flag: '🇹🇷'),
  CountryInfo(name: 'Russia', currencyCode: 'RUB', currencySymbol: '₽', currencyName: 'Russian Ruble', flag: '🇷🇺'),
  CountryInfo(name: 'Switzerland', currencyCode: 'CHF', currencySymbol: 'CHF', currencyName: 'Swiss Franc', flag: '🇨🇭'),
  CountryInfo(name: 'New Zealand', currencyCode: 'NZD', currencySymbol: 'NZ\$', currencyName: 'New Zealand Dollar', flag: '🇳🇿'),
  CountryInfo(name: 'Kenya', currencyCode: 'KES', currencySymbol: 'KSh', currencyName: 'Kenyan Shilling', flag: '🇰🇪'),
];

class CountrySelectionScreen extends StatefulWidget {
  final void Function(CountryInfo)? onComplete;

  const CountrySelectionScreen({super.key, this.onComplete});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen>
    with SingleTickerProviderStateMixin {
  CountryInfo? _selected;
  bool _saving = false;
  bool _dropdownOpen = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectCountry(CountryInfo country) {
    setState(() {
      _selected = country;
      _dropdownOpen = false;
    });
    _fadeController.forward(from: 0);
  }

  Future<void> _onGetStarted() async {
    if (_selected == null) return;

    setState(() => _saving = true);
    try {
      await ApiService.patch('/auth/settings', {
        'country': _selected!.name,
        'currencyCode': _selected!.currencyCode,
        'currencySymbol': _selected!.currencySymbol,
        'currencyName': _selected!.currencyName,
      });
      if (mounted) {
        widget.onComplete?.call(_selected!);
      }
    } catch (e) {
      debugPrint('[CountrySelection] save error: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return material.Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.purple.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.teal.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main content
            Column(
              children: [
                // App branding bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Center(
                          child: Icon(Icons.account_balance_wallet_outlined, size: 14, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SpendWise',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Select your\ncountry',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "We'll tailor your experience based on your local\ncurrency and financial standards.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.muted,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Warning info box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.info_outline_rounded,
                                    size: 16, color: AppTheme.amber),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Selected country cannot be changed later. Make sure you have selected your living country.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.amber,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // GLOBAL REGION label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'GLOBAL REGION',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppTheme.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dropdown selector
                        GestureDetector(
                          onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                if (_selected != null) ...[
                                  Text(_selected!.flag, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    _selected?.name ?? 'Choose your country',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _selected != null ? Colors.white : AppTheme.muted,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _dropdownOpen ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.muted,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Dropdown list
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: material.ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: kCountries.length,
                                itemBuilder: (ctx, i) {
                                  final c = kCountries[i];
                                  final isSelected = _selected?.currencyCode == c.currencyCode;
                                  return material.InkWell(
                                    onTap: () => _selectCountry(c),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Text(c.flag, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            c.currencyCode,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppTheme.muted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.check_rounded, size: 16, color: AppTheme.green),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          crossFadeState: _dropdownOpen
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),

                        const SizedBox(height: 32),

                        // Currency preview card (visible after selection)
                        if (_selected != null)
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.account_balance_wallet_outlined,
                                          size: 22, color: AppTheme.muted),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'PREFERRED CURRENCY',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _selected!.currencySymbol,
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _selected!.currencyCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selected!.currencyName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.teal,
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Get Started button (bottom)
            if (_selected != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: GestureDetector(
                    onTap: _saving ? null : _onGetStarted,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: material.CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
