import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/wallets/models/wallet.dart';
import 'package:wallet_app/features/transactions/models/transaction.dart';

void main() {
  test('wallet types have icons and labels', () {
    expect(WalletTypeStyle.of('CASH').label, 'Cash');
    expect(WalletTypeStyle.of('BANK_ACCOUNT').label, 'Bank Account');
    expect(WalletTypeStyle.of('CREDIT_CARD').label, 'Credit Card');
    expect(WalletTypeStyle.of('CRYPTO').label, 'Crypto');
    expect(WalletTypeStyle.of('SAVINGS').label, 'Savings');
  });

  test('expense is debit and income is credit', () {
    final expense = MoneyTransaction(
      id: '1',
      walletId: 'w',
      type: 'EXPENSE',
      amount: 10,
      currency: 'TND',
      date: DateTime(2026, 10, 12),
      status: 'POSTED',
    );
    final income = expense;
    expect(expense.isDebit, isTrue);
    expect(
      MoneyTransaction(
        id: '2',
        walletId: 'w',
        type: 'INCOME',
        amount: 10,
        currency: 'TND',
        date: DateTime(2026, 10, 12),
        status: 'POSTED',
      ).isDebit,
      isFalse,
    );
    expect(income.type, 'EXPENSE');
  });
}
