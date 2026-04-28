import 'dart:convert';
import 'dart:developer';
import 'dart:math' show max;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/formularios_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:intl/intl.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:boombet_app/services/eventos_service.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/services/sub_afiliados_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/create_tid.dart';
import 'package:boombet_app/views/pages/affiliates/events/create_event.dart';
import 'package:boombet_app/views/pages/affiliates/events/event_management_view.dart';
import 'package:boombet_app/views/pages/affiliates/stands/create_stand.dart';
import 'package:boombet_app/views/pages/affiliates/stands/stand_management_view.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/affiliates/forms/create_form.dart';
import 'package:boombet_app/views/pages/affiliates/forms/form_management_view.dart';
import 'package:boombet_app/views/pages/affiliates/sub-affiliates/create_subaffiliate.dart';
import 'package:boombet_app/views/pages/affiliates/sub-affiliates/subaffiliates_management_view.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/tids_management_view.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:boombet_app/core/utils/qr_saver.dart';

class AffiliatesToolsPage extends StatefulWidget {
  const AffiliatesToolsPage({super.key});

  @override
  State<AffiliatesToolsPage> createState() => _AffiliatesToolsPageState();
}

class _AffiliatesToolsPageState extends State<AffiliatesToolsPage> {
  late final Future<String?> _roleFuture = TokenService.getUserRole();

