import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'token_service.dart';

/// Cliente HTTP centralizado con manejo de errores, retry automático y 401 handler
///
/// Características:
/// - Auto-retry en errores de red (3 intentos con backoff exponencial)
/// - Detección de 401 (token expirado) y limpieza de tokens
/// - Headers centralizados (Authorization, Content-Type)
/// - Timeout configurable
/// - Logs detallados de todas las requests
class HttpClient {
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Callback para manejar 401 (token expirado)
  /// Se debe configurar desde main.dart después de inicializar la app
  static Function()? onUnauthorized;

  /// Headers base que se agregan a todas las requests
  static Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Agregar token de autorización si está disponible
    if (includeAuth) {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // Agregar headers adicionales
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Maneja la respuesta y detecta errores comunes
  static void _handleResponse(http.Response response, String url) {
    log(
      '[HttpClient] ${response.request?.method} $url - Status: ${response.statusCode}',
    );

    // SOLO 401 = No autenticado (token inválido o expirado)
    // 403 = Prohibido (sin permisos) - NO debe hacer logout automático
    if (response.statusCode == 401) {
      log('[HttpClient] ❌ 401 Unauthorized - Token expirado');
      // Limpiar tokens y notificar para logout
      TokenService.clearTokens();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
  }

  /// Realiza un POST con retry automático
  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log('[HttpClient] POST $url (Attempt ${retryCount + 1}/$_maxRetries)');
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }

  /// Realiza un GET con retry automático
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log('[HttpClient] GET $url (Attempt ${retryCount + 1}/$_maxRetries)');

      final response = await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return get(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return get(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return get(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }

  /// Realiza un PUT con retry automático
  static Future<http.Response> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log('[HttpClient] PUT $url (Attempt ${retryCount + 1}/$_maxRetries)');
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await http
          .put(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }

  /// Realiza un DELETE con retry automático
  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log('[HttpClient] DELETE $url (Attempt ${retryCount + 1}/$_maxRetries)');

      final response = await http
          .delete(Uri.parse(url), headers: requestHeaders)
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }

  /// Realiza un PATCH con retry automático
  static Future<http.Response> patch(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log('[HttpClient] PATCH $url (Attempt ${retryCount + 1}/$_maxRetries)');
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await http
          .patch(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log('[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log('[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < _maxRetries - 1) {
        log('[HttpClient] 🔄 Retry ${retryCount + 2}/$_maxRetries...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }
}
