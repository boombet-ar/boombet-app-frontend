import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Guarda [bytes] como PNG en disco y retorna la ruta del archivo.
/// Android → intenta la carpeta pública de Descargas primero,
///            si no existe usa el directorio externo de la app.
/// iOS / resto → directorio de documentos de la app.
Future<String?> saveQrImage(Uint8List bytes, String filename) async {
  Directory? dir;

  if (Platform.isAndroid) {
    // Carpeta pública Descargas (no necesita permiso en Android 10+)
    const publicDownloads = '/storage/emulated/0/Download';
    final downloadsDir = Directory(publicDownloads);
    if (await downloadsDir.exists()) {
      dir = downloadsDir;
    } else {
      // Fallback: directorio externo de la app
      dir = await getExternalStorageDirectory();
    }
  }

  // iOS o cualquier otro fallback
  dir ??= await getApplicationDocumentsDirectory();

  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
