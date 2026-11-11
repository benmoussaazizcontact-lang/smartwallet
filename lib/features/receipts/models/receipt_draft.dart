import 'dart:typed_data';

class ReceiptDraft {
  const ReceiptDraft({
    required this.operationId,
    required this.imageBytes,
    required this.imagePath,
    this.rawText,
    this.merchant,
    this.receiptNumber,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.date,
    this.tax,
    this.items = const [],
    this.arabicScriptSeen = false,
    this.amountNeedsReview = false,
  });

  /// Stable id for this confirmation. Reused as `client_request_id`.
  final String operationId;
  final Uint8List imageBytes;
  final String imagePath;
  final String? rawText;
  final String? merchant;
  final String? receiptNumber;
  final num? amount;
  final String? currency;
  final String? paymentMethod;
  final DateTime? date;
  final num? tax;
  final List<String> items;
  final bool arabicScriptSeen;
  final bool amountNeedsReview;
}
