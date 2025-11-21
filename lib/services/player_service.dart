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

  /// Obtiene los datos del jugador desde el endpoint /auth/userData
  /// Este endpoint devuelve: { "datosJugador": { ... } }
  Future<Map<String, dynamic>> fetchPlayerDataFromUserData(
    String dni,
    String genero,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/userData');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dni': dni, 'genero': genero}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // El backend devuelve: { "datosJugador": { ... } }
        if (data['datosJugador'] != null) {
          final playerData = PlayerData.fromJson(data['datosJugador']);
          return {'success': true, 'data': playerData};
        } else {
          return {
            'success': false,
            'message': 'No se encontraron datos del jugador',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Parsea los datos del jugador desde la respuesta del endpoint /auth/register
  /// El response tiene la estructura:
  /// {
  ///   "token": "...",
  ///   "playerData": {
  ///     "listaExistenciaFisica": [ { apenom, sexo, fecha_nacimiento, ... } ]
  ///   }
  /// }
  PlayerData? parsePlayerDataFromRegisterResponse(Map<String, dynamic> json) {
    try {
      final playerData = json['playerData'];
      if (playerData == null) return null;

      final lista = playerData['listaExistenciaFisica'];
      if (lista == null || lista is! List || lista.isEmpty) return null;

      final primerElemento = lista[0] as Map<String, dynamic>;
      return PlayerData.fromRegisterResponse(primerElemento);
    } catch (e) {
      print('Error parseando PlayerData desde register: $e');
      return null;
    }
  }

  /// Envía los datos confirmados del jugador al backend
  /// Placeholder endpoint - ajustar según necesidad
  Future<Map<String, dynamic>> sendConfirmedPlayerData(
    PlayerData data,
    String? token,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/confirmData');

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Datos confirmados correctamente'};
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
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
