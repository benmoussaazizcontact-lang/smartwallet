import 'receipt_amounts.dart';

/// Receipt, invoice, or bank statement. Arabic invoices are detected by script
/// keywords, then still reviewed before anything is saved.
String documentKindOf(String text) {
  final folded = text.toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e');
  if (RegExp(r'releve|statement|كشف').hasMatch(folded)) return 'statement';
  if (RegExp(r'facture|invoice|فاتورة').hasMatch(folded)) return 'invoice';
  return 'receipt';
}

class ReceiptParseResult {
  const ReceiptParseResult({
    this.merchant,
    this.receiptNumber,
    this.date,
    this.total,
    this.currency,
    this.paymentMethod,
    this.tax,
    this.items = const [],
    this.arabicScriptSeen = false,
    this.documentKind = 'receipt',
    required this.rawText,
    required this.amountNeedsReview,
  });

  final String? merchant;
  final String? receiptNumber;
  final DateTime? date;
  final num? total;
  final String? currency;
  final String? paymentMethod;
  final num? tax;
  final List<String> items;
  final bool arabicScriptSeen;
  final String documentKind;
  final String rawText;

  /// True when no final payable amount beat subtotal, tax, discount, or change.
  final bool amountNeedsReview;
}

enum _AmountRole { netDue, totalTtc, total, paid, subtotal, tax, discount, change }

class _LabeledAmount {
  const _LabeledAmount({
    required this.role,
    required this.amount,
    required this.currency,
  });

  final _AmountRole role;
  final num amount;
  final String? currency;
}

class OcrParser {
  const OcrParser();

  static final _amountPattern = RegExp(
    r'(\d{1,3}(?:[ \u00A0\u202F]\d{3})+(?:[.,]\d{1,3})?|\d+(?:[.,]\d{1,3})?)',
  );

  ReceiptParseResult parse(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? receiptNumber;
    for (final line in lines) {
      receiptNumber ??= _receiptNumber(line);
    }

    String? merchant;
    var bestScore = 0;
    for (final line in lines) {
      if (_isJunkMerchant(line) || _receiptNumber(line) != null) continue;
      final score = _merchantScore(line);
      if (score > bestScore) {
        bestScore = score;
        merchant = line;
      }
    }

    final labeled = <_LabeledAmount>[];
    for (final line in lines) {
      final role = _roleOf(_fold(line));
      if (role == null) continue;
      final amountMatch = _amountPattern.allMatches(line).lastOrNull;
      if (amountMatch == null) continue;
      final currency = currencyCodeIn(line);
      final amount = parseReceiptAmount(amountMatch.group(1)!, currency: currency);
      if (amount == null) continue;
      labeled.add(_LabeledAmount(role: role, amount: amount, currency: currency));
    }

    final chosen = _chooseFinalAmount(labeled);
    final currency = chosen?.currency ?? _singleCurrency(lines);

    String? payment;
    final foldedBlob = _fold(text);
    if (RegExp(r'\b(card|carte|cb|visa|mastercard)\b').hasMatch(foldedBlob)) {
      payment = 'Card';
    } else if (RegExp(r'\b(cash|espece|especes)\b').hasMatch(foldedBlob)) {
      payment = 'Cash';
    } else if (RegExp(r'\b(cheque|check)\b').hasMatch(foldedBlob)) {
      payment = 'Cheque';
    }

    final tax = labeled.where((item) => item.role == _AmountRole.tax).firstOrNull?.amount;
    final items = <String>[];
    for (final line in lines) {
      if (_roleOf(_fold(line)) != null || line == merchant || _receiptNumber(line) != null) {
        continue;
      }
      final amountMatch = _amountPattern.firstMatch(line);
      if (amountMatch == null) continue;
      final name = line.replaceAll(amountMatch.group(0)!, '').trim();
      if (name.length < 2) continue;
      items.add(line);
      if (items.length == 12) break;
    }

    return ReceiptParseResult(
      merchant: merchant,
      receiptNumber: receiptNumber,
      date: _dateIn(text),
      total: chosen?.amount,
      currency: chosen == null ? currency : (chosen.currency ?? currency),
      paymentMethod: payment,
      tax: tax,
      items: items,
      arabicScriptSeen: RegExp(r'[\u0600-\u06FF]').hasMatch(text),
      documentKind: documentKindOf(text),
      rawText: text,
      amountNeedsReview: chosen == null,
    );
  }

