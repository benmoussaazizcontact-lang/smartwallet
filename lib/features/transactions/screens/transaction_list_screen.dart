import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../categories/repositories/category_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class TransactionListScreen extends TransactionsScreen {
  const TransactionListScreen({super.key});
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _search = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  TransactionFilters _filters = const TransactionFilters();
  final _items = <MoneyTransaction>[];
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _loading = false;
        _error = null;
        _hasMore = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      final rows = await ref
          .read(transactionRepositoryProvider)
          .list(
            filters: _filters.copyWith(
              query: _search.text,
              minAmount: Money.tryParse(_min.text),
              maxAmount: Money.tryParse(_max.text),
            ),
          );
      if (!mounted || ref.read(currentUserIdProvider) != userId) return;
      setState(() {
        _items
          ..clear()
          ..addAll(rows);
        _hasMore = rows.length >= 30;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      if (_items.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualisation impossible : $error')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final rows = await ref
          .read(transactionRepositoryProvider)
          .list(
            filters: _filters.copyWith(
              query: _search.text,
              minAmount: Money.tryParse(_min.text),
              maxAmount: Money.tryParse(_max.text),
            ),
            offset: _items.length,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(rows);
        _hasMore = rows.length >= 30;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chargement des opérations impossible : $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Object> get _groupedRows {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMEd(locale);
    final rows = <Object>[];
    DateTime? lastDay;
    for (final t in _items) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (lastDay != day) {
        rows.add(fmt.format(t.date.toLocal()));
        lastDay = day;
      }
      rows.add(t);
    }
    return rows;
  }

  Future<void> _pick<T>(
    List<T> options,
    String Function(T) label,
    void Function(T) apply,
  ) async {
    final value = await showModalBottomSheet<T>(
      context: context,
      builder: (context) => ListView(
        children: options
            .map(
              (o) => ListTile(
                title: Text(label(o)),
                onTap: () => Navigator.pop(context, o),
              ),
            )
            .toList(),
      ),
    );
    if (value != null) {
      apply(value);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;
      _items.clear();
      _reload();
    });
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions-add-fab',
        onPressed: () => context.push('/add-transaction?type=EXPENSE'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.searchHint,
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    _filters.type == null
                        ? l10n.filterType
                        : localizedTransactionType(l10n, _filters.type!),
                  ),
                  selected: _filters.type != null,
                  onSelected: (_) => _pick(
                    ['EXPENSE', 'INCOME', 'PAYMENT', 'REFUND', 'TRANSFER'],
                    (t) => localizedTransactionType(l10n, t),
                    (t) =>
                        setState(() => _filters = _filters.copyWith(type: t)),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.filterWallet),
                  selected: _filters.walletId != null,
                  onSelected: (_) => _pick(
                    wallets,
                    (w) => w.name,
                    (w) => setState(
                      () => _filters = _filters.copyWith(walletId: w.walletId),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.filterCategory),
                  selected: _filters.categoryId != null,
                  onSelected: (_) => _pick(
                    categories,
                    (c) => localizedCategoryName(l10n, c.name),
                    (c) => setState(
                      () => _filters = _filters.copyWith(categoryId: c.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.filterDate),
                  selected: _filters.from != null,
                  onSelected: (_) async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (range != null) {
                      setState(() {
                        _filters = _filters.copyWith(
                          from: range.start,
                          to: range.end,
                        );
                      });
                      _reload();
                    }
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _min,
                    decoration: InputDecoration(labelText: l10n.minAmount),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSubmitted: (_) => _reload(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _max,
                    decoration: InputDecoration(labelText: l10n.maxAmount),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onSubmitted: (_) => _reload(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = const TransactionFilters();
                      _search.clear();
                      _min.clear();
                      _max.clear();
                    });
                    _reload();
                  },
                  child: Text(l10n.clear),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _items.isEmpty
                ? const LoadingSkeleton()
                : _error != null && _items.isEmpty
                ? ErrorView(message: '$_error', onRetry: _reload)
                : _items.isEmpty
                ? EmptyState(
                    title: l10n.noTransactions,
                    message: l10n.noTransactionsHint,
                    actionLabel: l10n.add,
                    onAction: () => context.push('/add-transaction'),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: _groupedRows.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _groupedRows.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final row = _groupedRows[index];
                          if (row is String) {
                            return DateGroupHeader(label: row);
                          }
                          final t = row as MoneyTransaction;
                          final wallet = wallets.where(
                            (w) => w.walletId == t.walletId,
                          );
                          return TransactionTile(
                            transaction: t,
                            walletName: wallet.isEmpty
                                ? null
                                : wallet.first.name,
                            onTap: () => context.go('/transactions/${t.id}'),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
