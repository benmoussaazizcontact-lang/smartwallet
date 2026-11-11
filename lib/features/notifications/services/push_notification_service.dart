import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../wallets/services/low_balance_notification_service.dart';

@pragma('vm:entry-point')
Future<void> walletPushBackgroundHandler(RemoteMessage message) async {}

/// Registers the signed-in device with FCM and stores its token under the
/// authenticated Supabase user. Server credentials never enter this client.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  Future<void>? _initializing;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _userId;
  SupabaseClient? _client;
  bool _firebaseReady = false;

  Future<void> syncUser(SupabaseClient client, String userId) async {
    if (kIsWeb) return; // Web push requires a VAPID key and service worker setup.
    await (_initializing ??= _initialize());
    if (!_firebaseReady) return;

    // Auth emits token refresh and user-update events too. Register the token
    // only once for the current account instead of prompting on each event.
    if (_userId == userId && identical(_client, client)) return;

    if (_userId != null && _userId != userId) {
      await _removeDeviceToken(_client, _userId);
      _userId = null;
      _client = null;
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      // iOS may not have an FCM token until APNs registration has completed.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      final stored = await _storeDeviceToken(client, userId, token);
      if (!stored) return;
      _client = client;
      _userId = userId;
    } catch (error) {
      debugPrint('FCM device registration failed: ${error.runtimeType}');
      return;
    }
    _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (nextToken) {
        final activeClient = _client;
        final activeUserId = _userId;
        if (activeClient != null && activeUserId != null) {
          unawaited(
            _storeDeviceToken(activeClient, activeUserId, nextToken).then((_) {}),
          );
        }
      },
    );
  }

  Future<void> removeSignedInDevice(SupabaseClient client, String userId) async {
    if (!_firebaseReady) return;
    await _removeDeviceToken(client, userId);
    _userId = null;
    _client = null;
  }

  Future<void> _initialize() async {
    final options = Env.firebaseOptions;
    if (options == null) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      await LowBalanceNotificationService.instance.initialize();
      FirebaseMessaging.onBackgroundMessage(walletPushBackgroundHandler);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'Wallet';
        final body = message.notification?.body;
        if (body != null && body.isNotEmpty) {
          unawaited(
            LowBalanceNotificationService.instance.showForegroundMessage(
              title,
              body,
            ),
          );
        }
      });
      _firebaseReady = true;
    } on FirebaseException catch (error) {
      debugPrint('Firebase push setup unavailable: ${error.code}');
    } catch (error) {
      debugPrint('Firebase push setup unavailable: ${error.runtimeType}');
    }
  }

  Future<bool> _storeDeviceToken(
    SupabaseClient client,
    String userId,
    String token,
  ) async {
    try {
      await client.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
      return true;
    } catch (error) {
      debugPrint('Push token registration failed: ${error.runtimeType}');
      return false;
    }
  }

  Future<void> _removeDeviceToken(SupabaseClient? client, String? userId) async {
    if (client == null || userId == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await client
            .from('push_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
    } catch (error) {
      // Do not block an explicit sign-out if token cleanup is temporarily offline.
      debugPrint('Push token cleanup failed: ${error.runtimeType}');
    }
  }
}
