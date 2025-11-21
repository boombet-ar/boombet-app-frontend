import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tempTokenKey = 'temp_jwt_token';

  /// Guarda el token JWT de forma segura (persistente)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Guarda el token temporal (no persistente entre reinicios de app)
  static Future<void> saveTemporaryToken(String token) async {
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
    
    // Si no existe, intenta obtener el token temporal
    if (token == null) {
      token = await _storage.read(key: _tempTokenKey);
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
  }

  /// Elimina solo el token temporal
  static Future<void> deleteTemporaryToken() async {
    await _storage.delete(key: _tempTokenKey);
  }

  /// Verifica si el token existe y es válido
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    print(
      'DEBUG TokenService - Token: ${token != null ? "exists (${token.substring(0, 20)}...)" : "null"}',
    );

    if (token == null || token.isEmpty) {
      print('DEBUG TokenService - Token is null or empty');
      return false;
    }

    try {
      // Verifica si el token ha expirado
      bool hasExpired = JwtDecoder.isExpired(token);
      print('DEBUG TokenService - Has expired: $hasExpired');

      if (!hasExpired) {
        final expirationDate = JwtDecoder.getExpirationDate(token);
        print('DEBUG TokenService - Expiration date: $expirationDate');
      }

      return !hasExpired;
    } catch (e) {
      print('DEBUG TokenService - Error validating token: $e');
      return false;
    }
  }

  /// Verifica si hay una sesión activa
  static Future<bool> hasActiveSession() async {
    print('DEBUG TokenService - Checking active session...');
    final isValid = await isTokenValid();
    print('DEBUG TokenService - Active session result: $isValid');
    return isValid;
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
}
