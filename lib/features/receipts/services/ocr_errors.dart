import '../../../l10n/generated/app_localizations.dart';

class OcrFailure implements Exception {
  const OcrFailure(this.kind);

  final OcrFailureKind kind;

  @override
  String toString() => kind.name;
}

enum OcrFailureKind { unreadable, noText, engine }

String localizedOcrMessage(Object error, AppLocalizations l10n) {
  if (error is OcrFailure) {
    return switch (error.kind) {
      OcrFailureKind.unreadable => l10n.ocrUnreadableImage,
      OcrFailureKind.noText => l10n.ocrNoText,
      OcrFailureKind.engine => l10n.ocrEngineFailed,
    };
  }
  final text = error.toString().toLowerCase();
  if (text.contains('no text') || text.contains('empty')) {
    return l10n.ocrNoText;
  }
  if (text.contains('nullpointer') ||
      text.contains('getclass') ||
      text.contains('platformexception') ||
      text.contains('inputimage') ||
      text.contains('mlkit')) {
    return l10n.ocrEngineFailed;
  }
  return l10n.ocrEngineFailed;
}
