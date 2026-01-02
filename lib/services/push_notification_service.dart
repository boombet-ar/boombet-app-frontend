import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centraliza los listeners de FCM para mensajes en foreground y arranques desde notificaciones.
class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'boombet_default';
  static const String _channelName = 'BoomBet Notifications';
  static const String _channelDescription = 'Notificaciones de BoomBet';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      );

  static Future<void> initialize() async {
    if (_initialized) return;

    await _setupLocalNotifications();

    // Mensaje que abrió la app desde terminada (cold start)
    await _handleInitialMessage();

    // Mensajes recibidos con la app en foreground
    FirebaseMessaging.onMessage.listen((message) {
      _logMessage(message, origin: 'FOREGROUND');
      _showLocalNotification(message);
    });

    // Usuario toca una notificación con la app en background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _logMessage(message, origin: 'OPENED_APP');
    });

    _initialized = true;
    debugPrint('🔔 PushNotificationService initialized');
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logMessage(initialMessage, origin: 'INITIAL_MESSAGE');
    }
  }

  static void _logMessage(RemoteMessage message, {required String origin}) {
    final notification = message.notification;

    debugPrint('📩 [$origin] messageId: ${message.messageId}');
    debugPrint('📩 [$origin] title: ${notification?.title}');
    debugPrint('📩 [$origin] body: ${notification?.body}');

    if (message.data.isNotEmpty) {
      debugPrint('📩 [$origin] data: ${message.data}');
    }
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initSettings);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      ticker: 'BoomBet',
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }
}
