import 'dart:async';

class DeepLinkPayload {
  DeepLinkPayload({required this.uri, this.token});

  final Uri uri;
  final String? token;

  bool get isEmailConfirmation {
    // Detectar esquema boombet
    if (uri.scheme == 'boombet') {
      final host = uri.host.toLowerCase();
      if (host == 'confirm') return true;
      final normalizedPath = uri.path.toLowerCase();
      return normalizedPath == '/confirm' || normalizedPath == 'confirm';
    }

    // Detectar URLs HTTP/HTTPS que contienen confirm en la ruta
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final path = uri.path.toLowerCase();
      if (path.contains('confirm')) {
        return true;
      }
    }

    return false;
  }

  bool get isPasswordReset {
    // Detectar esquema boombet
    if (uri.scheme == 'boombet') {
      final host = uri.host.toLowerCase();
      if (host == 'reset-password' || host == 'reset') return true;
      final normalizedPath = uri.path.toLowerCase();
      return normalizedPath == '/reset-password' ||
          normalizedPath == 'reset-password' ||
          normalizedPath == '/reset' ||
          normalizedPath == 'reset';
    }

    // Detectar URLs HTTP/HTTPS que contienen reset-password en la ruta
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final path = uri.path.toLowerCase();
      if (path.contains('reset-password') || path.contains('reset')) {
        return true;
      }
    }

    return false;
  }

  bool get isAffiliationCompleted {
    if (uri.scheme == 'boombet') {
      final host = uri.host.toLowerCase();
      final normalizedPath = uri.path.toLowerCase();
      if (host.contains('affiliation') || host.contains('afiliacion')) {
        return normalizedPath.contains('completed') ||
            normalizedPath.contains('completada') ||
            normalizedPath.contains('resultado');
      }
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final path = uri.path.toLowerCase();
      if (path.contains('affiliation') && path.contains('result')) return true;
      if (path.contains('afiliacion') && path.contains('resultado'))
        return true;
    }

    return false;
  }
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final StreamController<DeepLinkPayload> _controller =
      StreamController<DeepLinkPayload>.broadcast();

  DeepLinkPayload? _lastPayload;
  bool _initialRouteConsumed = false;

  Stream<DeepLinkPayload> get stream => _controller.stream;
  DeepLinkPayload? get lastPayload => _lastPayload;

  void emit(DeepLinkPayload payload) {
    _lastPayload = payload;
    // Log de entrada de payload para diagn├│stico de deeplinks/push
    try {
      // Evitar logs masivos en producci├│n, pero esto ayuda a tracing
      // de datos de deeplink.
      // ignore: avoid_print
      print('­ƒöù DeepLink emit: uri=${payload.uri} token=${payload.token}');
    } catch (_) {}
    _controller.add(payload);
  }

  void markPayloadHandled(DeepLinkPayload payload) {
    if (identical(_lastPayload, payload)) {
      _lastPayload = null;
    }
  }

  String? navigationPathForPayload(DeepLinkPayload payload) {
    // Logging detallado de resoluci├│n de ruta
    // ignore: avoid_print
    print(
      '­ƒöù Resolviendo navigationPathForPayload: uri=${payload.uri}, token=${payload.token}',
    );

    final token = payload.token;
    if (payload.isAffiliationCompleted) {
      // ignore: avoid_print
      print('­ƒöù Payload detectado como afiliaci├│n completada');
      return '/affiliation-results';
    }

    if (payload.isPasswordReset) {
      if (token == null || token.isEmpty) return null;
      return Uri(
        path: '/reset-password',
        queryParameters: {'token': token},
      ).toString();
    }

    if (payload.isEmailConfirmation) {
      if (token == null || token.isEmpty) return null;
      return Uri(
        path: '/confirm',
        queryParameters: {'token': token},
      ).toString();
    }

    return null;
  }

  String? consumeInitialRoute() {
    if (_initialRouteConsumed) {
      return null;
    }

    _initialRouteConsumed = true;

    if (_lastPayload == null) {
      return null;
    }

    return navigationPathForPayload(_lastPayload!);
  }

  void dispose() {
    _controller.close();
  }
}
