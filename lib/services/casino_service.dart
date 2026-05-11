import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/affiliated_casino_model.dart';
import 'package:boombet_app/models/pending_verification_model.dart';
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

  Future<void> verifyAffiliation({
    required int idAfiliacion,
    required String casinoUserId,
  }) async {
    final url = '${ApiConfig.baseUrl}/afiliacion/$idAfiliacion/verificar';
    log('POST → $url');

    final response = await HttpClient.post(
      url,
      body: {'casinoUserId': casinoUserId},
      includeAuth: true,
    );
    log('RESP ${response.statusCode} → ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<List<AffiliatedCasino>> getAffiliatedCasinos() async {
    final url = '${ApiConfig.baseUrl}/users/casinos_afiliados';
    log('GET → $url');

    final response = await HttpClient.get(url, includeAuth: true);
    log('RESP ${response.statusCode} → ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => AffiliatedCasino.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<List<PendingVerification>> getPendingVerifications() async {
    final url = '${ApiConfig.baseUrl}/afiliacion/admin/pendientes';
    log('GET → $url');

    final response = await HttpClient.get(url, includeAuth: true);
    log('RESP ${response.statusCode} → ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => PendingVerification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  Future<void> adminResolveVerification({
    required int afiliacionId,
    required String estado,
  }) async {
    final url = '${ApiConfig.baseUrl}/afiliacion/admin/verificar';
    log('POST → $url | afiliacionId=$afiliacionId estado=$estado');

    final response = await HttpClient.post(
      url,
      body: {'afiliacionId': afiliacionId, 'estado': estado},
      includeAuth: true,
    );
    log('RESP ${response.statusCode} → ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Limpia el cache de casinos
  void clearCache() {
    _casinoCache.clear();
  }
}
