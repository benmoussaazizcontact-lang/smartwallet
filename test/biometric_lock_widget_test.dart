import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/features/auth/domain/biometric_lock.dart';

class _LockHost extends StatelessWidget {
  const _LockHost({required this.policy, required this.enabled, required this.userId});

  final BiometricLockPolicy policy;
  final bool enabled;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    if (policy.blocksFinancialContent(enabled: enabled, userId: userId)) {
      return const Text('Confirmez votre identité');
    }
    return const Text('Dépenses 703.900 TND');
  }
}

void main() {
  testWidgets('a paused app hides finances until the same lock epoch is unlocked', (tester) async {
    final policy = BiometricLockPolicy()..unlock(0);
    await tester.pumpWidget(MaterialApp(home: _LockHost(policy: policy, enabled: true, userId: 'user')));
    expect(find.text('Dépenses 703.900 TND'), findsOneWidget);

    policy.apply(LockSignal.paused);
    await tester.pumpWidget(MaterialApp(home: _LockHost(policy: policy, enabled: true, userId: 'user')));
    expect(find.text('Confirmez votre identité'), findsOneWidget);
    expect(find.text('Dépenses 703.900 TND'), findsNothing);

    policy.apply(LockSignal.inactive);
    await tester.pumpWidget(MaterialApp(home: _LockHost(policy: policy, enabled: true, userId: 'user')));
    expect(find.text('Confirmez votre identité'), findsOneWidget);
  });
}
