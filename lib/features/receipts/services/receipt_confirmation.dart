import 'dart:convert';

/// One receipt confirmation. [operationId] is also the PostgreSQL
/// `client_request_id`, so a retry cannot create a second movement.
class ReceiptOperation {
  const ReceiptOperation({
    required this.userId,
    required this.operationId,
    required this.walletId,
    required this.amount,
    required this.currency,
    required this.date,
    this.merchant,
    this.categoryId,
    this.payment,
    this.rawText,
    this.transactionId,
    this.storagePath,
    this.receiptInserted = false,
    this.classificationRecorded = false,
    this.predictedCategoryId,
    this.confidence,
    this.modelName,
    this.wasCorrected = false,
  });

  final String userId;
  final String operationId;
  final String walletId;
  final num amount;
  final String currency;
  final DateTime date;
  final String? merchant;
  final String? categoryId;
  final String? payment;
  final String? rawText;
  final String? transactionId;
  final String? storagePath;
  final bool receiptInserted;
  final bool classificationRecorded;
  final String? predictedCategoryId;
  final double? confidence;
  final String? modelName;
  final bool wasCorrected;

  bool get hasTransaction => transactionId != null && transactionId!.isNotEmpty;

  ReceiptOperation copyWith({
    String? transactionId,
    String? storagePath,
    bool? receiptInserted,
    bool? classificationRecorded,
  }) {
    return ReceiptOperation(
      userId: userId,
      operationId: operationId,
      walletId: walletId,
      amount: amount,
      currency: currency,
      date: date,
      merchant: merchant,
      categoryId: categoryId,
      payment: payment,
      rawText: rawText,
      transactionId: transactionId ?? this.transactionId,
      storagePath: storagePath ?? this.storagePath,
      receiptInserted: receiptInserted ?? this.receiptInserted,
      classificationRecorded:
          classificationRecorded ?? this.classificationRecorded,
      predictedCategoryId: predictedCategoryId,
      confidence: confidence,
      modelName: modelName,
      wasCorrected: wasCorrected,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'operationId': operationId,
        'walletId': walletId,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'merchant': merchant,
        'categoryId': categoryId,
        'payment': payment,
        'rawText': rawText,
        'transactionId': transactionId,
        'storagePath': storagePath,
        'receiptInserted': receiptInserted,
        'classificationRecorded': classificationRecorded,
        'predictedCategoryId': predictedCategoryId,
        'confidence': confidence,
        'modelName': modelName,
        'wasCorrected': wasCorrected,
      };

  factory ReceiptOperation.fromJson(Map<String, dynamic> json) {
    return ReceiptOperation(
      userId: json['userId'] as String,
      operationId: json['operationId'] as String,
      walletId: json['walletId'] as String,
      amount: json['amount'] as num,
      currency: json['currency'] as String,
      date: DateTime.parse(json['date'] as String),
      merchant: json['merchant'] as String?,
      categoryId: json['categoryId'] as String?,
      payment: json['payment'] as String?,
      rawText: json['rawText'] as String?,
      transactionId: json['transactionId'] as String?,
      storagePath: json['storagePath'] as String?,
      receiptInserted: json['receiptInserted'] as bool? ?? false,
      classificationRecorded: json['classificationRecorded'] as bool? ?? false,
      predictedCategoryId: json['predictedCategoryId'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      modelName: json['modelName'] as String?,
      wasCorrected: json['wasCorrected'] as bool? ?? false,
    );
  }
}

abstract class ReceiptOperationStore {
  Future<void> save(ReceiptOperation operation);
  Future<ReceiptOperation?> find(String userId, String operationId);
  Future<List<ReceiptOperation>> pendingFor(String userId);
  Future<void> remove(String userId, String operationId);
}

class MemoryReceiptOperationStore implements ReceiptOperationStore {
  final Map<String, ReceiptOperation> _items = {};

  String _key(String userId, String operationId) => '$userId|$operationId';

  @override
  Future<ReceiptOperation?> find(String userId, String operationId) async {
    return _items[_key(userId, operationId)];
  }

  @override
  Future<List<ReceiptOperation>> pendingFor(String userId) async {
    return _items.values.where((item) => item.userId == userId).toList();
  }

  @override
  Future<void> remove(String userId, String operationId) async {
    _items.remove(_key(userId, operationId));
  }

  @override
  Future<void> save(ReceiptOperation operation) async {
    _items[_key(operation.userId, operation.operationId)] = operation;
  }
}

class SharedPrefsReceiptOperationStore implements ReceiptOperationStore {
  SharedPrefsReceiptOperationStore(this._read, this._write);

  static const storageKey = 'receipt_operations_v1';

  final String? Function() _read;
  final Future<void> Function(String value) _write;

  List<ReceiptOperation> _all() {
    final raw = _read();
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => ReceiptOperation.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> _persist(List<ReceiptOperation> items) {
    return _write(jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  @override
  Future<ReceiptOperation?> find(String userId, String operationId) async {
    for (final item in _all()) {
      if (item.userId == userId && item.operationId == operationId) return item;
    }
    return null;
  }

  @override
  Future<List<ReceiptOperation>> pendingFor(String userId) async {
    return _all().where((item) => item.userId == userId).toList();
  }

  @override
  Future<void> remove(String userId, String operationId) async {
    final next = _all()
        .where((item) => item.userId != userId || item.operationId != operationId)
        .toList();
    await _persist(next);
  }

  @override
  Future<void> save(ReceiptOperation operation) async {
    final next = _all()
        .where(
          (item) =>
              item.userId != operation.userId ||
              item.operationId != operation.operationId,
        )
        .toList()
      ..add(operation);
    await _persist(next);
  }
}

/// Side effects for one confirmation. Tests substitute a fake.
abstract class ReceiptSaveGateway {
  Future<String> createTransaction(ReceiptOperation operation);
  Future<String> uploadReceipt(ReceiptOperation operation);
  Future<void> insertReceipt(ReceiptOperation operation);
  Future<void> recordClassification(ReceiptOperation operation);
}

class ReceiptConfirmationWorkflow {
  const ReceiptConfirmationWorkflow(this.store);

  final ReceiptOperationStore store;

  /// Runs only the steps that are not already recorded.
  /// The operation id is stored before the financial call, so a restart
  /// retries with the same PostgreSQL idempotency key.
  Future<ReceiptOperation> run({
    required ReceiptOperation operation,
    required ReceiptSaveGateway gateway,
  }) async {
    var current = operation;
    await store.save(current);

    if (!current.hasTransaction) {
      final transactionId = await gateway.createTransaction(current);
      current = current.copyWith(transactionId: transactionId);
      await store.save(current);
    }
    if (current.storagePath == null) {
      final path = await gateway.uploadReceipt(current);
      current = current.copyWith(storagePath: path);
      await store.save(current);
    }
    if (!current.receiptInserted) {
      await gateway.insertReceipt(current);
      current = current.copyWith(receiptInserted: true);
      await store.save(current);
    }
    if (!current.classificationRecorded) {
      await gateway.recordClassification(current);
      current = current.copyWith(classificationRecorded: true);
      await store.save(current);
    }
    await store.remove(current.userId, current.operationId);
    return current;
  }
}
