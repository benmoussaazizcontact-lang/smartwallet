class RecurringItem {
  const RecurringItem({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.frequency,
    required this.nextExecutionDate,
    required this.isActive,
    this.description,
    this.lastExecutedOn,
  });

  final String id;
  final String walletId;
  final String? categoryId;
  final String type;
  final num amount;
  final String frequency;
  final DateTime nextExecutionDate;
  final bool isActive;
  final String? description;
  final DateTime? lastExecutedOn;

  factory RecurringItem.fromMap(Map<String, dynamic> map) {
    return RecurringItem(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      type: map['transaction_type'] as String,
      amount: num.parse(map['amount'].toString()),
      frequency: map['frequency'] as String,
      nextExecutionDate: DateTime.parse(map['next_execution_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      description: map['description'] as String?,
      lastExecutedOn: map['last_executed_on'] == null
          ? null
          : DateTime.parse(map['last_executed_on'] as String),
    );
  }
}
