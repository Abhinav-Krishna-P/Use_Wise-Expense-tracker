/// Represents a single category spending limit.
class SpendingLimitItem {
  final String category;
  final double limitAmount;
  final double spent;
  final String period; // 'daily', 'weekly', 'monthly'
  final DateTime periodStartedAt;

  const SpendingLimitItem({
    required this.category,
    required this.limitAmount,
    this.spent = 0,
    required this.period,
    required this.periodStartedAt,
  });

  double get remaining => (limitAmount - spent).clamp(0, limitAmount);
  double get usedPercent => limitAmount > 0 ? (spent / limitAmount).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spent >= limitAmount;

  factory SpendingLimitItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SpendingLimitItem(
      category: json['category'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      period: (json['period'] as String?) ?? 'monthly',
      periodStartedAt: json['periodStartedAt'] != null
          ? DateTime.parse(json['periodStartedAt'] as String)
          : now,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'limitAmount': limitAmount,
        'spent': spent,
        'period': period,
        'periodStartedAt': periodStartedAt.toIso8601String(),
      };

  SpendingLimitItem copyWith({
    String? category,
    double? limitAmount,
    double? spent,
    String? period,
    DateTime? periodStartedAt,
  }) {
    return SpendingLimitItem(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      periodStartedAt: periodStartedAt ?? this.periodStartedAt,
    );
  }
}

/// The full spending limits configuration.
class SpendingLimitConfig {
  final List<SpendingLimitItem> limits;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpendingLimitConfig({
    required this.limits,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpendingLimitConfig.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SpendingLimitConfig(
      limits: (json['limits'] as List<dynamic>? ?? const [])
          .map((e) {
            final item = Map<String, dynamic>.from(e as Map<String, dynamic>);
            item.putIfAbsent('period', () => (json['period'] as String?) ?? 'monthly');
            item.putIfAbsent(
              'periodStartedAt',
              () => (json['periodStartedAt'] as String?) ?? now.toIso8601String(),
            );
            return SpendingLimitItem.fromJson(item);
          })
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
    );
  }

  Map<String, dynamic> toJson() => {
        'limits': limits.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
