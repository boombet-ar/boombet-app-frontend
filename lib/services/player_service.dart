import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';

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

  Future<PlayerData> updatePlayerData(PlayerUpdateRequest data) async {
    final url = "${ApiConfig.baseUrl}/jugadores/update";

    log("PATCH → $url");
    log("BODY → ${data.toJson()}");

    final response = await HttpClient.patch(
      url,
      body: data.toJson(),
      includeAuth: true,
    );

    log("RESP PATCH ${response.statusCode} → ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return PlayerData.fromJugadorJson(jsonData);
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final url = "${ApiConfig.baseUrl}/users/me";
    log("🌐 GET → $url");

    final response = await HttpClient.get(url, includeAuth: true);
    log("📥 getCurrentUser response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  Future<void> unaffiliateCurrentUser() async {
    final url = "${ApiConfig.baseUrl}/users/me";
    log("DELETE → $url");

    final response = await HttpClient.delete(url, includeAuth: true);
    log("RESP → ${response.statusCode} ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 204) {
      await TokenService.deleteToken();
      return;
    }

    throw Exception("Error ${response.statusCode}: ${response.body}");
  }
}
