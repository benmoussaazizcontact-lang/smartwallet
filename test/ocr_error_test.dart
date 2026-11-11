import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/i18n/l10n_ext.dart';
import 'package:wallet_app/features/receipts/services/ocr_errors.dart';

void main() {
  testWidgets('OCR errors are localized and never expose Java stacks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = tester.element(find.byType(SizedBox)).l10n;
    const java = "java.lang.NullPointerException: Attempt to invoke virtual method "
        "'java.lang.Class java.lang.Object.getClass()' on a null object reference";
    final message = localizedOcrMessage(java, l10n);
    expect(message, l10n.ocrEngineFailed);
    expect(message.contains('NullPointerException'), isFalse);
    expect(message.contains('getClass'), isFalse);
    expect(localizedOcrMessage(const OcrFailure(OcrFailureKind.noText), l10n), l10n.ocrNoText);
    expect(
      localizedOcrMessage(const OcrFailure(OcrFailureKind.unreadable), l10n),
      l10n.ocrUnreadableImage,
    );
  });
}
