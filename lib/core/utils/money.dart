import 'package:intl/intl.dart';

import '../constants/currencies.dart';
import '../../l10n/generated/app_localizations.dart';

class Money {
  Money._();

  static final _amountPattern = RegExp(r'^\d+([.,]\d{1,3})?$');

  static num? tryParse(String raw) {
    final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return num.tryParse(normalized);
  }

  static String? validate(String raw, {int maxScale = 3, AppLocalizations? l10n}) {
    final normalized = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (normalized.isEmpty) return l10n?.amountRequired ?? 'Montant requis';
    if (!_amountPattern.hasMatch(normalized)) {
      return l10n?.amountInvalid ?? 'Format de montant invalide';
    }
    final value = num.tryParse(normalized);
    if (value == null || value <= 0) {
      return l10n?.amountPositive ?? 'Le montant doit être positif';
    }
    if (value > 999999999999999.999) {
      return l10n?.amountTooHigh ?? 'Montant trop élevé';
    }
    final parts = normalized.split('.');
    if (parts.length == 2 && parts[1].length > maxScale) {
      return l10n?.maxDecimals(maxScale) ?? 'Maximum $maxScale décimales';
    }
    final rounded = (value * 1000).round() / 1000;
    if ((rounded - value).abs() > 0.0000001) {
      return l10n?.maxDecimals(3) ?? 'Maximum 3 décimales';
    }
    return null;
  }

  /// Visual formatting only. Does not change the stored numeric value.
  static String format(num amount, String currencyCode, {String? locale}) {
    final currency = Currencies.of(currencyCode);
    final loc = locale ?? Intl.defaultLocale ?? 'en';
    final formatter = NumberFormat.decimalPatternDigits(
      locale: loc,
      decimalDigits: currency.fractionDigits,
    );
    final formatted = formatter.format(amount);
    return '\u2066$formatted\u00A0${currency.code}\u2069';
  }

  static num round3(num value) => (value * 1000).round() / 1000;
}
