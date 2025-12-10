import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Parser de errores HTTP que convierte excepciones en mensajes user-friendly
///
/// Convierte errores técnicos en mensajes claros y útiles para el usuario
class ErrorParser {
  /// Parsea cualquier error y retorna un mensaje comprensible
  static String parse(dynamic error, {String? fallbackMessage}) {
    if (error is TimeoutException) {
      return 'La conexión tardó demasiado tiempo. Por favor, intenta nuevamente.';
    }

    if (error is SocketException) {
      return 'Sin conexión a internet. Verifica tu conexión y vuelve a intentar.';
    }

    if (error is http.ClientException) {
      return 'Error de conexión. Verifica tu red e intenta nuevamente.';
    }

    if (error is http.Response) {
      return parseResponse(error);
    }

    if (error is FormatException) {
      return 'Error al procesar la respuesta del servidor.';
    }

    // Intentar extraer mensaje de error si es un String
    if (error is String) {
      return error;
    }

    // Mensaje por defecto
    return fallbackMessage ??
        'Error inesperado. Por favor, intenta nuevamente.';
  }

  /// Parsea una respuesta HTTP y retorna un mensaje según el código de estado
  /// [context] puede ser 'login', 'api', etc. para mensajes específicos del contexto
  static String parseResponse(
    http.Response response, {
    String context = 'api',
  }) {
    // Intentar extraer mensaje del body
    String? bodyMessage;
    try {
      if (response.body.isNotEmpty) {
        // Buscar patrones comunes de mensajes en JSON
        final body = response.body.toLowerCase();
        if (body.contains('message')) {
          // Extraer mensaje simple (sin parsear JSON completo)
          final messageMatch = RegExp(
            r'"message"\s*:\s*"([^"]*)"',
          ).firstMatch(response.body);
          if (messageMatch != null) {
            bodyMessage = messageMatch.group(1);
          }
        } else if (body.contains('error')) {
          final errorMatch = RegExp(
            r'"error"\s*:\s*"([^"]*)"',
          ).firstMatch(response.body);
          if (errorMatch != null) {
            bodyMessage = errorMatch.group(1);
          }
        }
      }
    } catch (e) {
      // Ignorar errores al parsear el body
    }

    // Mensajes por código de estado
    switch (response.statusCode) {
      case 400:
        return bodyMessage ??
            'Datos inválidos. Verifica la información ingresada.';

      case 401:
        // Diferenciar entre login fallido y sesión expirada
        if (context == 'login') {
          return bodyMessage ??
              'Usuario/Email o contraseña incorrectos. Verifica tus datos.';
        }
        return 'Sesión expirada. Por favor, inicia sesión nuevamente.';

      case 403:
        return bodyMessage ?? 'No tienes permiso para realizar esta acción.';

      case 404:
        return bodyMessage ?? 'Recurso no encontrado.';

      case 409:
        return bodyMessage ?? 'El usuario o email ya están registrados.';

      case 422:
        return bodyMessage ?? 'Los datos ingresados no son válidos.';

      case 429:
        return 'Demasiadas solicitudes. Por favor, espera un momento e intenta de nuevo.';

      case 500:
        return 'Error del servidor. Por favor, intenta más tarde.';

      case 502:
        return 'Servicio temporalmente no disponible. Intenta en unos momentos.';

      case 503:
        return 'Servicio en mantenimiento. Por favor, intenta más tarde.';

      case 504:
        return 'Tiempo de espera agotado. Por favor, intenta nuevamente.';

      default:
        if (response.statusCode >= 500) {
          return bodyMessage ??
              'Error del servidor (${response.statusCode}). Intenta más tarde.';
        }
        if (response.statusCode >= 400) {
          return bodyMessage ??
              'Error en la solicitud (${response.statusCode}).';
        }
        return bodyMessage ?? 'Error inesperado (${response.statusCode}).';
    }
  }

  /// Determina si un error es recuperable (puede reintentar)
  static bool isRetryable(dynamic error) {
    if (error is TimeoutException) return true;
    if (error is SocketException) return true;
    if (error is http.ClientException) return true;

    if (error is http.Response) {
      // 5xx son errores del servidor que podrían resolverse
      // 408, 429 son errores temporales
      return error.statusCode >= 500 ||
          error.statusCode == 408 ||
          error.statusCode == 429;
    }

    return false;
  }

  /// Determina si un error es de autenticación (debe cerrar sesión)
  static bool isAuthError(dynamic error) {
    if (error is http.Response) {
      return error.statusCode == 401;
    }
    return false;
  }

  /// Determina si un error es de red (sin conexión)
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is http.ClientException ||
        (error is TimeoutException &&
            error.message?.contains('network') == true);
  }

  /// Obtiene un mensaje corto para snackbar
  static String getShortMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Conexión lenta';
    }
    if (error is SocketException) {
      return 'Sin conexión';
    }
    if (error is http.Response) {
      switch (error.statusCode) {
        case 400:
          return 'Datos inválidos';
        case 401:
          return 'Sesión expirada';
        case 403:
          return 'Sin permisos';
        case 404:
          return 'No encontrado';
        case 409:
          return 'Ya existe';
        case 500:
          return 'Error del servidor';
        default:
          return 'Error ${error.statusCode}';
      }
    }
    return 'Error';
  }
}
