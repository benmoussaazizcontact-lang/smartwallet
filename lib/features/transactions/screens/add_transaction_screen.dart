import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../ai_classification/repositories/classification_repository.dart';
import '../../ai_classification/services/classification_result.dart';
import '../../ai_classification/services/transaction_classification_service.dart';
import '../../ai_classification/widgets/classification_banner.dart';
import '../../categories/repositories/category_repository.dart';
import '../../categories/widgets/category_selector.dart';
import '../../tags/widgets/tag_selector.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.initialType = 'EXPENSE'});

  final String initialType;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _description = TextEditingController();
  late String _type;
  String? _walletId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _loading = false;
  ClassificationResult? _suggestion;
  String? _advancedUnavailable;
  final _requestId = const Uuid().v4();
  bool _submitted = false;
  bool _attachLocation = false;
  GeoPoint? _point;
  final _tags = <String>{};

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'TRANSFER' ? 'EXPENSE' : widget.initialType;
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _classify({bool allowRemote = false}) async {
    final categories = ref.read(categoriesProvider).asData?.value ?? [];
    final corrections = ref.read(merchantCorrectionsProvider).asData?.value ?? [];
    final service = ref.read(transactionClassificationServiceProvider);
    if (!allowRemote) {
      final local = TransactionClassificationService.classifyLocal(
        text: '${_merchant.text} ${_description.text}',
        merchant: _merchant.text,
        categories: categories,
        corrections: corrections,
      );
      if (!mounted) return;
      setState(() {
        _suggestion = local;
        _advancedUnavailable = null;
        if (local != null && !local.isLowConfidence) {
          _categoryId = local.chosenCategoryId;
        }
      });
      return;
    }
    final outcome = await service.classify(
      text: '${_merchant.text} ${_description.text}',
      merchant: _merchant.text,
      amount: Money.tryParse(_amount.text),
      categories: categories,
      corrections: corrections,
    );
    if (!mounted) return;
    setState(() {
      _suggestion = outcome.suggestion;
      _advancedUnavailable = outcome.advancedUnavailableReason;
      if (outcome.suggestion != null && !outcome.suggestion!.isLowConfidence) {
        _categoryId = outcome.suggestion!.chosenCategoryId;
      }
    });
  }

  Future<void> _toggleLocation(bool value) async {
    if (!value) {
      setState(() {
        _attachLocation = false;
        _point = null;
      });
      return;
    }
    setState(() => _loading = true);
    final point = await const LocationService().currentPoint();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _attachLocation = point != null;
      _point = point;
    });
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationDenied)),
      );
    }
  }

  Future<void> _submit() async {
    if (_submitted) return;
    if (!_formKey.currentState!.validate()) return;
    if (_walletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectWallet)),
      );
      return;
    }
    final amount = Money.tryParse(_amount.text);
    if (amount == null) return;
    if (_suggestion?.isLowConfidence == true && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectCategoryLowConfidence)),
      );
      return;
    }
    setState(() {
      _loading = true;
      _submitted = true;
    });
    try {
      final id = await ref.read(transactionRepositoryProvider).create(
            walletId: _walletId!,
            type: _type,
            amount: amount,
            description:
                _description.text.trim().isEmpty ? null : _description.text.trim(),
            merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
            categoryId: _categoryId,
            date: _date,
            tagIds: _tags.toList(),
            clientRequestId: _requestId,
            latitude: _point?.latitude,
            longitude: _point?.longitude,
          );
      final predicted = _suggestion?.chosenCategoryId;
      await ref.read(classificationRepositoryProvider).record(
            transactionId: id,
            merchantKey: TransactionClassificationService.merchantKey(_merchant.text),
            predictedCategoryId: predicted,
            actualCategoryId: _categoryId,
            confidence: _suggestion?.confidence,
            modelName: _suggestion?.source.name ?? 'none',
            wasCorrected:
                predicted != null && _categoryId != null && predicted != _categoryId,
          );
      ref.invalidate(merchantCorrectionsForUserProvider);
      ref.invalidate(walletsForUserProvider);
      ref.invalidate(recentTransactionsForUserProvider);
      ref.invalidate(dashboardActivityForUserProvider);
      ref.invalidate(budgetsForUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.transactionSaved)),
        );
        context.go('/transactions');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _submitted = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider).asData?.value ?? [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addType(localizedTransactionType(l10n, _type)))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                color: AppColors.elevated(Theme.of(context).brightness),
              ),
              child: AppTextField(
                controller: _amount,
                label: l10n.amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Money.validate(v ?? '', l10n: l10n),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: [
                DropdownMenuItem(value: 'EXPENSE', child: Text(l10n.typeExpense)),
                DropdownMenuItem(value: 'INCOME', child: Text(l10n.typeIncome)),
                DropdownMenuItem(value: 'PAYMENT', child: Text(l10n.typePayment)),
                DropdownMenuItem(value: 'REFUND', child: Text(l10n.typeRefund)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
              decoration: InputDecoration(labelText: l10n.filterType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _walletId,
              items: wallets
                  .map(
                    (w) => DropdownMenuItem(
                      value: w.walletId,
                      child: Text(
                        '${w.name} · ${Money.format(w.currentBalance, w.currency)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _walletId = v),
              decoration: InputDecoration(labelText: l10n.filterWallet),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _merchant,
              label: l10n.merchant,
              onChanged: (_) => _classify(),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _description,
              label: l10n.description,
              onChanged: (_) => _classify(),
            ),
            const SizedBox(height: 12),
            CategorySelector(
              categories: categories,
              value: _categoryId,
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            ClassificationBanner(
              suggestion: _suggestion,
              advancedUnavailableReason: _advancedUnavailable,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _loading ? null : () => _classify(allowRemote: true),
                child: Text(l10n.tryAdvancedAi),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.tags, style: Theme.of(context).textTheme.titleSmall),
            TagSelector(
              selectedIds: _tags,
              onChanged: (v) => setState(() {
                _tags
                  ..clear()
                  ..addAll(v);
              }),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dateAndTime),
              subtitle: Text(_date.toLocal().toString().split('.').first),
              onTap: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (day == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_date),
                );
                setState(() {
                  _date = DateTime(
                    day.year,
                    day.month,
                    day.day,
                    time?.hour ?? _date.hour,
                    time?.minute ?? _date.minute,
                  );
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.attachLocation),
              subtitle: Text(
                _point == null
                    ? l10n.locationOptional
                    : (_point!.address ??
                        '${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}'),
              ),
              value: _attachLocation,
              onChanged: _toggleLocation,
            ),
            const SizedBox(height: 16),
            AppButton(label: l10n.save, loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
