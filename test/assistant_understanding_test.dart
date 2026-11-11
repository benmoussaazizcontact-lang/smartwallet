import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/planning/domain/finance_answers.dart';
import 'package:wallet_app/features/planning/domain/question_engine.dart';
import 'package:wallet_app/features/planning/domain/spend_rules.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  final ledger = _ledger();

  AssistantTurn ask(String question, [TalkContext context = const TalkContext(), String language = 'fr']) {
    return answerFinance(question, ledger, context: context, language: language, now: now);
  }

  test('typos, dialects, and follow-ups use the recorded categories', () {
    final food = ask('combient j ai depense pour le food ce moi');
    expect(food.intent, AssistantIntent.clarify);
    expect(food.text, contains('Restaurants'));
    expect(food.text, contains('120.000 TND'));
    expect(food.text, contains('Groceries'));
    expect(food.text, contains('80.000 TND'));
    expect(food.text.toLowerCase(), isNot(contains('reformulez')));

    expect(ask('combien j\'ai dépensé en nourriture ce mois').text, contains('Restaurants'));
    expect(ask('ch7al sarraft fel makla').text, contains('Groceries'));
    expect(ask('how much did i spend on food this month', const TalkContext(), 'en').text, contains('Restaurants'));
    expect(ask('كم أنفقت على النقل هذا الشهر', const TalkContext(), 'ar').text, contains('45.000 TND'));

    final transport = ask('comment du depense en transport pour ce mois');
    expect(transport.text, contains('45.000 TND'));
    expect(transport.text, contains('Transport'));
    expect(transport.text, isNot(contains('890')));

    final lastMonth = ask('et le mois dernier', transport.context);
    expect(lastMonth.text, contains('30.000 TND'));
    expect(lastMonth.text, contains('Transport'));

    final why = ask('pourquoi', lastMonth.context);
    expect(why.text, contains('Transport'));
    expect(why.text, contains('30.000 TND'));
    expect(why.text, contains('45.000 TND'));

    final lastWeek = ask('et la semaine derniere ?', transport.context);
    expect(lastWeek.text, contains('45.000 TND'));
    expect(lastWeek.text.toLowerCase(), contains('semaine'));
  });

  test('a savings plan never cuts more than the observed category', () {
    final plan = ask('comment economiser 300 tnd');
    expect(plan.simulation, isTrue);
    expect(plan.text.toLowerCase(), contains('simulation'));
    expect(plan.cuts, isNotEmpty);
    num reduced = 0;
    for (final cut in plan.cuts) {
      expect(cut.reduction, lessThanOrEqualTo(cut.observed + 0.001));
      expect(cut.category, isNot('Loyer'));
      reduced += cut.reduction;
    }
    expect(reduced, closeTo(300, 0.001));
    expect(plan.text, contains('300.000 TND'));

    final horizon = ask('je veux economiser 500 dinars en 3 mois');
    expect(horizon.simulation, isTrue);
    expect(horizon.text, contains('3 mois'));
    final monthly = horizon.cuts.fold<num>(0, (sum, cut) => sum + cut.reduction);
    expect(monthly, closeTo(166.667, 0.001));
    for (final cut in horizon.cuts) {
      expect(cut.reduction, lessThanOrEqualTo(cut.observed + 0.001));
    }

    final advice = ask('comment reduire mes depenses');
    expect(advice.simulation, isTrue);
    expect(advice.cuts.every((cut) => cut.reduction <= cut.observed + 0.001), isTrue);
    expect(ask('pk je depense trop').text.toLowerCase(), contains('simulation'));
  });

  test('balances, budgets, goals, and purchases stay inside recorded numbers', () {
    expect(ask('combien reste dans mon compte').text, contains('1500.000 TND'));
    expect(ask('combien reste dans mon wallet').text, contains('1500.000 TND'));
    expect(ask('quelle categorie me coute le plus').text, contains('Loyer'));
    expect(ask('quelle categorie me coute le plus').text, contains('400.000 TND'));

    final compare = ask('j\'ai depensé plus que le mois dernier ?');
    expect(compare.text, contains('810.000 TND'));
    expect(compare.text, contains('385.000 TND'));
    expect(compare.text.toLowerCase(), contains('plus'));

    final purchase = ask('est ce que je peux acheter un telephone a 2000 tnd');
    expect(purchase.simulation, isTrue);
    expect(purchase.text, contains('2000.000 TND'));
    expect(purchase.text, contains('1500.000 TND'));
    expect(purchase.text.toLowerCase(), contains('pas couvert'));

    expect(ask('quel est mon revenu ce mois').text, contains('2000.000 TND'));
    expect(ask('quel est mon revenu ce mois').text, isNot(contains('2890')));
    expect(ask('ou en est mon budget').text, contains('150.000 TND'));
    expect(ask('ou en est mon objectif').text, contains('Vacances'));
    expect(ask('ou en est mon objectif').text, contains('800.000 TND'));
    expect(ask('resume mes investissements').text.toLowerCase(), contains('manuel'));
    expect(ask('quels sont mes abonnements').text, contains('Netflix'));
    expect(ask('explique les anomalies').text, contains('Loisirs'));
    expect(ask('fais une prevision de cashflow').text, contains('insufficient_history'));
  });

  test('forty formulations stay on a known financial intent', () {
    const questions = [
      'combient j ai depense pour le food ce moi',
      'combien j\'ai dépensé en nourriture ce mois',
      'ch7al sarraft fel makla',
      'comment du depense en transport pour ce mois',
      'pk je depense trop',
      'comment economiser 300 tnd',
      'je veux economiser 500 dinars en 3 mois',
      'combien reste dans mon compte',
      'quelle categorie me coute le plus',
      'j\'ai depensé plus que le mois dernier ?',
      'est ce que je peux acheter un telephone a 2000 tnd',
      'comment reduire mes depenses',
      'et la semaine derniere ?',
      'et le mois dernier',
      'pourquoi',
      'how much did i spend on food this month',
      'how much did i spen on transport this month',
      'what is my income this month',
      'what is my wallet balance',
      'how is my budget',
      'كم أنفقت على النقل هذا الشهر',
      'quel est mon revenu ce mois',
      'ou en est mon budget',
      'ou en est mon objectif',
      'resume mes investissements',
      'quels sont mes abonnements',
      'explique les anomalies',
      'fais une prevision de cashflow',
      'depense taxi ce mois',
      'courses du mois',
      'loyer ce mois',
      'ai je depense plus ce mois',
      'show my largest category',
      'can i afford a phone at 2000 tnd',
      'save 100 tnd',
      'why do i spend too much',
      'bus ce moi',
      'metro this month',
      'solde du portefeuille',
      'progression de mon objectif',
      'gains de mon investissement',
      'detecte un abonnement',
    ];
    expect(questions.length, greaterThanOrEqualTo(40));
    for (final question in questions) {
      final turn = ask(question);
      expect(turn.intent, isNot(AssistantIntent.unknown), reason: question);
      expect(turn.text, isNot(contains('999')));
      expect(turn.text, isNot(contains('890')));
    }
  });

  test('empty history, incomplete loading, ambiguity, and network failures', () {
    final empty = answerFinance(
      'combien j ai depense ce mois',
      const AssistantLedger(events: [], currency: 'TND'),
      language: 'fr',
      now: now,
    );
    expect(empty.answered, isTrue);
    expect(empty.text, contains('0.000'));
    expect(empty.text, contains('chargement'));

    final loading = answerFinance(
      'combient j ai depense pour le food ce moi',
      const AssistantLedger(events: [], currency: 'TND', loaded: false),
      language: 'fr',
      now: now,
    );
    expect(loading.answered, isFalse);
    expect(loading.text, contains('chargement'));
    expect(loading.text, isNot(contains('0.000')));

    final unclear = answerFinance('alors ?', ledger, language: 'fr', now: now);
    expect(unclear.intent, AssistantIntent.unknown);

    final offline = replyForLoad(RecordLoad.offline, null, 'combien j ai depense', language: 'fr');
    expect(offline.definitive, isFalse);
    expect(offline.text, contains('Réseau'));
    expect(offline.text, isNot(contains('703')));

    final expired = replyForLoad(RecordLoad.sessionExpired, null, 'combien', language: 'en');
    expect(expired.text.toLowerCase(), contains('session'));
  });
}

