const Duration _isVerifiedTtl = Duration(seconds: 20);
bool? _cachedIsVerified;
DateTime? _cachedIsVerifiedAt;

/// Limpia la caché de verificación del usuario. Llamar en logout.
void clearVerificationCache() {
  _cachedIsVerified = null;
  _cachedIsVerifiedAt = null;
}

bool _parseIsVerified(dynamic data) {
  if (data is Map<String, dynamic>) {
    final direct =
        data['is_verified'] ?? data['isVerified'] ?? data['verified'];
    if (_parseIsVerified(direct)) return true;

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return _parseIsVerified(nested);
    }
  }

  if (data is bool) return data;
  if (data is num) return data == 1;
  if (data is String) {
    final lowered = data.toLowerCase().trim();
    return lowered == 'true' || lowered == '1';
  }

  return false;
}

/// Devuelve si el usuario está verificado, usando caché con TTL de 20 s.
/// [fetcher] es la función que hace el request a la API (inyectada desde el router).
Future<bool?> fetchIsVerified(
  Future<Map<String, dynamic>> Function() fetcher,
) async {
  final now = DateTime.now();
  if (_cachedIsVerifiedAt != null &&
      now.difference(_cachedIsVerifiedAt!) < _isVerifiedTtl) {
    return _cachedIsVerified;
  }

  try {
    final data = await fetcher();
    final parsed = _parseIsVerified(data);
    _cachedIsVerified = parsed;
    _cachedIsVerifiedAt = now;
    return parsed;
  } catch (_) {
    return null;
  }
}
