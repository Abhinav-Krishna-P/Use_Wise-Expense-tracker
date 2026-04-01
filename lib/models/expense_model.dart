class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;

  const ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
  });

  ExpenseModel copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
}

