import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseListItem({super.key, required this.expense});

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Transit': Icons.directions_car_rounded,
    'Bills': Icons.bolt_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.local_hospital_rounded,
    'Education': Icons.school_rounded,
    'Subscriptions': Icons.subscriptions_rounded,
    'Other': Icons.account_balance_wallet_rounded,
  };

  /// Keyword → icon lookup for common expense descriptions.
  /// Checked in order; first match wins.
  static const List<_KeywordIcon> _descriptionIcons = [
    // Streaming & subscriptions
    _KeywordIcon(['netflix'], Icons.play_circle_rounded),
    _KeywordIcon(['youtube', 'yt premium'], Icons.play_circle_rounded),
    _KeywordIcon(['spotify', 'music'], Icons.music_note_rounded),
    _KeywordIcon(['prime', 'amazon'], Icons.local_shipping_rounded),
    _KeywordIcon(['disney', 'hotstar'], Icons.play_circle_rounded),
    _KeywordIcon(['hbo', 'hulu', 'apple tv'], Icons.tv_rounded),

    // Mobile & telecom
    _KeywordIcon(['recharge', 'mobile', 'airtel', 'jio', 'vi ', 'bsnl', 'sim', 'phone bill'], Icons.phone_android_rounded),

    // Food & drink
    _KeywordIcon(['coffee', 'starbucks', 'café', 'cafe'], Icons.coffee_rounded),
    _KeywordIcon(['swiggy', 'zomato', 'food delivery', 'doordash', 'ubereats'], Icons.delivery_dining_rounded),
    _KeywordIcon(['pizza', 'domino', 'burger', 'mcdonald'], Icons.fastfood_rounded),
    _KeywordIcon(['restaurant', 'dining', 'dinner', 'lunch', 'breakfast', 'brunch'], Icons.restaurant_rounded),
    _KeywordIcon(['grocery', 'groceries', 'supermarket', 'vegetables', 'fruits'], Icons.local_grocery_store_rounded),
    _KeywordIcon(['snack', 'chips', 'bakery', 'cake'], Icons.bakery_dining_rounded),

    // Transport
    _KeywordIcon(['uber', 'ola', 'lyft', 'cab', 'taxi', 'ride'], Icons.local_taxi_rounded),
    _KeywordIcon(['bus', 'metro', 'train', 'railway'], Icons.directions_transit_rounded),
    _KeywordIcon(['fuel', 'petrol', 'diesel', 'gas station', 'cng'], Icons.local_gas_station_rounded),
    _KeywordIcon(['flight', 'airline', 'airport', 'plane'], Icons.flight_rounded),
    _KeywordIcon(['parking'], Icons.local_parking_rounded),

    // Shopping
    _KeywordIcon(['clothes', 'clothing', 'shirt', 'shoes', 'fashion', 'dress'], Icons.checkroom_rounded),
    _KeywordIcon(['electronics', 'gadget', 'laptop', 'headphone', 'charger'], Icons.devices_rounded),

    // Bills & utilities
    _KeywordIcon(['electricity', 'electric', 'power bill'], Icons.bolt_rounded),
    _KeywordIcon(['water bill', 'water'], Icons.water_drop_rounded),
    _KeywordIcon(['internet', 'wifi', 'broadband', 'fiber'], Icons.wifi_rounded),
    _KeywordIcon(['rent', 'house rent'], Icons.home_rounded),
    _KeywordIcon(['gas bill', 'piped gas', 'cooking gas', 'lpg'], Icons.local_fire_department_rounded),
    _KeywordIcon(['insurance'], Icons.health_and_safety_rounded),

    // Health
    _KeywordIcon(['medicine', 'pharmacy', 'medical', 'doctor', 'hospital', 'clinic'], Icons.local_pharmacy_rounded),
    _KeywordIcon(['gym', 'fitness', 'workout'], Icons.fitness_center_rounded),

    // Education
    _KeywordIcon(['book', 'books', 'course', 'tuition', 'class', 'udemy', 'coursera'], Icons.menu_book_rounded),

    // Entertainment
    _KeywordIcon(['movie', 'cinema', 'theatre', 'theater', 'pvr', 'inox'], Icons.theaters_rounded),
    _KeywordIcon(['game', 'gaming', 'playstation', 'xbox', 'steam'], Icons.sports_esports_rounded),

    // Money & transfers
    _KeywordIcon(['transfer', 'sent', 'upi', 'paytm', 'gpay', 'phonepe'], Icons.swap_horiz_rounded),
    _KeywordIcon(['atm', 'cash', 'withdrawal'], Icons.atm_rounded),
  ];

  IconData _resolveIcon() {
    final desc = expense.description.toLowerCase();
    for (final entry in _descriptionIcons) {
      for (final keyword in entry.keywords) {
        if (desc.contains(keyword)) return entry.icon;
      }
    }
    return _categoryIcons[expense.category] ?? Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppTheme.categoryColors[expense.category] ?? AppTheme.muted;
    final icon = _resolveIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 20, color: catColor),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600, fontSize: 13, color: context.colorScheme.foreground),
                ),
                Text(
                  '${expense.category.toUpperCase()} • ${DateFormat.jm().format(expense.date.toLocal())}',
                  style: AppTheme.caption.copyWith(fontSize: 9, letterSpacing: 0.5, color: context.colorScheme.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            '-${context.read<AuthProvider>().currencySymbol}${expense.amount.toStringAsFixed(2)}',
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w700, fontSize: 13, color: context.colorScheme.foreground),
          ),
        ],
      ),
    );
  }
}

class _KeywordIcon {
  final List<String> keywords;
  final IconData icon;
  const _KeywordIcon(this.keywords, this.icon);
}
