import 'dart:async';
import 'dart:convert';

import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centraliza los listeners de FCM para mensajes en foreground y arranques desde notificaciones.
class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;
  static bool _listening = false;
  static bool _enabledCache = true;
  static bool _adsEnabledCache = true;
  static bool _forumEnabledCache = true;

  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

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
    if (!_initialized) {
      await _setupLocalNotifications();
      _initialized = true;
    }

    // Cachear preferencia y aplicar estado.
    _enabledCache = await TokenService.getNotificationsEnabled();
    _adsEnabledCache = await TokenService.getAdsNotificationsEnabled();
    _forumEnabledCache = await TokenService.getForumNotificationsEnabled();
    if (!_enabledCache) {
      await _disableNotificationsFlow(deleteRemoteToken: false);
      debugPrint('🔕 PushNotificationService: notifications disabled (init)');
      return;
    }

    await _enableNotificationsFlow();
  }

  static Future<bool> isNotificationsEnabled() async {
    _enabledCache = await TokenService.getNotificationsEnabled();
    return _enabledCache;
  }

  static Future<bool> isAdsNotificationsEnabled() async {
    _adsEnabledCache = await TokenService.getAdsNotificationsEnabled();
    return _adsEnabledCache;
  }

  static Future<bool> isForumNotificationsEnabled() async {
    _forumEnabledCache = await TokenService.getForumNotificationsEnabled();
    return _forumEnabledCache;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    _enabledCache = enabled;
    await TokenService.setNotificationsEnabled(enabled);

    if (enabled) {
      await _enableNotificationsFlow();
    } else {
      await _disableNotificationsFlow(deleteRemoteToken: true);
    }
  }

  static Future<void> setAdsNotificationsEnabled(bool enabled) async {
    _adsEnabledCache = enabled;
    await TokenService.setAdsNotificationsEnabled(enabled);
  }

  static Future<void> setForumNotificationsEnabled(bool enabled) async {
    _forumEnabledCache = enabled;
    await TokenService.setForumNotificationsEnabled(enabled);
  }

  static Future<void> _enableNotificationsFlow() async {
    try {
      if (kIsWeb) {
        debugPrint('🔔 Push enable skipped: web platform');
        return;
      }

      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      // Pedir permisos de notificación al abrir la app
      await _requestPushPermissions();

      // Mensaje que abrió la app desde terminada (cold start)
      await _handleInitialMessage();

      await _startListening();

      debugPrint('🔔 PushNotificationService enabled');
    } catch (e, st) {
      debugPrint('🔔 Error enabling notifications: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _disableNotificationsFlow({
    required bool deleteRemoteToken,
  }) async {
    try {
      await _stopListening();
      await _localNotificationsPlugin.cancelAll();

      if (!kIsWeb) {
        await FirebaseMessaging.instance.setAutoInitEnabled(false);

        if (deleteRemoteToken) {
          try {
            await FirebaseMessaging.instance.deleteToken();
          } catch (e) {
            debugPrint('🔕 Error deleting FCM token: $e');
          }
        }
      }

      await TokenService.deleteFcmToken();

      debugPrint('🔕 PushNotificationService disabled');
    } catch (e, st) {
      debugPrint('🔕 Error disabling notifications: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _startListening() async {
    if (_listening) return;

    // Mensajes recibidos con la app en foreground
    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      if (!_enabledCache) return;
      if (!_shouldAllowMessage(message)) return;
      _logMessage(message, origin: 'FOREGROUND');
      _showLocalNotification(message);
    });

    // Usuario toca una notificación con la app en background
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      if (!_enabledCache) return;
      if (!_shouldAllowMessage(message)) return;
      _logMessage(message, origin: 'OPENED_APP');
      _handleNavigationFromMessage(message);
    });

    _listening = true;
  }

  static Future<void> _stopListening() async {
    if (!_listening) return;

    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedSub = null;
    _listening = false;
  }

  static Future<void> _handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && _shouldAllowMessage(initialMessage)) {
      _logMessage(initialMessage, origin: 'INITIAL_MESSAGE');
      _handleNavigationFromMessage(initialMessage);
    }
  }

  static bool _shouldAllowMessage(RemoteMessage message) {
    if (!_enabledCache) return false;

    final data = Map<String, dynamic>.from(message.data);

    // Fallback: cuando no hay data útil, usar texto para heurística básica.
    if (data.isEmpty) {
      data['title'] = message.notification?.title ?? '';
      data['body'] = message.notification?.body ?? '';
    }

    return _shouldAllowData(data);
  }

  static bool _shouldAllowData(Map<String, dynamic> data) {
    if (!_enabledCache) return false;

    if (!_forumEnabledCache && _isForumNotification(data)) {
      return false;
    }

    if (!_adsEnabledCache && _isAdsNotification(data)) {
      return false;
    }

    return true;
  }

  static bool _isForumNotification(Map<String, dynamic> data) {
    final text = _flattenNotificationData(data);
    const forumMarkers = [
      'forum',
      'foro',
      '/forum/',
      '/foro/',
      'post',
      'publicacion',
      'publicaciones',
      'respuesta',
      'reply',
    ];
    return forumMarkers.any(text.contains);
  }

  static bool _isAdsNotification(Map<String, dynamic> data) {
    final text = _flattenNotificationData(data);
    const adsMarkers = [
      'ad',
      'ads',
      'advert',
      'advertising',
      'promo',
      'promocion',
      'promoción',
      'publicidad',
      'campaign',
      'cupon',
      'cupón',
      'descuento',
      'oferta',
    ];
    return adsMarkers.any(text.contains);
  }

  static String _flattenNotificationData(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    void appendValue(dynamic value) {
      if (value == null) return;
      if (value is String) {
        buffer.write(' ');
        buffer.write(value.toLowerCase());
        return;
      }
      if (value is num || value is bool) {
        buffer.write(' ');
        buffer.write(value.toString().toLowerCase());
        return;
      }
      if (value is Map) {
        for (final entry in value.entries) {
          appendValue(entry.key);
          appendValue(entry.value);
        }
        return;
      }
      if (value is Iterable) {
        for (final item in value) {
          appendValue(item);
        }
        return;
      }
      appendValue(value.toString());
    }

    appendValue(data);
    return buffer.toString();
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
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (!_enabledCache) return;
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            final data = Map<String, dynamic>.from(decoded as Map);
            if (!_shouldAllowData(data)) return;
            debugPrint('📩 [LOCAL_TAP] payload decoded: ${data.keys.toList()}');
            _handleNavigationFromData(data);
          } else {
            debugPrint('⚠️ [LOCAL_TAP] payload no es Map');
          }
        } catch (e) {
          debugPrint('⚠️ [LOCAL_TAP] No se pudo parsear payload: $e');
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          _localNotificationTapBackgroundHandler,
    );

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
    if (!_enabledCache) return;

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

    String? payload;
    try {
      payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
    } catch (e) {
      debugPrint('⚠️ [LOCAL] No se pudo serializar payload: $e');
      payload = null;
    }

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  @pragma('vm:entry-point')
  static void _localNotificationTapBackgroundHandler(
    NotificationResponse response,
  ) {
    // Este callback puede correr en un isolate de background.
    // No intentamos navegar aquí; la navegación real se resuelve con
    // getInitialMessage/onMessageOpenedApp cuando la app está lista.
    debugPrint('📩 [LOCAL_TAP_BG] actionId=${response.actionId}');
  }

  static void _navigateToRoute(String route, {Object? extra}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        var targetRoute = route;
        if (route.startsWith('/forum/post/')) {
          final separator = route.contains('?') ? '&' : '?';
          targetRoute =
              '$route${separator}refresh=1&ts=${DateTime.now().millisecondsSinceEpoch}';
        }

        final navigator = appRouter.routerDelegate.navigatorKey.currentState;

        // Si no hay stack para volver, crear una base razonable.
        // Esto evita errores al “volver” luego de abrir por notificación.
        final canPop = navigator?.canPop() ?? false;
        if (!canPop) {
          appRouter.go('/home');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (extra != null) {
              appRouter.push(targetRoute, extra: extra);
            } else {
              appRouter.push(targetRoute);
            }
          });
          return;
        }

        if (extra != null) {
          appRouter.push(targetRoute, extra: extra);
        } else {
          appRouter.push(targetRoute);
        }
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] Error navegando a $route: $e');
      }
    });
  }

  static void _handleNavigationFromData(Map<String, dynamic> data) {
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
        debugPrint('📩 [PushNotificationService] parsedData: $parsedData');
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

    debugPrint('📩 [PushNotificationService] deeplink detectado: $deeplink');

    AffiliationResult? affiliationResult;
    try {
      final playerData = parsedData['playerData'];
      final responses = parsedData['responses'];
      if (playerData is Map && responses is Map) {
        affiliationResult = AffiliationResult.fromJson({
          'playerData': playerData,
          'responses': responses,
        });
      }
    } catch (_) {}

    final hasAffiliationPayload = affiliationResult != null;
    if ((deeplink == null || deeplink.isEmpty) && hasAffiliationPayload) {
      // Mantener comportamiento existente para afiliación.
      appRouter.routerDelegate.navigatorKey.currentState?.popUntil(
        (r) => r.isFirst,
      );
      appRouter.go('/affiliation-results', extra: affiliationResult);
      return;
    }

    if (deeplink == null || deeplink.isEmpty) return;

    try {
      final uri = Uri.parse(deeplink);
      final token =
          data['token'] ??
          data['verificacionToken'] ??
          data['verification_token'];

      final payload = DeepLinkPayload(uri: uri, token: token?.toString());
      DeepLinkService.instance.emit(payload);

      String? route = DeepLinkService.instance.navigationPathForPayload(
        payload,
      );

      if ((route == null || route.isEmpty) && payload.isAffiliationCompleted) {
        route = '/affiliation-results';
      }

      if (route != null && route.isNotEmpty) {
        if (route == '/affiliation-results' && affiliationResult != null) {
          appRouter.routerDelegate.navigatorKey.currentState?.popUntil(
            (r) => r.isFirst,
          );
          appRouter.go(route, extra: affiliationResult);
        } else {
          // Para deeplinks genéricos (ej foro), usar push para que exista back.
          _navigateToRoute(route);
        }
        DeepLinkService.instance.markPayloadHandled(payload);
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error manejando deeplink: $e');
    }
  }

  static void _handleNavigationFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    // Logs útiles para debugging.
    debugPrint('📩 [PushNotificationService] message.data: $data');
    debugPrint('📩 [PushNotificationService] full message: ${message.toMap()}');

    _handleNavigationFromData(Map<String, dynamic>.from(data));
  }
}
