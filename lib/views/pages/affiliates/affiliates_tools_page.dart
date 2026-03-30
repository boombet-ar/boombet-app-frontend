import 'dart:developer';
import 'dart:math' show max;

import 'package:boombet_app/config/app_constants.dart';
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
import 'package:boombet_app/views/pages/affiliates/sub-affiliates/create_subaffiliate.dart';
import 'package:boombet_app/views/pages/affiliates/sub-affiliates/subaffiliates_management_view.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/tids_management_view.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';

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
            Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(page: const LoginPage()),
              (route) => false,
            );
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
        Navigator.of(ctx).pushAndRemoveUntil(
          FadeRoute(page: const LoginPage()),
          (route) => false,
        );
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
  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
  List<EventoOption> _eventoOptions = kDefaultEventoOptions;
  List<StandOption> _standOptions = kDefaultStandOptions;
  List<StandModel> _stands = [];
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
