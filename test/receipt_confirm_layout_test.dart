import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/receipts/services/ocr_parser.dart';
import 'package:wallet_app/features/receipts/services/receipt_confirmation.dart';

void main() {
  testWidgets('the confirm button stays above the navigation bar', (tester) async {
    await tester.pumpWidget(_confirmHarness());
    final button = tester.getRect(find.text('Confirmer et enregistrer'));
    final nav = tester.getRect(find.byType(NavigationBar));
    expect(button.bottom, lessThanOrEqualTo(nav.top));
    expect(button.top, greaterThan(0));
    expect(find.text('Confirmer et enregistrer'), findsOneWidget);
  });

  testWidgets('the form scrolls and the button stays visible', (tester) async {
    await tester.pumpWidget(_confirmHarness());
    expect(find.text('Champ 0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Champ 24'), 200, scrollable: find.byType(Scrollable));
    expect(find.text('Champ 24'), findsOneWidget);
    expect(tester.getRect(find.text('Confirmer et enregistrer')).bottom, lessThanOrEqualTo(tester.getRect(find.byType(NavigationBar)).top));
  });

  testWidgets('an open keyboard does not cover the confirm button', (tester) async {
    await tester.pumpWidget(_confirmHarness(keyboard: 280));
    final button = tester.getRect(find.text('Confirmer et enregistrer'));
    final view = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(button.bottom, lessThanOrEqualTo(view - 280));
  });

  testWidgets('cancel leaves the screen and confirm is one action', (tester) async {
    var saved = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(
      builder: (context) => TextButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _confirmPage(onSave: () => saved++),
          ));
        },
        child: const Text('Ouvrir'),
      ),
    )));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer et enregistrer'), findsNothing);
    expect(saved, 0);
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer et enregistrer'));
    await tester.pump();
    expect(saved, 1);
    expect(find.text('Confirmer et enregistrer'), findsOneWidget);
  });

  test('a second confirmation reuses the same operation id', () {
    final first = ReceiptOperation(
      userId: 'user',
      operationId: 'receipt-1',
      walletId: 'wallet',
      amount: 3,
      currency: 'TND',
      date: DateTime.utc(2026, 11, 10),
    );
    final second = ReceiptOperation(
      userId: 'user',
      operationId: first.operationId,
      walletId: 'wallet',
      amount: 3,
      currency: 'TND',
      date: first.date,
    );
    expect(second.operationId, first.operationId);
  });

  test('an unreadable ticket does not invent a merchant or an amount', () {
    final parsed = const OcrParser().parse('   \n');
    expect(parsed.merchant, isNull);
    expect(parsed.total, isNull);
    expect(parsed.amountNeedsReview, isTrue);
    expect(parsed.receiptNumber, isNull);
  });
}

Widget _confirmHarness({double keyboard = 0, VoidCallback? onSave}) {
  return MaterialApp(home: _confirmPage(keyboard: keyboard, onSave: onSave));
}

Widget _confirmPage({double keyboard = 0, VoidCallback? onSave}) {
  return Builder(
    builder: (context) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          extendBody: false,
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < 30; i++) ListTile(title: Text('Champ $i')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: onSave ?? () {},
                      child: const Text('Confirmer et enregistrer'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: 3,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Accueil'),
              NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Portefeuilles'),
              NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Transactions'),
              NavigationDestination(icon: Icon(Icons.document_scanner), label: 'Scanner'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Paramètres'),
            ],
          ),
        ),
      );
    },
  );
}
