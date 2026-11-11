import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/errors/app_exception.dart';
import 'package:wallet_app/core/utils/validators.dart';

void main() {
  test('confirm password mismatch', () {
    expect(Validators.confirmPassword('abcabcabc', 'other'), isNotNull);
    expect(Validators.confirmPassword('abcdefgh', 'abcdefgh'), isNull);
  });

  test('maps supabase login error', () {
    final mapped = AppException.from('Invalid login credentials');
    expect(mapped.message.toLowerCase().contains('email'), isTrue);
  });

  test('maps network error', () {
    final mapped = AppException.from('SocketException: Failed host lookup');
    expect(mapped.code, 'network');
    expect(
      mapped.message.contains('Réseau') || mapped.message.contains('Network') || mapped.message.contains('الشبكة'),
      isTrue,
    );
  });

  test('signup email and password errors are not reported as network', () {
    final duplicate = AppException.from(
      'AuthApiException(message: A user with this email address has already been registered, statusCode: 422, code: user_already_exists)',
    );
    final smtp = AppException.from(
      'AuthApiException(message: Error sending confirmation email, statusCode: 500, code: unexpected_failure)',
    );
    final weak = AppException.from(
      'AuthApiException(message: Password should be at least 6 characters, statusCode: 422, code: weak_password)',
    );
    expect(duplicate.code, 'auth');
    expect(duplicate.message, isNot(contains('Network')));
    expect(smtp.code, 'email_delivery');
    expect(smtp.message, isNot(contains('Network')));
    expect(weak.code, 'auth');
    expect(weak.message, contains('password'));
  });
}
