import 'dart:convert';
import 'dart:developer';
import '../config/api_config.dart';
import '../utils/error_parser.dart';
import 'http_client.dart';
import 'token_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'biometric_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    final url = '${ApiConfig.baseUrl}/users/auth/login';
    final fcmToken = await _tryGetFcmToken();

    try {
      final response = await HttpClient.post(
        url,
        body: {
          'identifier': identifier,
          'password': password,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
        includeAuth: false, // Login no requiere token previo
        maxRetries: 1, // Login debe fallar rápido si no conecta
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        // Login exitoso
        final data = jsonDecode(response.body);

        try {
          // Limpiar cualquier token previo para evitar inconsistencias
          await TokenService.deleteToken();

          // Backend nuevo: accessToken. Compat: token (legacy)
          final token =
              (data['accessToken'] as String?) ?? (data['token'] as String?);
          final refreshToken = data['refreshToken'] as String?;

          if (token != null && token.isNotEmpty) {
            // Guía nueva: guardar ambos tokens de forma persistente (SecureStorage).
            // (Mantengo `rememberMe` por compatibilidad de firma, pero el storage es persistente.)
            await TokenService.saveToken(token);

            if (refreshToken != null && refreshToken.isNotEmpty) {
              await TokenService.saveRefreshToken(refreshToken);
            }
          }

          // Debug detallado de expiración/tiempos (no imprime tokens completos).
          await TokenService.debugLogAuthTokens('login');
        } on FormatException catch (e) {
          await TokenService.deleteToken();
          return {
            'success': false,
            'message': 'Error al procesar el token recibido: ${e.message}',
          };
        }

        // Adjuntar fcm_token enviado para tenerlo disponible aguas arriba
        return {'success': true, 'data': data, 'fcm_token': fcmToken};
      } else {
        // Usar ErrorParser para mensajes consistentes (con contexto 'login')
        return {
          'success': false,
          'message': ErrorParser.parseResponse(response, context: 'login'),
        };
      }
    } catch (e) {
      // Usar ErrorParser para convertir errores en mensajes claros
      return {'success': false, 'message': ErrorParser.parse(e)};
    }
  }

  /// Cierra la sesión del usuario eliminando el token
  Future<void> logout() async {
    BiometricService.resetRuntimeValidation();
    await TokenService.deleteToken();
    await TokenService.deleteFcmToken();

    try {
      await FirebaseMessaging.instance.deleteToken();
      log('🔔 [AuthService] FCM token deleted');
    } catch (e) {
      log('🔔 [AuthService] Error deleting FCM token: $e');
    }
  }

  /// Verifica si hay una sesión activa
  Future<bool> isLoggedIn() async {
    return await TokenService.hasActiveSession();
  }

  Future<String?> _tryGetFcmToken() async {
    try {
      // Preferir el token ya guardado para evitar pedirlo antes de permisos
      final stored = await TokenService.getFcmToken();
      if (stored != null && stored.isNotEmpty) return stored;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await TokenService.saveFcmToken(token);
        return token;
      }
    } catch (e) {
      log('🔔 [AuthService] No se pudo obtener FCM token para login: $e');
    }
    return null;
  }

  /// Obtiene el token actual
  Future<String?> getToken() async {
    final token = await TokenService.getToken();
    final tokenPreview = token != null
        ? (token.length > 25 ? '${token.substring(0, 25)}...' : token)
        : 'NULL';
    log('🔥 [AuthService] Token obtenido: $tokenPreview');

    return token;
  }

  Future<Map<String, dynamic>> register(
    String email,
    String dni,
    String telefono,
    String password,
    String gender, {
    String? username,
  }) async {
    final url = '${ApiConfig.baseUrl}/auth/register';

    final body = {
      'email': email,
      'dni': dni,
      'telefono': telefono,
      'password': password,
      'genero': gender,
    };

    // Agregar username si fue proporcionado
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    }

    try {
      final response = await HttpClient.post(
        url,
        body: body,
        includeAuth: false, // Registro no requiere token previo
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        // Usar ErrorParser para mensajes consistentes
        return {
          'success': false,
          'message': ErrorParser.parseResponse(response),
        };
      }
    } catch (e) {
      // Usar ErrorParser para convertir errores en mensajes claros
      return {'success': false, 'message': ErrorParser.parse(e)};
    }
  }
}
