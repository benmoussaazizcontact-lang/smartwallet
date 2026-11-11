import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/receipts/repositories/receipt_repository.dart';
import 'package:wallet_app/features/receipts/services/receipt_confirmation.dart';

void main() {
  const userA = '11111111-1111-4111-8111-111111111111';
  const userB = '22222222-2222-4222-8222-222222222222';
  const operationId = '33333333-3333-4333-8333-333333333333';

  test('receipt path uses the authenticated user, not a demo id', () {
    final path = receiptStoragePath(userId: userA, operationId: operationId);
    expect(path, '$userA/$operationId.jpg');
    expect(receiptPathBelongsToUser(path, userA), isTrue);
    expect(receiptPathBelongsToUser(path, userB), isFalse);
    expect(
      receiptPathBelongsToUser(
        '7d2f1a6e-9c4b-4e8a-b3d1-2f6a8c0e5b91/$operationId.jpg',
        userA,
      ),
      isFalse,
    );
  });

  test('upload failure retries the same transaction id', () async {
    final store = MemoryReceiptOperationStore();
    final gateway = _Gateway()..failUploads = 1;
    final operation = _operation(userA, operationId);
    final workflow = ReceiptConfirmationWorkflow(store);

    await expectLater(
      workflow.run(operation: operation, gateway: gateway),
      throwsA(isA<StateError>()),
    );
    expect(gateway.creates, 1);
    expect(gateway.uploads, 1);
    final pending = await store.find(userA, operationId);
    expect(pending?.transactionId, 'tx-1');
    expect(pending?.storagePath, isNull);

    final saved = await workflow.run(operation: pending!, gateway: gateway);
    expect(gateway.creates, 1);
    expect(gateway.uploads, 2);
    expect(saved.transactionId, 'tx-1');
    expect(saved.storagePath, '$userA/$operationId.jpg');
    expect(await store.pendingFor(userA), isEmpty);
  });

  test('postgres migration keeps one movement per client request id', () {
    final sql = File(
      'supabase/migrations/20261025120000_receipt_idempotency.sql',
    ).readAsStringSync();
    expect(sql, contains('WHEN unique_violation'));
    expect(sql, contains('client_request_id'));
    expect(sql, contains('receipts_user_transaction_uidx'));
    expect(sql.toLowerCase(), isNot(contains('disable row level security')));
  });

  test('a second account cannot see the first account pending receipt', () async {
    final store = MemoryReceiptOperationStore();
    await store.save(_operation(userA, operationId));
    expect(await store.pendingFor(userB), isEmpty);
    expect((await store.pendingFor(userA)).single.userId, userA);
  });

  test('repeated submission after success does not create again', () async {
    final store = MemoryReceiptOperationStore();
    final gateway = _Gateway();
    final workflow = ReceiptConfirmationWorkflow(store);
    final first = await workflow.run(
      operation: _operation(userA, operationId),
      gateway: gateway,
    );
    final second = await workflow.run(operation: first, gateway: gateway);
    expect(gateway.creates, 1);
    expect(second.transactionId, first.transactionId);
  });
}

ReceiptOperation _operation(String userId, String operationId) {
  return ReceiptOperation(
    userId: userId,
    operationId: operationId,
    walletId: 'wallet-1',
    amount: 48.5,
    currency: 'TND',
    date: DateTime.utc(2026, 10, 8),
    merchant: 'Restaurant',
  );
}

class _Gateway implements ReceiptSaveGateway {
  int creates = 0;
  int uploads = 0;
  int failUploads = 0;

  @override
  Future<String> createTransaction(ReceiptOperation operation) async {
    creates += 1;
    return 'tx-$creates';
  }

  @override
  Future<void> insertReceipt(ReceiptOperation operation) async {}

  @override
  Future<void> recordClassification(ReceiptOperation operation) async {}

  @override
  Future<String> uploadReceipt(ReceiptOperation operation) async {
    uploads += 1;
    if (uploads <= failUploads) {
      throw StateError('storage unavailable');
    }
    return '${operation.userId}/${operation.operationId}.jpg';
  }
}
