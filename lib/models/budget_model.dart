class FixedExpense {
  final String title;
  final double amount;

  const FixedExpense({required this.title, required this.amount});

  factory FixedExpense.fromJson(Map<String, dynamic> json) => FixedExpense(
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'title': title, 'amount': amount};
}

class BudgetPlan {
  final String id;
  final double monthlyIncome;
  final List<FixedExpense> fixedExpenses;
  final Map<String, String> questionAnswers;
  final String additionalInfo;
  final String selectedPlanType;
  final String selectedPlanName;
  final Map<String, double> planBreakdown;
  final double monthlyBudgetAmount;
  final DateTime createdAt;

  const BudgetPlan({
    required this.id,
    required this.monthlyIncome,
    required this.fixedExpenses,
    required this.questionAnswers,
    required this.additionalInfo,
    required this.selectedPlanType,
    required this.selectedPlanName,
    required this.planBreakdown,
    required this.monthlyBudgetAmount,
    required this.createdAt,
  });

  double get totalFixedExpenses =>
      fixedExpenses.fold(0.0, (sum, e) => sum + e.amount);

  factory BudgetPlan.fromJson(Map<String, dynamic> json) => BudgetPlan(
        id: json['id'] as String? ?? '',
        monthlyIncome: (json['monthlyIncome'] as num).toDouble(),
        fixedExpenses: (json['fixedExpenses'] as List<dynamic>)
            .map((e) => FixedExpense.fromJson(e as Map<String, dynamic>))
            .toList(),
        questionAnswers:
            Map<String, String>.from(json['questionAnswers'] as Map),
        additionalInfo: json['additionalInfo'] as String? ?? '',
        selectedPlanType: json['selectedPlanType'] as String,
        selectedPlanName: json['selectedPlanName'] as String,
        planBreakdown: (json['planBreakdown'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        monthlyBudgetAmount: (json['monthlyBudgetAmount'] as num).toDouble(),
        createdAt: json['createdAt'] is DateTime
            ? json['createdAt'] as DateTime
            : DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'monthlyIncome': monthlyIncome,
        'fixedExpenses': fixedExpenses.map((e) => e.toJson()).toList(),
        'questionAnswers': questionAnswers,
        'additionalInfo': additionalInfo,
        'selectedPlanType': selectedPlanType,
        'selectedPlanName': selectedPlanName,
        'planBreakdown': planBreakdown,
        'monthlyBudgetAmount': monthlyBudgetAmount,
        'createdAt': createdAt.toIso8601String(),
      };
}
