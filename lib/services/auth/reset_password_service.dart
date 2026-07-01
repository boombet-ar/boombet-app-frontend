import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordService {
  /// Enviar nueva contraseña al backend para resetear
  /// Endpoint: POST /api/users/auth/reset-password
  ///
  /// El token es el que viene en el parámetro de la URL del email
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    debugPrint('📝 Iniciando reset de contraseña...');
    debugPrint('🔐 Token: ${token.substring(0, 10)}...');

    try {
      // IMPORTANTE: No usar static final porque ApiConfig.baseUrl cambia en runtime
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/users/auth/reset-password');
      debugPrint('🌐 URL: $url');

      final body = {'token': token, 'newPassword': newPassword};

      debugPrint('📤 Body: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ TIMEOUT: El servidor tardó más de 30 segundos');
              return http.Response(
                jsonEncode({
                  'success': false,
                  'message': 'Timeout: El servidor tardó mucho en responder',
                }),
                408,
              );
            },
          );

      debugPrint('📥 Status Code: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      // Casos de éxito
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('✅ Contraseña reseteada exitosamente');
          return {
            'success': true,
            'message':
                data['message'] ?? 'Contraseña actualizada correctamente',
            'statusCode': response.statusCode,
          };
        } catch (e) {
          debugPrint('⚠️ Error al parsear respuesta exitosa: $e');
          return {
            'success': true,
            'message': 'Contraseña actualizada correctamente',
            'statusCode': response.statusCode,
          };
        }
      }

      // Casos de error
      switch (response.statusCode) {
        case 400:
          debugPrint('❌ Error 400: Bad Request');
          try {
            final data = jsonDecode(response.body);
            return {
              'success': false,
              'message': data['message'] ?? 'Datos inválidos',
              'statusCode': 400,
            };
          } catch (_) {
            return {
              'success': false,
              'message': 'Datos inválidos. Verifica los campos.',
              'statusCode': 400,
            };
          }

        case 401:
          debugPrint('❌ Error 401: Token inválido o expirado');
          return {
            'success': false,
            'message':
                'Token inválido o expirado. Solicita un nuevo correo de recuperación.',
            'statusCode': 401,
          };

        case 404:
          debugPrint('❌ Error 404: Usuario no encontrado');
          return {
            'success': false,
            'message': 'Usuario no encontrado',
            'statusCode': 404,
          };

        case 429:
          debugPrint('❌ Error 429: Rate limit exceeded');
          return {
            'success': false,
            'message': 'Demasiados intentos. Intenta más tarde.',
            'statusCode': 429,
          };

        case 408:
          debugPrint('⏱️ Error 408: Request Timeout');
          return {
            'success': false,
            'message':
                'El servidor tardó demasiado en responder. Intenta de nuevo.',
            'statusCode': 408,
          };

        default:
          debugPrint('❌ Error ${response.statusCode}: ${response.body}');
          try {
            final data = jsonDecode(response.body);
            return {
              'success': false,
              'message': data['message'] ?? 'Error al resetear contraseña',
              'statusCode': response.statusCode,
            };
          } catch (_) {
            return {
              'success': false,
              'message': 'Error al resetear contraseña: ${response.statusCode}',
              'statusCode': response.statusCode,
            };
          }
      }
    } catch (e) {
      debugPrint('💥 Excepción en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'statusCode': -1,
      };
    }
  }
}
