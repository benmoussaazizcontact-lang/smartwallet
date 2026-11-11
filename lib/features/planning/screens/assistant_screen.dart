import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../wallets/models/wallet.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../../intelligence/domain/advanced_finance.dart';
import '../../intelligence/domain/studio.dart';
import '../../intelligence/repositories/insight_store.dart';
import '../../intelligence/screens/insights_screen.dart';
import '../../intelligence/voice/voice_assistant.dart';
import '../domain/budget_math.dart';
import '../domain/finance_answers.dart';
import '../domain/investment_math.dart';
import '../domain/nl_transaction.dart';
import '../domain/question_engine.dart';
import '../domain/spend_rules.dart';
import '../repositories/budget_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/investment_repository.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({String role, String text, bool simulation})>[];
  TalkContext _context = const TalkContext();
  TransactionDraft? _draft;
  PreparedAction? _pending;
  num? _pendingAmount;
  bool _busy = false;
  String? _note;
  String? _retryQuestion;
  int _generation = 0;
  final _voice = VoiceAssistant();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  FinanceFacts _facts(BudgetHome home, {required String mixedCurrency}) {
    final goals = ref.read(goalsProvider).asData?.value ?? [];
    final now = DateTime.now();
    final month = periodWindow('monthly', now);
    final currencies = {
      for (final event in home.events)
        if (countsAsSpending(event) && month.contains(event.date.toLocal())) event.currency,
    };
    if (currencies.length > 1) {
      return FinanceFacts(
        spentThisMonth: null,
        largestCategory: null,
        largestCategoryAmount: null,
        currency: 'TND',
        previousWeekSpent: null,
        thisWeekSpent: null,
        weekComparable: false,
        hold: mixedCurrency,
      );
    }
    final currency = currencies.isEmpty
        ? (goals.isNotEmpty ? goals.first.currency : 'TND')
        : currencies.first;
    final spent = sumSpending(home.events, window: month, currency: currency);
    final byCategory = spendingByCategory(home.events, window: month, currency: currency);
    String? topName;
    num? topAmount;
    byCategory.forEach((name, amount) {
      if (topAmount == null || amount > topAmount!) {
        topName = name;
        topAmount = amount;
      }
    });
    final thisWeek = periodWindow('weekly', now);
    final lastWeek = previousWindow('weekly', now);
    final thisSpent = sumSpending(home.events, window: thisWeek, currency: currency);
    final lastSpent = sumSpending(home.events, window: lastWeek, currency: currency);
    final active = goals.where((goal) => goal.status == 'active');
    final goal = active.isEmpty ? null : active.first;
    return FinanceFacts(
      spentThisMonth: spent,
      largestCategory: topName,
      largestCategoryAmount: topAmount,
      currency: currency,
      previousWeekSpent: lastSpent,
      thisWeekSpent: thisSpent,
      weekComparable: home.events.isNotEmpty,
      goalName: goal?.name,
      goalGap: goal?.snapshot(now).gap,
    );
  }

  Future<void> _ask(String question) async {
    final text = question.trim();
    if (text.isEmpty) return;
    final language = ref.read(localeControllerProvider).languageCode;
    final intent = parseFinancialIntent(text);
    final draft = intent.kind == 'transaction_draft' ? parseNaturalTransaction(text, now: DateTime.now()) : null;
    setState(() {
      _busy = true;
      _messages.add((role: 'user', text: text, simulation: false));
      _draft = draft;
      _pending = intent.action;
      _pendingAmount = intent.draftAmount;
      _input.clear();
    });
    if (intent.kind == 'scenario') {
      final rows = ref.read(insightTransactionsProvider).asData?.value ?? const <TxnObs>[];
      final results = buildStudio(
        rows: rows,
        now: DateTime.now(),
        currency: 'TND',
        cashBalance: 0,
        goals: const [],
        holdings: const [],
      );
      setState(() {
        _busy = false;
        _messages.add((role: 'assistant', text: scenarioNarrative(results, intent.scenario ?? 'income_loss', 'TND'), simulation: true));
      });
      return;
    }
    if (intent.kind == 'budget_draft' || intent.kind == 'goal_draft') {
      if (intent.kind == 'goal_draft') {
        try {
          await ref.read(insightStoreProvider).recordPending(
                action: 'create_goal',
                payload: {'amount': intent.draftAmount, 'text': text, 'requires_confirmation': true},
              );
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }
    if (draft != null) {
      try {
        await ref.read(insightStoreProvider).recordPending(
              action: 'draft_transaction',
              payload: {
                'amount': draft.amount,
                'currency': draft.currency,
                'type': draft.type,
                'requires_confirmation': true,
              },
            );
      } catch (_) {}
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }
    final generation = ++_generation;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      final reply = replyForLoad(RecordLoad.sessionExpired, null, text, language: language);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _retryQuestion = text;
        _note = reply.text;
      });
      return;
    }
    BudgetHome home;
    try {
      final current = ref.read(budgetsProvider);
      if (current.hasError) ref.invalidate(budgetsForUserProvider);
      home = current.hasValue && !current.hasError
          ? current.requireValue
          : await ref.read(budgetsForUserProvider(userId).future);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      final reply = replyForLoad(classifyRecordFailure(error), null, text, language: language);
      setState(() {
        _busy = false;
        _retryQuestion = text;
        _note = reply.text;
      });
      return;
    }
    if (!mounted || generation != _generation) return;
    final l10n = context.l10n;
    final facts = _facts(home, mixedCurrency: l10n.currenciesSeparated);
    final ledger = _ledger(home, facts);
    final turn = answerFinance(text, ledger, context: _context, language: language);
    _context = turn.context;
    var answer = VerifiedAnswer(answered: turn.answered, text: turn.text, kind: answerKindFor(turn.intent));
    String? note = l10n.aiLocalOnly;
    try {
      final response = await ref.read(supabaseProvider).functions.invoke(
        'smartwallet-ai',
        body: {'currency': facts.currency, 'language': language, 'message': text},
      );
      final data = response.data;
      if (data is Map && data['text'] is String && facts.spentThisMonth != null) {
        final remoteSpent = num.tryParse('${data['spent']}');
        final narrative = data['text'] as String;
        if (data['executed'] == true) {
          note = l10n.aiLocalOnly;
        } else if (remoteSpent != null &&
            (remoteSpent - facts.spentThisMonth!).abs() < 0.001 &&
            narrativeMatchesFacts(narrative, facts) &&
            answer.kind == AnswerKind.monthSpend) {
          answer = VerifiedAnswer(answered: true, text: narrative, kind: answer.kind);
          note = data['available'] == true ? null : l10n.aiLocalOnly;
        }
      }
    } catch (_) {
      note = l10n.aiLocalOnly;
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _busy = false;
      _retryQuestion = answer.answered ? null : text;
      _note = note;
      _messages.add((role: 'assistant', text: answer.text, simulation: turn.simulation));
    });
    _scrollToEnd();
    if (userId.isEmpty) return;
    try {
      final conversation = await ref.read(supabaseProvider).from('ai_conversations').insert({
        'user_id': userId,
        'title': text.length > 80 ? text.substring(0, 80) : text,
      }).select('id').single();
      final id = conversation['id'] as String;
      await ref.read(supabaseProvider).from('ai_messages').insert([
        {'user_id': userId, 'conversation_id': id, 'role': 'user', 'body': text},
        {'user_id': userId, 'conversation_id': id, 'role': 'assistant', 'body': answer.text},
      ]);
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  AssistantLedger _ledger(BudgetHome home, FinanceFacts facts) {
    final walletsAsync = ref.read(walletsProvider);
    final goals = ref.read(goalsProvider).asData?.value ?? const <GoalRecord>[];
    final portfolios = ref.read(portfoliosProvider).asData?.value ?? const <PortfolioView>[];
    final categoryNames = <String, String>{
      for (final event in home.events)
        if (event.categoryId != null && (event.categoryName ?? '').isNotEmpty) event.categoryId!: event.categoryName!,
    };
    return AssistantLedger(
      events: home.events,
      currency: facts.currency,
      loaded: true,
      hold: facts.hold,
      walletsReady: !walletsAsync.isLoading,
      wallets: [
        for (final wallet in walletsAsync.asData?.value ?? const <WalletBalance>[])
          if (!wallet.isArchived)
            AssistantWallet(
              name: wallet.name,
              currency: wallet.currency,
              balance: wallet.currentBalance,
              type: wallet.walletType,
            ),
      ],
      goals: [
        for (final goal in goals)
          if (goal.status == 'active')
            AssistantGoalView(
              name: goal.name,
              target: goal.target,
              saved: goal.saved,
              currency: goal.currency,
            ),
      ],
      budgets: [
        for (final item in [...home.rollup.overall, ...home.rollup.categories])
          AssistantBudgetView(
            name: item.spec.name,
            limit: item.spec.limit,
            spent: item.spent,
            currency: item.spec.currency,
            period: item.spec.period,
            categoryName: item.spec.categoryId == null ? null : categoryNames[item.spec.categoryId!],
          ),
      ],
      assets: [
        for (final portfolio in portfolios)
          for (final asset in portfolio.assets)
            AssistantAssetView(
              label: asset.symbol,
              currency: asset.currency,
              manualPrice: asset.manualPrice,
              marketValue: asset.marketValue,
              gain: asset.currentPrice == null
                  ? asset.position.realized
                  : (unrealizedGain(asset.position, asset.currentPrice) ?? 0) + asset.position.realized,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.watch(budgetsProvider);
    ref.watch(walletsProvider);
    ref.watch(goalsProvider);
    ref.watch(portfoliosProvider);
    final suggestions = [
      l10n.aiSuggestMonth,
      l10n.aiSuggestCategory,
      l10n.aiSuggestSave,
      l10n.aiSuggestBalance,
      l10n.aiSuggestWeek,
      l10n.aiSuggestDraft,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.assistantTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.assistantHint),
          ),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_note!),
                  if (_retryQuestion != null)
                    TextButton(
                      onPressed: _busy ? null : () => _ask(_retryQuestion!),
                      child: Text(l10n.retry),
                    ),
                ],
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final suggestion in suggestions)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ActionChip(label: Text(suggestion), onPressed: () => _ask(suggestion)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in _messages)
                  Align(
                    alignment: message.role == 'user' ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                    child: Card(
                      color: message.role == 'user'
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              textDirection: RegExp(r'[\u0600-\u06FF]').hasMatch(message.text)
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                            if (message.simulation)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  l10n.aiSimulation,
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_pending != null && _pending!.kind != 'create_transaction' && _pending!.kind != 'scenario')
                  Card(
                    child: ListTile(
                      title: Text(l10n.confirmDraft),
                      subtitle: Text(_pending!.summary),
                      trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                      onTap: _pending!.kind == 'create_goal'
                          ? () => context.push('/plan/goals/new')
                          : () async {
                              final amount = _pendingAmount;
                              if (amount == null) return;
                              await ref.read(budgetRepositoryProvider).save(
                                    name: 'Studio',
                                    period: 'monthly',
                                    currency: 'TND',
                                    limit: amount,
                                  );
                              ref.invalidate(budgetsForUserProvider);
                              if (mounted) setState(() => _pending = null);
                            },
                    ),
                  ),
                if (_draft != null)
                  Card(
                    child: ListTile(
                      title: Text(l10n.confirmDraft),
                      subtitle: Text(
                        '${Money.format(_draft!.amount, _draft!.currency)} · ${_draft!.type} · ${_draft!.categoryHint ?? ''}',
                      ),
                      trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right),
                      onTap: () => context.push('/plan/assistant/confirm', extra: _draft),
                    ),
                  ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _input,
                    builder: (context, _) {
                      final arabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_input.text);
                      return AppTextField(
                        controller: _input,
                        label: l10n.ask,
                        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                      );
                    },
                  ),
                ),
                VoiceButton(
                  languageCode: ref.watch(localeControllerProvider).languageCode,
                  unavailableLabel: l10n.voiceUnavailable,
                  onText: (text) {
                    _input.text = text;
                    if (text.trim().isNotEmpty) _ask(text);
                  },
                ),
                IconButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await _ask(_input.text);
                          final last = _messages.where((message) => message.role == 'assistant');
                          if (last.isNotEmpty) {
                            await _voice.speak(last.last.text, ref.read(localeControllerProvider).languageCode);
                          }
                        },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DraftTransactionScreen extends ConsumerStatefulWidget {
  const DraftTransactionScreen({super.key, required this.draft});

  final TransactionDraft draft;

  @override
  ConsumerState<DraftTransactionScreen> createState() => _DraftTransactionScreenState();
}

