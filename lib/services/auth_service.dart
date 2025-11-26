import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/login');

    try {
      print('[AuthService] POST ${url.toString()}');
      print(
        '[AuthService] Body: {"identifier": "$identifier", "password": "***"}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      print('[AuthService] Status: ${response.statusCode}');
      print('[AuthService] Response: ${response.body}');

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
      } else if (response.statusCode == 401) {
        // Credenciales inválidas (usuario/email no existe o contraseña incorrecta)
        return {
          'success': false,
          'message': 'Usuario/Email o contraseña incorrectos',
        };
      } else if (response.statusCode == 404) {
        // Usuario/Email no encontrado en la base de datos
        return {
          'success': false,
          'message': 'El usuario o email no existe en la base de datos',
        };
      } else {
        // Otro error del servidor
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Error de conexión
      return {'success': false, 'message': 'Error de conexión: $e'};
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
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

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
      print('[AuthService] POST ${url.toString()}');
      print('[AuthService] Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('[AuthService] Status: ${response.statusCode}');
      print('[AuthService] Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 400) {
        // Error de validación (email ya existe, etc.)
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el registro',
        };
      } else if (response.statusCode == 403) {
        // Error 403 Forbidden
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Acceso denegado (403)',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Acceso denegado (403): ${response.body}',
          };
        }
      } else {
        // Otro error
        return {
          'success': false,
          'message':
              'Error del servidor (${response.statusCode}): ${response.body}',
        };
      }
    } catch (e) {
      // Error de conexión
      print('[AuthService] Exception: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
