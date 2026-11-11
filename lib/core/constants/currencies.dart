class SupportedCurrency {
  const SupportedCurrency({
    required this.code,
    required this.fractionDigits,
    required this.label,
  });

  final String code;
  final int fractionDigits;
  final String label;
}

class Currencies {
  Currencies._();

  static const tnd = SupportedCurrency(
    code: 'TND',
    fractionDigits: 3,
    label: 'Dinar tunisien',
  );
  static const eur = SupportedCurrency(
    code: 'EUR',
    fractionDigits: 2,
    label: 'Euro',
  );
  static const usd = SupportedCurrency(
    code: 'USD',
    fractionDigits: 2,
    label: 'Dollar US',
  );

  static const all = [tnd, eur, usd];

  static SupportedCurrency of(String code) {
    return all.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => SupportedCurrency(
        code: code.toUpperCase(),
        fractionDigits: 2,
        label: code.toUpperCase(),
      ),
    );
  }
}
