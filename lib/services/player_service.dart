import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/http_client.dart';

class PlayerService {
  Future<PlayerData> getPlayerData(String idJugador) async {
    final url = "${ApiConfig.baseUrl}/jugadores/$idJugador";
    log("🌐 GET → $url");

    final response = await HttpClient.get(url, includeAuth: true);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      log("📥 PlayerData recibido: $jsonData");
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

    log("PATCH → $url");
    log("BODY → ${data.toJson()}");

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
