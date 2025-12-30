import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
    log("🌐 GET (no-cache) → $url");

    // evitar cache para refrescar icon_url
    final response = await HttpClient.get(
      url,
      includeAuth: true,
      cacheTtl: Duration.zero,
    );
    log("📥 getCurrentUser response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }
  }

  Future<String?> getCurrentUserAvatarUrl() async {
    // limpiar cache previo para forzar reload
    HttpClient.clearCache(urlPattern: '/users/me');
    final data = await getCurrentUser();
    final avatar = _extractAvatarUrl(data);
    if (avatar.isEmpty) return null;
    return _appendCacheBuster(_resolveAvatarUrl(avatar));
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

  Future<String> uploadAvatar({
    required List<int> bytes,
    required String filename,
    String mimeType = 'image/jpeg',
  }) async {
    final url = "${ApiConfig.baseUrl}/users/set_icon";
    log("📤 Upload avatar → $url ($filename | $mimeType) field=file");

    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Token no encontrado, iniciá sesión nuevamente");
    }

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final body = await streamedResponse.stream.bytesToString();
    log("📥 Avatar upload resp ${streamedResponse.statusCode} → $body");

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201) {
      final jsonData = jsonDecode(body);
      final avatarUrl = _appendCacheBuster(
        _resolveAvatarUrl(_extractAvatarUrl(jsonData)),
      );
      if (avatarUrl.isEmpty) {
        throw Exception("Respuesta sin URL de avatar");
      }
      return avatarUrl;
    }

    throw Exception("Error ${streamedResponse.statusCode}: $body");
  }

  String _resolveAvatarUrl(String raw) {
    if (raw.isEmpty) return '';

    String ensureEncoded(String url) {
      try {
        final uri = Uri.parse(url);
        final encoded = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          pathSegments: uri.pathSegments,
        );
        return encoded.toString();
      } catch (_) {
        return url.replaceAll(' ', '%20');
      }
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return _proxyImageForWeb(ensureEncoded(raw));
    }

    final baseUri = Uri.parse(ApiConfig.baseUrl);
    final path = baseUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final joined = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: raw.startsWith('/') ? raw : '$path/$raw',
    );
    return _proxyImageForWeb(joined.toString());
  }

  String _proxyImageForWeb(String url) {
    if (!kIsWeb) return url;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return url;
    return '$proxyBase$url';
  }

  String _appendCacheBuster(String url) {
    if (url.isEmpty) return url;
    try {
      final uri = Uri.parse(url);
      final updatedQuery = Map<String, dynamic>.from(uri.queryParameters);
      updatedQuery['t'] = DateTime.now().millisecondsSinceEpoch.toString();
      return uri.replace(queryParameters: updatedQuery).toString();
    } catch (_) {
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  String _extractAvatarUrl(dynamic jsonData) {
    if (jsonData is Map<String, dynamic>) {
      final direct =
          jsonData['avatarUrl'] ??
          jsonData['avatar_url'] ??
          jsonData['url'] ??
          jsonData['avatar'] ??
          jsonData['iconUrl'] ??
          jsonData['icon_url'] ??
          jsonData['icon'];
      if (direct is String && direct.isNotEmpty) return direct;

      final data = jsonData['data'];
      if (data is Map<String, dynamic>) {
        final nested =
            data['avatarUrl'] ??
            data['avatar_url'] ??
            data['url'] ??
            data['avatar'] ??
            data['iconUrl'] ??
            data['icon_url'] ??
            data['icon'];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }

    return '';
  }
}
