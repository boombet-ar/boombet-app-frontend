import 'dart:ui' as ui;

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/formularios_service.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:boombet_app/views/pages/affiliates/forms/create_form.dart';
import 'package:boombet_app/utils/qr_saver.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ExternalRafflesPage extends StatefulWidget {
  const ExternalRafflesPage({super.key});

  @override
  State<ExternalRafflesPage> createState() => _ExternalRafflesPageState();
}

class _ExternalRafflesPageState extends State<ExternalRafflesPage> {
  static const int _pageSize = 5;
  static const String _tipo = 'FORM';

  final _raffleService = RaffleService();
  final _formulariosService = FormulariosService();

  bool _isLoading = true;
  String? _errorMessage;
  List<RaffleModel> _raffles = const [];
  Map<int, int> _sorteoFormIdMap = const {};
  int _currentPage = 0;
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRaffles();
    _loadFormularios();
  }

  Future<void> _loadFormularios() async {
    try {
      final forms = await _formulariosService.fetchFormularios();
      if (!mounted) return;
      setState(() {
        _sorteoFormIdMap = {
          for (final f in forms)
            if (f.sorteoId != null) f.sorteoId!: f.id,
        };
      });
    } catch (_) {}
  }

  Future<void> _loadRaffles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final raw = await _raffleService.fetchRaffles();
      if (!mounted) return;
      final all = raw.map(RaffleModel.fromMap).toList(growable: false);
      setState(() {
        _raffles = all.where((r) => r.tipo == _tipo).toList(growable: false);
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar los sorteos.';
      });
    }
  }

  int get _totalPages {
    if (_raffles.isEmpty) return 0;
    return (_raffles.length / _pageSize).ceil();
  }

  List<RaffleModel> get _currentRaffles {
    if (_raffles.isEmpty) return const [];
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _raffles.length);
    return _raffles.sublist(start, end);
  }

  String _formatEndAt(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  DateTime? _parseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleToggleActive(RaffleModel raffle) async {
    final id = raffle.id;
    if (id == null || _togglingIds.contains(id)) return;

    setState(() {
      _togglingIds.add(id);
      _raffles = _raffles.map((r) {
        if (r.id != id) return r;
        return RaffleModel(
          id: r.id,
          codigoSorteo: r.codigoSorteo,
          activo: !r.activo,
          cantidadGanadores: r.cantidadGanadores,
          emailPresentador: r.emailPresentador,
          text: r.text,
          mediaUrl: r.mediaUrl,
          casinoGralId: r.casinoGralId,
          tidId: r.tidId,
          fechaFin: r.fechaFin,
          premios: r.premios,
          afiliadorId: r.afiliadorId,
          createdAt: r.createdAt,
          tipo: r.tipo,
        );
      }).toList(growable: false);
    });

    try {
      await _raffleService.toggleRaffleActive(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _raffles = _raffles.map((r) {
          if (r.id != id) return r;
          return RaffleModel(
            id: r.id,
            codigoSorteo: r.codigoSorteo,
            activo: !r.activo,
            cantidadGanadores: r.cantidadGanadores,
            emailPresentador: r.emailPresentador,
            text: r.text,
            mediaUrl: r.mediaUrl,
            casinoGralId: r.casinoGralId,
            tidId: r.tidId,
            fechaFin: r.fechaFin,
            premios: r.premios,
            afiliadorId: r.afiliadorId,
            createdAt: r.createdAt,
            tipo: r.tipo,
          );
        }).toList(growable: false);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'No se pudo cambiar el estado del sorteo.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.40)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _togglingIds.remove(id));
    }
  }

  Future<void> _handleEdit(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              tipo: _tipo,
              raffleId: raffle.id,
              initialText: raffle.text,
              initialCasinoGralId: raffle.casinoGralId,
              initialFechaFin: _parseDateTime(raffle.fechaFin),
              initialMediaUrl: raffle.mediaUrl,
              initialTidId: raffle.tidId,
              initialCantidadGanadores: raffle.cantidadGanadores,
              initialPremios: raffle.premios,
              initialEmailPresentador: raffle.emailPresentador,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadRaffles();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(RaffleModel raffle) async {
    if (raffle.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar sorteo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar este sorteo? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppConstants.primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _raffleService.deleteRaffle(raffle.id!);
      await _loadRaffles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'Sorteo eliminado correctamente.',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'No se pudo eliminar el sorteo: $error',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.40)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _handleCreateForm(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showCreateFormDialog(
      context: context,
      preSorteoId: raffle.id,
      onCreated: (created) {
        setState(() {
          _sorteoFormIdMap = {..._sorteoFormIdMap, raffle.id!: created.id};
        });
      },
    );
  }

  Future<void> _handleDownloadQr(RaffleModel raffle) async {
    if (raffle.id == null) return;
    final formId = _sorteoFormIdMap[raffle.id];
    if (formId == null) return;
    final url = '${ApiConfig.menuUrl}sorteoForm?formId=$formId';
    await showDialog<void>(
      context: context,
      builder: (_) => _QrDownloadDialog(
        url: url,
        code: raffle.codigoSorteo,
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateRaffleSection(
              showHeader: false,
              tipo: _tipo,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadRaffles();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              // ── Botón crear ──────────────────────────────────────────────────
              _CreateButton(
                onPressed: _openCreateDialog,
                label: 'Crear sorteo por formulario',
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(height: 12),

              // ── Contenido ────────────────────────────────────────────────────
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: green,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                _ErrorState(message: _errorMessage!, onRetry: _loadRaffles)
              else if (_raffles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: green.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          color: green.withValues(alpha: 0.55), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay sorteos por formulario para mostrar.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ..._currentRaffles.map(
                  (raffle) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FormRaffleCard(
                      raffle: raffle,
                      formId: _sorteoFormIdMap[raffle.id],
                      formatEndAt: _formatEndAt(raffle.fechaFin),
                      onEdit: () => _handleEdit(raffle),
                      onDelete: () => _handleDelete(raffle),
                      onToggleActive: () => _handleToggleActive(raffle),
                      onDownloadQr: () => _handleDownloadQr(raffle),
                      onCreateForm: () => _handleCreateForm(raffle),
                      isToggling: _togglingIds.contains(raffle.id),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: green.withValues(alpha: 0.12)),
                  ),
                  child: Center(
                    child: PaginationBar(
                      currentPage: _currentPage + 1,
                      canGoPrevious: _currentPage > 0,
                      canGoNext: _currentPage < (_totalPages - 1),
                      onPrev: () {
                        if (_currentPage <= 0) return;
                        setState(() => _currentPage -= 1);
                      },
                      onNext: () {
                        if (_currentPage >= (_totalPages - 1)) return;
                        setState(() => _currentPage += 1);
                      },
                      primaryColor: green,
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: SingleChildScrollView(child: content),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _FormRaffleCard extends StatelessWidget {
  final RaffleModel raffle;
  final int? formId;
  final String formatEndAt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onDownloadQr;
  final VoidCallback onCreateForm;
  final bool isToggling;

  const _FormRaffleCard({
    required this.raffle,
    required this.formId,
    required this.formatEndAt,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onDownloadQr,
    required this.onCreateForm,
    required this.isToggling,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Imagen o placeholder ──────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadius - 1),
                bottomLeft: Radius.circular(AppConstants.borderRadius - 1),
              ),
              child: SizedBox(
                width: 90,
                child: raffle.mediaUrl.isEmpty
                    ? Container(
                        color: green.withValues(alpha: 0.06),
                        child: Center(
                          child: Icon(Icons.assignment_outlined,
                              color: green.withValues(alpha: 0.35), size: 28),
                        ),
                      )
                    : Image.network(
                        raffle.mediaUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: green.withValues(alpha: 0.06),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: green, strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: green.withValues(alpha: 0.06),
                          child: Center(
                            child: Icon(Icons.assignment_outlined,
                                color: green.withValues(alpha: 0.35), size: 28),
                          ),
                        ),
                      ),
              ),
            ),

            // ── Info ──────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Código + estado + switch ──────────────────────────────
                    Row(
                      children: [
                        if (raffle.codigoSorteo.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: green.withValues(alpha: 0.28)),
                            ),
                            child: Text(
                              raffle.codigoSorteo,
                              style: const TextStyle(
                                color: green,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: raffle.activo
                                ? green
                                : Colors.white.withValues(alpha: 0.20),
                            boxShadow: raffle.activo
                                ? [
                                    BoxShadow(
                                      color: green.withValues(alpha: 0.55),
                                      blurRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          raffle.activo ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            color: raffle.activo
                                ? green.withValues(alpha: 0.80)
                                : Colors.white.withValues(alpha: 0.28),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (isToggling)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: green.withValues(alpha: 0.60),
                            ),
                          )
                        else
                          Transform.scale(
                            scale: 0.70,
                            alignment: Alignment.centerRight,
                            child: Switch(
                              value: raffle.activo,
                              onChanged: (_) => onToggleActive(),
                              activeThumbColor: green,
                              activeTrackColor: green.withValues(alpha: 0.25),
                              inactiveThumbColor:
                                  Colors.white.withValues(alpha: 0.30),
                              inactiveTrackColor:
                                  Colors.white.withValues(alpha: 0.08),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    // ── Texto ─────────────────────────────────────────────────
                    Text(
                      raffle.text.isEmpty ? '—' : raffle.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Fecha de cierre ───────────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            formatEndAt,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (formId == null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onCreateForm,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dynamic_form_outlined,
                                  size: 13,
                                  color: Colors.white.withValues(alpha: 0.35)),
                              const SizedBox(width: 6),
                              Text(
                                'Crear formulario',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (formId != null) ...[
                      const SizedBox(height: 8),
                      // ── Link del formulario ───────────────────────────────
                      Builder(builder: (context) {
                        final url =
                            '${ApiConfig.menuUrl}sorteoForm?formId=$formId';
                        return GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Link copiado al portapapeles',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppConstants.primaryGreen,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                  color: green.withValues(alpha: 0.20)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link_rounded,
                                    size: 13,
                                    color: green.withValues(alpha: 0.65)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    url,
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
                                    size: 12,
                                    color: green.withValues(alpha: 0.55)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 10),

                    // ── Acciones ──────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (formId != null) ...[
                          _CardIconButton(
                            icon: Icons.qr_code_2_rounded,
                            color: Colors.white.withValues(alpha: 0.70),
                            onTap: onDownloadQr,
                          ),
                          const SizedBox(width: 6),
                        ],
                        _CardIconButton(
                          icon: Icons.edit_outlined,
                          color: green,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 6),
                        _CardIconButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppConstants.errorRed,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón crear ────────────────────────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CreateButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: green, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: green, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
            color: AppConstants.errorRed.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppConstants.errorRed.withValues(alpha: 0.70), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(
                    color: AppConstants.primaryGreen, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Dialog QR ─────────────────────────────────────────────────────────────────

class _QrDownloadDialog extends StatefulWidget {
  final String url;
  final String code;

  const _QrDownloadDialog({required this.url, required this.code});

  @override
  State<_QrDownloadDialog> createState() => _QrDownloadDialogState();
}

class _QrDownloadDialogState extends State<_QrDownloadDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _downloading = false;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final filename =
          'qr_${widget.code.isNotEmpty ? widget.code : 'sorteo'}.png';
      final savedPath = await saveQrBytes(pngBytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          savedPath != null ? 'QR guardado en: $savedPath' : 'QR descargado',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryGreen,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al descargar: $e',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40)),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded,
                      color: green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'QR del sorteo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.45),
                        size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── QR ───────────────────────────────────────────────────────
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: widget.url,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── URL ──────────────────────────────────────────────────────
              Text(
                widget.url,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: green.withValues(alpha: 0.60), fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 20),

              // ── Botón descargar ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : _download,
                  icon: _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.download_rounded,
                          size: 18, color: Colors.black),
                  label: Text(
                    _downloading ? 'Descargando...' : 'Descargar PNG',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    disabledBackgroundColor:
                        green.withValues(alpha: 0.50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icon button compacto ───────────────────────────────────────────────────────

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
