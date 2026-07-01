import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordService {
  /// Envía un correo de recuperación de contraseña al email proporcionado
  ///
  /// Retorna un Map con:
  /// {
  ///   'success': bool,
  ///   'message': String,
  ///   'statusCode': int
  /// }
  static Future<Map<String, dynamic>> sendPasswordResetEmail(
    String email,
  ) async {
    try {
      // IMPORTANTE: No usar static final porque ApiConfig.baseUrl cambia en runtime
      final baseUrl = ApiConfig.baseUrl;

      debugPrint('📧 [ForgotPassword] ===== INICIANDO LLAMADA =====');
      debugPrint('📧 [ForgotPassword] Email raw: "$email"');
      debugPrint('📧 [ForgotPassword] Email trimmed: "${email.trim()}"');
      debugPrint('📧 [ForgotPassword] Email isEmpty: ${email.isEmpty}');
      debugPrint('📧 [ForgotPassword] Email length: ${email.length}');

      final url = Uri.parse('$baseUrl/users/auth/forgot-password');
      debugPrint('📧 [ForgotPassword] BaseUrl: $baseUrl');
      debugPrint('📧 [ForgotPassword] URL: $url');

      final payload = {'email': email};

      debugPrint('📧 [ForgotPassword] Payload antes de jsonEncode: $payload');
      final jsonPayload = jsonEncode(payload);
      debugPrint('📧 [ForgotPassword] Payload JSON: $jsonPayload');
      debugPrint('📧 [ForgotPassword] Payload bytes: ${jsonPayload.codeUnits}');

      debugPrint('📧 [ForgotPassword] Iniciando solicitud HTTP...');
      debugPrint('📧 [ForgotPassword] ========== REQUEST ==========');
      debugPrint('📧 [ForgotPassword] Method: POST');
      debugPrint('📧 [ForgotPassword] URL: $url');
      debugPrint(
        '📧 [ForgotPassword] Headers: Content-Type: application/json, Accept: application/json',
      );
      debugPrint('📧 [ForgotPassword] Body: $jsonPayload');
      debugPrint('📧 [ForgotPassword] ============================');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonPayload,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ [ForgotPassword] Timeout después de 30 segundos');
              return http.Response('Request timeout', 408);
            },
          );

      debugPrint('📧 [ForgotPassword] Respuesta recibida');
      debugPrint('📧 [ForgotPassword] Response Status: ${response.statusCode}');
      debugPrint('📧 [ForgotPassword] Response Body: ${response.body}');
      debugPrint('📧 [ForgotPassword] ===== PROCESANDO RESPUESTA =====');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ EMAIL ENVIADO EXITOSAMENTE
        debugPrint('✅ [ForgotPassword] Email enviado exitosamente');

        String message = 'Se ha enviado un correo de recuperación a $email';
        try {
          final responseData = jsonDecode(response.body);
          message = responseData['message'] ?? message;
        } catch (e) {
          debugPrint('⚠️ [ForgotPassword] Error parseando respuesta: $e');
        }

        return {
          'success': true,
          'message': message,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        // ❌ EMAIL NO ENCONTRADO
        debugPrint('❌ [ForgotPassword] Email no encontrado en el sistema');

        return {
          'success': false,
          'message': 'El email no se encuentra registrado en nuestro sistema.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 429) {
        // ❌ DEMASIADOS INTENTOS
        debugPrint('❌ [ForgotPassword] Demasiados intentos');

        return {
          'success': false,
          'message': 'Demasiados intentos. Por favor intenta más tarde.',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 408) {
        // ❌ TIMEOUT
        debugPrint('❌ [ForgotPassword] Timeout del servidor');

        return {
          'success': false,
          'message':
              'El servidor tardó demasiado en responder. Por favor intenta más tarde.',
          'statusCode': response.statusCode,
        };
      } else {
        // ❌ ERROR GENÉRICO
        debugPrint(
          '❌ [ForgotPassword] Error desconocido: ${response.statusCode}',
        );

        String errorMessage =
            'Error ${response.statusCode}: No se pudo enviar el correo';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint('⚠️ [ForgotPassword] Error parseando error: $e');
          // Si no se puede parsear, usar el body tal cual
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
        }

        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('❌ [ForgotPassword] ===== EXCEPCIÓN CAPTURADA =====');
      debugPrint('❌ [ForgotPassword] Error type: ${e.runtimeType}');
      debugPrint('❌ [ForgotPassword] Error message: $e');
      debugPrint('❌ [ForgotPassword] Stack trace: ${StackTrace.current}');

      return {
        'success': false,
        'message': 'Error al conectar con el servidor: $e',
        'statusCode': -1,
      };
    }
  }
}
