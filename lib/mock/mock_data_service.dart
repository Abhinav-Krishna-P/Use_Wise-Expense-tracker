import '../models/expense_model.dart';

class MockDataService {
  static int _responseIndex = 0;

  static final List<String> _aiResponses = [
    "✅ Got it! I've logged ₹450 for Zomato Biryani under Food 🍛\nAdded to today's expenses!",
    "✅ Logged ₹250 for Uber ride to office under Transport 🚗\nYour transport spend today: ₹250",
    "✅ Added ₹1,500 for Electricity Bill under Bills ⚡\nBig one! That's logged.",
    "✅ Noted ₹800 for PVR Movie tickets under Entertainment 🎬\nEnjoy the movie!",
    "✅ Saved ₹320 for Apollo Pharmacy under Health 💊\nHealth expenses tracked!",
    "✅ Logged ₹180 for Auto to metro under Transport 🛺",
    "✅ Added ₹2,200 for Grocery shopping under Shopping 🛍️",
  ];

  static final List<ExpenseModel> _mockExpenses = [
    ExpenseModel(
      id: 'mock_food',
      description: 'Zomato Biryani',
      amount: 450,
      category: 'Food',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_transport',
      description: 'Uber ride to office',
      amount: 250,
      category: 'Transport',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_bills',
      description: 'Electricity Bill',
      amount: 1500,
      category: 'Bills',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_ent',
      description: 'PVR Movie tickets',
      amount: 800,
      category: 'Entertainment',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_health',
      description: 'Apollo Pharmacy',
      amount: 320,
      category: 'Health',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_transport2',
      description: 'Auto to metro',
      amount: 180,
      category: 'Transport',
      date: DateTime.now(),
    ),
    ExpenseModel(
      id: 'mock_shopping',
      description: 'Grocery shopping',
      amount: 2200,
      category: 'Shopping',
      date: DateTime.now(),
    ),
  ];

  static String getNextAIResponse() {
    final response = _aiResponses[_responseIndex % _aiResponses.length];
    _responseIndex++;
    return response;
  }

  static ExpenseModel getNextMockExpense() {
    final index = (_responseIndex - 1) % _mockExpenses.length;
    final template = _mockExpenses[index];
    return ExpenseModel(
      id: '${template.id}_${DateTime.now().millisecondsSinceEpoch}',
      description: template.description,
      amount: template.amount,
      category: template.category,
      date: DateTime.now(),
    );
  }

  /// Pre-seeded expenses that appear in the analytics screen
  static List<ExpenseModel> getInitialExpenses() {
    final now = DateTime.now();
    return [
      ExpenseModel(
        id: 'seed_1',
        description: 'Swiggy Dinner',
        amount: 380,
        category: 'Food',
        date: now.subtract(const Duration(minutes: 30)),
      ),
      ExpenseModel(
        id: 'seed_2',
        description: 'Ola to Mall',
        amount: 210,
        category: 'Transport',
        date: now.subtract(const Duration(hours: 1)),
      ),
      ExpenseModel(
        id: 'seed_3',
        description: 'Netflix Subscription',
        amount: 199,
        category: 'Entertainment',
        date: now.subtract(const Duration(hours: 2)),
      ),
      ExpenseModel(
        id: 'seed_4',
        description: 'Amazon Order',
        amount: 1450,
        category: 'Shopping',
        date: now.subtract(const Duration(hours: 3)),
      ),
      ExpenseModel(
        id: 'seed_5',
        description: 'Chai & Samosa',
        amount: 60,
        category: 'Food',
        date: now.subtract(const Duration(hours: 5)),
      ),
      ExpenseModel(
        id: 'seed_6',
        description: 'Metro Card Recharge',
        amount: 500,
        category: 'Transport',
        date: now.subtract(const Duration(hours: 6)),
      ),
      ExpenseModel(
        id: 'seed_7',
        description: 'Gym Membership',
        amount: 1200,
        category: 'Health',
        date: now.subtract(const Duration(hours: 8)),
      ),
      ExpenseModel(
        id: 'seed_8',
        description: 'WiFi Bill',
        amount: 899,
        category: 'Bills',
        date: now.subtract(const Duration(hours: 10)),
      ),
    ];
  }

  // ── Analytics mock data ──

  static const Map<String, double> categoryBreakdown = {
    'Food': 8575,
    'Transport': 5390,
    'Shopping': 4410,
    'Bills': 2940,
    'Entertainment': 1960,
    'Health': 1225,
    'Education': 0,
  };

  static const double totalMonthly = 24500;
  static const double totalWeekly = 6800;
  static const double totalDaily = 1240;
  static const double dailyAvg = 820;

  static const List<double> weeklyLineData = [520, 890, 430, 1100, 680, 950, 1240];
  static const List<double> monthlyBarData = [5200, 6800, 7100, 5400];
  static const double forecastTotal = 31000;
}

