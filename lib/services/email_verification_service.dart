import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';

class EmailVerificationService {
  static const _verifyPath = '/users/auth/verify';

  /// Verifica el email del usuario llamando a /api/users/auth/verify con el token
  /// Si es exitoso, marca el email como verificado y retorna true
  static Future<bool> verifyEmailWithToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      log('[EmailVerificationService] Token vacío, no se puede verificar');
      emailVerifiedNotifier.value = false;
      return false;
    }

    final baseUrl = ApiConfig.baseUrl;
    final headers = {'api-key': ApiConfig.apiKey};
    final meta = {
      'codigoAfiliado': ApiConfig.codigoAfiliado,
      'micrositioId': ApiConfig.micrositioId.toString(),
    };

    Future<bool> runGet(
      String description,
      Map<String, String> params, {
      bool includeMeta = true,
      bool includeHeaders = true,
    }) async {
      final uri = Uri.parse(
        '$baseUrl$_verifyPath',
      ).replace(queryParameters: includeMeta ? {...meta, ...params} : params);
      log('[EmailVerificationService] Intentando $description: $uri');
      final response = await HttpClient.get(
        uri.toString(),
        includeAuth: false,
        headers: includeHeaders ? headers : null,
      );
      if (_isSuccess(response.statusCode) ||
          _isAlreadyVerified(response.statusCode, response.body)) {
        return _markVerified();
      }
      _logFailure(description, response.statusCode, response.body);
      return false;
    }

    Future<bool> runGetPath(String description, String pathSuffix) async {
      final uri = Uri.parse('$baseUrl$_verifyPath$pathSuffix');
      log('[EmailVerificationService] Intentando $description: $uri');
      final response = await HttpClient.get(
        uri.toString(),
        includeAuth: false,
        headers: headers,
      );
      if (_isSuccess(response.statusCode) ||
          _isAlreadyVerified(response.statusCode, response.body)) {
        return _markVerified();
      }
      _logFailure(description, response.statusCode, response.body);
      return false;
    }

    Future<bool> runPost(
      String description,
      Map<String, String> body, {
      bool includeMeta = true,
      bool includeHeaders = true,
    }) async {
      log(
        '[EmailVerificationService] Intentando $description en $baseUrl$_verifyPath',
      );
      final response = await HttpClient.post(
        '$baseUrl$_verifyPath',
        body: {
          if (includeMeta) ...meta,
          ...body,
          if (includeMeta) 'apiKey': ApiConfig.apiKey,
        },
        includeAuth: false,
        headers: includeHeaders ? headers : null,
      );
      if (_isSuccess(response.statusCode) ||
          _isAlreadyVerified(response.statusCode, response.body)) {
        return _markVerified();
      }
      _logFailure(description, response.statusCode, response.body);
      return false;
    }

    final attempts = [
      () => runGet(
        'GET query token simple',
        {'token': trimmedToken},
        includeMeta: false,
        includeHeaders: false,
      ),
      () => runGet('GET query token', {'token': trimmedToken}),
      () => runGet('GET query verificationToken', {
        'verificationToken': trimmedToken,
      }),
      () => runGet('GET query verification_token', {
        'verification_token': trimmedToken,
      }),
      () => runGet('GET query token+meta', {
        'token': trimmedToken,
        'apiKey': ApiConfig.apiKey,
      }),
      () => runGetPath('GET path /{token}', '/$trimmedToken'),
      () => runGetPath('GET path /token/{token}', '/token/$trimmedToken'),
      () => runPost(
        'POST body token simple',
        {'token': trimmedToken},
        includeMeta: false,
        includeHeaders: false,
      ),
      () => runPost('POST body token', {'token': trimmedToken}),
      () => runPost('POST body verificationToken', {
        'verificationToken': trimmedToken,
      }),
      () => runPost('POST body verification_token', {
        'verification_token': trimmedToken,
      }),
    ];

    for (final attempt in attempts) {
      final success = await attempt();
      if (success) {
        return true;
      }
    }

    emailVerifiedNotifier.value = false;
    return false;
  }

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  static bool _isAlreadyVerified(int statusCode, String body) {
    if (statusCode != 400) return false;
    final normalized = body.toLowerCase();
    return normalized.contains('ya fue utilizado') ||
        normalized.contains('already been used') ||
        normalized.contains('ya fue usado');
  }

  static bool _markVerified() {
    emailVerifiedNotifier.value = true;
    return true;
  }

  static void _logFailure(String description, int statusCode, String body) {
    final cleanBody = body.trim();
    final preview = cleanBody.isEmpty
        ? '<empty>'
        : cleanBody.length <= 200
        ? cleanBody
        : '${cleanBody.substring(0, 200)}...';
    log(
      '[EmailVerificationService] $description falló ($statusCode) Body: $preview',
    );
  }
}
