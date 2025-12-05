import 'dart:async';

class DeepLinkPayload {
  DeepLinkPayload({required this.uri, this.token});

  final Uri uri;
  final String? token;

  bool get isEmailConfirmation {
    if (uri.scheme != 'boombet') return false;
    final host = (uri.host ?? '').toLowerCase();
    if (host == 'confirm') return true;
    final normalizedPath = uri.path.toLowerCase();
    return normalizedPath == '/confirm' || normalizedPath == 'confirm';
  }
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final StreamController<DeepLinkPayload> _controller =
      StreamController<DeepLinkPayload>.broadcast();

  DeepLinkPayload? _lastPayload;

  Stream<DeepLinkPayload> get stream => _controller.stream;
  DeepLinkPayload? get lastPayload => _lastPayload;

  void emit(DeepLinkPayload payload) {
    _lastPayload = payload;
    _controller.add(payload);
  }

  void dispose() {
    _controller.close();
  }
}
