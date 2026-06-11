import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/infra/token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:boombet_app/services/infra/http_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  const NotificationService();

  /// Envía el FCM token al backend para habilitar notificaciones push.
  /// Requiere JWT en el header (includeAuth = true) y responde 200 vació.
  Future<bool> saveFcmTokenToBackend({String? fcmTokenOverride}) async {
    final url = '${ApiConfig.baseUrl}/notifications/save_fcmtoken';

    final fcmToken = fcmTokenOverride ?? await _tryGetFcmToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      log('🔔 [NotificationService] No FCM token available to send');
      return false;
    }

    final response = await HttpClient.post(
      url,
      body: {'token': fcmToken},
      includeAuth: true,
      maxRetries: 1,
      timeout: const Duration(seconds: 30),
    );

    final success = response.statusCode >= 200 && response.statusCode < 300;
    if (!success) {
      log(
        '🔔 [NotificationService] Failed to save FCM token. '
        'status=${response.statusCode} body=${response.body}',
      );
    }
    return success;
  }

  /// Dispara una notificación de test para el usuario autenticado.
  /// Endpoint: POST /api/notifications/me
  /// Nota: ApiConfig.baseUrl ya incluye /api.
  Future<bool> sendTestNotificationToMe({
    String title = 'BoomBet',
    String body = 'Notificación de prueba',
    Map<String, String>? data,
    bool ensureFcmRegistered = true,
  }) async {
    final url = '${ApiConfig.baseUrl}/notifications/me';

    if (ensureFcmRegistered) {
      // El backend usa JWT + FCM. Asegurar que haya FCM token disponible y registrado.
      final fcmToken = await _tryGetFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        log('🔔 [NotificationService] No FCM token available for test');
        return false;
      }

      // Registrar/actualizar el token en backend antes del test.
      await saveFcmTokenToBackend(fcmTokenOverride: fcmToken);
    }

    final requestBody = <String, dynamic>{
      'title': title,
      'body': body,
      if (data != null && data.isNotEmpty) 'data': data,
    };

    final response = await HttpClient.post(
      url,
      body: requestBody,
      includeAuth: true,
      maxRetries: 1,
      timeout: const Duration(seconds: 30),
    );

    final success = response.statusCode >= 200 && response.statusCode < 300;
    if (!success) {
      log(
        '🔔 [NotificationService] Failed to send test notification. '
        'status=${response.statusCode} body=${response.body}',
      );
    }
    return success;
  }

  Future<String?> _tryGetFcmToken() async {
    try {
      final stored = await TokenService.getFcmToken();
      if (stored != null && stored.isNotEmpty) return stored;

      // En Web, pedir getToken() puede disparar el prompt de permisos del browser.
      // No lo hacemos nunca.
      if (kIsWeb) return null;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await TokenService.saveFcmToken(token);
        return token;
      }
    } catch (e) {
      log('🔔 [NotificationService] No se pudo obtener FCM token: $e');
    }
    return null;
  }
}
