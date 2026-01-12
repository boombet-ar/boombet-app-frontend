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
  static const Duration _defaultTimeout = Duration(seconds: 60);
  static const int _defaultMaxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _defaultGetCacheTtl = Duration(seconds: 25);
  static const int _maxCacheEntries = 64;

  static final http.Client _client = http.Client();
  static final Map<String, _CachedItem> _getCache = {};
  static final Map<String, Future<http.Response>> _inflightGets = {};

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
      'Connection': 'keep-alive',
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

  static String _buildCacheKey(String url, Map<String, String> headers) {
    final sortedHeaders = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final headerSignature = sortedHeaders
        .map((entry) => '${entry.key}:${entry.value}')
        .join('|');
    return '$url|$headerSignature';
  }

  static void _pruneCache() {
    if (_getCache.length <= _maxCacheEntries) return;

    final entries = _getCache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
    final removeCount = _getCache.length - _maxCacheEntries;

    for (var i = 0; i < removeCount; i++) {
      _getCache.remove(entries[i].key);
    }
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
    int? maxRetries,
    int retryCount = 0,
  }) async {
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log(
        '[HttpClient] POST $url (Attempt ${retryCount + 1}/$effectiveMaxRetries)',
      );
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await _client
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

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return post(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
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
    Duration? cacheTtl,
    int? maxRetries,
    int retryCount = 0,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final ttl = cacheTtl ?? _defaultGetCacheTtl;
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );
    final cacheKey = _buildCacheKey(url, requestHeaders);
    final startAttempt = retryCount.clamp(0, effectiveMaxRetries - 1);

    if (ttl > Duration.zero) {
      final cached = _getCache[cacheKey];
      if (cached != null && !cached.isExpired) {
        log('[HttpClient] ♻️ GET cache hit: $url');
        return cached.response;
      }

      final inflight = _inflightGets[cacheKey];
      if (inflight != null) {
        log('[HttpClient] ⏳ Reusing in-flight GET: $url');
        return inflight;
      }
    }

    Future<http.Response> requestFuture = _performGet(
      url: url,
      requestHeaders: requestHeaders,
      effectiveTimeout: effectiveTimeout,
      startAttempt: startAttempt,
      maxRetries: effectiveMaxRetries,
    );

    if (ttl > Duration.zero) {
      _inflightGets[cacheKey] = requestFuture;
    }

    try {
      final response = await requestFuture;

      if (ttl > Duration.zero &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        _getCache[cacheKey] = _CachedItem(
          response: http.Response.bytes(
            response.bodyBytes,
            response.statusCode,
            headers: response.headers,
            request: response.request,
            isRedirect: response.isRedirect,
            persistentConnection: response.persistentConnection,
            reasonPhrase: response.reasonPhrase,
          ),
          expiresAt: DateTime.now().add(ttl),
        );

        _pruneCache();
      }

      return response;
    } finally {
      if (ttl > Duration.zero) {
        _inflightGets.remove(cacheKey);
      }
    }
  }

  static Future<http.Response> _performGet({
    required String url,
    required Map<String, String> requestHeaders,
    required Duration effectiveTimeout,
    required int startAttempt,
    required int maxRetries,
  }) async {
    for (var attempt = startAttempt; attempt < maxRetries; attempt++) {
      final attemptNumber = attempt + 1;

      try {
        log('[HttpClient] GET $url (Attempt $attemptNumber/$maxRetries)');

        final response = await _client
            .get(Uri.parse(url), headers: requestHeaders)
            .timeout(effectiveTimeout);

        _handleResponse(response, url);
        return response;
      } on TimeoutException catch (e) {
        log('[HttpClient] ⏱️ Timeout en $url: $e');

        if (attempt >= maxRetries - 1) {
          rethrow;
        }

        log(
          '[HttpClient] 🔄 Retry ${attemptNumber + 1}/$maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * attemptNumber);
      } on SocketException catch (e) {
        log('[HttpClient] 🌐 Error de conexión en $url: $e');

        if (attempt >= maxRetries - 1) {
          rethrow;
        }

        log(
          '[HttpClient] 🔄 Retry ${attemptNumber + 1}/$maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * attemptNumber);
      } on http.ClientException catch (e) {
        log('[HttpClient] ❌ Client error en $url: $e');

        if (attempt >= maxRetries - 1) {
          rethrow;
        }

        log(
          '[HttpClient] 🔄 Retry ${attemptNumber + 1}/$maxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * attemptNumber);
      } catch (e) {
        log('[HttpClient] ❌ Error inesperado en $url: $e');
        rethrow;
      }
    }

    throw Exception('GET $url falló después de $maxRetries intentos');
  }

  /// Realiza un PUT con retry automático
  static Future<http.Response> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    bool includeAuth = true,
    int? maxRetries,
    int retryCount = 0,
  }) async {
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log(
        '[HttpClient] PUT $url (Attempt ${retryCount + 1}/$effectiveMaxRetries)',
      );
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await _client
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

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return put(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
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
    int? maxRetries,
    int retryCount = 0,
  }) async {
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log(
        '[HttpClient] DELETE $url (Attempt ${retryCount + 1}/$effectiveMaxRetries)',
      );

      final response = await _client
          .delete(Uri.parse(url), headers: requestHeaders)
          .timeout(effectiveTimeout);

      _handleResponse(response, url);
      return response;
    } on TimeoutException catch (e) {
      log('[HttpClient] ⏱️ Timeout en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
          '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries en ${_retryDelay.inSeconds}s...',
        );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return delete(
          url,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
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
    int? maxRetries,
    int retryCount = 0,
  }) async {
    final effectiveMaxRetries = maxRetries ?? _defaultMaxRetries;
    final effectiveTimeout = timeout ?? _defaultTimeout;
    final requestHeaders = await _getHeaders(
      additionalHeaders: headers,
      includeAuth: includeAuth,
    );

    try {
      log(
        '[HttpClient] PATCH $url (Attempt ${retryCount + 1}/$effectiveMaxRetries)',
      );
      if (body != null) {
        log('[HttpClient] Body: ${jsonEncode(body)}');
      }

      final response = await _client
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

      if (retryCount < effectiveMaxRetries - 1) {
        log('[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on SocketException catch (e) {
      log('[HttpClient] 🌐 Error de conexión en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log('[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } on http.ClientException catch (e) {
      log('[HttpClient] ❌ Client error en $url: $e');

      if (retryCount < effectiveMaxRetries - 1) {
        log(
            '[HttpClient] 🔄 Retry ${retryCount + 2}/$effectiveMaxRetries...',
          );
        await Future.delayed(_retryDelay * (retryCount + 1));
        return patch(
          url,
          body: body,
          headers: headers,
          timeout: timeout,
          includeAuth: includeAuth,
          maxRetries: maxRetries,
          retryCount: retryCount + 1,
        );
      }

      rethrow;
    } catch (e) {
      log('[HttpClient] ❌ Error inesperado en $url: $e');
      rethrow;
    }
  }

  /// Limpia el caché para una URL específica o para todas las URLs que coincidan con el patrón
  static void clearCache({String? urlPattern}) {
    if (urlPattern == null) {
      log('[HttpClient] 🗑️ Clearing all cache');
      _getCache.clear();
      _inflightGets.clear();
    } else {
      log('[HttpClient] 🗑️ Clearing cache for pattern: $urlPattern');
      _getCache.removeWhere((key, value) => key.contains(urlPattern));
      _inflightGets.removeWhere((key, value) => key.contains(urlPattern));
    }
  }
}

class _CachedItem {
  final http.Response response;
  final DateTime expiresAt;

  _CachedItem({required this.response, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
