import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class Env {
  Env._();

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (value.isEmpty || !value.startsWith('https://')) {
      throw StateError('SUPABASE_URL manquante ou invalide dans .env');
    }
    return value;
  }

  /// Optional inference service. Empty means the app keeps the on-device baseline.
  static String? get mlServiceUrl {
    final value = dotenv.env['SMARTWALLET_ML_URL']?.trim() ?? '';
    if (value.isEmpty || !value.startsWith('https://')) return null;
    return value;
  }

  static String get supabasePublishableKey {
    final value =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ??
        dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
        '';
    if (value.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY manquante dans .env');
    }
    return value;
  }

  /// Firebase client configuration is public app metadata, never a server key.
  /// Notifications remain disabled until the Firebase app IDs are configured.
  static FirebaseOptions? get firebaseOptions {
    if (kIsWeb) return null; // Web push additionally needs a VAPID key/service worker.
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return null;
    }
    final appIdKey = platform == TargetPlatform.android
        ? 'FIREBASE_ANDROID_APP_ID'
        : 'FIREBASE_IOS_APP_ID';
    final apiKeyName = platform == TargetPlatform.android
        ? 'FIREBASE_ANDROID_API_KEY'
        : 'FIREBASE_IOS_API_KEY';
    final appId = dotenv.env[appIdKey]?.trim();
    final apiKey = dotenv.env[apiKeyName]?.trim();
    final fallbackApiKey = dotenv.env['FIREBASE_API_KEY']?.trim();
    final resolvedApiKey = apiKey?.isNotEmpty == true ? apiKey : fallbackApiKey;
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim();
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim();
    if (appId == null || appId.isEmpty ||
        resolvedApiKey == null || resolvedApiKey.isEmpty ||
        senderId == null || senderId.isEmpty ||
        projectId == null || projectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      appId: appId,
      apiKey: resolvedApiKey,
      messagingSenderId: senderId,
      projectId: projectId,
      iosBundleId: platform == TargetPlatform.iOS ? 'com.example.walletApp' : null,
    );
  }
}
