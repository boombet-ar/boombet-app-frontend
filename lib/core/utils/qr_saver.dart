// Exporta la implementación correcta según plataforma:
// Web    → qr_saver_web.dart  (descarga en el browser)
// Mobile → qr_saver_stub.dart (guarda en disco)
export 'qr_saver_stub.dart' if (dart.library.html) 'qr_saver_web.dart';
