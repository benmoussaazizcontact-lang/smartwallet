import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../ai_classification/repositories/classification_repository.dart';
import '../../ai_classification/services/classification_result.dart';
import '../../ai_classification/services/transaction_classification_service.dart';
import '../../ai_classification/widgets/classification_banner.dart';
import '../../categories/repositories/category_repository.dart';
import '../../categories/widgets/category_selector.dart';
import '../../planning/repositories/budget_repository.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../wallets/repositories/wallet_repository.dart';
import '../models/receipt_draft.dart';
import '../services/ocr_parser.dart';
import '../services/receipt_amounts.dart';
import '../providers/receipt_providers.dart';
import '../repositories/receipt_repository.dart';
import '../services/receipt_confirmation.dart';

class ConfirmReceiptScreen extends ConsumerStatefulWidget {
  const ConfirmReceiptScreen({super.key, required this.draft});

  final ReceiptDraft draft;

  @override
  ConsumerState<ConfirmReceiptScreen> createState() =>
      _ConfirmReceiptScreenState();
}

class _ConfirmReceiptScreenState extends ConsumerState<ConfirmReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchant;
  late final TextEditingController _receiptNumber;
  late final TextEditingController _amount;
  late final TextEditingController _payment;
  late String _currency;
  late DateTime _date;
  late final String _operationId;
  String? _walletId;
  String? _categoryId;
  String? _transactionId;
  String? _storagePath;
  bool _receiptInserted = false;
  bool _classificationRecorded = false;
  ClassificationResult? _suggestion;
  bool _busy = false;
  bool _classified = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _operationId = widget.draft.operationId;
    _merchant = TextEditingController(text: widget.draft.merchant ?? '');
    _receiptNumber = TextEditingController(text: widget.draft.receiptNumber ?? '');
    _amount = TextEditingController(
      text: widget.draft.amount == null
          ? ''
          : formatReceiptAmount(widget.draft.amount!, widget.draft.currency ?? 'TND'),
    );
    _payment = TextEditingController(text: widget.draft.paymentMethod ?? '');
    _currency = widget.draft.currency ?? 'TND';
    _date = widget.draft.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _merchant.dispose();
    _receiptNumber.dispose();
    _amount.dispose();
    _payment.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final existing = await ref
        .read(receiptOperationStoreProvider)
        .find(userId, _operationId);
    if (!mounted || existing == null) return;
    setState(() {
      _transactionId = existing.transactionId;
      _storagePath = existing.storagePath;
      _receiptInserted = existing.receiptInserted;
      _classificationRecorded = existing.classificationRecorded;
      if (existing.hasTransaction) {
        _walletId = existing.walletId;
        _currency = existing.currency;
        _date = existing.date;
        _amount.text = existing.amount.toString();
        _merchant.text = existing.merchant ?? _merchant.text;
        _payment.text = existing.payment ?? _payment.text;
        _categoryId = existing.categoryId ?? _categoryId;
      }
    });
  }

  Future<void> _classify() async {
    final categories = ref.read(categoriesProvider).asData?.value ?? [];
    final corrections = ref.read(merchantCorrectionsProvider).asData?.value ?? [];
    final outcome = await ref.read(transactionClassificationServiceProvider).classify(
          text: '${_merchant.text} ${widget.draft.rawText ?? ''}',
          merchant: _merchant.text,
          amount: Money.tryParse(_amount.text),
          categories: categories,
          corrections: corrections,
          allowRemote: false,
        );
    if (!mounted) return;
    setState(() {
      _suggestion = outcome.suggestion;
      if (_categoryId == null &&
          outcome.suggestion != null &&
          !outcome.suggestion!.isLowConfidence) {
        _categoryId = outcome.suggestion!.chosenCategoryId;
      }
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _show(context.l10n.notSignedIn);
      return;
    }
    if (_walletId == null) {
      _show(context.l10n.selectWallet);
      return;
    }
    if (_suggestion?.isLowConfidence == true && _categoryId == null) {
      _show(context.l10n.selectCategoryLowConfidence);
      return;
    }
    final amount = Money.tryParse(_amount.text);
    if (amount == null) return;
    final operation = ReceiptOperation(
      userId: userId,
      operationId: _operationId,
      walletId: _walletId!,
      amount: _transactionId == null ? amount : (Money.tryParse(_amount.text) ?? amount),
      currency: _currency,
      date: _date,
      merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
      categoryId: _categoryId,
      payment: _payment.text.trim().isEmpty ? null : _payment.text.trim(),
      rawText: widget.draft.rawText,
      transactionId: _transactionId,
      storagePath: _storagePath,
      receiptInserted: _receiptInserted,
      classificationRecorded: _classificationRecorded,
      predictedCategoryId: _suggestion?.chosenCategoryId,
      confidence: _suggestion?.confidenceMeasured == true
          ? _suggestion?.confidence
          : null,
      modelName: _suggestion?.source.name ?? 'none',
      wasCorrected: _suggestion?.chosenCategoryId != null &&
          _categoryId != null &&
          _suggestion?.chosenCategoryId != _categoryId,
    );
    setState(() => _busy = true);
    final store = ref.read(receiptOperationStoreProvider);
    try {
      final saved = await ReceiptConfirmationWorkflow(store).run(
        operation: operation,
        gateway: _Gateway(
          ref,
          widget.draft.imageBytes,
          tax: widget.draft.tax,
          items: widget.draft.items,
          receiptNumber: _receiptNumber.text.trim(),
        ),
      );
      ref.invalidate(pendingReceiptsForUserProvider);
      ref.invalidate(walletsForUserProvider);
      ref.invalidate(recentTransactionsForUserProvider);
      ref.invalidate(dashboardActivityForUserProvider);
      ref.invalidate(budgetsForUserProvider);
      ref.invalidate(merchantCorrectionsForUserProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.receiptSaved)),
      );
      context.go('/transactions/${saved.transactionId}');
    } catch (_) {
      final restored = await store.find(userId, _operationId);
      if (!mounted) return;
      setState(() {
        _transactionId = restored?.transactionId ?? _transactionId;
        _storagePath = restored?.storagePath ?? _storagePath;
        _receiptInserted = restored?.receiptInserted ?? _receiptInserted;
        _classificationRecorded =
            restored?.classificationRecorded ?? _classificationRecorded;
      });
      final created = _transactionId != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created ? context.l10n.receiptUploadRetry : context.l10n.receiptSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wallets = ref.watch(walletsProvider);
    final walletItems = wallets.asData?.value ?? const [];
    final categories = ref.watch(categoriesProvider).asData?.value ?? [];
    if (!_restored) {
      _restored = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
    }
    if (!_classified && categories.isNotEmpty) {
      _classified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _classify());
    }
    final locked = _transactionId != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.confirmReceipt)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                widget.draft.imageBytes,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (widget.draft.amountNeedsReview && _transactionId == null) ...[
              const SizedBox(height: 12),
              Text(l10n.amountNeedsReview),
            ],
            if (widget.draft.arabicScriptSeen) ...[
              const SizedBox(height: 12),
              Text(l10n.arabicOcrLimited),
            ],
            if (widget.draft.rawText != null && documentKindOf(widget.draft.rawText!) != 'receipt') ...[
              const SizedBox(height: 8),
              Text('${l10n.documentKindLabel}: ${documentKindOf(widget.draft.rawText!)}'),
            ],
            if (widget.draft.tax != null) ...[
              const SizedBox(height: 8),
              Text('${l10n.taxLabel}: ${Money.format(widget.draft.tax!, widget.draft.currency ?? '')}'),
            ],
            if (widget.draft.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.receiptItems),
              for (final item in widget.draft.items) Text(item),
            ],
            if (_transactionId != null) ...[
              const SizedBox(height: 12),
              Text(l10n.receiptUploadRetry),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _walletId,
              items: walletItems
                  .map(
                    (w) => DropdownMenuItem(
                      value: w.walletId,
                      child: Text(
                        '${w.name} · ${Money.format(w.currentBalance, w.currency)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: locked ? null : (v) => setState(() => _walletId = v),
              decoration: InputDecoration(labelText: l10n.filterWallet),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _merchant,
              label: l10n.merchant,
              enabled: !locked,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _receiptNumber,
              label: l10n.receiptNumber,
              enabled: !locked,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amount,
              label: l10n.amount,
              enabled: !locked,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Money.validate(v ?? '', l10n: l10n),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: Currencies.all
                  .map((c) => DropdownMenuItem(value: c.code, child: Text(c.code)))
                  .toList(),
              onChanged: locked ? null : (v) => setState(() => _currency = v ?? _currency),
              decoration: InputDecoration(labelText: l10n.currency),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _payment,
              label: l10n.paymentMethod,
              enabled: !locked,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.date),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              onTap: locked
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
            ),
            CategorySelector(
              categories: categories,
              value: _categoryId,
              onChanged: locked ? null : (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            ClassificationBanner(suggestion: _suggestion),
            if (widget.draft.rawText != null) ...[
              const SizedBox(height: 12),
              Text(l10n.ocrText, style: Theme.of(context).textTheme.titleSmall),
              Text(widget.draft.rawText!, maxLines: 8, overflow: TextOverflow.ellipsis),
            ],
          ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton(
                    label: l10n.confirmAndSave,
                    loading: _busy,
                    onPressed: _busy ? null : _save,
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => context.pop(),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Gateway implements ReceiptSaveGateway {
  _Gateway(this.ref, this.bytes, {this.tax, this.items = const [], this.receiptNumber});
  final WidgetRef ref;
  final Uint8List bytes;
  final num? tax;
  final List<String> items;
  final String? receiptNumber;

  @override
  Future<String> createTransaction(ReceiptOperation operation) {
    return ref.read(transactionRepositoryProvider).create(
          walletId: operation.walletId,
          type: 'EXPENSE',
          amount: operation.amount,
          merchant: operation.merchant,
          categoryId: operation.categoryId,
          date: operation.date,
          description: operation.payment == null
              ? 'Receipt scan'
              : 'Receipt · ${operation.payment}',
          clientRequestId: operation.operationId,
        );
  }

  @override
  Future<String> uploadReceipt(ReceiptOperation operation) {
    return ref.read(receiptRepositoryProvider).uploadImage(
          bytes,
          operationId: operation.operationId,
        );
  }

  @override
  Future<void> insertReceipt(ReceiptOperation operation) {
    return ref.read(receiptRepositoryProvider).insert(
          transactionId: operation.transactionId!,
          imagePath: operation.storagePath!,
          merchant: operation.merchant,
          receiptDate: operation.date,
          total: operation.amount,
          currency: operation.currency,
          extractedData: {
            'raw': operation.rawText,
            'payment_method': operation.payment,
            'ocr_engine': 'mlkit-latin',
            'tax': tax,
            'items': items,
            'receipt_number': receiptNumber,
            'confirmed': true,
            'operation_id': operation.operationId,
          },
        );
  }

  @override
  Future<void> recordClassification(ReceiptOperation operation) {
    return ref.read(classificationRepositoryProvider).record(
          transactionId: operation.transactionId!,
          merchantKey: TransactionClassificationService.merchantKey(operation.merchant),
          predictedCategoryId: operation.predictedCategoryId,
          actualCategoryId: operation.categoryId,
          confidence: operation.confidence,
          modelName: operation.modelName ?? 'none',
          wasCorrected: operation.wasCorrected,
        );
  }
}
