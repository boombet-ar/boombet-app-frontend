import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Centraliza los listeners de FCM para mensajes en foreground y arranques desde notificaciones.
class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Mensaje que abrió la app desde terminada (cold start)
    await _handleInitialMessage();

    // Mensajes recibidos con la app en foreground
    FirebaseMessaging.onMessage.listen((message) {
      _logMessage(message, origin: 'FOREGROUND');
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
}
