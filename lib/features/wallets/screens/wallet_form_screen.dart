import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../repositories/wallet_repository.dart';

class AddWalletScreen extends StatelessWidget {
  const AddWalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const _WalletEditor();
}

class EditWalletScreen extends StatelessWidget {
  const EditWalletScreen({super.key, required this.walletId});

  final String walletId;

  @override
  Widget build(BuildContext context) => _WalletEditor(walletId: walletId);
}

class WalletFormScreen extends StatelessWidget {
  const WalletFormScreen({super.key, this.walletId});

  final String? walletId;

  @override
  Widget build(BuildContext context) => _WalletEditor(walletId: walletId);
}

class _WalletEditor extends ConsumerStatefulWidget {
  const _WalletEditor({this.walletId});

  final String? walletId;

  @override
  ConsumerState<_WalletEditor> createState() => _WalletEditorState();
}

class _WalletEditorState extends ConsumerState<_WalletEditor> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _initial = TextEditingController(text: '0');
  final _limit = TextEditingController(text: '0');
  final _crypto = TextEditingController();
  String _type = 'CASH';
  String _currency = 'TND';
  String _color = '#2563EB';
  bool _loading = false;
  bool _loaded = false;
  bool _loadingWallet = false;
  Object? _loadError;

  bool get _editing => widget.walletId != null;

  static const _palette = [
    '#2563EB',
    '#10B981',
    '#8B5CF6',
    '#F59E0B',
    '#EF4444',
    '#14B8A6',
  ];

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    _limit.dispose();
    _crypto.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.walletId != null) _load();
  }

  Future<void> _load() async {
    if (!_editing || _loaded || _loadingWallet) return;
    _loadingWallet = true;
    try {
      final wallet = await ref
          .read(walletRepositoryProvider)
          .getById(widget.walletId!);
      if (!mounted) return;
      _name.text = wallet.name;
      _type = wallet.walletType;
      _currency = wallet.currency;
      _limit.text = wallet.creditLimit.toString();
      _crypto.text = wallet.cryptoSymbol ?? '';
      _color = wallet.color ?? '#2563EB';
      _loaded = true;
      setState(() => _loadError = null);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      _loadingWallet = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      if (_editing) {
        await repo.update(
          id: widget.walletId!,
          name: _name.text,
          creditLimit: _type == 'CREDIT_CARD'
              ? Money.tryParse(_limit.text) ?? 0
              : 0,
          cryptoSymbol: _type == 'CRYPTO' ? _crypto.text.trim() : null,
          icon: _type,
          color: _color,
        );
      } else {
        final createdId = await repo.create(
          name: _name.text,
          walletType: _type,
          currency: _currency,
          initialBalance: Money.tryParse(_initial.text) ?? 0,
          creditLimit: _type == 'CREDIT_CARD'
              ? Money.tryParse(_limit.text) ?? 0
              : 0,
          cryptoSymbol: _type == 'CRYPTO' ? _crypto.text.trim() : null,
          icon: _type,
          color: _color,
        );
        ref.invalidate(walletsForUserProvider);
        if (mounted) context.go('/wallets/$createdId');
        return;
      }
      ref.invalidate(walletsForUserProvider);
      if (mounted) context.go('/wallets');
    } catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        final message = error is AppException && error.code == 'unauthenticated'
            ? l10n.notSignedIn
            : l10n.walletSaveFailed;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_editing && !_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editWallet)),
        body: Center(
          child: _loadError == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.walletLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _load();
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? l10n.editWallet : l10n.addWalletTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppTextField(
              controller: _name,
              label: l10n.name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: [
                DropdownMenuItem(value: 'CASH', child: Text(l10n.typeCash)),
                DropdownMenuItem(
                  value: 'BANK_ACCOUNT',
                  child: Text(l10n.typeBank),
                ),
                DropdownMenuItem(
                  value: 'CREDIT_CARD',
                  child: Text(l10n.typeCard),
                ),
                DropdownMenuItem(value: 'CRYPTO', child: Text(l10n.typeCrypto)),
                DropdownMenuItem(
                  value: 'SAVINGS',
                  child: Text(l10n.typeSavings),
                ),
              ],
              onChanged: _editing
                  ? null
                  : (v) => setState(() => _type = v ?? _type),
              decoration: InputDecoration(labelText: l10n.walletType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: Currencies.all
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} · ${c.label}'),
                    ),
                  )
                  .toList(),
              onChanged: _editing
                  ? null
                  : (v) => setState(() => _currency = v ?? _currency),
              decoration: InputDecoration(labelText: l10n.currency),
            ),
            if (!_editing) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _initial,
                label: l10n.initialBalance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty || v.trim() == '0') {
                    return null;
                  }
                  return Money.validate(v, l10n: l10n);
                },
              ),
            ],
            if (_type == 'CREDIT_CARD') ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _limit,
                label: l10n.creditLimit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
            if (_type == 'CRYPTO') ...[
              const SizedBox(height: 12),
              AppTextField(controller: _crypto, label: l10n.assetSymbol),
            ],
            const SizedBox(height: 16),
            Text(l10n.color, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _palette
                  .map(
                    (hex) => ChoiceChip(
                      selected: _color == hex,
                      label: CircleAvatar(
                        radius: 8,
                        backgroundColor: Color(
                          int.parse(hex.replaceFirst('#', 'FF'), radix: 16),
                        ),
                      ),
                      onSelected: (_) => setState(() => _color = hex),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _editing ? l10n.save : l10n.create,
              loading: _loading,
              onPressed: _loadingWallet || (_editing && !_loaded)
                  ? null
                  : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
