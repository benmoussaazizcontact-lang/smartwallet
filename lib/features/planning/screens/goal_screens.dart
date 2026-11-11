import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../domain/budget_math.dart';
import '../domain/goal_math.dart';
import '../domain/spend_rules.dart';
import '../domain/what_if.dart';
import '../repositories/budget_repository.dart';
import '../repositories/goal_repository.dart';

const goalKinds = [
  'laptop',
  'car',
  'travel',
  'house',
  'education',
  'emergency',
  'phone',
  'investments',
  'custom',
];

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plan/goals/new'),
        child: const Icon(Icons.add),
      ),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: '$error',
          onRetry: () => ref.invalidate(goalsForUserProvider),
        ),
        data: (items) {
          final active = items.where((goal) => goal.status != 'archived').toList();
          if (active.isEmpty) {
            return EmptyState(
              title: l10n.noPlanData,
              message: l10n.goalsTitle,
              actionLabel: l10n.newGoal,
              onAction: () => context.push('/plan/goals/new'),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final goal in active)
                Card(
                  child: ListTile(
                    title: Text(goal.name),
                    subtitle: Text(
                      '${l10n.savedLabel} ${Money.format(goal.saved, goal.currency)} · ${goal.snapshot(DateTime.now()).percent}%',
                    ),
                    trailing: Text(Money.format(goal.target, goal.currency)),
                    onTap: () => context.push('/plan/goals/${goal.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  String _kind = 'custom';
  String _currency = 'TND';
  int _priority = 2;
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGoal)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(controller: _name, label: l10n.name),
          const SizedBox(height: 12),
          AppTextField(
            controller: _target,
            label: l10n.goalTarget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            items: [for (final kind in goalKinds) DropdownMenuItem(value: kind, child: Text(kind))],
            onChanged: (value) => setState(() => _kind = value ?? _kind),
            decoration: InputDecoration(labelText: l10n.goalsTitle),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            items: [
              for (final currency in Currencies.all)
                DropdownMenuItem(value: currency.code, child: Text(currency.code)),
            ],
            onChanged: (value) => setState(() => _currency = value ?? _currency),
            decoration: InputDecoration(labelText: l10n.currency),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _priority,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1')),
              DropdownMenuItem(value: 2, child: Text('2')),
              DropdownMenuItem(value: 3, child: Text('3')),
            ],
            onChanged: (value) => setState(() => _priority = value ?? _priority),
            decoration: InputDecoration(labelText: l10n.priorityLabel),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_date == null ? l10n.goalTarget : _date!.toIso8601String().split('T').first),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                initialDate: _date ?? DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          Text(l10n.virtualHint),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.save,
            loading: _saving,
            onPressed: () async {
              final target = Money.tryParse(_target.text);
              if (target == null || _name.text.trim().isEmpty) return;
              setState(() => _saving = true);
              try {
                await ref.read(goalRepositoryProvider).save(
                      name: _name.text,
                      kind: _kind,
                      target: target,
                      currency: _currency,
                      targetDate: _date,
                      priority: _priority,
                    );
                ref.invalidate(goalsForUserProvider);
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

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  final _amount = TextEditingController();
  final _uuid = const Uuid();
  late String _requestId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _requestId = _uuid.v4();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goals = ref.watch(goalsProvider);
    final home = ref.watch(budgetsProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalsTitle)),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(message: '$error'),
        data: (items) {
          final goal = items.where((row) => row.id == widget.goalId).firstOrNull;
          if (goal == null) return Center(child: Text(l10n.noPlanData));
          final now = DateTime.now();
          final snapshot = goal.snapshot(now);
          final monthly = requiredMonthly(snapshot);
          final contributions = ref.watch(_contributionsProvider(goal.id));
          final spends = <CategorySpend>[];
          if (home != null) {
            final totals = spendingByCategory(
              home.events,
              window: periodWindow('monthly', now),
              currency: goal.currency,
            );
            totals.forEach((name, amount) {
              spends.add(CategorySpend(name: name, amount: amount, currency: goal.currency));
            });
          }
          final cuts = suggestCuts(spends: spends, currency: goal.currency);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(goal.name, style: Theme.of(context).textTheme.headlineSmall),
              Text('${snapshot.percent}%'),
              LinearProgressIndicator(value: snapshot.progress),
              Text('${l10n.goalTarget}: ${Money.format(goal.target, goal.currency)}'),
              Text('${l10n.savedLabel}: ${Money.format(goal.saved, goal.currency)}'),
              if (monthly != null) Text('${l10n.requiredMonthly}: ${Money.format(monthly, goal.currency)}'),
              Text(l10n.virtualHint),
              if (cuts.sufficient)
                Text('${l10n.potentialSavings}: ${Money.format(cuts.monthlyFreed, goal.currency)}'),
              const SizedBox(height: 12),
              AppTextField(
                controller: _amount,
                label: l10n.contribute,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: l10n.contribute,
                loading: _saving,
                onPressed: () async {
                  final amount = Money.tryParse(_amount.text);
                  if (amount == null) return;
                  setState(() => _saving = true);
                  try {
                    await ref.read(goalRepositoryProvider).contribute(
                          goalId: goal.id,
                          amount: amount,
                          currency: goal.currency,
                          clientRequestId: _requestId,
                        );
                    ref.invalidate(goalsForUserProvider);
                    ref.invalidate(_contributionsProvider(goal.id));
                    _requestId = _uuid.v4();
                    _amount.clear();
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(goalRepositoryProvider).setStatus(goal.id, 'completed');
                  ref.invalidate(goalsForUserProvider);
                },
                child: Text(l10n.completeGoal),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(goalRepositoryProvider).setStatus(goal.id, 'archived');
                  ref.invalidate(goalsForUserProvider);
                  if (context.mounted) context.pop();
                },
                child: Text(l10n.archive),
              ),
              const SizedBox(height: 12),
              contributions.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('$error'),
                data: (rows) => Column(
                  children: [
                    for (final row in rows)
                      ListTile(
                        title: Text(Money.format(row.amount, row.currency)),
                        subtitle: Text(row.date.toIso8601String().split('T').first),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final _contributionsProvider = FutureProvider.family<List<ContributionRecord>, String>((ref, goalId) {
  return ref.watch(goalRepositoryProvider).contributions(goalId);
});

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
