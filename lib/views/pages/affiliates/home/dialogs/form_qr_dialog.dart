import 'dart:ui' as ui;

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/utils/qr_saver.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/domain/formularios_service.dart';
import 'package:boombet_app/services/domain/raffle_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class FormQrDialog extends StatefulWidget {
  final TidModel tid;

  const FormQrDialog({super.key, required this.tid});

  @override
  State<FormQrDialog> createState() => _FormQrDialogState();
}

class _FormQrDialogState extends State<FormQrDialog> {
  final _formulariosService = FormulariosService();
  final _qrRepaintKey = GlobalKey();

  bool _isLoadingForms = false;
  bool _formsLoaded = false;
  List<FormularioModel> _forms = [];
  Map<int, String> _sorteoNames = {};
  Map<int, String> _sorteoMediaUrls = {};
  String? _loadError;
  int? _selectedFormId;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadForms();
  }

  Future<void> _loadForms() async {
    setState(() => _isLoadingForms = true);
    try {
      final results = await Future.wait([
        _formulariosService.fetchFormularios(),
        RaffleService().fetchRaffles(),
      ]);
      final loadedForms = results[0] as List<FormularioModel>;
      final rawRaffles = results[1] as List<Map<String, dynamic>>;
      final names = <int, String>{};
      final mediaUrls = <int, String>{};
      for (final r in rawRaffles) {
        final id = r['id'];
        final text = r['text']?.toString();
        final media = r['mediaUrl']?.toString();
        final numId = id is int ? id : int.tryParse(id.toString()) ?? -1;
        if (id != null && text != null && text.isNotEmpty) {
          names[numId] = text;
        }
        if (id != null && media != null && media.isNotEmpty) {
          mediaUrls[numId] = media;
        }
      }
      if (!mounted) return;
      setState(() {
        _forms = loadedForms;
        _sorteoNames = names;
        _sorteoMediaUrls = mediaUrls;
        _isLoadingForms = false;
        _formsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'No se pudieron cargar los formularios.';
        _isLoadingForms = false;
      });
    }
  }

  Future<void> _handleDownload(String qrUrl) async {
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
          await saveQrImage(bytes, 'form_${safeName}_qr.png');
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

    final selectedForm = _forms.where((f) => f.id == _selectedFormId).firstOrNull;
    final selectedMediaUrl = selectedForm?.sorteoId != null ? _sorteoMediaUrls[selectedForm!.sorteoId] : null;
    final qrUrl = _selectedFormId != null
        ? '${ApiConfig.menuUrl}sorteoForm?formId=$_selectedFormId&tidId=${widget.tid.id}${ApiConfig.mediaUrlParam(selectedMediaUrl)}'
        : null;

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: const Icon(Icons.dynamic_form_outlined,
                          color: green, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QR de Formulario',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          Text(widget.tid.tid,
                              style: TextStyle(
                                  color: green.withValues(alpha: 0.70),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoadingForms)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(
                          color: green, strokeWidth: 2.5),
                    ),
                  )
                else if (_loadError != null)
                  Text(_loadError!,
                      style: const TextStyle(
                          color: AppConstants.errorRed, fontSize: 12))
                else if (_forms.isEmpty && _formsLoaded)
                  Text('No hay formularios disponibles.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12))
                else if (_formsLoaded) ...[
                  Text('Seleccionar formulario',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedFormId,
                    dropdownColor: dialogBg,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Formulario',
                      labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.20)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: green),
                      ),
                    ),
                    iconEnabledColor: green.withValues(alpha: 0.60),
                    items: _forms
                        .map((f) => DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(
                                'Form #${f.id}${f.sorteoId != null ? ' (${_sorteoNames[f.sorteoId] ?? 'Sorteo #${f.sorteoId}'})' : f.tidId != null ? ' (TID #${f.tidId})' : ''}',
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedFormId = v),
                  ),
                ],
                if (qrUrl != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: RepaintBoundary(
                      key: _qrRepaintKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: QrImageView(
                          data: qrUrl,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: qrUrl));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Link copiado'),
                        backgroundColor: green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: green.withValues(alpha: 0.20)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded,
                              size: 13,
                              color: green.withValues(alpha: 0.60)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(qrUrl,
                                style: TextStyle(
                                    color: green.withValues(alpha: 0.80),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded,
                              size: 12,
                              color: green.withValues(alpha: 0.55)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading
                          ? null
                          : () => _handleDownload(qrUrl),
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
