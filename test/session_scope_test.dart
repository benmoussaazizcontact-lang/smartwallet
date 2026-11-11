import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/session/session_scope.dart';

void main() {
  test('cached data is hidden when the account changes', () {
    expect(
      belongsToActiveUser(loadedFor: 'user-a', active: 'user-a'),
      isTrue,
    );
    expect(
      belongsToActiveUser(loadedFor: 'user-a', active: 'user-b'),
      isFalse,
    );
    expect(
      belongsToActiveUser(loadedFor: 'user-a', active: null),
      isFalse,
    );
    expect(
      belongsToActiveUser(loadedFor: null, active: 'user-b'),
      isFalse,
    );
  });
}
