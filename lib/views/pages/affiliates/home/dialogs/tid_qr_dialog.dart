import 'dart:developer';
import 'dart:ui' as ui;

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/utils/qr_saver.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/domain/tids_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:qr_flutter/qr_flutter.dart';

class TidQrDialog extends StatefulWidget {
  final TidModel tid;

  const TidQrDialog({super.key, required this.tid});

  @override
  State<TidQrDialog> createState() => _TidQrDialogState();
}

class _TidQrDialogState extends State<TidQrDialog> {
  final _tidsService = TidsService();
  final _qrRepaintKey = GlobalKey();

  bool _isFetching = false;
  String? _qrData;
  String? _fetchError;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isFetching = true);
    try {
      final result = await _tidsService.fetchTidById(id: widget.tid.id);
      if (!mounted) return;
      final base = kIsWeb ? Uri.base.origin : 'https://app.boombet.com';
      setState(() {
        _qrData = '$base/register?tid=${result.tid}';
        _isFetching = false;
      });
    } catch (e) {
      log('[TidQrDialog] fetchTidById error: $e');
      if (!mounted) return;
      setState(() {
        _fetchError = 'No se pudo obtener el TID.';
        _isFetching = false;
      });
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final boundary = _qrRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('No se pudo capturar el QR');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Error al generar imagen');
      final bytes = byteData.buffer.asUint8List();
      final safeName =
          widget.tid.tid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final savedPath =
          await saveQrImage(bytes, 'tid_${safeName}_qr.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(savedPath != null
            ? 'QR guardado en Descargas'
            : 'QR descargado correctamente'),
        backgroundColor: AppConstants.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al descargar: $e'),
        backgroundColor: AppConstants.errorRed,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: green.withValues(alpha: 0.20)),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: green.withValues(alpha: 0.22)),
                      ),
                      child: const Icon(Icons.qr_code_rounded,
                          color: green, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.tid.tid.isNotEmpty
                            ? widget.tid.tid
                            : 'QR del TID',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_qrData != null)
                  RepaintBoundary(
                    key: _qrRepaintKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: _qrData!,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black),
                      ),
                    ),
                  )
                else if (_fetchError != null)
                  SizedBox(
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppConstants.errorRed, size: 28),
                        const SizedBox(height: 8),
                        Text(_fetchError!,
                            style: const TextStyle(
                                color: AppConstants.errorRed,
                                fontSize: 13),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  const SizedBox(
                    height: 120,
                    child: Center(
                        child: CircularProgressIndicator(
                            color: green, strokeWidth: 2.5)),
                  ),
                const SizedBox(height: 16),
                if (_qrData != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isDownloading ? null : _handleDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.download_rounded,
                              size: 16),
                      label: Text(
                          _isDownloading
                              ? 'Descargando...'
                              : 'Descargar QR',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            green.withValues(alpha: 0.45),
                        padding:
                            const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: green.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: green.withValues(alpha: 0.18)),
                      ),
                    ),
                    child: const Text('Cerrar',
                        style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Tocá en cualquier lugar para cerrar',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12)),
        ],
      ),
    );
  }
}
