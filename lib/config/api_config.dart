import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Compile-time environment variables
  // Default: Local Docker (development)
  // Override with: --dart-define=API_HOST=your-azure-host.com --dart-define=API_PORT=443 --dart-define=API_SCHEME=https
  static const String _envHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '', // Empty means use platform-specific defaults
  );
  static const String _envPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '7070',
  );
  static const String _envScheme = String.fromEnvironment(
    'API_SCHEME',
    defaultValue: 'http',
  );

  // Variables de Bonda API
  static String apiKey =
      '61099OdstDC6fGUHy6SHblguE9nrqT0VgCxVlTpPcRb0hryCwLQs9SnnZ9nfFGRY';
  static int micrositioId = 911909;
  static String codigoAfiliado = '123456';

  static String get baseUrl {
    // If API_HOST is explicitly set, use it
    if (_envHost.isNotEmpty) {
      final port = _envPort.isNotEmpty ? ':$_envPort' : '';
      return '$_envScheme://$_envHost$port/api';
    }

    // Otherwise, use platform-specific defaults (local Docker)
    if (kIsWeb) {
      return 'http://localhost:7070/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:7070/api'; // Android emulator → Docker host
    } else if (Platform.isIOS) {
      return 'http://localhost:7070/api';
    } else {
      return 'http://localhost:7070/api';
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
