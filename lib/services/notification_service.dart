import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:boombet_app/services/http_client.dart';

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

  Future<String?> _tryGetFcmToken() async {
    try {
      final stored = await TokenService.getFcmToken();
      if (stored != null && stored.isNotEmpty) return stored;

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
