String parseCouponErrorMessage(Object error, {bool claimedCoupons = false}) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  final target = claimedCoupons ? 'cupones reclamados' : 'cupones';

  int? readStatusCode() {
    final match = RegExp(r'(^|\D)([1-5]\d\d)(\D|$)').firstMatch(lower);
    if (match == null) return null;
    return int.tryParse(match.group(2) ?? '');
  }

  final statusCode = readStatusCode();

  final isTimeout =
      lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('time out');
  if (isTimeout || statusCode == 408) {
    return 'La solicitud está tardando más de lo normal. Intentá nuevamente.';
  }

  final isAuthError =
      statusCode == 401 ||
      statusCode == 403 ||
      lower.contains('unauthorized') ||
      lower.contains('forbidden') ||
      lower.contains('token') ||
      lower.contains('sesión') ||
      lower.contains('sesion expirada');
  if (isAuthError) {
    return 'Tu sesión expiró. Iniciá sesión nuevamente para ver tus $target.';
  }

  final isNetworkError =
      lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network error') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('xmlhttprequest error') ||
      lower.contains('clientexception');
  if (isNetworkError) {
    return 'No pudimos conectarnos a internet. Verificá tu conexión e intentá otra vez.';
  }

  final isServerError =
      (statusCode != null && statusCode >= 500) ||
      lower.contains('status":"error') ||
      lower.contains('servidor') ||
      lower.contains('server error') ||
      lower.contains('error inesperado');
  if (isServerError) {
    return 'Estamos teniendo un problema del servidor para cargar los $target. Intentá nuevamente en unos minutos.';
  }

  return 'No pudimos cargar los $target por el momento. Intentá nuevamente.';
}
