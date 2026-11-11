import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/auth/domain/account_deletion.dart';

void main() {
  test('account deletion requires the exact confirmation word', () {
    expect(accountDeletionConfirmed('supprimer', 'SUPPRIMER'), isTrue);
    expect(accountDeletionConfirmed(' SUPPRIMER ', 'SUPPRIMER'), isTrue);
    expect(accountDeletionConfirmed('delete', 'SUPPRIMER'), isFalse);
    expect(accountDeletionConfirmed('', 'SUPPRIMER'), isFalse);
  });
}
