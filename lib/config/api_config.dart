import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Compile-time environment variables
  // Default: Azure Backend (production)
  // Override with: --dart-define=API_HOST=localhost --dart-define=API_PORT=7070 --dart-define=API_SCHEME=http for local Docker
  static const String _envHost = String.fromEnvironment(
    'API_HOST',
    defaultValue:
        'boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io',
  );
  static const String _envPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '', // Empty for default HTTPS port (443)
  );
  static const String _envScheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'https',
  );

  // Variables de Bonda API
  static String apiKey =
      '61099OdstDC6fGUHy6SHblguE9nrqT0VgCxVlTpPcRb0hryCwLQs9SnnZ9nfFGRY';
  static int micrositioId = 911909;
  static String codigoAfiliado = '123456';

  static String get baseUrl {
    // If API_HOST is explicitly set or using default Azure backend
    if (_envHost.isNotEmpty) {
      final port = _envPort.isNotEmpty ? ':$_envPort' : '';
      return '$_envScheme://$_envHost$port/api';
    }

    // Fallback to platform-specific defaults (should not reach here with new defaults)
    if (kIsWeb) {
      return 'https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api';
    } else if (Platform.isAndroid) {
      return 'https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api';
    } else if (Platform.isIOS) {
      return 'https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api';
    } else {
      return 'https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api';
    }
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

    return Uri(
      scheme: scheme,
      host: uri.host,
      port: uri.port,
      path: pathWithoutApi, // normalmente '', o '/'
    ).toString().replaceFirst(RegExp(r'/$'), '');
    // 👆 me aseguro de no terminar con doble //
  }

  static String get effectiveUrl => baseUrl;
}
