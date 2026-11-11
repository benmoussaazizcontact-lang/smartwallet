import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/auth/auth_redirect.dart';

void main() {
  test('email links open the app instead of localhost', () {
    expect(authCallbackUrl, 'smartwallet://auth/callback');
    expect(authCallbackUrl.contains('localhost'), isFalse);
    expect(Uri.parse(authCallbackUrl).scheme, 'smartwallet');
    expect(isAuthCallbackLocation('/callback'), isTrue);
    expect(isAuthCallbackLocation('smartwallet://auth/callback'), isTrue);
    expect(isAuthCallbackLocation('/home'), isFalse);
    expect(
      isRecoveryLink(Uri.parse('smartwallet://auth/callback?type=recovery')),
      isTrue,
    );
    expect(
      isRecoveryLink(Uri.parse('smartwallet://auth/callback?type=signup')),
      isFalse,
    );
  });
}
