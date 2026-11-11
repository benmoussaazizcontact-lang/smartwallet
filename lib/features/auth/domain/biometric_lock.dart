/// Local lock signals. `inactive` is a transient system state, including the
/// biometric dialog itself, and must not lock or unlock the app.
enum LockSignal { inactive, paused, hidden, resumed }

class BiometricLockPolicy {
  bool locked = true;
  LockSignal phase = LockSignal.resumed;
  int epoch = 0;

  void apply(LockSignal signal) {
    phase = signal;
    if (signal == LockSignal.paused || signal == LockSignal.hidden) {
      locked = true;
      epoch += 1;
    }
  }

  void unlock(int epochAtStart) {
    if (epochAtStart != epoch) return;
    locked = false;
  }

  /// Financial screens stay hidden until a signed-in user passes an enabled lock.
  bool blocksFinancialContent({required bool enabled, required String? userId}) {
    if (userId == null) return true;
    if (!enabled) return false;
    return locked;
  }
}
