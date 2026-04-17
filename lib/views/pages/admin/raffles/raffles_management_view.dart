import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RafflesManagementView extends StatefulWidget {
  const RafflesManagementView({super.key});

  @override
  State<RafflesManagementView> createState() => _RafflesManagementViewState();
}

class _RafflesManagementViewState extends State<RafflesManagementView> {
  static const int _pageSize = 5;
  final RaffleService _raffleService = RaffleService();
  final TidsService _tidsService = TidsService();
  Map<int, String> _tidCodesById = const {};

  bool _isLoading = true;
  String? _errorMessage;
  List<RaffleModel> _raffles = const [];
  Map<int, String> _casinoNamesById = const {};
  int _currentPage = 0;
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _loadCasinoNames();
    _loadRaffles();
    _loadTids();
  }

  Future<void> _loadCasinoNames() async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/publicidades/casinos',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(response.body);
      List<dynamic> rawItems = const [];
      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final content = decoded['content'];
        if (data is List) {
          rawItems = data;
        } else if (content is List) {
          rawItems = content;
        }
      }

      final parsed = <int, String>{};
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nombre = map['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;

        final idValue = map['id'];
        final parsedId = idValue is int ? idValue : int.tryParse('$idValue');
        if (parsedId == null) continue;

        parsed[parsedId] = nombre;
      }

      if (!mounted) return;
      setState(() => _casinoNamesById = parsed);
    } catch (_) {
      // fallback: mostramos el id si no se pudo cargar el catálogo
    }
  }

  Future<void> _loadTids() async {
    try {
      final tids = await _tidsService.fetchTids();
      if (!mounted) return;
      setState(() {
        _tidCodesById = {for (final t in tids) t.id: t.tid};
      });
    } catch (_) {
      // fallback silencioso
    }
  }

  Future<void> _loadRaffles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await _raffleService.fetchRaffles();
      if (!mounted) return;
      setState(() {
        _raffles = raw.map(RaffleModel.fromMap).toList(growable: false);
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
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _casinoLabel(int? casinoGralId) {
    if (casinoGralId == null) return 'Boombet';
    return _casinoNamesById[casinoGralId] ?? casinoGralId.toString();
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

    // Update optimista
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
        );
      }).toList(growable: false);
    });

    try {
      await _raffleService.toggleRaffleActive(id);
    } catch (_) {
      // Revertir si falla
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
          );
        }).toList(growable: false);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingIds.remove(id));
    }
  }

  Future<void> _handleDetail(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _RaffleDetailModal(
        raffleId: raffle.id!,
        raffleService: _raffleService,
        casinoLabel: _casinoLabel(raffle.casinoGralId),
      ),
    );
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
              tipo: 'APP',
              raffleId: raffle.id,
              initialText: raffle.text,
              initialCasinoGralId: raffle.casinoGralId,
              initialFechaFin: _parseDateTime(raffle.fechaFin),
              initialMediaUrl: raffle.mediaUrl,
              initialTidId: raffle.tidId,
              initialCantidadGanadores: raffle.cantidadGanadores,
              initialPremios: raffle.premios,
              initialEmailPresentador: raffle.emailPresentador,
              initialInstrucciones: raffle.instrucciones,
              initialActivo: raffle.activo,
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Eliminar sorteo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar este sorteo? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _raffleService.deleteRaffle(raffle.id!);
      await _loadRaffles();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sorteo eliminado correctamente.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppConstants.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el sorteo: $error',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
              tipo: 'APP',
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
              // ── Botón crear ──────────────────────────────────────────────
              _RaffleCreateButton(
                onPressed: _openCreateDialog,
                label: 'Crear sorteo',
                icon: Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 12),

              // ── Contenido ────────────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: green.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: green.withValues(alpha: 0.55),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay sorteos activos para mostrar.',
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
                    child: _RaffleCard(
                      raffle: raffle,
                      casinoLabel: _casinoLabel(raffle.casinoGralId),
                      formatEndAt: _formatEndAt(raffle.fechaFin),
                      tidCode: raffle.tidId != null
                          ? _tidCodesById[raffle.tidId]
                          : null,
                      onTap: () => _handleDetail(raffle),
                      onEdit: () => _handleEdit(raffle),
                      onDelete: () => _handleDelete(raffle),
                      onToggleActive: () => _handleToggleActive(raffle),
                      isToggling: _togglingIds.contains(raffle.id),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
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
    return SingleChildScrollView(child: content);
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _RaffleCard extends StatelessWidget {
  final RaffleModel raffle;
  final String casinoLabel;
  final String formatEndAt;
  final String? tidCode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final bool isToggling;

  const _RaffleCard({
    required this.raffle,
    required this.casinoLabel,
    required this.formatEndAt,
    this.tidCode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
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
            // ── Imagen ────────────────────────────────────────────────────
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
                          child: Icon(
                            Icons.emoji_events_outlined,
                            color: green.withValues(alpha: 0.35),
                            size: 28,
                          ),
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
                                color: green,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: green.withValues(alpha: 0.06),
                          child: Center(
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: green.withValues(alpha: 0.35),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // ── Info ───────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Header: código + estado + switch ─────────────────
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

                    // ── Texto ────────────────────────────────────────────
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

                    // ── Meta: casino · cierre ────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.casino_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text(
                          casinoLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
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

                    if (tidCode != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF29FF5E).withValues(alpha: 0.18),
                              const Color(0xFF29FF5E).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color:
                                const Color(0xFF29FF5E).withValues(alpha: 0.50),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code_rounded,
                              size: 13,
                              color: Color(0xFF29FF5E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TID',
                              style: TextStyle(
                                color: const Color(0xFF29FF5E)
                                    .withValues(alpha: 0.70),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 1,
                              height: 12,
                              color: const Color(0xFF29FF5E)
                                  .withValues(alpha: 0.30),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tidCode!,
                              style: const TextStyle(
                                color: Color(0xFF29FF5E),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // ── Acciones ─────────────────────────────────────────
                    Row(
                      children: [
                        // Ver detalle
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.70)),
                                const SizedBox(width: 5),
                                Text(
                                  'Ver detalle',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Editar (icon)
                        _CardIconButton(
                          icon: Icons.edit_outlined,
                          color: green,
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 6),
                        // Eliminar (icon)
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

// ── Modal de detalle ───────────────────────────────────────────────────────────

class _RaffleDetailModal extends StatefulWidget {
  final int raffleId;
  final RaffleService raffleService;
  final String casinoLabel;

  const _RaffleDetailModal({
    required this.raffleId,
    required this.raffleService,
    required this.casinoLabel,
  });

  @override
  State<_RaffleDetailModal> createState() => _RaffleDetailModalState();
}

class _RaffleDetailModalState extends State<_RaffleDetailModal> {
  bool _loading = true;
  String? _error;
  RaffleModel? _raffle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await widget.raffleService.fetchRaffleById(widget.raffleId);
      if (!mounted) return;
      setState(() {
        _raffle = RaffleModel.fromMap(raw);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el sorteo.';
        _loading = false;
      });
    }
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.emoji_events_outlined, color: green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del sorteo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.45), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // ── Contenido ────────────────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: green, strokeWidth: 2.5)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
              )
            else if (_raffle != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: _RaffleDetailBody(
                    raffle: _raffle!,
                    casinoLabel: widget.casinoLabel,
                    formatDate: _formatDate,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RaffleDetailBody extends StatelessWidget {
  final RaffleModel raffle;
  final String casinoLabel;
  final String Function(String) formatDate;

  const _RaffleDetailBody({
    required this.raffle,
    required this.casinoLabel,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Imagen banner ───────────────────────────────────────────
        if (raffle.mediaUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                raffle.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: green.withValues(alpha: 0.06),
                  child: Center(
                    child: Icon(Icons.emoji_events_outlined, color: green.withValues(alpha: 0.35), size: 32),
                  ),
                ),
              ),
            ),
          ),
        if (raffle.mediaUrl.isNotEmpty) const SizedBox(height: 14),

        // ── Código + estado ─────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: green.withValues(alpha: 0.25)),
              ),
              child: Text(
                raffle.codigoSorteo.isEmpty ? '-' : raffle.codigoSorteo,
                style: const TextStyle(
                  color: green,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: raffle.activo
                    ? green.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: raffle.activo ? green : Colors.white.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    raffle.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: raffle.activo ? green : Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Descripción ─────────────────────────────────────────────
        if (raffle.text.isNotEmpty) ...[
          Text(
            raffle.text,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.45),
          ),
          const SizedBox(height: 14),
        ],

        // ── Info chips ──────────────────────────────────────────────
        _DetailRow(icon: Icons.casino_outlined, label: 'Casino', value: casinoLabel),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: 'Cierre',
          value: formatDate(raffle.fechaFin),
        ),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.emoji_events_outlined,
          label: 'Ganadores',
          value: raffle.cantidadGanadores.toString(),
        ),
        if (raffle.emailPresentador != null && raffle.emailPresentador!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Presentador',
            value: raffle.emailPresentador!,
          ),
        ],
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Creado',
          value: formatDate(raffle.createdAt),
        ),

        // ── Premios ─────────────────────────────────────────────────
        if (raffle.premios.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Premios',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...raffle.premios.map(
            (premio) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: premio.imgUrl.isEmpty
                          ? Container(
                              color: green.withValues(alpha: 0.06),
                              child: Icon(Icons.star_outline_rounded, color: green.withValues(alpha: 0.40), size: 20),
                            )
                          : Image.network(
                              premio.imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                color: green.withValues(alpha: 0.06),
                                child: Icon(Icons.star_outline_rounded, color: green.withValues(alpha: 0.40), size: 20),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      premio.nombre,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '#${premio.orden}',
                    style: TextStyle(color: green.withValues(alpha: 0.60), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppConstants.primaryGreen.withValues(alpha: 0.55)),
        const SizedBox(width: 7),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ── Icon button compacto para acciones de card ────────────────────────────────

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

// ── Estado de error ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppConstants.errorRed.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppConstants.errorRed,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.errorRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.errorRed.withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppConstants.errorRed,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reintentar',
                      style: TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón crear ────────────────────────────────────────────────────────────────

class _RaffleCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _RaffleCreateButton({
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

