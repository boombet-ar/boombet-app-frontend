import 'dart:convert';
import 'dart:developer';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/publicidad_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';

class PublicidadService {
  Future<List<Publicidad>> getMyAds() async {
    final token = await TokenService.getToken();
    final url = '${ApiConfig.baseUrl}/publicidades/me';

    log('📡 Publicidades: endpoint único -> $url');
    if (token == null || token.isEmpty) {
      log('⚠️ Publicidades: token ausente antes de llamar');
    } else {
      final preview = token.length > 12
          ? '${token.substring(0, 6)}...${token.substring(token.length - 6)}'
          : token;
      log(
        '🔑 Publicidades: token presente (${token.length} chars) preview=$preview',
      );
    }

    log('📡 GET → $url');
    final response = await HttpClient.get(url, includeAuth: true);
    log('📡 Publicidades request headers: ${response.request?.headers}');
    log('📡 Publicidades status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      log('📥 Publicidades raw body: ${response.body}');
      try {
        final data = jsonDecode(response.body);
        final ads = Publicidad.listFromJson(data);
        log('📥 Publicidades parseadas: ${ads.length}');
        return ads;
      } catch (e) {
        log('❌ Error parseando publicidades desde $url: $e');
        return const [];
      }
    }

    log('❌ Publicidades status ${response.statusCode} body=${response.body}');
    return const [];
  }
}
