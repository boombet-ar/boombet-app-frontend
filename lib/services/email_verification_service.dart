import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';

class EmailVerificationService {
  static const _statusPath = '/users/auth/me';

  /// Llama al endpoint autenticado que devuelve el estado actual del usuario
  /// y retorna `true` si detecta que el email ya fue confirmado.
  static Future<bool> syncEmailVerificationStatus({String? email}) async {
    final response = await HttpClient.get(
      '${ApiConfig.baseUrl}$_statusPath',
      includeAuth: true,
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      emailVerifiedNotifier.value = false;
      return false;
    }

    try {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final verified = _extractVerifiedFlag(decoded);
      emailVerifiedNotifier.value = verified;
      return verified;
    } catch (_) {
      emailVerifiedNotifier.value = false;
      return false;
    }
  }

  static bool _extractVerifiedFlag(Map<String, dynamic> payload) {
    bool? normalize(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
      return null;
    }

    final candidates = <dynamic>[
      payload['emailVerified'],
      payload['email_verified'],
      payload['verified'],
      payload['status'],
    ];

    for (final key in ['user', 'data', 'profile', 'result']) {
      final nested = payload[key];
      if (nested is Map<String, dynamic>) {
        candidates.addAll([
          nested['emailVerified'],
          nested['email_verified'],
          nested['verified'],
          nested['status'],
        ]);
      }
    }

    for (final value in candidates) {
      final normalized = normalize(value);
      if (normalized != null) {
        return normalized;
      }
    }

    return false;
  }
}
