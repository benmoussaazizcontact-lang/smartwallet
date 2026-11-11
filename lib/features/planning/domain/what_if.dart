class CategorySpend {
  const CategorySpend({required this.name, required this.amount, required this.currency});

  final String name;
  final num amount;
  final String currency;
}

class WhatIfResult {
  const WhatIfResult({
    required this.monthlyReduction,
    required this.months,
    required this.savings,
    required this.currency,
  });

  final num monthlyReduction;
  final int months;
  final num savings;
  final String currency;
}

WhatIfResult simulateSavings({
  required num monthlyReduction,
  required int months,
  required String currency,
}) {
  final safeMonths = months < 0 ? 0 : months;
  final reduction = monthlyReduction < 0 ? 0 : monthlyReduction;
  return WhatIfResult(
    monthlyReduction: reduction,
    months: safeMonths,
    savings: reduction * safeMonths,
    currency: currency,
  );
}

class CutSuggestion {
  const CutSuggestion({
    required this.sufficient,
    required this.monthlyFreed,
    required this.lines,
    required this.currency,
  });

  final bool sufficient;
  final num monthlyFreed;
  final List<String> lines;
  final String currency;
}

/// Applies the caller's reduction rates to actual category spending.
/// Rates are fractions, for example 0.15 for 15 percent.
CutSuggestion suggestCuts({
  required List<CategorySpend> spends,
  required String currency,
  Map<String, num> rates = const {},
}) {
  final same = spends.where((row) => row.currency == currency && row.amount > 0).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  if (same.isEmpty) {
    return CutSuggestion(
      sufficient: false,
      monthlyFreed: 0,
      lines: const [],
      currency: currency,
    );
  }
  final applied = <String, num>{};
  if (rates.isEmpty) {
    if (same.isNotEmpty) applied[same.first.name] = 0.15;
    if (same.length > 1) applied[same[1].name] = 0.10;
  } else {
    applied.addAll(rates);
  }
  num freed = 0;
  final lines = <String>[];
  for (final row in same) {
    final rate = applied[row.name];
    if (rate == null || rate <= 0) continue;
    final amount = row.amount * rate;
    freed += amount;
    lines.add(row.name);
  }
  return CutSuggestion(
    sufficient: freed > 0,
    monthlyFreed: freed,
    lines: lines,
    currency: currency,
  );
}
