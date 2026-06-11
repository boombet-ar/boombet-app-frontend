import 'dart:developer';
import 'dart:ui' as ui;

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/utils/qr_saver.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/domain/eventos_service.dart';
import 'package:boombet_app/services/domain/formularios_service.dart';
import 'package:boombet_app/services/domain/raffle_service.dart';
import 'package:boombet_app/services/domain/tids_service.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/affiliates/forms/create_form.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EventDetailPage extends StatefulWidget {
  final int eventoId;
  final EventoModel? evento;

  const EventDetailPage({
    super.key,
    required this.eventoId,
    this.evento,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final TidsService _tidsService = TidsService();
  final EventosService _eventosService = EventosService();
  final FormulariosService _formulariosService = FormulariosService();

  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
  List<FormularioModel> _formularios = [];
  Map<int, String> _sorteoMediaUrlById = {};
  Map<int, Map<String, dynamic>> _sorteoById = {};
  RaffleModel? _sorteoDelEvento;
  int? _totalAfiliaciones;
  bool _afiliacionesError = false;
  final Set<int> _deletingIds = {};
  final Set<int> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _tids.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _afiliacionesError = false;
    });

    try {
      final allTids = await _tidsService.fetchTids();
      if (!mounted) return;
      setState(() {
        _tids = allTids.where((t) => t.idEvento == widget.eventoId).toList();
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[EventDetailPage] tids load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los TIDs: $e';
        _isLoading = false;
      });
    }

    // Formularios del evento + mediaUrls de sorteos: carga no crítica
    try {
      final results = await Future.wait([
        _formulariosService.fetchFormularios(),
        RaffleService().fetchRaffles(),
      ]);
      if (!mounted) return;
      final allForms = results[0] as List<FormularioModel>;
      final rawRaffles = results[1] as List<Map<String, dynamic>>;
      final mediaUrls = <int, String>{};
      final sorteoById = <int, Map<String, dynamic>>{};
      for (final r in rawRaffles) {
        final id = r['id'];
        final numId = id is int ? id : int.tryParse(id.toString()) ?? -1;
        if (numId == -1) continue;
        sorteoById[numId] = r;
        final media = r['mediaUrl']?.toString();
        if (media != null && media.isNotEmpty) mediaUrls[numId] = media;
      }
      RaffleModel? sorteoDelEvento;
      for (final r in rawRaffles) {
        final raffle = RaffleModel.fromMap(r);
        if (raffle.eventoId == widget.eventoId) {
          sorteoDelEvento = raffle;
          break;
        }
      }
      setState(() {
        _formularios = allForms.where((f) => f.eventoId == widget.eventoId).toList();
        _sorteoMediaUrlById = mediaUrls;
        _sorteoById = sorteoById;
        _sorteoDelEvento = sorteoDelEvento;
      });
    } catch (e) {
      log('[EventDetailPage] formularios load error: $e');
    }

    // Afiliaciones count: carga no crítica, muestra error inline
    try {
      final total = await _eventosService.fetchEventoTotalAfiliaciones(
        id: widget.eventoId,
      );
      if (!mounted) return;
      setState(() => _totalAfiliaciones = total);
    } catch (e) {
      log('[EventDetailPage] afiliaciones load error: $e');
      if (!mounted) return;
      setState(() => _afiliacionesError = true);
    }
  }

  Future<void> _delete(TidModel tid) async {
    if (_deletingIds.contains(tid.id)) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
    final textColor =
        isDark ? AppConstants.textDark : AppConstants.lightLabelText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Eliminar TID', style: TextStyle(color: textColor)),
        content: Text(
          '¿Querés eliminar el TID "${tid.tid}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingIds.add(tid.id));

    try {
      await _tidsService.deleteTid(id: tid.id);
      if (!mounted) return;
      setState(() {
        _tids = _tids.where((t) => t.id != tid.id).toList();
        _deletingIds.remove(tid.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(tid.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el TID.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeFromEvento(TidModel tid) async {
    if (_removingIds.contains(tid.id)) return;

    setState(() => _removingIds.add(tid.id));

    try {
      await _tidsService.removeTidFromEvento(
        id: tid.id,
        tidCode: tid.tid,
      );
      if (!mounted) return;
      setState(() {
        _tids = _tids.where((t) => t.id != tid.id).toList();
        _removingIds.remove(tid.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _removingIds.remove(tid.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo sacar el TID del evento.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showCreateTidDialog() async {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const textColor = AppConstants.textDark;
    const dialogBg = AppConstants.darkAccent;
    final tidController = TextEditingController();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          title: const Text(
            'Crear TID',
            style: TextStyle(color: textColor),
          ),
          content: TextField(
            controller: tidController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Código TID',
              hintText: 'Ej: SHOW_123',
              labelStyle:
                  TextStyle(color: textColor.withValues(alpha: 0.7)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppConstants.primaryGreen),
              ),
            ),
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final tid = tidController.text.trim();
                      if (tid.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _tidsService.createTid(
                          tid: tid,
                          idEvento: widget.eventoId,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        _loadData(force: true);
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No se pudo crear el TID: $e'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primaryGreen,
                      ),
                    )
                  : const Text(
                      'Crear',
                      style: TextStyle(color: AppConstants.primaryGreen),
                    ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 200),
      tidController.dispose,
    );
  }

  void _showTidQr(TidModel tid) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    final qrRepaintKey = GlobalKey();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        bool isFetching = false;
        String? qrData;
        String? fetchError;
        bool isDownloading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!isFetching && qrData == null && fetchError == null) {
              isFetching = true;
              _tidsService
                  .fetchTidById(id: tid.id)
                  .then((result) {
                    setDialogState(() {
                      final base = kIsWeb ? Uri.base.origin : 'https://app.boombet.com';
                      qrData = '$base/register?tid=${result.tid}';
                      isFetching = false;
                    });
                  })
                  .catchError((e) {
                    log('[EventDetailPage] fetchTidById error: $e');
                    setDialogState(() {
                      fetchError = 'No se pudo obtener el TID.';
                      isFetching = false;
                    });
                  });
            }

            Future<void> handleDownload() async {
              if (isDownloading) return;
              setDialogState(() => isDownloading = true);
              try {
                final boundary = qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                if (boundary == null) throw Exception('No se pudo capturar el QR');
                final image = await boundary.toImage(pixelRatio: 3.0);
                final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                if (byteData == null) throw Exception('Error al generar imagen');
                final bytes = byteData.buffer.asUint8List();
                final safeName = tid.tid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                final savedPath = await saveQrImage(bytes, 'tid_${safeName}_qr.png');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(savedPath != null ? 'QR guardado en Descargas' : 'QR descargado correctamente'),
                    backgroundColor: green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Error al descargar: $e'),
                    backgroundColor: AppConstants.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } finally {
                if (ctx.mounted) setDialogState(() => isDownloading = false);
              }
            }

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
                      boxShadow: [BoxShadow(color: green.withValues(alpha: 0.25), blurRadius: 32, spreadRadius: 2)],
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
                                border: Border.all(color: green.withValues(alpha: 0.22)),
                              ),
                              child: const Icon(Icons.qr_code_rounded, color: green, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tid.tid.isNotEmpty ? tid.tid : 'QR del TID',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (qrData != null)
                          RepaintBoundary(
                            key: qrRepaintKey,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.all(12),
                              child: QrImageView(
                                data: qrData!,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                              ),
                            ),
                          )
                        else if (fetchError != null)
                          SizedBox(
                            height: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppConstants.errorRed, size: 28),
                                const SizedBox(height: 8),
                                Text(fetchError!, style: const TextStyle(color: AppConstants.errorRed, fontSize: 13), textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: green, strokeWidth: 2.5))),
                        const SizedBox(height: 16),
                        if (qrData != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isDownloading ? null : handleDownload,
                              icon: isDownloading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                  : const Icon(Icons.download_rounded, size: 16),
                              label: Text(isDownloading ? 'Descargando...' : 'Descargar QR', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: green.withValues(alpha: 0.45),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              backgroundColor: green.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: green.withValues(alpha: 0.18))),
                            ),
                            child: const Text('Cerrar', style: TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Tocá en cualquier lugar para cerrar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFormQrDialog(TidModel tid, {int? lockedFormId}) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    final qrRepaintKey = GlobalKey();
    final formulariosService = FormulariosService();

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        bool isLoadingForms = false;
        bool formsLoaded = false;
        List<FormularioModel> forms = [];
        Map<int, String> sorteoNames = {};
        Map<int, String> sorteoMediaUrls = {};
        String? loadError;
        int? selectedFormId = lockedFormId;
        bool isDownloading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!isLoadingForms && !formsLoaded && loadError == null) {
              isLoadingForms = true;
              Future.wait([
                formulariosService.fetchFormularios(),
                RaffleService().fetchRaffles(),
              ]).then((results) {
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
                setDialogState(() {
                  forms = loadedForms;
                  sorteoNames = names;
                  sorteoMediaUrls = mediaUrls;
                  isLoadingForms = false;
                  formsLoaded = true;
                });
              }).catchError((e) {
                setDialogState(() {
                  loadError = 'No se pudieron cargar los formularios.';
                  isLoadingForms = false;
                });
              });
            }

            final selectedForm = forms.where((f) => f.id == selectedFormId).firstOrNull;
            final selectedMediaUrl = selectedForm?.sorteoId != null ? sorteoMediaUrls[selectedForm!.sorteoId] : null;
            final qrUrl = selectedFormId != null
                ? '${ApiConfig.menuUrl}sorteoForm?formId=$selectedFormId&tidId=${tid.id}${ApiConfig.mediaUrlParam(selectedMediaUrl)}'
                : null;

            Future<void> handleDownload() async {
              if (isDownloading || qrUrl == null) return;
              setDialogState(() => isDownloading = true);
              try {
                final boundary = qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                if (boundary == null) throw Exception('No se pudo capturar el QR');
                final image = await boundary.toImage(pixelRatio: 3.0);
                final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                if (byteData == null) throw Exception('Error al generar imagen');
                final bytes = byteData.buffer.asUint8List();
                final safeName = tid.tid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                final savedPath = await saveQrImage(bytes, 'form_${safeName}_qr.png');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(savedPath != null ? 'QR guardado en Descargas' : 'QR descargado correctamente'),
                    backgroundColor: green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ));
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Error al descargar: $e'),
                    backgroundColor: AppConstants.errorRed,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              } finally {
                if (ctx.mounted) setDialogState(() => isDownloading = false);
              }
            }

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
                      boxShadow: [BoxShadow(color: green.withValues(alpha: 0.25), blurRadius: 32, spreadRadius: 2)],
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
                                border: Border.all(color: green.withValues(alpha: 0.22)),
                              ),
                              child: const Icon(Icons.dynamic_form_outlined, color: green, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('QR de Formulario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text(tid.tid, style: TextStyle(color: green.withValues(alpha: 0.70), fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isLoadingForms)
                          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: green, strokeWidth: 2.5)))
                        else if (loadError != null)
                          Text(loadError!, style: const TextStyle(color: AppConstants.errorRed, fontSize: 12))
                        else if (forms.isEmpty)
                          Text('No hay formularios disponibles.', style: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 12))
                        else if (lockedFormId != null) ...[
                          Text('Formulario del evento', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final f = forms.where((f) => f.id == lockedFormId).firstOrNull;
                            final label = f != null
                                ? 'Form #${f.id}${f.sorteoId != null ? ' · ${sorteoNames[f.sorteoId] ?? 'Sorteo #${f.sorteoId}'}' : f.tidId != null ? ' · TID #${f.tidId}' : ''}'
                                : 'Form #$lockedFormId';
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: green.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 13, color: green.withValues(alpha: 0.60)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          Text('Seleccionar formulario', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int>(
                            value: selectedFormId,
                            dropdownColor: dialogBg,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Formulario',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: green)),
                            ),
                            iconEnabledColor: green.withValues(alpha: 0.60),
                            items: forms.map((f) => DropdownMenuItem<int>(
                              value: f.id,
                              child: Text(
                                'Form #${f.id}${f.sorteoId != null ? ' (${sorteoNames[f.sorteoId] ?? 'Sorteo #${f.sorteoId}'})' : f.tidId != null ? ' (TID #${f.tidId})' : ''}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedFormId = v),
                          ),
                        ],
                        if (qrUrl != null) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: RepaintBoundary(
                              key: qrRepaintKey,
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.all(12),
                                child: QrImageView(
                                  data: qrUrl,
                                  version: QrVersions.auto,
                                  size: 200,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: qrUrl));
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: const Text('Link copiado'),
                                backgroundColor: green,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ));
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: green.withValues(alpha: 0.20)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.link_rounded, size: 13, color: green.withValues(alpha: 0.60)),
                                  const SizedBox(width: 7),
                                  Expanded(child: Text(qrUrl, style: TextStyle(color: green.withValues(alpha: 0.80), fontSize: 10, fontWeight: FontWeight.w500))),
                                  const SizedBox(width: 6),
                                  Icon(Icons.copy_rounded, size: 12, color: green.withValues(alpha: 0.55)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isDownloading ? null : handleDownload,
                              icon: isDownloading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                  : const Icon(Icons.download_rounded, size: 16),
                              label: Text(isDownloading ? 'Descargando...' : 'Descargar QR', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: green.withValues(alpha: 0.45),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              backgroundColor: green.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: green.withValues(alpha: 0.18))),
                            ),
                            child: const Text('Cerrar', style: TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Tocá en cualquier lugar para cerrar', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTidAffiliationsCount(TidModel tid) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isFetching = false;
        int? totalJugadores;
        String? fetchError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!isFetching && totalJugadores == null && fetchError == null) {
              isFetching = true;
              _tidsService
                  .fetchTidTotalJugadores(id: tid.id)
                  .then((count) {
                    setDialogState(() {
                      totalJugadores = count;
                      isFetching = false;
                    });
                  })
                  .catchError((e) {
                    setDialogState(() {
                      fetchError = 'No se pudo obtener la cantidad.';
                      isFetching = false;
                    });
                  });
            }

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: green.withValues(alpha: 0.20)),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        border: Border(
                          bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.people_outline, color: green, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Afiliaciones',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                Text(
                                  tid.tid.isNotEmpty ? tid.tid : 'TID',
                                  style: TextStyle(color: green.withValues(alpha: 0.70), fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: isFetching
                          ? const SizedBox(
                              height: 48,
                              child: Center(
                                child: CircularProgressIndicator(color: green, strokeWidth: 2.5),
                              ),
                            )
                          : fetchError != null
                              ? Text(
                                  fetchError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 13),
                                )
                              : Column(
                                  children: [
                                    Text(
                                      '$totalJugadores',
                                      style: const TextStyle(
                                        color: green,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'jugador${totalJugadores == 1 ? '' : 'es'} afiliado${totalJugadores == 1 ? '' : 's'}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                                    ),
                                  ],
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: green.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: green.withValues(alpha: 0.18)),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(color: green, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _quickCreateSorteo() async {
    if (!mounted) return;
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: green.withValues(alpha: 0.20)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              initialEventoId: widget.eventoId,
              lockEvento: true,
              onCreated: () {
                Navigator.of(dialogCtx).pop();
                _loadData(force: true);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickCreateForm() async {
    if (!mounted) return;
    await showCreateFormDialog(
      context: context,
      onCreated: (_) => _loadData(force: true),
    );
  }

  void _handleEditSorteo(int sorteoId) {
    final raw = _sorteoById[sorteoId];
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo obtener la información del sorteo.'),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    final raffle = RaffleModel.fromMap(raw);
    final fechaFin = raffle.fechaFin.isNotEmpty
        ? DateTime.tryParse(raffle.fechaFin)?.toLocal()
        : null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppConstants.primaryGreen.withValues(alpha: 0.20)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              raffleId: raffle.id,
              initialText: raffle.text,
              initialCasinoGralId: raffle.casinoGralId,
              initialFechaFin: fechaFin,
              initialMediaUrl: raffle.mediaUrl,
              initialEventoId: raffle.eventoId,
              initialCantidadGanadores: raffle.cantidadGanadores,
              initialPremios: raffle.premios,
              initialEmailPresentador: raffle.emailPresentador,
              initialInstrucciones: raffle.instrucciones,
              initialActivo: raffle.activo,
              lockEvento: true,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadData(force: true);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final nombre =
        widget.evento?.nombre.isNotEmpty == true
            ? widget.evento!.nombre
            : 'Evento #${widget.eventoId}';

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Info del evento ────────────────────────────────────
                if (widget.evento != null) ...[
                  _SectionLabel(text: 'Información', accent: accent),
                  _EventInfoTile(evento: widget.evento!, accent: accent),
                  const SizedBox(height: 20),
                ],

                // ── Afiliaciones ───────────────────────────────────────
                _SectionLabel(text: 'Afiliaciones', accent: accent),
                _AfiliacionesTile(
                  total: _totalAfiliaciones,
                  isLoading: _isLoading,
                  hasError: _afiliacionesError,
                  accent: accent,
                ),
                const SizedBox(height: 20),

                // ── Sorteo ─────────────────────────────────────────────
                if (!_isLoading && _sorteoDelEvento == null) ...[
                  _SectionLabel(text: 'Sorteo', accent: accent),
                  _CreateActionButton(
                    icon: Icons.emoji_events_outlined,
                    label: 'Crear Sorteo',
                    accent: accent,
                    onTap: _quickCreateSorteo,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Formularios ────────────────────────────────────────
                _SectionLabel(text: 'Formularios del evento', accent: accent),
                if (_formularios.isNotEmpty)
                  ..._formularios.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DetailFormTile(
                          form: f,
                          accent: accent,
                          mediaUrl: f.sorteoId != null ? _sorteoMediaUrlById[f.sorteoId] : null,
                          onEditSorteo: f.sorteoId != null ? () => _handleEditSorteo(f.sorteoId!) : null,
                        ),
                      ))
                else if (!_isLoading)
                  _CreateActionButton(
                    icon: Icons.dynamic_form_outlined,
                    label: 'Crear Formulario',
                    accent: accent,
                    onTap: _quickCreateForm,
                  ),
                const SizedBox(height: 20),

                // ── Crear TID ──────────────────────────────────────────
                _SectionLabel(text: 'TIDs del evento', accent: accent),
                _CreateTidButton(accent: accent, onTap: _showCreateTidDialog),
                const SizedBox(height: 12),

                // ── Lista TIDs ─────────────────────────────────────────
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accent,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (_error != null)
                  _DetailError(
                    message: _error!,
                    onRetry: () => _loadData(force: true),
                  )
                else if (_tids.isEmpty)
                  _DetailEmpty(
                    onRetry: () => _loadData(force: true),
                  )
                else ...[
                  ..._tids.map((tid) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DetailTidTile(
                          tid: tid,
                          accent: accent,
                          isDeleting: _deletingIds.contains(tid.id),
                          isRemoving: _removingIds.contains(tid.id),
                          onDelete: () => _delete(tid),
                          onRemoveFromEvento: () => _removeFromEvento(tid),
                          onShowQr: () => _showTidQr(tid),
                          onShowFormQr: () => _showFormQrDialog(tid, lockedFormId: _formularios.isNotEmpty ? _formularios.first.id : null),
                          onViewAffiliations: () => _showTidAffiliationsCount(tid),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConstants.darkAccent,
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: accent),
                        const SizedBox(width: 12),
                        Text(
                          '${_tids.length} TID${_tids.length == 1 ? '' : 's'} asignado${_tids.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────────

class _EventInfoTile extends StatelessWidget {
  final EventoModel evento;
  final Color accent;

  const _EventInfoTile({required this.evento, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fechaFin = evento.fechaFin != null
        ? _formatFecha(evento.fechaFin!)
        : 'Sin fecha de fin';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_note_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.nombre.isNotEmpty ? evento.nombre : 'Sin nombre',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fechaFin,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: evento.activo
                  ? AppConstants.primaryGreen.withValues(alpha: 0.15)
                  : AppConstants.errorRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              evento.activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: evento.activo
                    ? AppConstants.primaryGreen
                    : AppConstants.errorRed,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String fechaFin) {
    try {
      final dt = DateTime.parse(fechaFin).toLocal();
      return 'Fin: ${DateFormat('dd/MM/yyyy').format(dt)}';
    } catch (_) {
      return 'Fin: $fechaFin';
    }
  }
}

class _AfiliacionesTile extends StatelessWidget {
  final int? total;
  final bool isLoading;
  final bool hasError;
  final Color accent;

  const _AfiliacionesTile({
    required this.total,
    required this.isLoading,
    required this.hasError,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const statColor = Color(0xFF4CAF82); // verde distinto al accent principal

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: statColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, color: statColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Jugadores afiliados',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statColor,
              ),
            )
          else if (hasError)
            const Icon(Icons.error_outline, color: AppConstants.errorRed, size: 20)
          else
            Text(
              total?.toString() ?? '—',
              style: const TextStyle(
                color: statColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color accent;

  const _SectionLabel({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateTidButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _CreateTidButton({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_link, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Crear TID',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: accent),
          ],
        ),
      ),
    );
  }
}

class _DetailTidTile extends StatelessWidget {
  final TidModel tid;
  final Color accent;
  final bool isDeleting;
  final bool isRemoving;
  final VoidCallback onDelete;
  final VoidCallback onRemoveFromEvento;
  final VoidCallback onShowQr;
  final VoidCallback onShowFormQr;
  final VoidCallback? onViewAffiliations;

  const _DetailTidTile({
    required this.tid,
    required this.accent,
    required this.isDeleting,
    required this.isRemoving,
    required this.onDelete,
    required this.onRemoveFromEvento,
    required this.onShowQr,
    required this.onShowFormQr,
    this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = isDeleting || isRemoving;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tid.tid.isNotEmpty ? tid.tid : 'Sin TID',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onViewAffiliations,
                  icon: const Icon(
                    Icons.people_outline,
                    size: 13,
                    color: AppConstants.primaryGreen,
                  ),
                  label: const Text(
                    'Ver afiliaciones',
                    style: TextStyle(color: AppConstants.primaryGreen, fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'QR de formulario',
            onPressed: busy ? null : onShowFormQr,
            icon: Icon(Icons.dynamic_form_outlined, color: busy ? AppConstants.primaryGreen.withValues(alpha: 0.30) : AppConstants.primaryGreen, size: 20),
          ),
          IconButton(
            tooltip: 'Ver QR del TID',
            onPressed: busy ? null : onShowQr,
            icon: Icon(Icons.qr_code_rounded, color: busy ? AppConstants.primaryGreen.withValues(alpha: 0.30) : AppConstants.primaryGreen, size: 20),
          ),
          IconButton(
            tooltip: 'Sacar del evento',
            onPressed: busy ? null : onRemoveFromEvento,
            icon: isRemoving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                : const Icon(Icons.link_off, color: Colors.orange),
          ),
          IconButton(
            tooltip: 'Eliminar TID',
            onPressed: busy ? null : onDelete,
            icon: isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.errorRed,
                    ),
                  )
                : const Icon(Icons.delete_outline, color: AppConstants.errorRed),
          ),
        ],
      ),
    );
  }
}

class _DetailFormTile extends StatelessWidget {
  final FormularioModel form;
  final Color accent;
  final String? mediaUrl;
  final VoidCallback? onEditSorteo;

  const _DetailFormTile({required this.form, required this.accent, this.mediaUrl, this.onEditSorteo});

  String get _link {
    if (form.sorteoId != null || form.tidId != null) {
      return '${ApiConfig.menuUrl}sorteoForm?formId=${form.id}${ApiConfig.mediaUrlParam(mediaUrl)}';
    }
    return '';
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Link copiado',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      backgroundColor: AppConstants.primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final link = _link;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.dynamic_form_outlined,
                    color: green, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Formulario #${form.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              if (form.tidId != null)
                _FormChip(
                    icon: Icons.track_changes_outlined,
                    label: 'TID #${form.tidId}')
              else if (form.sorteoId != null)
                _FormChip(
                    icon: Icons.emoji_events_outlined,
                    label: 'Sorteo #${form.sorteoId}'),
              if (onEditSorteo != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onEditSorteo,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: AppConstants.primaryGreen.withValues(alpha: 0.30)),
                    ),
                    child: const Icon(Icons.edit_outlined, color: AppConstants.primaryGreen, size: 14),
                  ),
                ),
              ],
            ],
          ),
          if (link.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _copyLink(context),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 13, color: green.withValues(alpha: 0.60)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        link,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: green.withValues(alpha: 0.80),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded,
                        size: 12, color: green.withValues(alpha: 0.55)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FormChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: green.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: green.withValues(alpha: 0.70)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: green.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _CreateActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: accent),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudieron cargar los TIDs.',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _DetailEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay TIDs asignados a este evento.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Refrescar')),
        ],
      ),
    );
  }
}
