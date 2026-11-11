import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/auth/domain/biometric_lock.dart';
import 'package:wallet_app/features/planning/domain/finance_answers.dart';
import 'package:wallet_app/features/planning/domain/spend_rules.dart';
import 'package:wallet_app/features/transactions/models/transaction.dart';

SpendEvent event(String type, num amount, DateTime date, {String status = 'POSTED', String currency = 'TND'}) {
  return SpendEvent(date: date, type: type, status: status, amount: amount, currency: currency);
}

void main() {
  test('home and assistant use the same month and exclude transfers', () {
    final now = DateTime(2026, 11, 10, 22);
    final events = [
      event('EXPENSE', 703.900, DateTime(2026, 11, 4)),
      event('TRANSFER_OUT', 890, DateTime(2026, 11, 6)),
      event('REFUND', 20, DateTime(2026, 11, 7)),
      event('INCOME', 100, DateTime(2026, 11, 2)),
      event('EXPENSE', 50, DateTime(2026, 11, 8), status: 'VOIDED'),
      event('EXPENSE', 40, DateTime(2026, 10, 31, 23, 30)),
    ];
    final flow = monthCashflow(events, now: now, currency: 'TND');
    expect(flow.expense, closeTo(703.900, 0.001));
    expect(flow.income, 100);
    expect(flow.window.start, DateTime(2026, 11, 1));
    expect(flow.window.end, DateTime(2026, 12, 1));
    num previousDebitRule = 0;
    for (final item in events.where((item) => item.status != 'VOIDED' && !item.date.isBefore(DateTime(2026, 11, 1)))) {
      if (item.type == 'EXPENSE' || item.type == 'PAYMENT' || item.type == 'TRANSFER_OUT') {
        previousDebitRule += item.amount;
      }
    }
    expect(previousDebitRule, closeTo(1593.900, 0.001));
    expect(flow.expense, isNot(previousDebitRule));
  });

  test('a timestamp is interpreted in local time before the month check', () {
    final parsed = MoneyTransaction.fromMap({
      'id': '1',
      'wallet_id': 'w',
      'transaction_type': 'EXPENSE',
      'amount': '12.500',
      'currency': 'TND',
      'transaction_date': '2026-10-31T23:30:00Z',
      'status': 'POSTED',
    });
    expect(parsed.date.isUtc, isFalse);
    final flow = monthCashflow(
      [parsed.toSpendEvent()],
      now: DateTime(2026, 11, 10),
      currency: 'TND',
    );
    final localMonth = periodWindow('monthly', DateTime(2026, 11, 10));
    expect(flow.expense, localMonth.contains(parsed.date) ? 12.500 : 0);
  });

  test('the assistant does not turn a loading state into zero spending', () {
    final loading = replyForLoad(RecordLoad.loading, null, 'Combien ai-je dépensé ce mois-ci ?', language: 'fr');
    expect(loading.definitive, isFalse);
    expect(loading.text, isNot(contains('pas encore')));

    final unloaded = answerQuestion(
      'Combien ai-je dépensé ce mois-ci ?',
      const FinanceFacts(
        spentThisMonth: null,
        largestCategory: null,
        largestCategoryAmount: null,
        currency: 'TND',
        previousWeekSpent: null,
        thisWeekSpent: null,
        weekComparable: false,
        loaded: false,
      ),
      language: 'fr',
    );
    expect(unloaded.answered, isFalse);
    expect(unloaded.text, contains('chargement'));

    final empty = answerQuestion(
      'Combien ai-je dépensé ce mois-ci ?',
      const FinanceFacts(
        spentThisMonth: 0,
        largestCategory: null,
        largestCategoryAmount: null,
        currency: 'TND',
        previousWeekSpent: 0,
        thisWeekSpent: 0,
        weekComparable: true,
      ),
      language: 'fr',
    );
    expect(empty.answered, isTrue);
    expect(empty.text, contains('pas encore'));

    final ready = replyForLoad(
      RecordLoad.ready,
      const FinanceFacts(
        spentThisMonth: 703.900,
        largestCategory: 'Food',
        largestCategoryAmount: 200,
        currency: 'TND',
        previousWeekSpent: 10,
        thisWeekSpent: 12,
        weekComparable: true,
      ),
      'Combien ai-je dépensé ce mois-ci ?',
      language: 'fr',
    );
    expect(ready.definitive, isTrue);
    expect(ready.text, contains('703.900 TND'));
    expect(classifyRecordFailure(Exception('SocketException')), RecordLoad.offline);
    expect(classifyRecordFailure(Exception('Not signed in')), RecordLoad.sessionExpired);
  });

  test('background locks again and a transient inactive state does not', () {
    final policy = BiometricLockPolicy();
    expect(policy.blocksFinancialContent(enabled: true, userId: 'user'), isTrue);
    policy.unlock(policy.epoch);
    expect(policy.blocksFinancialContent(enabled: true, userId: 'user'), isFalse);
    policy.apply(LockSignal.inactive);
    expect(policy.locked, isFalse);
    policy.apply(LockSignal.paused);
    expect(policy.locked, isTrue);
    expect(policy.blocksFinancialContent(enabled: false, userId: 'user'), isFalse);
    expect(policy.blocksFinancialContent(enabled: true, userId: null), isTrue);
    final started = policy.epoch;
    policy.apply(LockSignal.hidden);
    policy.unlock(started);
    expect(policy.locked, isTrue);
    policy.unlock(policy.epoch);
    expect(policy.locked, isFalse);
    policy.apply(LockSignal.resumed);
    expect(policy.locked, isFalse);
  });
}
