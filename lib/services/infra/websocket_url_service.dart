import 'package:boombet_app/config/api_config.dart';

/// Service centralizado para generar URLs de WebSocket
class WebSocketUrlService {
  /// Genera una URL única de WebSocket basada en la configuración de la app
  /// Retorna: ws://localhost:8080/affiliation/1764275924965
  static String generateAffiliationUrl() {
    final baseUrl = ApiConfig.baseUrl;
    var wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    // Quitar "/api" del final si existe (WebSocket está en la raíz)
    if (wsUrl.endsWith('/api')) {
      wsUrl = wsUrl.substring(0, wsUrl.length - 4);
    }

    // Generar ID único basado en timestamp
    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    return '$wsUrl/affiliation/$uniqueId';
  }
}
