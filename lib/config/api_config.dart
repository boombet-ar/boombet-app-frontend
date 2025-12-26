import 'package:boombet_app/config/env.dart';

class ApiConfig {
  static const String _basePath = '/api';

  static String get apiHost => Env.getString('API_HOST');
  static String get apiPort => Env.getString('API_PORT', allowEmpty: true);
  static String get apiScheme => Env.getString('API_SCHEME', fallback: 'https');

  static String get imageProxyBase =>
      Env.getString('IMAGE_PROXY_BASE', allowEmpty: true);
  static String get videoProxyBase =>
      Env.getString('VIDEO_PROXY_BASE', allowEmpty: true);

  static String get baseUrl {
    final host = apiHost.trim();
    if (host.isEmpty) {
      throw StateError('[ApiConfig] API_HOST is required');
    }

    final portSegment = apiPort.isNotEmpty ? ':$apiPort' : '';
    final normalizedPath = _basePath.startsWith('/')
        ? _basePath
        : '/$_basePath';
    return '$apiScheme://$host$portSegment$normalizedPath';
  }

  /// Base para WebSocket -> sin el `/api` en el path
  static String get wsBaseUrl {
    final restBase = baseUrl; // ej 'http://localhost:8080/api'
    final uri = Uri.parse(restBase);

    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';

    // Le saco el /api del path
    final pathWithoutApi = uri.path.replaceFirst('/api', '');

    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.port,
      path: pathWithoutApi, // normalmente '', o '/'
    ).toString().replaceFirst(RegExp(r'/$'), '');
  }

  static String get effectiveUrl => baseUrl;
}
