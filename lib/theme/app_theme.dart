import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF09090B);
  static const Color card = Color(0xFF141415); 
  static const Color border = Color(0xFF27272A);
  static const Color text = Color(0xFFFAFAFA);
  static const Color muted = Color(0xFFA1A1AA);
  static const Color primary = Color(0xFFFAFAFA);
  static const Color primaryForeground = Color(0xFF09090B);

  static const Color chartOrange = Color(0xFFFF5722);
  static const Color chartTeal = Color(0xFF009688);
  static const Color chartBlue = Color(0xFF0D47A1);
  static const Color chartYellow = Color(0xFFFFC107);
  
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFE53935);

  // Fallbacks for older unedited widgets to compile
  static const Color teal = Color(0xFF14B8A6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color amber = Color(0xFFF59E0B);
  static const Color bgCard = card;
  static const Color bgGlass = Color(0x1AFFFFFF);
  static const Color textPrimary = text;
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Map<String, Color> categoryColors = {
    'Food': purple,
    'Transport': teal,
    'Transit': teal,
    'Bills': amber,
    'Shopping': chartYellow,
    'Entertainment': chartBlue,
    'Health': green,
    'Education': Color(0xFF3B82F6),
    'Subscriptions': chartOrange,
    'Other': Color(0xFF6B7280),
  };

  static const Map<String, String> categoryEmojis = {
    'Food': '🍔',
    'Transport': '🚗',
    'Transit': '🚗',
    'Bills': '⚡',
    'Shopping': '🛍️',
    'Entertainment': '🎬',
    'Health': '💊',
    'Education': '📚',
    'Subscriptions': '📱',
    'Other': '💰',
  };

  static TextStyle displayAmount = GoogleFonts.inter(
    fontSize: 44,
    fontWeight: FontWeight.w700,
  );

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyText = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        background: Color(0xFFFAFAFA),
        foreground: Color(0xFF09090B),
        card: Color(0xFFFFFFFF),
        cardForeground: Color(0xFF09090B),
        popover: Color(0xFFFFFFFF),
        popoverForeground: Color(0xFF09090B),
        primary: Color(0xFF09090B),
        primaryForeground: Color(0xFFFAFAFA),
        secondary: Color(0xFFF4F4F5),
        secondaryForeground: Color(0xFF09090B),
        muted: Color(0xFFF4F4F5),
        mutedForeground: Color(0xFF71717A),
        accent: Color(0xFFF4F4F5),
        accentForeground: Color(0xFF09090B),
        destructive: red,
        destructiveForeground: Color(0xFFFAFAFA),
        border: Color(0xFFE4E4E7),
        input: Color(0xFFE4E4E7),
        ring: Color(0xFFA1A1AA),
        chart1: chartOrange,
        chart2: chartTeal,
        chart3: chartBlue,
        chart4: chartYellow,
        chart5: red,
      ),
      radius: 0.5,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        background: background,
        foreground: text,
        card: card,
        cardForeground: text,
        popover: card,
        popoverForeground: text,
        primary: primary,
        primaryForeground: primaryForeground,
        secondary: Color(0xFF27272A),
        secondaryForeground: text,
        muted: Color(0xFF27272A),
        mutedForeground: muted,
        accent: Color(0xFF27272A),
        accentForeground: text,
        destructive: red,
        destructiveForeground: text,
        border: border,
        input: border,
        ring: muted,
        chart1: chartOrange,
        chart2: chartTeal,
        chart3: chartBlue,
        chart4: chartYellow,
        chart5: red,
      ),
      radius: 0.5,
    );
  }
}

extension ThemeContext on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

