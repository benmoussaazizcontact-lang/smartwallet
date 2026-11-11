import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/planning/domain/question_engine.dart';
import 'package:wallet_app/features/planning/domain/spend_rules.dart';

void main() {
  final now = DateTime(2026, 11, 6);
  final ledger = _ledger();

  AssistantTurn ask(String question, [TalkContext context = const TalkContext()]) {
    return answerFinance(question, ledger, context: context, language: 'fr', now: now);
  }

  test('arabizi digits inside words are not amounts', () {
    final understood = understandQuestion('3andi 300 dinar');
    expect(understood.amount, 300);
    expect(understandQuestion('kadech 3andi flouss').amount, isNull);
    expect(understandQuestion('ch7al sraft').amount, isNull);
  });

  test('tunisian latin, arabizi, and typos resolve the same intents', () {
    for (final question in [
      'kadech andi flouss',
      'kadech 3andi flous',
      '9adech 3andi flouss',
      'ch7al 3andi flous',
      'kadech andi flousss',
      '9adech 3ndi flos',
    ]) {
      final turn = ask(question);
      expect(turn.intent, AssistantIntent.walletBalance, reason: question);
      expect(turn.text, contains('1500.000 TND'));
      expect(turn.text, contains('3andek'));
    }

    final week = ask('kadech sraft joma hethi');
    expect(week.intent, AssistantIntent.spendingTotal);
    expect(week.text, contains('Jem3a hedhi'));
    expect(week.text, contains('395.000 TND'));
    expect(ask('9adech srafet jom3a hethi').text, contains('395.000 TND'));
    expect(ask('kadech sraft jma hdhi').text, contains('395.000 TND'));

    final food = ask('9adech sraft fel makla');
    expect(food.text, contains('120.000 TND'));
    expect(food.text, contains('80.000 TND'));
    final previous = ask('w chhar eli fet', food.context);
    expect(previous.text, contains('200.000 TND'));
    expect(previous.text, contains('50.000 TND'));

    final transport = ask('kadech sraft fel transport');
    expect(transport.text, contains('45.000 TND'));
    expect(ask('w joma hethi', transport.context).text, contains('45.000 TND'));
    expect(ask('w chhar eli fet', transport.context).text, contains('30.000 TND'));
  });

  test('arabic and mixed questions use recorded amounts', () {
    final arabicSpend = ask('كم أنفقت هذا الشهر؟');
    expect(arabicSpend.text, contains('810.000 TND'));
    expect(arabicSpend.text, contains('هذا الشهر'));

    final arabicBalance = ask('كم عندي مال؟');
    expect(arabicBalance.intent, AssistantIntent.walletBalance);
    expect(arabicBalance.text, contains('1500.000 TND'));

    expect(ask('قداش عندي فلوس').text, contains('1500.000 TND'));
    expect(ask('قداش صرفت الجمعة هاذي').text, contains('395.000 TND'));
    expect(ask('combien jai depense food mois').text, contains('120.000 TND'));
    expect(ask('how much spend transport').intent, AssistantIntent.spendingByCategory);
    expect(ask('how much spend transport').text, contains('45.000 TND'));
  });

  test('a vague question is not turned into an amount', () {
    final turn = ask('chnowa');
    expect(turn.intent, AssistantIntent.unknown);
    expect(turn.text, isNot(contains('810.000')));
  });

  test('periods stay half-open around the local day', () {
    final today = _windowForTest('today', now);
    expect(today.contains(DateTime(2026, 11, 6, 23)), isTrue);
    expect(today.contains(DateTime(2026, 11, 7)), isFalse);
    final yesterday = _windowForTest('yesterday', now);
    expect(yesterday.contains(DateTime(2026, 11, 5, 12)), isTrue);
    expect(yesterday.contains(DateTime(2026, 11, 6)), isFalse);
  });

  testWidgets('an arabic answer keeps right-to-left direction without reversing digits', (tester) async {
    const amount = '1500.000 TND';
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Text('رصيدك $amount', textDirection: TextDirection.rtl),
      ),
    ));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.textDirection, TextDirection.rtl);
    expect(text.data, contains('1500.000'));
    expect(text.data, isNot(contains('000.0051')));
  });
}

PeriodWindow _windowForTest(String period, DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  if (period == 'today') return PeriodWindow(day, day.add(const Duration(days: 1)));
  return PeriodWindow(day.subtract(const Duration(days: 1)), day);
}

AssistantLedger _ledger() {
  SpendEvent row(int day, String type, num amount, String category, {String status = 'POSTED', int month = 11}) {
    return SpendEvent(
      date: DateTime(2026, month, day),
      type: type,
      status: status,
      amount: amount,
      currency: 'TND',
      categoryId: category,
      categoryName: category,
    );
  }

  return AssistantLedger(
    events: [
      row(1, 'EXPENSE', 400, 'Loyer'),
      row(1, 'INCOME', 2000, 'Salaire'),
      row(1, 'EXPENSE', 15, 'Abonnements'),
      row(2, 'EXPENSE', 120, 'Restaurants'),
      row(2, 'EXPENSE', 999, 'Restaurants', status: 'VOIDED'),
      row(2, 'TRANSFER', 890, 'Virement'),
      row(3, 'EXPENSE', 80, 'Groceries'),
      row(3, 'REFUND', 50, 'Restaurants'),
      row(4, 'EXPENSE', 45, 'Transport'),
      row(5, 'EXPENSE', 60, 'Loisirs'),
      row(6, 'EXPENSE', 90, 'Shopping'),
      row(5, 'EXPENSE', 200, 'Restaurants', month: 10),
      row(6, 'EXPENSE', 30, 'Transport', month: 10),
      row(7, 'EXPENSE', 50, 'Groceries', month: 10),
    ],
    currency: 'TND',
    wallets: const [
      AssistantWallet(name: 'Banque', currency: 'TND', balance: 1500, type: 'BANK_ACCOUNT'),
    ],
  );
}