  @override
  Widget build(BuildContext context) {
    final textColor = AppConstants.textDark;
    final bgColor = AppConstants.darkBg;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              'Para volver atrás tenés que cerrar sesión. ¿Querés hacerlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (shouldLogout == true && context.mounted) {
          await AuthService().logout();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: FutureBuilder<String?>(
        future: _roleFuture,
        builder: (context, snapshot) {
        final role = snapshot.data?.trim().toUpperCase();
        final isAffiliator = role == 'AFILIADOR';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAffiliator) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.errorRed.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.errorRed.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.gpp_bad_outlined,
                        color: AppConstants.errorRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso restringido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solo afiliadores pueden acceder a esta sección.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  children: [
                    _AffiliatorPrimaryActionButton(
                      title: 'TIDs (Tracking IDs)',
                      subtitle: 'Administrar y consultar tracking IDs',
                      icon: Icons.track_changes_outlined,
                      onTap: () => context.push('/affiliates-tools/tids'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Eventos',
                      subtitle: 'Gestionar eventos y estadísticas',
                      icon: Icons.event_note_outlined,
                      onTap: () => context.push('/affiliates-tools/eventos'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Stands / Puestos',
                      subtitle: 'Configurar y administrar puestos',
                      icon: Icons.storefront_outlined,
                      onTap: () => context.push('/affiliates-tools/stands'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Sub-afiliadores',
                      subtitle: 'Gestionar tu red de sub-afiliadores',
                      icon: Icons.group_outlined,
                      onTap: () =>
                          context.push('/affiliates-tools/sub-afiliadores'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Sorteos',
                      subtitle: 'Gestión de sorteos y premios',
                      icon: Icons.emoji_events_outlined,
                      onTap: () => context.push('/affiliates-tools/sorteos'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Formularios',
                      subtitle: 'Crear y gestionar formularios',
                      icon: Icons.dynamic_form_outlined,
                      onTap: () => context.push('/affiliates-tools/formularios'),
                    ),
                    const SizedBox(height: 24),
                    _LogoutButton(context: context),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

// ── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final BuildContext context;
  const _LogoutButton({required this.context});

  Future<void> _logout(BuildContext ctx) async {
    final shouldLogout = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && ctx.mounted) {
      await AuthService().logout();
      if (ctx.mounted) {
        ctx.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext outerContext) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _logout(outerContext),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Cerrar sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.errorRed,
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.40),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    );
  }
}

class TidsPage extends StatefulWidget {
  const TidsPage({super.key});

  @override
  State<TidsPage> createState() => _TidsPageState();
}

class _TidsPageState extends State<TidsPage> {
  static const int _pageSize = 10;

  final TidsService _tidsService = TidsService();
  final EventosService _eventosService = EventosService();
  final StandsService _standsService = StandsService();
  final FormulariosService _formulariosService = FormulariosService();
  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
  List<EventoOption> _eventoOptions = kDefaultEventoOptions;
  List<StandOption> _standOptions = kDefaultStandOptions;
  List<StandModel> _stands = [];
  Map<int, int> _tidFormIdMap = const {};
  final Set<int> _editingIds = {};
  final Set<int> _deletingIds = {};
  int _currentPage = 1;

  int get _totalPages => max(1, (_tids.length / _pageSize).ceil());
  List<TidModel> get _pagedTids {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _tids.length);
    return _tids.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadTids();
    _loadEventoOptions();
    _loadStandOptions();
    _loadTidFormularios();
  }

  Future<void> _loadTidFormularios() async {
    try {
      final forms = await _formulariosService.fetchFormularios();
      if (!mounted) return;
      setState(() {
        _tidFormIdMap = {
          for (final f in forms)
            if (f.tidId != null) f.tidId!: f.id,
        };
      });
    } catch (_) {}
  }

  Future<void> _handleCreateFormForTid(int tidId) async {
    await showCreateFormDialog(
      context: context,
      preTidId: tidId,
      onCreated: (created) {
        setState(() {
          _tidFormIdMap = {..._tidFormIdMap, tidId: created.id};
        });
      },
    );
  }

  Future<void> _loadEventoOptions() async {
    try {
      final eventos = await _eventosService.fetchEventos();
      if (!mounted) return;
      setState(() {
        _eventoOptions = [
          const EventoOption(id: null, label: 'Sin evento'),
          ...eventos.map(
            (e) => EventoOption(
              id: e.id,
              label: e.nombre.isNotEmpty ? e.nombre : 'Evento #${e.id}',
            ),
          ),
        ];
      });
    } catch (_) {
      // Si falla, el dropdown queda con "Sin evento" como fallback
    }
  }

  Future<void> _loadStandOptions() async {
    try {
      final stands = await _standsService.fetchStands();
      if (!mounted) return;
      setState(() {
        _stands = stands;
        _standOptions = [
          const StandOption(id: null, label: 'Sin stand'),
          ...stands.map(
            (s) => StandOption(
              id: s.id,
              label: s.nombre.isNotEmpty ? s.nombre : 'Stand #${s.id}',
            ),
          ),
        ];
      });
    } catch (_) {
      // Si falla, el dropdown queda con "Sin stand" como fallback
    }
  }

  Future<void> _loadTids({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _tids.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tids = await _tidsService.fetchTids();
      if (!mounted) return;
      setState(() {
        _tids = tids;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[TidsPage] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los TIDs: $e';
        _isLoading = false;
      });
    }
  }

  void _replaceTidInList(TidModel updated) {
    _tids = _tids.map((t) => t.id == updated.id ? updated : t).toList();
  }

  Future<void> _edit(TidModel tid) async {
    if (_editingIds.contains(tid.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;
    const textColor = Colors.white;

    final tidController = TextEditingController(text: tid.tid);
    // Tratar idEvento == 0 como "sin evento"
    int? selectedEventoId = tid.idEvento == 0 ? null : tid.idEvento;
    int? selectedStandId = tid.idStand;

    final result = await showDialog<(String, int?, int?)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: green.withValues(alpha: 0.22)),
          ),
          title: const Text(
            'Editar TID',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tidController,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'TID',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EventoDropdown(
                options: _eventoOptions,
                selectedId: selectedEventoId,
                accent: green,
                textColor: textColor,
                bgColor: dialogBg,
                onChanged: (v) => setDialogState(() => selectedEventoId = v),
              ),
              const SizedBox(height: 16),
              StandDropdown(
                options: _standOptions,
                selectedId: selectedStandId,
                accent: green,
                textColor: textColor,
                bgColor: dialogBg,
                onChanged: (v) => setDialogState(() => selectedStandId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: green),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, (
                tidController.text.trim(),
                selectedEventoId,
                selectedStandId,
              )),
              child: const Text(
                'Guardar',
                style: TextStyle(color: green),
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), tidController.dispose);

    if (result == null) return;

    final newTid = result.$1;
    final newIdEvento = result.$2;
    final newIdStand = result.$3;

    if (newTid.isEmpty) return;

    setState(() => _editingIds.add(tid.id));

    try {
      final updated = await _tidsService.updateTid(
        id: tid.id,
        tid: newTid,
        idEvento: newIdEvento,
        idStand: newIdStand,
        sendIdStand: true,
      );
      if (!mounted) return;
      setState(() {
        _replaceTidInList(updated);
        _editingIds.remove(tid.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _editingIds.remove(tid.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el TID.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _delete(TidModel tid) async {
    if (_deletingIds.contains(tid.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar TID',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar el TID "${tid.tid}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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
        if (_currentPage > 1 &&
            (_currentPage - 1) * _pageSize >= _tids.length) {
          _currentPage--;
        }
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──────────────────────────────────────────
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
                          bottom: BorderSide(
                            color: green.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: green.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.track_changes_outlined,
                              color: green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tid.tid,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tracking ID',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.38),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Contenido ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: totalJugadores != null
                          ? Column(
                              children: [
                                Text(
                                  'Total de afiliaciones',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: green.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$totalJugadores',
                                        style: const TextStyle(
                                          color: green,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        totalJugadores == 1
                                            ? 'jugador afiliado'
                                            : 'jugadores afiliados',
                                        style: TextStyle(
                                          color: green.withValues(alpha: 0.60),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : fetchError != null
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppConstants.errorRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fetchError!,
                                    style: const TextStyle(
                                      color: AppConstants.errorRed,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(
                              height: 56,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: green,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                    ),

                    // ── Acción ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: green.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: green.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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

  void _showTidQr(TidModel tid) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    // Key fuera del builder para que sobreviva los rebuilds del StatefulBuilder
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
            // ── Carga inicial ────────────────────────────────────────────
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
                    log('[TidsPage] fetchTidById error: $e');
                    setDialogState(() {
                      fetchError = 'No se pudo obtener el TID.';
                      isFetching = false;
                    });
                  });
            }

            // ── Descarga ─────────────────────────────────────────────────
            Future<void> handleDownload() async {
              if (isDownloading) return;
              setDialogState(() => isDownloading = true);
              try {
                final boundary = qrRepaintKey.currentContext
                    ?.findRenderObject() as RenderRepaintBoundary?;
                if (boundary == null) throw Exception('No se pudo capturar el QR');

                final image = await boundary.toImage(pixelRatio: 3.0);
                final byteData = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (byteData == null) throw Exception('Error al generar imagen');

                final bytes = byteData.buffer.asUint8List();
                final safeName = tid.tid
                    .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
                final filename = 'tid_${safeName}_qr.png';

                final savedPath = await saveQrImage(bytes, filename);

                if (ctx.mounted) {
                  final msg = savedPath != null
                      ? 'QR guardado en Descargas'
                      : 'QR descargado correctamente';
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: green,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                log('[TidsPage] QR download error: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error al descargar: $e'),
                      backgroundColor: AppConstants.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
                  // ── QR card ──────────────────────────────────────────────
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
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: green.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.qr_code_rounded,
                                color: green,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tid.tid.isNotEmpty ? tid.tid : 'QR del TID',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── QR / loading / error ─────────────────────────
                        if (qrData != null)
                          RepaintBoundary(
                            key: qrRepaintKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: QrImageView(
                                data: qrData!,
                                version: QrVersions.auto,
                                size: 220,
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
                          )
                        else if (fetchError != null)
                          SizedBox(
                            height: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppConstants.errorRed,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  fetchError!,
                                  style: const TextStyle(
                                    color: AppConstants.errorRed,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: green,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ── Botón descargar (solo con QR listo) ──────────
                        if (qrData != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isDownloading ? null : handleDownload,
                              icon: isDownloading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.download_rounded,
                                      size: 16,
                                    ),
                              label: Text(
                                isDownloading
                                    ? 'Descargando...'
                                    : 'Descargar QR',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: green,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor:
                                    green.withValues(alpha: 0.45),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // ── Botón cerrar ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              backgroundColor:
                                  green.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: green.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(
                                color: green,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tocá en cualquier lugar para cerrar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          TidsManagementView(
            onCreate: () => showCreateTidDialog(
              context: context,
              tidsService: _tidsService,
              eventoOptions: _eventoOptions,
              standOptions: _standOptions,
              onCreated: () => _loadTids(force: true),
            ),
            items: _pagedTids,
            totalItems: _tids.length,
            isLoading: _isLoading,
            errorMessage: _error,
            editingIds: _editingIds,
            deletingIds: _deletingIds,
            onRetry: () => _loadTids(force: true),
            onEdit: _edit,
            onDelete: _delete,
            onViewAffiliations: _showTidAffiliationsCount,
            onShowQr: _showTidQr,
            onCreateForm: _handleCreateFormForTid,
            tidFormIdMap: _tidFormIdMap,
            eventoNames: {
              for (final opt in _eventoOptions)
                if (opt.id != null) opt.id!: opt.label,
            },
            standNames: {for (final s in _stands) s.id: s.nombre},
          ),
          if (!_isLoading && _error == null && _totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Center(
                child: PaginationBar(
                  currentPage: _currentPage,
                  canGoPrevious: _currentPage > 1,
                  canGoNext: _currentPage < _totalPages,
                  onPrev: () => setState(() => _currentPage--),
                  onNext: () => setState(() => _currentPage++),
                  primaryColor: Theme.of(context).colorScheme.primary,
                  textColor: AppConstants.textDark,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  static const int _pageSize = 10;

  final EventosService _eventosService = EventosService();
  bool _isLoading = false;
  String? _error;
  List<EventoModel> _eventos = [];
  final Set<int> _updatingIds = {};
  final Set<int> _deletingIds = {};
  int _currentPage = 1;

  int get _totalPages => max(1, (_eventos.length / _pageSize).ceil());
  List<EventoModel> get _pagedEventos {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _eventos.length);
    return _eventos.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadEventos();
  }

  Future<void> _loadEventos({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _eventos.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final eventos = await _eventosService.fetchEventos();
      if (!mounted) return;
      setState(() {
        _eventos = eventos;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      log('[EventosPage] load error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar eventos: $e';
        _isLoading = false;
      });
    }
  }

  void _handleGoToPage(int targetPage) {
    if (targetPage < 1 || targetPage > _totalPages) return;
    setState(() => _currentPage = targetPage);
  }

  void _replaceEventoInList(EventoModel updated) {
    _eventos = _eventos.map((e) => e.id == updated.id ? updated : e).toList();
  }

  Future<void> _toggleActive(EventoModel evento, bool isActive) async {
    if (_updatingIds.contains(evento.id)) return;

    setState(() {
      _updatingIds.add(evento.id);
      _replaceEventoInList(
        EventoModel(
          id: evento.id,
          nombre: evento.nombre,
          activo: isActive,
          fechaFin: evento.fechaFin,
          idAfiliador: evento.idAfiliador,
        ),
      );
    });

    try {
      final updated = await _eventosService.toggleEventoActivo(id: evento.id);
      if (!mounted) return;
      setState(() {
        _replaceEventoInList(updated);
        _updatingIds.remove(evento.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replaceEventoInList(evento);
        _updatingIds.remove(evento.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado del evento.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _delete(EventoModel evento) async {
    if (_deletingIds.contains(evento.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar "${evento.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: green)),
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

    setState(() => _deletingIds.add(evento.id));

    try {
      await _eventosService.deleteEvento(id: evento.id);
      if (!mounted) return;

      setState(() {
        _eventos = _eventos.where((e) => e.id != evento.id).toList();
        _deletingIds.remove(evento.id);
        if (_currentPage > 1 &&
            (_currentPage - 1) * _pageSize >= _eventos.length) {
          _currentPage--;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(evento.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el evento.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAffiliationsCount(EventoModel evento) {
    context.push('/affiliates-tools/eventos/${evento.id}', extra: evento);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          EventManagementView(
            onCreate: () => showCreateEventoDialog(
              context: context,
              eventosService: _eventosService,
              onCreated: () => _loadEventos(force: true),
            ),
            items: _pagedEventos,
            totalItems: _eventos.length,
            isLoading: _isLoading,
            errorMessage: _error,
            page: _currentPage - 1,
            totalPages: _totalPages,
            pageSize: _pageSize,
            isFirstPage: _currentPage == 1,
            isLastPage: _currentPage == _totalPages,
            updatingIds: _updatingIds,
            deletingIds: _deletingIds,
            onRetry: () => _loadEventos(force: true),
            onGoToPage: _handleGoToPage,
            onToggleActive: _toggleActive,
            onDelete: _delete,
            onViewAffiliations: _showAffiliationsCount,
          ),
          if (!_isLoading && _error == null && _totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Center(
                child: PaginationBar(
                  currentPage: _currentPage,
                  canGoPrevious: _currentPage > 1,
                  canGoNext: _currentPage < _totalPages,
                  onPrev: () => _handleGoToPage(_currentPage - 1),
                  onNext: () => _handleGoToPage(_currentPage + 1),
                  primaryColor: theme.colorScheme.primary,
                  textColor: AppConstants.textDark,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class StandsPage extends StatefulWidget {
  const StandsPage({super.key});

  @override
  State<StandsPage> createState() => _StandsPageState();
}

class _StandsPageState extends State<StandsPage> {
  static const int _pageSize = 10;

  final StandsService _standsService = StandsService();

  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  List<StandModel> _stands = [];

  final Set<int> _editingIds = {};
  final Set<int> _deletingIds = {};
  final Set<int> _togglingIds = {};

  int get _totalPages => max(1, (_stands.length / _pageSize).ceil());

  List<StandModel> get _pagedStands {
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, _stands.length);
    return _stands.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _loadStands();
  }

  Future<void> _loadStands({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _stands.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stands = await _standsService.fetchStands();
      if (!mounted) return;
      setState(() {
        _stands = stands;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[StandsPage] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los puestos: $e';
        _isLoading = false;
      });
    }
  }

  void _handleGoToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
  }

  void _replaceStandInList(StandModel updated) {
    _stands = _stands.map((s) => s.id == updated.id ? updated : s).toList();
  }

  Future<void> _createStand() async {
    await showCreateStandDialog(
      context: context,
      standsService: _standsService,
      onCreated: (result) {
        if (!mounted) return;
        setState(() {
          _stands = [..._stands, result.stand];
          _currentPage = _totalPages;
        });
        _showStandCredentialsDialog(result);
      },
    );
  }

  Future<void> _editStand(StandModel stand) async {
    if (_editingIds.contains(stand.id)) return;

    final nombre = await _showStandRenameDialog(initialNombre: stand.nombre);
    if (nombre == null || !mounted) return;

    setState(() => _editingIds.add(stand.id));

    try {
      final updated = await _standsService.updateStand(
        id: stand.id,
        nombre: nombre,
      );
      if (!mounted) return;
      setState(() {
        _replaceStandInList(updated);
        _editingIds.remove(stand.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _editingIds.remove(stand.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el puesto.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleActive(StandModel stand, bool value) async {
    if (_togglingIds.contains(stand.id)) return;

    setState(() {
      _togglingIds.add(stand.id);
      _replaceStandInList(stand.copyWith(activo: value));
    });

    try {
      final updated = await _standsService.toggleStandActivo(
        id: stand.id,
        activo: value,
      );
      if (!mounted) return;
      setState(() {
        _replaceStandInList(updated);
        _togglingIds.remove(stand.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replaceStandInList(stand);
        _togglingIds.remove(stand.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cambiar el estado del puesto.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteStand(StandModel stand) async {
    if (_deletingIds.contains(stand.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar puesto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar "${stand.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: green)),
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

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(stand.id));

    try {
      await _standsService.deleteStand(id: stand.id);
      if (!mounted) return;
      setState(() {
        _stands = _stands.where((s) => s.id != stand.id).toList();
        _deletingIds.remove(stand.id);
        if (_currentPage > 1 &&
            (_currentPage - 1) * _pageSize >= _stands.length) {
          _currentPage--;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(stand.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el puesto.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStandCredentialsDialog(StandCreationResult result) {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: green.withValues(alpha: 0.22)),
        ),
        title: const Row(
          children: [
            Icon(Icons.key_outlined, color: green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Credenciales del operador',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: AppConstants.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: AppConstants.errorRed,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guardá estas credenciales ahora. No se volverán a mostrar.',
                      style: TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CredentialRow(
              label: 'Puesto',
              value: result.stand.nombre,
              textColor: Colors.white,
            ),
            const SizedBox(height: 10),
            _CredentialRow(
              label: 'Usuario',
              value: result.username,
              textColor: Colors.white,
            ),
            const SizedBox(height: 10),
            _CredentialRow(
              label: 'Contraseña',
              value: result.password,
              textColor: Colors.white,
              obscure: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido',
              style: TextStyle(color: green),
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo solo para renombrar un puesto existente
  Future<String?> _showStandRenameDialog({
    required String initialNombre,
  }) async {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final nombreController = TextEditingController(text: initialNombre);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: green.withValues(alpha: 0.22)),
        ),
        title: const Text(
          'Editar puesto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nombreController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: green)),
          ),
          TextButton(
            onPressed: () {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) return;
              Navigator.pop(ctx, nombre);
            },
            child: const Text('Guardar', style: TextStyle(color: green)),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), nombreController.dispose);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          StandManagementView(
            onCreate: _createStand,
            items: _pagedStands,
            totalItems: _stands.length,
            isLoading: _isLoading,
            errorMessage: _error,
            editingIds: _editingIds,
            deletingIds: _deletingIds,
            togglingIds: _togglingIds,
            onRetry: () => _loadStands(force: true),
            onEdit: _editStand,
            onDelete: _deleteStand,
            onToggleActive: _toggleActive,
          ),
          if (!_isLoading && _error == null && _totalPages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Center(
                child: PaginationBar(
                  currentPage: _currentPage,
                  canGoPrevious: _currentPage > 1,
                  canGoNext: _currentPage < _totalPages,
                  onPrev: () => _handleGoToPage(_currentPage - 1),
                  onNext: () => _handleGoToPage(_currentPage + 1),
                  primaryColor: theme.colorScheme.primary,
                  textColor: AppConstants.textDark,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}

class _AffiliatorPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AffiliatorPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: green.withValues(alpha: 0.20)),
                ),
                child: Icon(icon, color: green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: green.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SorteosPage — listado unificado APP / FORM con selector
// ─────────────────────────────────────────────────────────────────────────────

class SorteosPage extends StatefulWidget {
  const SorteosPage({super.key});

  @override
  State<SorteosPage> createState() => _SorteosPageState();
}

class _SorteosPageState extends State<SorteosPage> {
  static const int _pageSize = 5;

  final _raffleService = RaffleService();
  final _tidsService = TidsService();
  final _formulariosService = FormulariosService();

  bool _isLoading = true;
  String? _errorMessage;
  List<RaffleModel> _allRaffles = const [];
  Map<int, String> _casinoNamesById = const {};
  Map<int, String> _tidCodesById = const {};
  Map<int, int> _sorteoFormIdMap = const {};
  int _currentPage = 0;
  final Set<int> _togglingIds = {};
  String _tipo = 'APP';

  @override
  void initState() {
    super.initState();
    _loadRaffles();
    _loadCasinoNames();
    _loadTidCodes();
    _loadFormularios();
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
        _allRaffles = raw.map(RaffleModel.fromMap).toList(growable: false);
        _currentPage = 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar los sorteos.';
      });
    }
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
        if (data is List) rawItems = data;
        else if (content is List) rawItems = content;
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
    } catch (_) {}
  }

  Future<void> _loadTidCodes() async {
    try {
      final tids = await _tidsService.fetchTids();
      if (!mounted) return;
      setState(() {
        _tidCodesById = {for (final t in tids) t.id: t.tid};
      });
    } catch (_) {}
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

  String _casinoLabel(int? id) =>
      id == null ? 'Boombet' : (_casinoNamesById[id] ?? id.toString());

  String _formatDate(String raw) {
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

  List<RaffleModel> get _filteredRaffles =>
      _allRaffles.where((r) => r.tipo == _tipo).toList(growable: false);

  int get _totalPages {
    final f = _filteredRaffles;
    return f.isEmpty ? 0 : (f.length / _pageSize).ceil();
  }

  List<RaffleModel> get _currentRaffles {
    final f = _filteredRaffles;
    if (f.isEmpty) return const [];
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, f.length);
    return f.sublist(start, end);
  }

  void _switchTipo(String tipo) {
    if (_tipo == tipo) return;
    setState(() {
      _tipo = tipo;
      _currentPage = 0;
    });
  }

  RaffleModel _withToggledActivo(RaffleModel r) => RaffleModel(
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
        instrucciones: r.instrucciones,
      );

  Future<void> _handleToggleActive(RaffleModel raffle) async {
    final id = raffle.id;
    if (id == null || _togglingIds.contains(id)) return;
    setState(() {
      _togglingIds.add(id);
      _allRaffles = _allRaffles
          .map((r) => r.id == id ? _withToggledActivo(r) : r)
          .toList(growable: false);
    });
    try {
      await _raffleService.toggleRaffleActive(id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allRaffles = _allRaffles
            .map((r) => r.id == id ? _withToggledActivo(r) : r)
            .toList(growable: false);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('No se pudo cambiar el estado del sorteo.',
            style: TextStyle(color: Colors.white)),
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
      builder: (ctx) => Dialog(
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
              initialInstrucciones: raffle.instrucciones,
              initialActivo: raffle.activo,
              onCreated: () {
                Navigator.of(ctx).pop();
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
    const green = AppConstants.primaryGreen;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text('Eliminar sorteo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
            '¿Querés eliminar este sorteo? Esta acción no se puede deshacer.',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: green))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppConstants.errorRed))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _raffleService.deleteRaffle(raffle.id!);
      await _loadRaffles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Sorteo eliminado correctamente.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppConstants.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo eliminar el sorteo: $error',
            style: const TextStyle(color: Colors.white)),
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

  Future<void> _handleDetailApp(RaffleModel raffle) async {
    if (raffle.id == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SorteosDetailModal(
        raffleId: raffle.id!,
        raffleService: _raffleService,
        casinoLabel: _casinoLabel(raffle.casinoGralId),
      ),
    );
  }

  Future<void> _handleDownloadQrForm(RaffleModel raffle) async {
    if (raffle.id == null) return;
    final formId = _sorteoFormIdMap[raffle.id];
    if (formId == null) return;
    final url = '${ApiConfig.menuUrl}sorteoForm?formId=$formId';
    await showDialog<void>(
      context: context,
      builder: (_) => _SorteosQrDialog(url: url, code: raffle.codigoSorteo),
    );
  }

  Future<void> _handleCreateFormForSorteo(RaffleModel raffle) async {
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

  Future<void> _openCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
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
              tipo: _tipo,
              onCreated: () {
                Navigator.of(ctx).pop();
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
    final filtered = _filteredRaffles;
    final current = _currentRaffles;

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Selector APP / FORM ───────────────────────────────────
                _TipoSelector(selected: _tipo, onSelect: _switchTipo),

                const SizedBox(height: 12),

                // ── Botón crear ───────────────────────────────────────────
                _SorteosCreateButton(
                  label: _tipo == 'APP'
                      ? 'Crear sorteo'
                      : 'Crear sorteo por formulario',
                  icon: _tipo == 'APP'
                      ? Icons.emoji_events_outlined
                      : Icons.assignment_outlined,
                  onPressed: _openCreateDialog,
                ),

                const SizedBox(height: 12),

                // ── Contenido ─────────────────────────────────────────────
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: green, strokeWidth: 2.5)),
                  )
                else if (_errorMessage != null)
                  _SorteosErrorState(
                      message: _errorMessage!, onRetry: _loadRaffles)
                else if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      border:
                          Border.all(color: green.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tipo == 'APP'
                              ? Icons.emoji_events_outlined
                              : Icons.assignment_outlined,
                          color: green.withValues(alpha: 0.55),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tipo == 'APP'
                                ? 'No hay sorteos de la app para mostrar.'
                                : 'No hay sorteos por formulario para mostrar.',
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
                  ...current.map(
                    (raffle) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _tipo == 'APP'
                          ? _AppRaffleCard(
                              raffle: raffle,
                              casinoLabel: _casinoLabel(raffle.casinoGralId),
                              formatEndAt: _formatDate(raffle.fechaFin),
                              tidCode: raffle.tidId != null
                                  ? _tidCodesById[raffle.tidId]
                                  : null,
                              onTap: () => _handleDetailApp(raffle),
                              onEdit: () => _handleEdit(raffle),
                              onDelete: () => _handleDelete(raffle),
                              onToggleActive: () =>
                                  _handleToggleActive(raffle),
                              isToggling: _togglingIds.contains(raffle.id),
                            )
                          : _SorteosFormCard(
                              raffle: raffle,
                              formId: _sorteoFormIdMap[raffle.id],
                              formatEndAt: _formatDate(raffle.fechaFin),
                              onEdit: () => _handleEdit(raffle),
                              onDelete: () => _handleDelete(raffle),
                              onToggleActive: () =>
                                  _handleToggleActive(raffle),
                              onDownloadQr: () =>
                                  _handleDownloadQrForm(raffle),
                              onCreateForm: () =>
                                  _handleCreateFormForSorteo(raffle),
                              isToggling: _togglingIds.contains(raffle.id),
                            ),
                    ),
                  ),
                  if (_totalPages > 1) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                            color: green.withValues(alpha: 0.12)),
                      ),
                      child: Center(
                        child: PaginationBar(
                          currentPage: _currentPage + 1,
                          canGoPrevious: _currentPage > 0,
                          canGoNext: _currentPage < (_totalPages - 1),
                          onPrev: () {
                            if (_currentPage > 0)
                              setState(() => _currentPage--);
                          },
                          onNext: () {
                            if (_currentPage < _totalPages - 1)
                              setState(() => _currentPage++);
                          },
                          primaryColor: green,
                          textColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatefulWidget {
  final String label;
  final String value;
  final Color textColor;
  final bool obscure;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.textColor,
    this.obscure = false,
  });

  @override
  State<_CredentialRow> createState() => _CredentialRowState();
}

class _CredentialRowState extends State<_CredentialRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.obscure && !_revealed
        ? '•' * widget.value.length.clamp(6, 20)
        : widget.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (widget.obscure)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppConstants.primaryGreen,
              ),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Copiar',
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: AppConstants.primaryGreen,
            ),
            onPressed: () {
              // ignore: deprecated_member_use
              Clipboard.setData(ClipboardData(text: widget.value));
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sorteos — clases auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _TipoSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _TipoSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    Widget chip(String label, String value, IconData icon) {
      final isSelected = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? green.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isSelected
                    ? green.withValues(alpha: 0.40)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected
                        ? green
                        : Colors.white.withValues(alpha: 0.40)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? green
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          chip('App', 'APP', Icons.emoji_events_outlined),
          chip('Formulario', 'FORM', Icons.assignment_outlined),
        ],
      ),
    );
  }
}

class _SorteosCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SorteosCreateButton({
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

class _SorteosErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SorteosErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border:
            Border.all(color: AppConstants.errorRed.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppConstants.errorRed.withValues(alpha: 0.70), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style:
                    TextStyle(color: AppConstants.primaryGreen, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SorteosCardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SorteosCardIconButton({
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

// ── Card tipo APP ──────────────────────────────────────────────────────────────

class _AppRaffleCard extends StatelessWidget {
  final RaffleModel raffle;
  final String casinoLabel;
  final String formatEndAt;
  final String? tidCode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final bool isToggling;

  const _AppRaffleCard({
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
                          child: Icon(Icons.emoji_events_outlined,
                              color: green.withValues(alpha: 0.35), size: 28),
                        ),
                      )
                    : Image.network(
                        raffle.mediaUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: green.withValues(alpha: 0.06),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: green, strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: green.withValues(alpha: 0.06),
                          child: Center(
                            child: Icon(Icons.emoji_events_outlined,
                                color: green.withValues(alpha: 0.35), size: 28),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                                        blurRadius: 5)
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
                                color: green.withValues(alpha: 0.60)),
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
                    Text(
                      raffle.text.isEmpty ? '—' : raffle.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.casino_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Text(casinoLabel,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11)),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 7),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.18)),
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
                                fontSize: 11),
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
                          gradient: LinearGradient(colors: [
                            const Color(0xFF29FF5E).withValues(alpha: 0.18),
                            const Color(0xFF29FF5E).withValues(alpha: 0.08),
                          ]),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: const Color(0xFF29FF5E)
                                  .withValues(alpha: 0.50),
                              width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_rounded,
                                size: 13, color: Color(0xFF29FF5E)),
                            const SizedBox(width: 6),
                            Text('TID',
                                style: TextStyle(
                                    color: const Color(0xFF29FF5E)
                                        .withValues(alpha: 0.70),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8)),
                            const SizedBox(width: 5),
                            Container(
                                width: 1,
                                height: 12,
                                color: const Color(0xFF29FF5E)
                                    .withValues(alpha: 0.30)),
                            const SizedBox(width: 5),
                            Text(tidCode!,
                                style: const TextStyle(
                                    color: Color(0xFF29FF5E),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.14)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 13,
                                    color:
                                        Colors.white.withValues(alpha: 0.70)),
                                const SizedBox(width: 5),
                                Text('Ver detalle',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.70),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _SorteosCardIconButton(
                            icon: Icons.edit_outlined,
                            color: green,
                            onTap: onEdit),
                        const SizedBox(width: 6),
                        _SorteosCardIconButton(
                            icon: Icons.delete_outline_rounded,
                            color: AppConstants.errorRed,
                            onTap: onDelete),
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

// ── Card tipo FORM ─────────────────────────────────────────────────────────────

class _SorteosFormCard extends StatelessWidget {
  final RaffleModel raffle;
  final int? formId;
  final String formatEndAt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onDownloadQr;
  final VoidCallback onCreateForm;
  final bool isToggling;

  const _SorteosFormCard({
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
    final url = formId != null
        ? '${ApiConfig.menuUrl}sorteoForm?formId=$formId'
        : '';

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
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: green.withValues(alpha: 0.06),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: green, strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: green.withValues(alpha: 0.06),
                          child: Center(
                            child: Icon(Icons.assignment_outlined,
                                color: green.withValues(alpha: 0.35), size: 28),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                                        blurRadius: 5)
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
                                color: green.withValues(alpha: 0.60)),
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
                    Text(
                      raffle.text.isEmpty ? '—' : raffle.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.35),
                    ),
                    const SizedBox(height: 8),
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
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (url.isEmpty) ...[
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
                    if (url.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Link copiado al portapapeles',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: AppConstants.primaryGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ));
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
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.copy_rounded,
                                  size: 12,
                                  color: green.withValues(alpha: 0.55)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (formId != null) ...[
                          _SorteosCardIconButton(
                              icon: Icons.qr_code_2_rounded,
                              color: Colors.white.withValues(alpha: 0.70),
                              onTap: onDownloadQr),
                          const SizedBox(width: 6),
                        ],
                        _SorteosCardIconButton(
                            icon: Icons.edit_outlined,
                            color: green,
                            onTap: onEdit),
                        const SizedBox(width: 6),
                        _SorteosCardIconButton(
                            icon: Icons.delete_outline_rounded,
                            color: AppConstants.errorRed,
                            onTap: onDelete),
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

// ── Modal detalle (APP) ────────────────────────────────────────────────────────

class _SorteosDetailModal extends StatefulWidget {
  final int raffleId;
  final RaffleService raffleService;
  final String casinoLabel;

  const _SorteosDetailModal({
    required this.raffleId,
    required this.raffleService,
    required this.casinoLabel,
  });

  @override
  State<_SorteosDetailModal> createState() => _SorteosDetailModalState();
}

class _SorteosDetailModalState extends State<_SorteosDetailModal> {
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

  String _fmt(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      return DateFormat('dd/MM/yyyy HH:mm')
          .format(DateTime.parse(raw).toLocal());
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
                    bottom:
                        BorderSide(color: green.withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.emoji_events_outlined,
                        color: green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del sorteo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.45), size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: CircularProgressIndicator(
                        color: green, strokeWidth: 2.5)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65))),
              )
            else if (_raffle != null)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: _SorteosDetailBody(
                    raffle: _raffle!,
                    casinoLabel: widget.casinoLabel,
                    formatDate: _fmt,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SorteosDetailBody extends StatelessWidget {
  final RaffleModel raffle;
  final String casinoLabel;
  final String Function(String) formatDate;

  const _SorteosDetailBody({
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
        if (raffle.mediaUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                raffle.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: green.withValues(alpha: 0.06),
                  child: Center(
                    child: Icon(Icons.emoji_events_outlined,
                        color: green.withValues(alpha: 0.35), size: 32),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                      color: raffle.activo
                          ? green
                          : Colors.white.withValues(alpha: 0.30),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    raffle.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                        color: raffle.activo
                            ? green
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (raffle.text.isNotEmpty) ...[
          Text(raffle.text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13.5, height: 1.45)),
          const SizedBox(height: 14),
        ],
        _SorteosDetailRow(
            icon: Icons.casino_outlined,
            label: 'Casino',
            value: casinoLabel),
        const SizedBox(height: 8),
        _SorteosDetailRow(
            icon: Icons.schedule_rounded,
            label: 'Cierre',
            value: formatDate(raffle.fechaFin)),
        const SizedBox(height: 8),
        _SorteosDetailRow(
            icon: Icons.emoji_events_outlined,
            label: 'Ganadores',
            value: raffle.cantidadGanadores.toString()),
        if (raffle.emailPresentador != null &&
            raffle.emailPresentador!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SorteosDetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Presentador',
              value: raffle.emailPresentador!),
        ],
        const SizedBox(height: 8),
        _SorteosDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Creado',
            value: formatDate(raffle.createdAt)),
        if (raffle.premios.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Premios',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
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
                              child: Icon(Icons.star_outline_rounded,
                                  color: green.withValues(alpha: 0.40),
                                  size: 20))
                          : Image.network(
                              premio.imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: green.withValues(alpha: 0.06),
                                  child: Icon(Icons.star_outline_rounded,
                                      color: green.withValues(alpha: 0.40),
                                      size: 20)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(premio.nombre,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  Text('#${premio.orden}',
                      style: TextStyle(
                          color: green.withValues(alpha: 0.60),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SorteosDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SorteosDetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 13,
            color: AppConstants.primaryGreen.withValues(alpha: 0.55)),
        const SizedBox(width: 7),
        Text('$label: ',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ── Dialog QR (FORM) ──────────────────────────────────────────────────────────

class _SorteosQrDialog extends StatefulWidget {
  final String url;
  final String code;

  const _SorteosQrDialog({required this.url, required this.code});

  @override
  State<_SorteosQrDialog> createState() => _SorteosQrDialogState();
}

class _SorteosQrDialogState extends State<_SorteosQrDialog> {
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
      final bytes = byteData.buffer.asUint8List();
      final safeName =
          widget.code.isNotEmpty ? widget.code : 'sorteo';
      final savedPath =
          await saveQrImage(bytes, 'qr_${safeName}_form.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          savedPath != null ? 'QR guardado en: $savedPath' : 'QR descargado',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryGreen,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: green, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('QR del sorteo',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.45), size: 20),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                        eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.url,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: green.withValues(alpha: 0.60), fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
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
                    disabledBackgroundColor: green.withValues(alpha: 0.50),
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

// ─────────────────────────────────────────────────────────────────────────────
// FormsPage
// ─────────────────────────────────────────────────────────────────────────────

class FormsPage extends StatefulWidget {
  const FormsPage({super.key});

  @override
  State<FormsPage> createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  final _service = FormulariosService();

  bool _isLoading = false;
  String? _error;
  List<FormularioModel> _items = [];
  final Set<int> _deletingIds = {};

  // Para los dropdowns del diálogo de creación
  Map<int, String> _tidCodesById = const {};
  Map<int, String> _sorteoCodesById = const {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadTidOptions();
    _loadSorteoOptions();
  }

  Future<void> _load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _items.isNotEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchFormularios();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los formularios: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTidOptions() async {
    try {
      final tids = await _tidsService.fetchTids();
      if (!mounted) return;
      setState(() {
        _tidCodesById = {for (final t in tids) t.id: t.tid};
      });
    } catch (_) {}
  }

  Future<void> _loadSorteoOptions() async {
    try {
      final raw = await _raffleService.fetchRaffles();
      if (!mounted) return;
      final sorteos = raw.map(RaffleModel.fromMap).where((s) => s.tipo == 'FORM').toList(growable: false);
      setState(() {
        _sorteoCodesById = {
          for (final s in sorteos)
            if (s.id != null)
              s.id!: s.text.isNotEmpty
                  ? s.text
                  : s.codigoSorteo.isNotEmpty
                      ? s.codigoSorteo
                      : '#${s.id}',
        };
      });
    } catch (_) {}
  }

  final _tidsService = TidsService();
  final _raffleService = RaffleService();

  Future<void> _delete(FormularioModel item) async {
    if (_deletingIds.contains(item.id)) return;

    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar formulario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar el formulario #${item.id}? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: green)),
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

    setState(() => _deletingIds.add(item.id));

    try {
      await _service.deleteFormulario(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((f) => f.id != item.id).toList();
        _deletingIds.remove(item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Formulario eliminado.',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: AppConstants.primaryGreen,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo eliminar el formulario.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            FormsManagementView(
              items: _items,
              totalItems: _items.length,
              isLoading: _isLoading,
              errorMessage: _error,
              deletingIds: _deletingIds,
              onRetry: () => _load(force: true),
              onDelete: _delete,
              tidCodesById: _tidCodesById,
              sorteoCodesById: _sorteoCodesById,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SubAfiliadoresPage
// ─────────────────────────────────────────────────────────────────────────────

class SubAfiliadoresPage extends StatefulWidget {
  const SubAfiliadoresPage({super.key});

  @override
  State<SubAfiliadoresPage> createState() => _SubAfiliadoresPageState();
}

class _SubAfiliadoresPageState extends State<SubAfiliadoresPage> {
  final SubAfiliadosService _service = SubAfiliadosService();

  bool _isLoading = false;
  String? _error;
  List<SubAfiliadoModel> _items = [];
  final Set<int> _deletingIds = {};
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _items.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchSubAfiliados();
      if (!mounted) return;
      setState(() {
        _items = result;
        _isLoading = false;
      });
    } catch (e, stack) {
      log('[SubAfiliadoresPage] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar los sub-afiliadores: $e';
        _isLoading = false;
      });
    }
  }

  void _replaceInList(SubAfiliadoModel updated) {
    _items = _items.map((s) => s.id == updated.id ? updated : s).toList();
  }

  Future<void> _toggleActivo(SubAfiliadoModel item) async {
    if (_togglingIds.contains(item.id)) return;

    setState(() {
      _togglingIds.add(item.id);
      _replaceInList(item.copyWith(activo: !item.activo));
    });

    try {
      final updated = await _service.toggleActivo(item.id);
      if (!mounted) return;
      setState(() {
        _replaceInList(updated);
        _togglingIds.remove(item.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replaceInList(item);
        _togglingIds.remove(item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cambiar el estado del sub-afiliador.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTotalJugadores(SubAfiliadoModel item) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool isFetching = false;
        int? total;
        String? fetchError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!isFetching && total == null && fetchError == null) {
              isFetching = true;
              _service
                  .fetchTotalJugadores(item.id)
                  .then((count) {
                    setDialogState(() {
                      total = count;
                      isFetching = false;
                    });
                  })
                  .catchError((_) {
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
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────────
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
                          bottom: BorderSide(
                            color: green.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: green.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nombre.isNotEmpty
                                      ? item.nombre
                                      : 'Sub-afiliador',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sub-afiliador',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.38),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Contenido ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: total != null
                          ? Column(
                              children: [
                                Text(
                                  'Total de afiliaciones',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: green.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$total',
                                        style: const TextStyle(
                                          color: green,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        total == 1
                                            ? 'jugador afiliado'
                                            : 'jugadores afiliados',
                                        style: TextStyle(
                                          color: green.withValues(alpha: 0.60),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : fetchError != null
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppConstants.errorRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fetchError!,
                                    style: const TextStyle(
                                      color: AppConstants.errorRed,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(
                              height: 56,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: green,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                    ),

                    // ── Acción ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            backgroundColor: green.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: green.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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

  Future<void> _delete(SubAfiliadoModel item) async {
    if (_deletingIds.contains(item.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Eliminar sub-afiliador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar a "${item.nombre.isNotEmpty ? item.nombre : 'este sub-afiliador'}"? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppConstants.errorRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(item.id));

    try {
      await _service.deleteSubAfiliado(item.id);
      if (!mounted) return;
      setState(() {
        _items = _items.where((s) => s.id != item.id).toList();
        _deletingIds.remove(item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Sub-afiliador eliminado.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el sub-afiliador.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/affiliates-tools');
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
          padding: EdgeInsets.zero,
        children: [
          SubAfiliadosManagementView(
            onCreate: () => showCreateSubAfiliadoDialog(
              context: context,
              service: _service,
              onCreated: (created) {
                setState(() => _items = [..._items, created]);
              },
            ),
            items: _items,
            totalItems: _items.length,
            isLoading: _isLoading,
            errorMessage: _error,
            deletingIds: _deletingIds,
            togglingIds: _togglingIds,
            onRetry: () => _load(force: true),
            onDelete: _delete,
            onToggleActivo: _toggleActivo,
            onViewTotal: _showTotalJugadores,
          ),
        ],
      ),
    ),
    );
  }
}
