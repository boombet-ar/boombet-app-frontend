import 'dart:convert';
import '../config/api_config.dart';
import '../models/player_model.dart';
import '../utils/error_parser.dart';
import 'http_client.dart';

class PlayerService {
  /// Obtiene los datos del jugador desde el endpoint /auth/userData
  /// Este endpoint devuelve: { "datosJugador": { ... } }
  Future<Map<String, dynamic>> fetchPlayerDataFromUserData(
    String dni,
    String genero,
  ) async {
    final url = '${ApiConfig.baseUrl}/auth/userData';

    try {
      final response = await HttpClient.post(
        url,
        body: {'dni': dni, 'genero': genero},
        includeAuth: false, // Este endpoint no requiere auth
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
          'message': ErrorParser.parseResponse(response),
        };
      }
    } catch (e) {
      return {'success': false, 'message': ErrorParser.parse(e)};
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
    final url = '${ApiConfig.baseUrl}/auth/confirmData';

    try {
      final response = await HttpClient.post(
        url,
        body: data.toJson(),
        includeAuth: true, // Usa el token guardado automáticamente
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Datos confirmados correctamente'};
      } else {
        return {
          'success': false,
          'message': ErrorParser.parseResponse(response),
        };
      }
    } catch (e) {
      return {'success': false, 'message': ErrorParser.parse(e)};
    }
  }

  /// Actualiza los datos del jugador en el backend
  Future<Map<String, dynamic>> updatePlayerData(PlayerData playerData) async {
    final url = '${ApiConfig.baseUrl}/player/update';

    try {
      final response = await HttpClient.put(
        url,
        body: playerData.toJson(),
        includeAuth: true,
      );

      if (response.statusCode == 200) {
        // Actualización exitosa
        return {'success': true, 'message': 'Datos actualizados correctamente'};
      } else {
        return {
          'success': false,
          'message': ErrorParser.parseResponse(response),
        };
      }
    } catch (e) {
      return {'success': false, 'message': ErrorParser.parse(e)};
    }
  }

  /// Obtiene los datos del jugador desde el backend
  Future<Map<String, dynamic>> getPlayerData(String dni) async {
    final url = '${ApiConfig.baseUrl}/player/$dni';

    try {
      final response = await HttpClient.get(url, includeAuth: true);

      if (response.statusCode == 200) {
        // Obtención exitosa
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'message': ErrorParser.parseResponse(response),
        };
      }
    } catch (e) {
      return {'success': false, 'message': ErrorParser.parse(e)};
    }
  }
}
