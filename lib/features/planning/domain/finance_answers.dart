import 'question_engine.dart';

class FinanceFacts {
  const FinanceFacts({
    required this.spentThisMonth,
    required this.largestCategory,
    required this.largestCategoryAmount,
    required this.currency,
    required this.previousWeekSpent,
    required this.thisWeekSpent,
    required this.weekComparable,
    this.goalName,
    this.goalGap,
    this.loaded = true,
    this.hold,
  });

  final num? spentThisMonth;
  final String? largestCategory;
  final num? largestCategoryAmount;
  final String currency;
  final num? previousWeekSpent;
  final num? thisWeekSpent;
  final bool weekComparable;
  final String? goalName;
  final num? goalGap;
  final bool loaded;
  final String? hold;

  bool get hasMonth => loaded && spentThisMonth != null;
}

enum RecordLoad { loading, ready, empty, failed, offline, sessionExpired }

/// A financial sentence is definitive only after the records have loaded.
class AssistantReply {
  const AssistantReply({required this.definitive, required this.text, this.kind});

  final bool definitive;
  final String text;
  final AnswerKind? kind;
}

AssistantReply replyForLoad(
  RecordLoad load,
  FinanceFacts? facts,
  String question, {
  required String language,
}) {
  final fr = language.startsWith('fr');
  final ar = language.startsWith('ar');
  switch (load) {
    case RecordLoad.loading:
      return AssistantReply(
        definitive: false,
        text: ar
            ? 'السجلات ما زالت تُحمَّل.'
            : fr
                ? 'Les enregistrements sont encore en cours de chargement.'
                : 'Your records are still loading.',
      );
    case RecordLoad.failed:
      return AssistantReply(
        definitive: false,
        text: ar
            ? 'تعذر تحميل السجلات.'
            : fr
                ? 'Les enregistrements n’ont pas pu être chargés.'
                : 'The records could not be loaded.',
      );
    case RecordLoad.offline:
      return AssistantReply(
        definitive: false,
        text: ar
            ? 'الشبكة غير متاحة.'
            : fr
                ? 'Réseau indisponible.'
                : 'Network unavailable.',
      );
    case RecordLoad.sessionExpired:
      return AssistantReply(
        definitive: false,
        text: ar
            ? 'انتهت الجلسة. سجّل الدخول مرة أخرى.'
            : fr
                ? 'La session a expiré. Reconnectez-vous.'
                : 'Your session has expired. Sign in again.',
      );
    case RecordLoad.ready:
    case RecordLoad.empty:
      final answer = answerQuestion(
        question,
        facts ??
            FinanceFacts(
              spentThisMonth: 0,
              largestCategory: null,
              largestCategoryAmount: null,
              currency: 'TND',
              previousWeekSpent: 0,
              thisWeekSpent: 0,
              weekComparable: false,
            ),
        language: language,
      );
      return AssistantReply(definitive: answer.answered, text: answer.text, kind: answer.kind);
  }
}

RecordLoad classifyRecordFailure(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('jwt') || text.contains('not signed') || text.contains('unauthenticated') || text.contains('session')) {
    return RecordLoad.sessionExpired;
  }
  if (text.contains('socket') || text.contains('network') || text.contains('réseau') || text.contains('failed host')) {
    return RecordLoad.offline;
  }
  return RecordLoad.failed;
}

enum AnswerKind { monthSpend, topCategory, weekChange, goalGap, categorySpend, analysis, clarify, unknown }

AnswerKind classifyQuestion(String question) {
  return answerKindFor(understandQuestion(question).intent);
}

AnswerKind answerKindFor(AssistantIntent intent) {
  return switch (intent) {
    AssistantIntent.spendingTotal => AnswerKind.monthSpend,
    AssistantIntent.spendingByCategory => AnswerKind.categorySpend,
    AssistantIntent.topExpenseCategories => AnswerKind.topCategory,
    AssistantIntent.spendingComparison => AnswerKind.weekChange,
    AssistantIntent.goalProgress => AnswerKind.goalGap,
    AssistantIntent.clarify => AnswerKind.clarify,
    AssistantIntent.unknown => AnswerKind.unknown,
    _ => AnswerKind.analysis,
  };
}

class VerifiedAnswer {
  const VerifiedAnswer({required this.answered, required this.text, required this.kind});

  final bool answered;
  final String text;
  final AnswerKind kind;
}

VerifiedAnswer answerQuestion(String question, FinanceFacts facts, {required String language, TalkContext context = const TalkContext()}) {
  final turn = answerFinance(
    question,
    AssistantLedger(
      events: const [],
      currency: facts.currency,
      loaded: facts.loaded,
      hold: facts.hold,
      aggregateSpent: facts.spentThisMonth,
      aggregateTopCategory: facts.largestCategory,
      aggregateTopAmount: facts.largestCategoryAmount,
      aggregateThisWeek: facts.thisWeekSpent,
      aggregateLastWeek: facts.previousWeekSpent,
      weekComparable: facts.weekComparable,
      aggregateOnly: true,
      goals: facts.goalName == null || facts.goalGap == null
          ? const []
          : [
              AssistantGoalView(
                name: facts.goalName!,
                target: facts.goalGap! + 0,
                saved: 0,
                currency: facts.currency,
              ),
            ],
    ),
    context: context,
    language: language,
  );
  return VerifiedAnswer(answered: turn.answered, text: turn.text, kind: answerKindFor(turn.intent));
}


bool narrativeMatchesFacts(String narrative, FinanceFacts facts) {
  if (!facts.hasMonth) return !RegExp(r'\d').hasMatch(narrative);
  final spent = facts.spentThisMonth!.toStringAsFixed(3);
  return narrative.contains(spent) || narrative.contains(facts.spentThisMonth!.toString());
}
