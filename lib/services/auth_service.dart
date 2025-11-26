import 'dart:convert';
import '../config/api_config.dart';
import '../utils/error_parser.dart';
import 'http_client.dart';
import 'token_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    final url = '${ApiConfig.baseUrl}/users/auth/login';

    try {
      final response = await HttpClient.post(
        url,
        body: {'identifier': identifier, 'password': password},
        includeAuth: false, // Login no requiere token previo
      );

      if (response.statusCode == 200) {
        // Login exitoso
        final data = jsonDecode(response.body);

        // Solo guardar el token si el usuario marcó "Recordar"
        if (rememberMe) {
          // Guardar el token JWT
          if (data['token'] != null) {
            await TokenService.saveToken(data['token']);
          }

          // Guardar refresh token si existe
          if (data['refreshToken'] != null) {
            await TokenService.saveRefreshToken(data['refreshToken']);
          }
        } else {
          // Si no quiere recordar, guardar en sesión temporal
          if (data['token'] != null) {
            await TokenService.saveTemporaryToken(data['token']);
          }
        }

        return {'success': true, 'data': data};
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

  /// Cierra la sesión del usuario eliminando el token
  Future<void> logout() async {
    await TokenService.deleteToken();
  }

  /// Verifica si hay una sesión activa
  Future<bool> isLoggedIn() async {
    return await TokenService.hasActiveSession();
  }

  /// Obtiene el token actual
  Future<String?> getToken() async {
    return await TokenService.getToken();
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
