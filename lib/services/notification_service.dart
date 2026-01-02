import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  const NotificationService();

  Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final url = '${ApiConfig.baseUrl}/notifications/send';

    final fcmToken = await _tryGetFcmToken();

    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      if (data != null && data.isNotEmpty) 'data': data,
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
    };

    final response = await HttpClient.post(
      url,
      body: payload,
      includeAuth: true,
      maxRetries: 1,
      timeout: const Duration(seconds: 30),
    );

    final success = response.statusCode >= 200 && response.statusCode < 300;
    final decoded = success
        ? _tryDecode(response.body)
        : _tryDecode(response.body);

    return {
      'success': success,
      'statusCode': response.statusCode,
      'data': decoded,
      'raw': response.body,
    };
  }

  Map<String, dynamic>? _tryDecode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      log('🔔 [NotificationService] Respuesta no JSON: $body');
      return null;
    }
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
