import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tempTokenKey = 'temp_jwt_token';
  static const _fcmTokenKey = 'fcm_token';

  /// Guarda el token JWT de forma segura (persistente)
  static Future<void> saveToken(String token) async {
    // Validar que el token tenga formato correcto (3 partes separadas por puntos)
    if (!_isValidTokenFormat(token)) {
      log('ERROR: Token format is invalid. Expected: header.payload.signature');
      throw FormatException('Token format is invalid');
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Valida que el token tenga el formato JWT correcto (3 partes)
  static bool _isValidTokenFormat(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  /// Guarda el token temporal (no persistente entre reinicios de app)
  static Future<void> saveTemporaryToken(String token) async {
    // Validar que el token tenga formato correcto
    if (!_isValidTokenFormat(token)) {
      log('ERROR: Temporary token format is invalid');
      throw FormatException('Token format is invalid');
    }
    await _storage.write(key: _tempTokenKey, value: token);
  }

  /// Guarda el refresh token de forma segura
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  /// Obtiene el token JWT almacenado (persistente o temporal)
  static Future<String?> getToken() async {
    // Primero intenta obtener el token persistente
    String? token = await _storage.read(key: _tokenKey);

    // Si existe pero es inválido, borrarlo
    if (token != null && !_isValidTokenFormat(token)) {
      log('WARNING: Persistent token has invalid format. Deleting...');
      await _storage.delete(key: _tokenKey);
      token = null;
    }

    // Si no existe, intenta obtener el token temporal
    token ??= await _storage.read(key: _tempTokenKey);

    // Si el temporal existe pero es inválido, borrarlo
    if (token != null && !_isValidTokenFormat(token)) {
      log('WARNING: Temporary token has invalid format. Deleting...');
      await _storage.delete(key: _tempTokenKey);
      token = null;
    }

    return token;
  }

  /// Obtiene solo el token persistente (ignora temporal)
  static Future<String?> getPersistentToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    if (!_isValidTokenFormat(token)) {
      log('WARNING: Persistent token has invalid format. Deleting...');
      await _storage.delete(key: _tokenKey);
      return null;
    }

    return token;
  }

  /// Obtiene el refresh token almacenado
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Elimina el token (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tempTokenKey);
    await _storage.delete(key: _fcmTokenKey);
  }

  /// Elimina solo el token temporal
  static Future<void> deleteTemporaryToken() async {
    await _storage.delete(key: _tempTokenKey);
  }

  /// Verifica si el token existe y es válido
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    final preview = token != null
        ? token.substring(0, math.min(token.length, 20))
        : 'null';
    final suffix = token != null && token.length > 20 ? '...' : '';
    log(
      'DEBUG TokenService - Token: ${token != null ? "exists ($preview$suffix)" : preview}',
    );

    if (token == null || token.isEmpty) {
      log('DEBUG TokenService - Token is null or empty');
      return false;
    }

    // Verificar formato antes de intentar decodificar
    if (!_isValidTokenFormat(token)) {
      log('DEBUG TokenService - Token has invalid format. Deleting...');
      await deleteToken();
      return false;
    }

    try {
      // Verifica si el token ha expirado
      bool hasExpired = JwtDecoder.isExpired(token);
      log('DEBUG TokenService - Has expired: $hasExpired');

      if (!hasExpired) {
        final expirationDate = JwtDecoder.getExpirationDate(token);
        log('DEBUG TokenService - Expiration date: $expirationDate');
      }

      return !hasExpired;
    } catch (e) {
      log('DEBUG TokenService - Error validating token: $e');
      // Si falla la decodificación, limpiar tokens
      await deleteToken();
      return false;
    }
  }

  /// Verifica si hay una sesión activa (solo token persistente)
  /// Los tokens temporales NO cuentan como sesión activa al reiniciar
  static Future<bool> hasActiveSession() async {
    log('DEBUG TokenService - Checking active session...');

    // Solo verificar token PERSISTENTE (no temporal)
    final persistentToken = await getPersistentToken();

    if (persistentToken == null || persistentToken.isEmpty) {
      log('DEBUG TokenService - No persistent token found');
      return false;
    }

    try {
      bool hasExpired = JwtDecoder.isExpired(persistentToken);
      log('DEBUG TokenService - Persistent token expired: $hasExpired');
      return !hasExpired;
    } catch (e) {
      log('DEBUG TokenService - Error validating persistent token: $e');
      return false;
    }
  }

  /// Obtiene información del token decodificado
  static Future<Map<String, dynamic>?> getTokenData() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.decode(token);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene el tiempo de expiración del token
  static Future<DateTime?> getTokenExpirationDate() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      return null;
    }
  }

  /// Limpia todos los tokens (persistente, temporal y refresh)
  /// Se usa cuando el token expira (401) o en logout forzado
  static Future<void> clearTokens() async {
    log('[TokenService] Limpiando todos los tokens...');
    await deleteToken();
    log('[TokenService] ✅ Tokens eliminados');
  }

  /// Guarda el token FCM para enviarlo luego al backend
  static Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  /// Obtiene el token FCM almacenado
  static Future<String?> getFcmToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  /// Elimina el token FCM almacenado
  static Future<void> deleteFcmToken() async {
    await _storage.delete(key: _fcmTokenKey);
  }
}
