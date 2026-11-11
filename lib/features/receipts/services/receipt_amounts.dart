/// Parses a receipt amount using the currency written next to it.
///
/// TND uses three millime digits (`48,500` and `48.500` are 48.500).
/// EUR and USD use a two-digit fraction (`48,50` is 48.50). A three-digit
/// group on those currencies is a thousands separator (`1.250` is 1250),
/// not a decimal. When both separators appear, the rightmost one is the
/// decimal mark. Three grouped digits with no currency are left unresolved.
num? parseReceiptAmount(String raw, {String? currency}) {
  var text = raw
      .replaceAll('\u00A0', '')
      .replaceAll('\u202F', '')
      .replaceAll(' ', '');
  if (text.isEmpty || !RegExp(r'\d').hasMatch(text)) return null;

  final code = _currencyCode(currency);
  final hasDot = text.contains('.');
  final hasComma = text.contains(',');
  if (hasDot && hasComma) {
    final decimalIsDot = text.lastIndexOf('.') > text.lastIndexOf(',');
    final thousands = decimalIsDot ? ',' : '.';
    text = text.replaceAll(thousands, '');
    if (!decimalIsDot) text = text.replaceAll(',', '.');
    return num.tryParse(text);
  }

  if (!hasDot && !hasComma) return num.tryParse(text);

  final separator = hasDot ? '.' : ',';
  final parts = text.split(separator);
  if (parts.length > 2) {
    if (parts.skip(1).any((part) => part.length != 3)) return null;
    return num.tryParse(parts.join());
  }
  if (parts.length != 2 || parts[0].isEmpty || !RegExp(r'^\d+$').hasMatch(parts[1])) {
    return null;
  }
  final fraction = parts[1];
  if (fraction.length == 3) {
    if (code == 'TND') return num.tryParse('${parts[0]}.$fraction');
    if (code == 'EUR' || code == 'USD') return num.tryParse(parts.join());
    return null;
  }
  if (fraction.length <= 2) return num.tryParse('${parts[0]}.$fraction');
  return null;
}

String? _currencyCode(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return switch (raw.toUpperCase()) {
    'DT' || 'TND' => 'TND',
    '€' || 'EUR' => 'EUR',
    '\$' || 'USD' => 'USD',
    _ => raw.toUpperCase(),
  };
}

String? currencyCodeIn(String text) {
  final match = RegExp(
    r'(TND|EUR|USD|DT|€|\$)',
    caseSensitive: false,
  ).firstMatch(text);
  if (match != null) return _currencyCode(match.group(1));
  if (RegExp(r'\b(dinar|dinars)\b', caseSensitive: false).hasMatch(text)) {
    return 'TND';
  }
  if (RegExp(r'(^|[^A-Za-zÀ-ÿ])[dD]([^A-Za-zÀ-ÿ]|$)').hasMatch(text)) {
    return 'TND';
  }
  return null;
}

/// Shows millimes for TND (`3.000`) and cents for EUR/USD.
String formatReceiptAmount(num amount, String? currency) {
  final digits = currency == 'EUR' || currency == 'USD' ? 2 : 3;
  return amount.toStringAsFixed(digits);
}
