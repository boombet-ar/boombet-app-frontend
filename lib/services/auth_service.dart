import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Login exitoso
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 401) {
        // Credenciales inválidas (usuario no existe o contraseña incorrecta)
        return {
          'success': false,
          'message': 'Usuario o contraseña incorrectos',
        };
      } else if (response.statusCode == 404) {
        // Usuario no encontrado en la base de datos
        return {
          'success': false,
          'message': 'El usuario no existe en la base de datos',
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

  Future<Map<String, dynamic>> register(
    String username,
    String dni,
    String password,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'dni': dni,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registro exitoso
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 400) {
        // Error de validación (usuario ya existe, etc.)
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