  _LabeledAmount? _chooseFinalAmount(List<_LabeledAmount> labeled) {
    const rank = {
      _AmountRole.netDue: 4,
      _AmountRole.totalTtc: 3,
      _AmountRole.total: 2,
    };
    _LabeledAmount? best;
    var bestRank = 0;
    for (final item in labeled) {
      final itemRank = rank[item.role] ?? 0;
      if (itemRank > bestRank) {
        best = item;
        bestRank = itemRank;
      }
    }
    return best;
  }

  String? _singleCurrency(List<String> lines) {
    final codes = lines.map(currencyCodeIn).whereType<String>().toSet();
    if (codes.length == 1) return codes.single;
    return null;
  }

  DateTime? _dateIn(String text) {
    final blob = text.replaceAll('\n', ' ');
    final iso = RegExp(r'(20\d{2})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(blob);
    final dmy = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(blob);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    if (dmy == null) return null;
    final day = int.parse(dmy.group(1)!);
    final month = int.parse(dmy.group(2)!);
    var year = int.parse(dmy.group(3)!);
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  _AmountRole? _roleOf(String folded) {
    if (RegExp(r'net a payer|amount due|balance due').hasMatch(folded)) {
      return _AmountRole.netDue;
    }
    if (RegExp(r'sous[\s-]*total|sub[\s-]*total|total\s+ht|hors\s+taxe')
        .hasMatch(folded)) {
      return _AmountRole.subtotal;
    }
    if (RegExp(r'monnaie|change due|rendu').hasMatch(folded)) {
      return _AmountRole.change;
    }
    if (RegExp(r'\bremise\b|\bdiscount\b|\breduction\b').hasMatch(folded)) {
      return _AmountRole.discount;
    }
    if (RegExp(r'\btva\b|\bvat\b|\btax\b').hasMatch(folded)) {
      return _AmountRole.tax;
    }
    if (RegExp(r'montant paye|amount paid|montant regle|cash tendered')
        .hasMatch(folded)) {
      return _AmountRole.paid;
    }
    if (RegExp(r'total ttc|montant ttc|\bttc\b').hasMatch(folded)) {
      return _AmountRole.totalTtc;
    }
    if (RegExp(r'\bprix\b').hasMatch(folded) &&
        !RegExp(r'unitaire|unit price').hasMatch(folded)) {
      return _AmountRole.total;
    }
    if (RegExp(r'\btotal\b|\bmontant\b|\bamount\b').hasMatch(folded)) {
      return _AmountRole.total;
    }
    return null;
  }

  String? _receiptNumber(String line) {
    final match = RegExp(
      r'(?:n\s*[°ºo.]|numero|numéro)\s*[:.]?\s*(\d{4,})',
      caseSensitive: false,
    ).firstMatch(line);
    return match?.group(1);
  }

  int _merchantScore(String line) {
    var score = 10;
    if (RegExp(r'[A-Z]{3,}').hasMatch(line)) score += 20;
    if (RegExp(r'\b[A-Z]\.[A-Z]').hasMatch(line)) score += 10;
    final folded = _fold(line);
    if (RegExp(r'non garde|automobile').hasMatch(folded)) score -= 8;
    return score;
  }

  bool _isJunkMerchant(String line) {
    final folded = _fold(line);
    if (_roleOf(folded) != null) return true;
    if (RegExp(r'^(date|tel|phone|ticket|receipt|facture|invoice)\b')
        .hasMatch(folded)) {
      return true;
    }
    if (RegExp(r'^(card|carte|cash|espece|especes|cheque|visa|mastercard)$')
        .hasMatch(folded)) {
      return true;
    }
    if (_receiptNumber(line) != null && folded.replaceAll(RegExp(r'[^a-z]'), '').length <= 4) {
      return true;
    }
    if (RegExp(r'^\d').hasMatch(line)) return true;
    return false;
  }

  String _fold(String input) {
    const from = 'àáâäãåèéêëìíîïòóôöõùúûüýÿçñ';
    const to = 'aaaaaaeeeeiiiiooooouuuuyycn';
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }
}

extension on Iterable<RegExpMatch> {
  RegExpMatch? get lastOrNull {
    RegExpMatch? last;
    for (final match in this) {
      last = match;
    }
    return last;
  }
}
