import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension AsyncValueRead<T> on AsyncValue<T> {
  T? get orNull => asData?.value;
}

/// Passe à `true` après [Supabase.initialize] dans [BootstrapApp].
class SupabaseBootstrapNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() => state = true;
}

final supabaseBootstrapReadyProvider =
    NotifierProvider<SupabaseBootstrapNotifier, bool>(
      SupabaseBootstrapNotifier.new,
    );

final supabaseProvider = Provider<SupabaseClient>((ref) {
  ref.watch(supabaseBootstrapReadyProvider);
  return Supabase.instance.client;
});

/// Session Supabase synchronisée avec [onAuthStateChange].
class CurrentSessionNotifier extends Notifier<Session?> {
  StreamSubscription<AuthState>? _subscription;

  @override
  Session? build() {
    _subscription?.cancel();
    _subscription = null;

    if (!ref.watch(supabaseBootstrapReadyProvider)) {
      return null;
    }

    final client = ref.watch(supabaseProvider);
    _subscription = client.auth.onAuthStateChange.listen((event) {
      // A null session is authoritative only for a real sign-out. Other
      // transient auth notifications must not erase the last usable session.
      if (event.session != null || event.event == AuthChangeEvent.signedOut) {
        state = event.session;
      }
    });
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    return client.auth.currentSession;
  }
}

final currentSessionProvider =
    NotifierProvider<CurrentSessionNotifier, Session?>(
      CurrentSessionNotifier.new,
    );

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

/// Latest Supabase auth event. A password-recovery link is distinct from a
/// normal sign-in so the app can ask for a new password.
class LastAuthEventNotifier extends Notifier<AuthChangeEvent?> {
  StreamSubscription<AuthState>? _subscription;

  @override
  AuthChangeEvent? build() {
    _subscription?.cancel();
    _subscription = null;
    if (!ref.watch(supabaseBootstrapReadyProvider)) return null;

    final client = ref.watch(supabaseProvider);
    _subscription = client.auth.onAuthStateChange.listen((event) {
      state = event.event;
    });
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return null;
  }
}

final lastAuthEventProvider =
    NotifierProvider<LastAuthEventNotifier, AuthChangeEvent?>(
      LastAuthEventNotifier.new,
    );
