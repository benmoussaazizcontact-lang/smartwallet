import '../../planning/domain/spend_rules.dart';

class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.currency,
    this.description,
    this.merchant,
    required this.date,
    required this.status,
    this.latitude,
    this.longitude,
    this.categoryName,
  });

  final String id;
  final String walletId;
  final String? categoryId;
  final String type;
  final num amount;
  final String currency;
  final String? description;
  final String? merchant;
  final DateTime date;
  final String status;
  final num? latitude;
  final num? longitude;
  final String? categoryName;

  bool get isDebit =>
      type == 'EXPENSE' || type == 'PAYMENT' || type == 'TRANSFER_OUT';

  /// Shared cash-flow row. Transfers stay visible in the activity list and
  /// stay out of income and expense totals.
  SpendEvent toSpendEvent() {
    return SpendEvent(
      date: date,
      type: type,
      status: status,
      amount: amount,
      currency: currency,
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
  bool get isVoided => status == 'VOIDED';
  bool get hasLocation => latitude != null && longitude != null;

  factory MoneyTransaction.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];
    return MoneyTransaction(
      id: map['id'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      type: (map['transaction_type'] as String?) ?? 'EXPENSE',
      amount: num.parse(map['amount'].toString()),
      currency: map['currency'] as String,
      description: map['description'] as String?,
      merchant: map['merchant'] as String?,
      date: DateTime.parse(
        (map['transaction_date'] as String?) ?? map['created_at'] as String,
      ).toLocal(),
      status: (map['status'] as String?) ?? 'POSTED',
      latitude: map['latitude'] == null ? null : num.parse(map['latitude'].toString()),
      longitude:
          map['longitude'] == null ? null : num.parse(map['longitude'].toString()),
      categoryName: map['category_name'] as String? ??
          (category is Map<String, dynamic> ? category['name'] as String? : null),
    );
  }

  factory MoneyTransaction.fromTransfer(Map<String, dynamic> map, {required bool outgoing}) {
    return MoneyTransaction(
      id: map['id'] as String,
      walletId: outgoing ? map['from_wallet_id'] as String : map['to_wallet_id'] as String,
      type: outgoing ? 'TRANSFER_OUT' : 'TRANSFER',
      amount: num.parse(map['amount'].toString()),
      currency: map['currency'] as String,
      description: map['description'] as String? ?? 'Transfer',
      date: DateTime.parse(map['created_at'] as String).toLocal(),
      status: 'POSTED',
    );
  }
}

class TransactionFilters {
  const TransactionFilters({
    this.query,
    this.type,
    this.walletId,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
    this.from,
    this.to,
  });

  final String? query;
  final String? type;
  final String? walletId;
  final String? categoryId;
  final num? minAmount;
  final num? maxAmount;
  final DateTime? from;
  final DateTime? to;

  TransactionFilters copyWith({
    String? query,
    String? type,
    String? walletId,
    String? categoryId,
    num? minAmount,
    num? maxAmount,
    DateTime? from,
    DateTime? to,
    bool clearType = false,
    bool clearWallet = false,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return TransactionFilters(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
    );
  }
}
