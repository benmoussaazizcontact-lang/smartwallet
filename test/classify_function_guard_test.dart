import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classify-transaction requires a user before calling the model', () {
    final source = File(
      'supabase/functions/classify-transaction/index.ts',
    ).readAsStringSync();
    final authAt = source.indexOf('auth.getUser');
    final modelAt = source.indexOf('api.openai.com');
    expect(authAt, greaterThan(0));
    expect(modelAt, greaterThan(authAt));
    expect(source, contains('Authentication required.'));
    expect(source, contains('401'));
    expect(source, contains('429'));
    expect(source, isNot(contains('classification_corrections')));
    expect(source, isNot(contains('service_role')));
    expect(source, isNot(contains('console.log')));
  });
}
