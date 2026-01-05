import 'dart:convert';

import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/token_service.dart';
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

    // Pedir permisos de notificación al abrir la app
    await _requestPushPermissions();

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
      _handleNavigationFromMessage(message);
    });

    _initialized = true;
    debugPrint('🔔 PushNotificationService initialized');
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logMessage(initialMessage, origin: 'INITIAL_MESSAGE');
      _handleNavigationFromMessage(initialMessage);
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

  static Future<void> _requestPushPermissions() async {
    try {
      // Solo pedir permisos en plataformas soportadas por FCM
      if (kIsWeb) {
        debugPrint('🔔 Push permissions skipped: web platform');
        return;
      }

      const supportedPlatforms = {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      };

      if (!supportedPlatforms.contains(defaultTargetPlatform)) {
        debugPrint('🔔 Push permissions skipped: unsupported platform');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('🔔 Permission status: ${settings.authorizationStatus}');

      // Solo obtener y guardar el token si el usuario autorizó
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        debugPrint('🔥 FCM Token (on launch): $token');

        if (token != null && token.isNotEmpty) {
          await TokenService.saveFcmToken(token);
        }
      }
    } catch (e, st) {
      debugPrint('🔔 Error requesting push permissions: $e');
      debugPrint('$st');
    }
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

  static void _handleNavigationFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    // data['data'] puede venir como string JSON o map. Parsear con cuidado.
    Map<String, dynamic> parsedData = {};
    final rawDataField = data['data'];
    if (rawDataField != null) {
      try {
        if (rawDataField is String) {
          parsedData = Map<String, dynamic>.from(jsonDecode(rawDataField));
        } else if (rawDataField is Map) {
          parsedData = Map<String, dynamic>.from(rawDataField as Map);
        }
        debugPrint('­ƒöù [PushNotificationService] parsedData: $parsedData');
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] No se pudo parsear data: $e');
      }
    }
    // payload_json puede traer playerData/responses
    final payloadJsonRaw = data['payload_json'];
    if (payloadJsonRaw != null) {
      try {
        Map<String, dynamic> payloadJson;
        if (payloadJsonRaw is String) {
          payloadJson = Map<String, dynamic>.from(jsonDecode(payloadJsonRaw));
        } else if (payloadJsonRaw is Map) {
          payloadJson = Map<String, dynamic>.from(payloadJsonRaw as Map);
        } else {
          payloadJson = {};
        }

        // Mezclar sin pisar campos ya presentes
        parsedData = {...payloadJson, ...parsedData};
        debugPrint(
          '-- [PushNotificationService] payload_json merged: $parsedData',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [PushNotificationService] No se pudo parsear payload_json: $e',
        );
      }
    }

    final deeplinkRaw =
        parsedData['deeplink'] ??
        data['deeplink'] ??
        data['deep_link'] ??
        data['link'] ??
        data['url'];
    final deeplink = deeplinkRaw?.toString().trim();

    debugPrint('­ƒöù [PushNotificationService] deeplink detectado: $deeplink');
    debugPrint('­ƒöù [PushNotificationService] message.data: $data');
    debugPrint('­ƒöù [PushNotificationService] rawDataField: $rawDataField');
    debugPrint(
      '­ƒöù [PushNotificationService] full message: ${message.toMap()}',
    );

    AffiliationResult? affiliationResult;
    try {
      final playerData = parsedData['playerData'];
      final responses = parsedData['responses'];
      if (playerData is Map && responses is Map) {
        affiliationResult = AffiliationResult.fromJson({
          'playerData': playerData,
          'responses': responses,
        });
        try {
          debugPrint(
            '­ƒöù [PushNotificationService] AffiliationResult json: ${jsonEncode(affiliationResult)}',
          );
        } catch (_) {
          debugPrint(
            '­ƒöù [PushNotificationService] AffiliationResult no serializable con jsonEncode',
          );
        }
      } else {
        debugPrint(
          '⚠️ [PushNotificationService] playerData/responses faltan o no son Map',
        );
      }
    } catch (e) {
      debugPrint(
        '⚠️ [PushNotificationService] No se pudo construir AffiliationResult: $e',
      );
    }

    final hasAffiliationPayload = affiliationResult != null;

    // Si no hay deeplink pero sí payload de afiliación, navegar igual.
    if ((deeplink == null || deeplink.isEmpty) && hasAffiliationPayload) {
      debugPrint(
        '­ƒöù [PushNotificationService] Sin deeplink pero con payload de afiliación, navegando directo.',
      );
      appRouter.routerDelegate.navigatorKey.currentState?.popUntil(
        (r) => r.isFirst,
      );
      appRouter.go('/affiliation-results', extra: affiliationResult);
      return;
    }

    if (deeplink == null || deeplink.isEmpty) return;

    try {
      final uri = Uri.parse(deeplink.toString());
      final token =
          data['token'] ??
          data['verificacionToken'] ??
          data['verification_token'];

      final payload = DeepLinkPayload(uri: uri, token: token?.toString());

      debugPrint(
        '­ƒöù [PushNotificationService] DeepLinkPayload uri=$uri token=$token',
      );

      DeepLinkService.instance.emit(payload);

      String? route = DeepLinkService.instance.navigationPathForPayload(
        payload,
      );
      debugPrint('­ƒöù [PushNotificationService] navigationPath: $route');

      // Fallback: si el deeplink es afiliación completada pero no obtuvimos ruta
      if ((route == null || route.isEmpty) && payload.isAffiliationCompleted) {
        route = '/affiliation-results';
        debugPrint(
          '­ƒöù [PushNotificationService] Fallback a /affiliation-results',
        );
      }

      if (route != null && route.isNotEmpty) {
        if (route == '/affiliation-results' && affiliationResult != null) {
          debugPrint(
            '­ƒöù [PushNotificationService] Navegando a $route con extra AffiliationResult',
          );
          // Asegurar que la navegación use el stack raíz
          appRouter.routerDelegate.navigatorKey.currentState?.popUntil(
            (r) => r.isFirst,
          );
          // go + extra garantiza reemplazo de la ubicación actual
          appRouter.go(route, extra: affiliationResult);
        } else {
          debugPrint(
            '­ƒöù [PushNotificationService] Navegando a $route sin extra',
          );
          appRouter.routerDelegate.navigatorKey.currentState?.popUntil(
            (r) => r.isFirst,
          );
          appRouter.go(route);
        }
        DeepLinkService.instance.markPayloadHandled(payload);
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error manejando deeplink: $e');
    }
  }
}
