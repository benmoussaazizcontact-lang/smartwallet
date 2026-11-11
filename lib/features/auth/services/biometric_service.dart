import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/biometric_lock.dart';

/// Service biométrie utilisant local_auth.
/// ⚠️ La biométrie est un verrou LOCAL uniquement — elle ne remplace pas
/// l'authentification Supabase côté serveur. Elle protège l'accès à l'app
/// sur l'appareil, mais la session Supabase reste active en arrière-plan.
class BiometricService {
  BiometricService()
    : _auth = LocalAuthentication(),
      _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;
  final BiometricLockPolicy lock = BiometricLockPolicy();

  static const _bioEnabledKey = 'biometric_enabled';
  static const _bioUserKey = 'biometric_user_id';
  static DateTime? _lastSuccessfulAuthentication;
  Future<bool>? _authenticationInFlight;

  bool get recentlyAuthenticated {
    final last = _lastSuccessfulAuthentication;
    return last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 2);
  }

  void clearRecentAuthentication() => _lastSuccessfulAuthentication = null;

  void onLifecycle(LockSignal signal) => lock.apply(signal);

  /// Vérifie si le matériel biométrique est disponible
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    final canCheck = await _auth.canCheckBiometrics;
    final isSupported = await _auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Retourne les types biométriques disponibles
  Future<List<BiometricType>> getAvailableTypes() async {
    if (kIsWeb) return [];
    return _auth.getAvailableBiometrics();
  }

  /// Vérifie si la biométrie est activée pour un utilisateur
  Future<bool> isEnabledForUser(String userId) async {
    final enabled = await _storage.read(key: _bioEnabledKey);
    final storedUser = await _storage.read(key: _bioUserKey);
    return enabled == 'true' && storedUser == userId;
  }

  /// Active la biométrie pour un utilisateur après vérification réussie
  Future<bool> enable(String userId) async {
    if (!await isAvailable()) return false;
    final authenticated = await authenticate(
      reason: 'Confirmez votre empreinte pour activer la biométrie',
    );
    if (!authenticated) return false;
    await _storage.write(key: _bioEnabledKey, value: 'true');
    await _storage.write(key: _bioUserKey, value: userId);
    return true;
  }

  /// Désactive la biométrie
  Future<bool> disable(String userId) async {
    if (!await isAvailable()) return false;
    final authenticated = await authenticate(
      reason: 'Confirmez votre empreinte pour désactiver la biométrie',
    );
    if (!authenticated) return false;
    final storedUser = await _storage.read(key: _bioUserKey);
    if (storedUser != userId) return false;
    await _storage.delete(key: _bioEnabledKey);
    await _storage.delete(key: _bioUserKey);
    return true;
  }

  /// Recovery path after an explicit Supabase sign-out when local auth is
  /// unavailable. It only clears this device's preference; it cannot unlock
  /// the existing authenticated session.
  Future<void> clearPreferenceAfterSignOut() async {
    await _storage.delete(key: _bioEnabledKey);
    await _storage.delete(key: _bioUserKey);
    clearRecentAuthentication();
  }

  /// Authentifie l'utilisateur via biométrie
  Future<bool> authenticate({
    String reason = 'Vérifiez votre identité pour accéder à l\'application',
  }) {
    final pending = _authenticationInFlight;
    if (pending != null) return pending;
    final future = _authenticate(reason);
    _authenticationInFlight = future;
    return future.whenComplete(() => _authenticationInFlight = null);
  }

  Future<bool> _authenticate(String reason) async {
    if (kIsWeb) return false;
    final available = await isAvailable();
    if (!available) return false;
    final epoch = lock.epoch;
    final authenticated = await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
    if (!authenticated || epoch != lock.epoch) return false;
    _lastSuccessfulAuthentication = DateTime.now();
    lock.unlock(epoch);
    return true;
  }
}