AssistantLedger _ledger() {
  SpendEvent row(
    int year,
    int month,
    int day,
    String type,
    num amount,
    String category, {
    String status = 'POSTED',
    String? merchant,
  }) {
    return SpendEvent(
      date: DateTime(year, month, day),
      type: type,
      status: status,
      amount: amount,
      currency: 'TND',
      categoryId: category,
      categoryName: category,
      merchant: merchant,
    );
  }

  return AssistantLedger(
    events: [
      row(2026, 11, 1, 'EXPENSE', 400, 'Loyer'),
      row(2026, 11, 1, 'INCOME', 2000, 'Salaire'),
      row(2026, 11, 1, 'EXPENSE', 15, 'Abonnements', merchant: 'Netflix'),
      row(2026, 11, 2, 'EXPENSE', 120, 'Restaurants'),
      row(2026, 11, 2, 'EXPENSE', 999, 'Restaurants', status: 'VOIDED'),
      row(2026, 11, 2, 'TRANSFER', 890, 'Virement'),
      row(2026, 11, 3, 'EXPENSE', 80, 'Groceries'),
      row(2026, 11, 3, 'REFUND', 50, 'Restaurants'),
      row(2026, 11, 4, 'EXPENSE', 45, 'Transport'),
      row(2026, 11, 5, 'EXPENSE', 60, 'Loisirs'),
      row(2026, 11, 6, 'EXPENSE', 90, 'Shopping'),
      row(2026, 10, 5, 'EXPENSE', 200, 'Restaurants'),
      row(2026, 10, 5, 'EXPENSE', 15, 'Abonnements', merchant: 'Netflix'),
      row(2026, 10, 6, 'EXPENSE', 30, 'Transport'),
      row(2026, 10, 7, 'EXPENSE', 50, 'Groceries'),
      row(2026, 10, 8, 'EXPENSE', 20, 'Loisirs'),
      row(2026, 10, 9, 'EXPENSE', 70, 'Shopping'),
      row(2026, 9, 5, 'EXPENSE', 15, 'Abonnements', merchant: 'Netflix'),
    ],
    currency: 'TND',
    wallets: const [
      AssistantWallet(name: 'Banque', currency: 'TND', balance: 1500, type: 'BANK_ACCOUNT'),
    ],
    goals: const [
      AssistantGoalView(name: 'Vacances', target: 1000, saved: 200, currency: 'TND'),
    ],
    budgets: const [
      AssistantBudgetView(name: 'Restaurants', limit: 150, spent: 120, currency: 'TND', period: 'monthly', categoryName: 'Restaurants'),
    ],
    assets: const [
      AssistantAssetView(label: 'BTC', currency: 'TND', manualPrice: true, gain: 12),
    ],
  );
}
