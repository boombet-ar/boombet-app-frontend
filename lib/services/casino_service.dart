import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';

class CasinoService {
  static final Map<int, String> _casinoCache = {};

  /// Obtiene el nombre del casino por ID desde la BD
  /// Utiliza cache para evitar múltiples llamadas al mismo casino
  Future<String> getCasinoName(int casinoId) async {
    // Retornar desde cache si existe
    if (_casinoCache.containsKey(casinoId)) {
      return _casinoCache[casinoId]!;
    }

    try {
      final url = "${ApiConfig.baseUrl}/casino_general/$casinoId";
      log("🏢 GET → $url");

      final response = await HttpClient.get(url, includeAuth: true);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final name =
            jsonData['nombre']?.toString() ??
            jsonData['name']?.toString() ??
            'Casino $casinoId';

        // Guardar en cache
        _casinoCache[casinoId] = name;
        log("✅ Casino name: $name");
        return name;
      } else {
        log("⚠️ Error ${response.statusCode} getting casino: ${response.body}");
        return 'Casino $casinoId';
      }
    } catch (e) {
      log("❌ Error fetching casino name: $e");
      return 'Casino $casinoId';
    }
  }

  /// Limpia el cache de casinos
  void clearCache() {
    _casinoCache.clear();
  }
}
