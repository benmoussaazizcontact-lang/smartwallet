import 'package:flutter/material.dart';

const walletTypeValues = [
  'CASH',
  'BANK_ACCOUNT',
  'CREDIT_CARD',
  'CRYPTO',
  'SAVINGS',
];

Map<String, Object?> walletInsertRow({
  required String userId,
  required String name,
  required String walletType,
  required String currency,
  required num initialBalance,
  num creditLimit = 0,
  String? cryptoSymbol,
  String? icon,
  String? color,
}) {
  return {
    'user_id': userId,
    'name': name.trim(),
    'wallet_type': walletType,
    'currency': currency,
    'initial_balance': initialBalance,
    'credit_limit': creditLimit,
    'crypto_symbol': cryptoSymbol,
    'icon': icon,
    'color': color,
  };
}

class WalletTypeStyle {
  const WalletTypeStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  static WalletTypeStyle of(String type) {
    return switch (type) {
      'CASH' => const WalletTypeStyle(
          label: 'Cash',
          icon: Icons.payments_outlined,
          color: Color(0xFF10B981),
        ),
      'BANK_ACCOUNT' => const WalletTypeStyle(
          label: 'Bank Account',
          icon: Icons.account_balance_outlined,
          color: Color(0xFF2563EB),
        ),
      'CREDIT_CARD' => const WalletTypeStyle(
          label: 'Credit Card',
          icon: Icons.credit_card,
          color: Color(0xFF8B5CF6),
        ),
      'CRYPTO' => const WalletTypeStyle(
          label: 'Crypto',
          icon: Icons.currency_bitcoin,
          color: Color(0xFFF59E0B),
        ),
      'SAVINGS' => const WalletTypeStyle(
          label: 'Savings',
          icon: Icons.savings_outlined,
          color: Color(0xFF14B8A6),
        ),
      _ => const WalletTypeStyle(
          label: 'Wallet',
          icon: Icons.account_balance_wallet_outlined,
          color: Color(0xFF2563EB),
        ),
    };
  }
}

class WalletBalance {
  const WalletBalance({
    required this.walletId,
    required this.userId,
    required this.name,
    required this.walletType,
    required this.currency,
    required this.initialBalance,
    required this.currentBalance,
    required this.creditLimit,
    required this.debt,
    this.availableCredit,
    this.cryptoSymbol,
    this.icon,
    this.color,
    required this.isArchived,
    required this.createdAt,
  });

  final String walletId;
  final String userId;
  final String name;
  final String walletType;
  final String currency;
  final num initialBalance;
  final num currentBalance;
  final num creditLimit;
  final num debt;
  final num? availableCredit;
  final String? cryptoSymbol;
  final String? icon;
  final String? color;
  final bool isArchived;
  final DateTime createdAt;

  WalletTypeStyle get style => WalletTypeStyle.of(walletType);

  Color get displayColor {
    final hex = color;
    if (hex != null && hex.length >= 7) {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    }
    return style.color;
  }

  String get typeLabel => style.label;

  factory WalletBalance.fromMap(Map<String, dynamic> map) {
    num n(Object? v) => v == null ? 0 : num.parse(v.toString());
    return WalletBalance(
      walletId: map['wallet_id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      walletType: map['wallet_type'] as String,
      currency: map['currency'] as String,
      initialBalance: n(map['initial_balance']),
      currentBalance: n(map['current_balance']),
      creditLimit: n(map['credit_limit']),
      debt: n(map['debt']),
      availableCredit:
          map['available_credit'] == null ? null : n(map['available_credit']),
      cryptoSymbol: map['crypto_symbol'] as String?,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isArchived: map['is_archived'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
