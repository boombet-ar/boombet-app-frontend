import 'package:boombet_app/config/env.dart';

class ApiConfig {
  static const String _basePath = '/api';

  static String get apiHost => Env.getString('API_HOST');
  static String get apiPort => Env.getString('API_PORT', allowEmpty: true);

  /// Si `API_SCHEME` está vacío, se toma del `API_HOST` (si trae esquema)
  /// o se usa `https` por defecto.
  static String get apiScheme =>
      Env.getString('API_SCHEME', allowEmpty: true).trim();

  static String get imageProxyBase =>
      Env.getString('IMAGE_PROXY_BASE', allowEmpty: true);
  static String get videoProxyBase =>
      Env.getString('VIDEO_PROXY_BASE', allowEmpty: true);

  static String get baseUrl {
    final rawHost = apiHost.trim();
    if (rawHost.isEmpty) {
      throw StateError('[ApiConfig] API_HOST is required');
    }

    // API_HOST puede venir como:
    // - example.com
    // - example.com:8080
    // - http://example.com
    // - https://example.com:8443
    // - https://example.com/backend (path prefix opcional)
    Uri? parsed;
    try {
      parsed = rawHost.contains('://')
          ? Uri.parse(rawHost)
          : Uri.parse('http://$rawHost');
    } catch (_) {
      parsed = null;
    }

    final host = (parsed?.host ?? rawHost).trim();
    if (host.isEmpty) {
      throw StateError('[ApiConfig] API_HOST is invalid: $rawHost');
    }

    final schemeFromHost = (parsed?.scheme ?? '').trim();
    final effectiveScheme = apiScheme.isNotEmpty
        ? apiScheme
        : (schemeFromHost.isNotEmpty ? schemeFromHost : 'https');

    final portFromHost = (parsed != null && parsed.hasPort)
        ? parsed.port
        : null;
    final effectivePort = apiPort.isNotEmpty
        ? int.tryParse(apiPort)
        : portFromHost;

    // Si API_HOST trae un path prefix (ej: /backend), lo respetamos.
    final prefixPath = (parsed?.path ?? '').trim();
    final normalizedPrefix = _normalizePrefixPath(prefixPath);
    final normalizedBasePath = _normalizePath(_basePath);
    final fullPath = normalizedPrefix.endsWith(normalizedBasePath)
        ? normalizedPrefix
        : _joinPaths(normalizedPrefix, normalizedBasePath);

    return Uri(
      scheme: effectiveScheme,
      host: host,
      port: effectivePort,
      path: fullPath,
    ).toString();
  }

  static String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || trimmed == '/') return '';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String _normalizePrefixPath(String path) {
    final normalized = _normalizePath(path);
    if (normalized.isEmpty) return '';
    return normalized.replaceFirst(RegExp(r'/$'), '');
  }

  static String _joinPaths(String a, String b) {
    final left = a.replaceFirst(RegExp(r'/$'), '');
    final right = b.startsWith('/') ? b : '/$b';
    if (left.isEmpty) return right;
    return '$left$right';
  }

  /// Base para WebSocket -> sin el `/api` en el path
  static String get wsBaseUrl {
    final restBase = baseUrl;
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
