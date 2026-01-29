import 'package:flutter/foundation.dart';

/// Centralizado para leer variables de entorno via --dart-define
class Env {
  Env._();

  // Dart-defines para permitir overrides en CI/build
  static const _defineApiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );
  static const _defineApiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '',
  );
  static const _defineApiScheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: '',
  );
  static const _defineApiBasePath = String.fromEnvironment(
    'API_BASE_PATH',
    defaultValue: '',
  );
  static const _defineImageProxyBase = String.fromEnvironment(
    'IMAGE_PROXY_BASE',
    defaultValue: '',
  );
  static const _defineVideoProxyBase = String.fromEnvironment(
    'VIDEO_PROXY_BASE',
    defaultValue: '',
  );
  static const _defineUserDataKey = String.fromEnvironment(
    'USERDATA_KEY',
    defaultValue: '',
  );

  static bool _loaded = false;

  static Future<void> load({String fileName = '.env'}) async {
    if (_loaded) return;
    debugPrint('[Env] Skipping $fileName; using --dart-define only');
    _loaded = true;
  }

  static String _fromDefines(String key) {
    switch (key) {
      case 'API_HOST':
        return _defineApiHost;
      case 'API_PORT':
        return _defineApiPort;
      case 'API_SCHEME':
        return _defineApiScheme;
      case 'API_BASE_PATH':
        return _defineApiBasePath;
      case 'IMAGE_PROXY_BASE':
        return _defineImageProxyBase;
      case 'VIDEO_PROXY_BASE':
        return _defineVideoProxyBase;
      case 'USERDATA_KEY':
        return _defineUserDataKey;
      default:
        return '';
    }
  }

  static String _rawValue(String key) {
    final defineValue = _fromDefines(key);
    if (defineValue.isNotEmpty) return defineValue;
    return '';
  }

  static String getString(
    String key, {
    String? fallback,
    bool allowEmpty = false,
  }) {
    final value = _rawValue(key);
    if (value.isNotEmpty) return value;
    if (fallback != null) return fallback;
    if (allowEmpty) return '';
    throw StateError('[Env] Missing required env var: $key');
  }

  static int getInt(String key, {int? fallback}) {
    final value = _rawValue(key);
    if (value.isNotEmpty) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      throw StateError('[Env] Env var $key must be an int');
    }
    if (fallback != null) return fallback;
    throw StateError('[Env] Missing required env var: $key');
  }
}
