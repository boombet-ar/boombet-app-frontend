import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/player_model.dart';
import 'token_service.dart';

class PlayerService {
  /// Obtiene los headers con el token de autorización
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Actualiza los datos del jugador en el backend
  Future<Map<String, dynamic>> updatePlayerData(PlayerData playerData) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/player/update');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(playerData.toJson()),
      );

      if (response.statusCode == 200) {
        // Actualización exitosa
        return {'success': true, 'message': 'Datos actualizados correctamente'};
      } else if (response.statusCode == 404) {
        // Jugador no encontrado
        return {
          'success': false,
          'message': 'No se encontró el jugador en la base de datos',
        };
      } else if (response.statusCode == 400) {
        // Error de validación
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Datos inválidos',
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

  /// Obtiene los datos del jugador desde el backend
  Future<Map<String, dynamic>> getPlayerData(String dni) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/player/$dni');

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Obtención exitosa
        return {'success': true, 'data': jsonDecode(response.body)};
      } else if (response.statusCode == 404) {
        // Jugador no encontrado
        return {
          'success': false,
          'message': 'No se encontró el jugador en la base de datos',
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
}
