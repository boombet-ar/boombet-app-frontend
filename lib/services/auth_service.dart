import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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
      } else if (response.statusCode == 401) {
        // Credenciales inválidas (email no existe o contraseña incorrecta)
        return {'success': false, 'message': 'Email o contraseña incorrectos'};
      } else if (response.statusCode == 404) {
        // Email no encontrado en la base de datos
        return {
          'success': false,
          'message': 'El email no existe en la base de datos',
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
    String gender,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'dni': dni,
          'telefono': telefono,
          'password': password,
          'genero': gender,
        }),
      );

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
      } else {
        // Otro error
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
}
