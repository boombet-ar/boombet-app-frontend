import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String customUrl = '';

  static String get baseUrl {
    if (customUrl.isNotEmpty) return customUrl;

    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:8080/api';
    } else {
      return 'http://localhost:8080/api';
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
    // 👆 me aseguro de no terminar con doble //
  }

  static String get effectiveUrl => baseUrl;
}