class _DraftTransactionScreenState extends ConsumerState<DraftTransactionScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  final _requestId = const Uuid().v4();
  String? _walletId;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.draft.amount.toString());
    _description = TextEditingController(text: widget.draft.description);
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    final sameCurrency = wallets.where((wallet) => wallet.currency == widget.draft.currency).toList();
    final selected = _walletId ?? (sameCurrency.isEmpty ? null : sameCurrency.first.walletId);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.draftTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.draftTitle),
          const SizedBox(height: 12),
          AppTextField(
            controller: _amount,
            label: l10n.budgetLimit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _description, label: l10n.name),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selected,
            items: [
              for (final wallet in sameCurrency)
                DropdownMenuItem(value: wallet.walletId, child: Text(wallet.name)),
            ],
            onChanged: (value) => setState(() => _walletId = value),
            decoration: InputDecoration(labelText: l10n.chooseWallet),
          ),
          const SizedBox(height: 8),
          Text('${widget.draft.type} · ${widget.draft.currency} · ${widget.draft.categoryHint ?? l10n.allCategories}'),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.confirm,
            loading: _saving,
            onPressed: _saved || selected == null
                ? null
                : () async {
                    final amount = Money.tryParse(_amount.text);
                    if (amount == null) return;
                    setState(() => _saving = true);
                    try {
                      await ref.read(transactionRepositoryProvider).create(
                            walletId: selected,
                            type: widget.draft.type,
                            amount: amount,
                            description: _description.text,
                            merchant: widget.draft.merchant,
                            date: widget.draft.date,
                            clientRequestId: _requestId,
                          );
                      ref.invalidate(recentTransactionsForUserProvider);
                      ref.invalidate(budgetsForUserProvider);
                      try {
                        await ref.read(insightStoreProvider).approveLatest('draft_transaction');
                      } catch (_) {}
                      setState(() => _saved = true);
                      if (context.mounted) context.pop();
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
