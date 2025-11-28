import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:http/http.dart';

class PlayerService {
  Future<PlayerData> getPlayerData(String idJugador) async {
    final url = "${ApiConfig.baseUrl}/jugadores/$idJugador";
    print("🌐 GET → $url");

    final response = await HttpClient.get(url, includeAuth: true);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print("📥 PlayerData recibido: $jsonData");
      return PlayerData.fromJugadorJson(jsonData);
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  Future<PlayerData> updatePlayerData(
    String idJugador,
    PlayerUpdateRequest data,
  ) async {
    final url = "${ApiConfig.baseUrl}/jugadores/update/$idJugador";

    print("PATCH → $url");
    print("BODY → ${data.toJson()}");

    final response = await HttpClient.patch(
      url,
      body: data.toJson(),
      includeAuth: true,
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return PlayerData.fromJugadorJson(jsonData);
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }
}
