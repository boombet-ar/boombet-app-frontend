import 'dart:async';

class DeepLinkPayload {
  DeepLinkPayload({required this.uri, this.token});

  final Uri uri;
  final String? token;

  int? get forumPostId {
    int? tryParseInt(String? value) {
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed);
    }

    bool looksLikeForumOrPublicaciones(Uri u) {
      final host = u.host.toLowerCase();
      if (host.contains('foro') ||
          host.contains('forum') ||
          host.contains('publicacion') ||
          host.contains('publicaciones') ||
          host.contains('post') ||
          host.contains('posts')) {
        return true;
      }

      final segments = u.pathSegments.map((s) => s.toLowerCase()).toList();
      return segments.contains('foro') ||
          segments.contains('forum') ||
          segments.contains('publicacion') ||
          segments.contains('publicaciones') ||
          segments.contains('post') ||
          segments.contains('posts') ||
          segments.contains('replies') ||
          segments.contains('respuestas');
    }

    // 1) Preferir query params comunes.
    final fromQuery =
        tryParseInt(uri.queryParameters['postId']) ??
        tryParseInt(uri.queryParameters['publicationId']) ??
        tryParseInt(uri.queryParameters['publicacionId']) ??
        tryParseInt(uri.queryParameters['id']);

    if (fromQuery != null) {
      // Si viene un id por query, asumir que es deeplink de publicación.
      return fromQuery;
    }

    // 2) Intentar parsear el último segmento si es numérico.
    if (!looksLikeForumOrPublicaciones(uri)) {
      return null;
    }

    if (uri.pathSegments.isEmpty) return null;

    // Buscar el primer segmento numérico de derecha a izquierda.
    for (final seg in uri.pathSegments.reversed) {
      final parsed = tryParseInt(seg);
      if (parsed != null) return parsed;
    }

    return null;
  }

  bool get isForumPostDetail => forumPostId != null;

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

  bool get isRoulette {
    if (uri.scheme == 'boombet') {
      final host = uri.host.toLowerCase();
      final path = uri.path.toLowerCase();
      return host.contains('roulette') || path.contains('roulette');
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri.path.toLowerCase().contains('roulette');
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
    _controller.add(payload);
  }

  void markPayloadHandled(DeepLinkPayload payload) {
    if (identical(_lastPayload, payload)) {
      _lastPayload = null;
    }
  }

  String? navigationPathForPayload(DeepLinkPayload payload) {
    final token = payload.token;

    if (payload.isForumPostDetail) {
      final postId = payload.forumPostId;
      if (postId == null) return null;
      return '/forum/post/$postId';
    }

    if (payload.isAffiliationCompleted) {
      return '/affiliation-results';
    }

    if (payload.isRoulette) {
      return '/play-roulette';
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
