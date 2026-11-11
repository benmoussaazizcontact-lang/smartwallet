class TransactionDraft {
  const TransactionDraft({
    required this.amount,
    required this.currency,
    required this.type,
    required this.date,
    required this.description,
    this.categoryHint,
    this.merchant,
  });

  final num amount;
  final String currency;
  final String type;
  final DateTime date;
  final String description;
  final String? categoryHint;
  final String? merchant;
}

final _amountPattern = RegExp(
  r'(\d+(?:[.,]\d{1,3})?)\s*(tnd|dt|dinars?|دينار|eur|€|usd|\$)?',
  caseSensitive: false,
);

TransactionDraft? parseNaturalTransaction(String raw, {required DateTime now}) {
  final text = raw.trim();
  if (text.length < 4) return null;
  final match = _amountPattern.firstMatch(text);
  if (match == null) return null;
  final amount = num.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (amount == null || amount <= 0) return null;
  final token = (match.group(2) ?? '').toLowerCase();
  final currency = switch (token) {
    'eur' || '€' => 'EUR',
    'usd' || '\$' => 'USD',
    'tnd' || 'dt' || 'dinar' || 'dinars' || 'دينار' => 'TND',
    _ => text.toLowerCase().contains('euro')
        ? 'EUR'
        : text.toLowerCase().contains('dollar')
            ? 'USD'
            : 'TND',
  };
  final lower = text.toLowerCase();
  final income = RegExp(r'\b(received|reçu|recu|income|salaire|salary|استلمت)\b').hasMatch(lower);
  final date = _dateFrom(lower, now);
  return TransactionDraft(
    amount: amount,
    currency: currency,
    type: income ? 'INCOME' : 'EXPENSE',
    date: date,
    description: text,
    categoryHint: _categoryHint(lower),
    merchant: _merchant(lower),
  );
}

DateTime _dateFrom(String lower, DateTime now) {
  if (RegExp(r'yesterday|hier|أمس|امس').hasMatch(lower)) {
    return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  }
  if (RegExp(r'today|aujourd|\baujourdhui|اليوم').hasMatch(lower)) {
    return DateTime(now.year, now.month, now.day);
  }
  return DateTime(now.year, now.month, now.day);
}

String? _categoryHint(String lower) {
  const hints = {
    'restaurant': 'Restaurants',
    'resto': 'Restaurants',
    'food': 'Food',
    'café': 'Coffee',
    'cafe': 'Coffee',
    'taxi': 'Taxi',
    'transport': 'Transport',
    'essence': 'Fuel',
    'fuel': 'Fuel',
    'shopping': 'Shopping',
    'courses': 'Groceries',
    'grocery': 'Groceries',
    'مطعم': 'Restaurants',
  };
  for (final entry in hints.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

String? _merchant(String lower) {
  final at = RegExp(r'(?:at|chez|في)\s+([a-zA-Z0-9][\w &-]{1,40})').firstMatch(lower);
  return at?.group(1)?.trim();
}
