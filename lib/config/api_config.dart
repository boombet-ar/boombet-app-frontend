import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // URL base según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Para web, usar localhost
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      // Para emulador Android, usar 10.0.2.2
      return 'http://10.0.2.2:8080/api';
    } else if (Platform.isIOS) {
      // Para simulador iOS, usar localhost
      return 'http://localhost:8080/api';
    } else {
      // Por defecto (Windows, macOS, Linux desktop)
      return 'http://localhost:8080/api';
    }
  }

  // Método alternativo para configurar manualmente la URL si es necesario
  static String customUrl = '';

  static String get effectiveUrl => customUrl.isNotEmpty ? customUrl : baseUrl;
}
