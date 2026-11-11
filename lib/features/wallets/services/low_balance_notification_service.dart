import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Displays FCM messages while the app is in the foreground. Background and
/// terminated notifications are delivered by Firebase using its notification payload.
class LowBalanceNotificationService {
  LowBalanceNotificationService._();
  static final instance = LowBalanceNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;

  Future<void> initialize() async {
    await (_initializing ??= _initialize());
  }

  Future<void> showForegroundMessage(String title, String body) async {
    await initialize();
    await _plugin.show(
      100,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wallet_low_balance',
          'Alertes de solde',
          channelDescription: 'Alertes de solde des portefeuilles Wallet.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_wallet'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'wallet_low_balance',
        'Alertes de solde',
        description: 'Alertes de solde des portefeuilles Wallet.',
        importance: Importance.high,
      ),
    );
  }
}
