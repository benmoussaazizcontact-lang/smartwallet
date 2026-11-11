import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/shared/widgets/app_button.dart';
import 'package:wallet_app/shared/widgets/empty_state.dart';

void main() {
  test('email validator', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('bad'), isNotNull);
    expect(Validators.email('user@example.com'), isNull);
  });

  test('password validator', () {
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password('longenough'), isNull);
  });

  testWidgets('empty state shows action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EmptyState(
          title: 'None',
          message: 'Create one',
          actionLabel: 'Add',
          onAction: () => tapped = true,
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });

  testWidgets('app button disables while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Go', loading: true, onPressed: null),
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
