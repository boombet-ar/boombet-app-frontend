import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/auth/auth_service.dart';
import 'package:boombet_app/services/domain/eventos_service.dart';
import 'package:boombet_app/services/domain/formularios_service.dart';
import 'package:boombet_app/services/domain/raffle_service.dart';
import 'package:boombet_app/services/domain/stands_service.dart';
import 'package:boombet_app/services/domain/sub_afiliados_service.dart';
import 'package:boombet_app/services/domain/tids_service.dart';
import 'package:boombet_app/services/infra/token_service.dart';
import 'package:boombet_app/views/pages/affiliates/tids/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/tids/create_tid.dart';
import 'package:boombet_app/views/pages/affiliates/stands/create_stand.dart';
import 'package:boombet_app/views/pages/affiliates/sub_affiliates/create_subaffiliate.dart';
import 'package:boombet_app/views/pages/affiliates/forms/create_form.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:boombet_app/views/pages/affiliates/home/eventos_tab.dart';
import 'package:boombet_app/views/pages/affiliates/home/sin_evento_tab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home principal del panel de afiliados.
///
/// - Tab "Eventos": cards expandibles con conteos y acciones rápidas.
/// - Tab "Sin evento": lista filtrable de entidades sin evento asignado.
/// - FAB contextual: wizard en tab Eventos, selector en tab Sin Evento.
class AffiliatesHomePage extends StatefulWidget {
  const AffiliatesHomePage({super.key});

  @override
  State<AffiliatesHomePage> createState() => _AffiliatesHomePageState();
}

class _AffiliatesHomePageState extends State<AffiliatesHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);

  // ── Estado de carga ────────────────────────────────────────────────────
  bool _loading = true;
  String? _loadError;

  // ── Datos cargados ─────────────────────────────────────────────────────
  List<EventoModel> _eventos = [];
  List<TidModel> _tids = [];
  List<RaffleModel> _sorteos = [];
  List<FormularioModel> _formularios = [];
  List<StandModel> _stands = [];
  List<SubAfiliadoModel> _subAfiliados = [];

  // ── Estado de acciones ─────────────────────────────────────────────────
  final Set<int> _updatingIds = {};
  final Set<int> _deletingIds = {};

  // ── Auth ───────────────────────────────────────────────────────────────
  late final Future<String?> _roleFuture = TokenService.getUserRole();

  // ── Servicios ─────────────────────────────────────────────────────────
  final _eventosService = EventosService();
  final _tidsService = TidsService();
  final _standsService = StandsService();
  final _subAfiliadosService = SubAfiliadosService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Carga paralela de todos los datos ────────────────────────────────

  Future<void> _loadAll({bool force = false}) async {
    if (!force && !_loading && _eventos.isNotEmpty) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        EventosService().fetchEventos(includeDetails: false),
        TidsService().fetchTids(),
        RaffleService().fetchRaffles(),
        FormulariosService().fetchFormularios(),
        StandsService().fetchStands(),
        SubAfiliadosService().fetchSubAfiliados(),
      ]);

      if (!mounted) return;
      setState(() {
        _eventos = results[0] as List<EventoModel>;
        _tids = results[1] as List<TidModel>;
        _sorteos = (results[2] as List<Map<String, dynamic>>)
            .map(RaffleModel.fromMap)
            .toList();
        _formularios = results[3] as List<FormularioModel>;
        _stands = results[4] as List<StandModel>;
        _subAfiliados = results[5] as List<SubAfiliadoModel>;
        _loading = false;
      });
    } catch (e, stack) {
      log('[AffiliatesHome] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _loadError = 'Error al cargar los datos. Intentá de nuevo.';
        _loading = false;
      });
    }
  }

  // ── Conteos por evento (computed) ─────────────────────────────────────

  Map<int, int> get _tidCountByEvento {
    final map = <int, int>{};
    for (final t in _tids) {
      if (t.idEvento != 0) map[t.idEvento] = (map[t.idEvento] ?? 0) + 1;
    }
    return map;
  }

  Map<int, int> get _sorteoCountByEvento {
    final map = <int, int>{};
    for (final s in _sorteos) {
      if (s.eventoId != null) {
        map[s.eventoId!] = (map[s.eventoId!] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<int, RaffleModel> get _sorteoByEvento {
    final map = <int, RaffleModel>{};
    for (final s in _sorteos) {
      if (s.eventoId != null && !map.containsKey(s.eventoId)) {
        map[s.eventoId!] = s;
      }
    }
    return map;
  }

  Map<int, int> get _formCountByEvento {
    final map = <int, int>{};
    for (final f in _formularios) {
      if (f.eventoId != null) {
        map[f.eventoId!] = (map[f.eventoId!] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<int, FormularioModel> get _formByEvento {
    final map = <int, FormularioModel>{};
    for (final f in _formularios) {
      if (f.eventoId != null && !map.containsKey(f.eventoId)) {
        map[f.eventoId!] = f;
      }
    }
    return map;
  }

  // ── Opciones de dropdowns (para create TID en la card) ───────────────

  List<EventoOption> get _eventoOptions => [
        const EventoOption(id: null, label: 'Sin evento'),
        ..._eventos.map(
          (e) => EventoOption(
            id: e.id,
            label: e.nombre.isNotEmpty ? e.nombre : 'Evento #${e.id}',
          ),
        ),
      ];

  List<StandOption> get _standOptions => [
        const StandOption(id: null, label: 'Sin stand'),
        ..._stands.map((s) => StandOption(id: s.id, label: s.nombre)),
      ];

  // ── Acciones sobre eventos ────────────────────────────────────────────

  Future<void> _toggleActive(EventoModel ev, bool isActive) async {
    if (_updatingIds.contains(ev.id)) return;
    setState(() {
      _updatingIds.add(ev.id);
      _eventos = _eventos
          .map(
            (e) => e.id == ev.id
                ? EventoModel(
                    id: e.id,
                    nombre: e.nombre,
                    activo: isActive,
                    fechaFin: e.fechaFin,
                    idAfiliador: e.idAfiliador,
                  )
                : e,
          )
          .toList();
    });

    try {
      final updated = await _eventosService.toggleEventoActivo(id: ev.id, activo: isActive);
      if (!mounted) return;
      setState(() {
        _eventos = _eventos.map((e) => e.id == updated.id ? updated : e).toList();
        _updatingIds.remove(ev.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventos = _eventos.map((e) => e.id == ev.id ? ev : e).toList();
        _updatingIds.remove(ev.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cambiar el estado del evento.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteEvento(EventoModel ev) async {
    if (_deletingIds.contains(ev.id)) return;

    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);

    final cascade = await showDialog<bool>(
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
          'Eliminar evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar también todo lo relacionado con "${ev.nombre}" (sorteos, TIDs, stands)?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );

    if (cascade == null || !mounted) return;

    setState(() => _deletingIds.add(ev.id));

    try {
      await _eventosService.deleteEvento(id: ev.id, cascade: cascade);
      if (!mounted) return;
      setState(() {
        _eventos = _eventos.where((e) => e.id != ev.id).toList();
        _deletingIds.remove(ev.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(ev.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el evento.')),
      );
    }
  }

  // ── FAB contextual ────────────────────────────────────────────────────

  void _onFabPressed() {
    if (_tabCtrl.index == 0) {
      // Tab Eventos → wizard de creación completa
      context.push('/affiliates-tools/wizard');
    } else {
      // Tab Sin Evento → selector de entidad individual
      _showEntitySelector();
    }
  }

  void _showEntitySelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle con color verde sutil
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Título con barra lateral neon
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppConstants.primaryGreen,
                        AppConstants.primaryGreen.withValues(alpha: 0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryGreen.withValues(alpha: 0.55),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  '¿Qué querés crear?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Separador neon
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppConstants.primaryGreen.withValues(alpha: 0.20),
                  AppConstants.primaryGreen.withValues(alpha: 0.40),
                  AppConstants.primaryGreen.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _entityOptions(ctx),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _entityOptions(BuildContext ctx) {
    final items = [
      (
        icon: Icons.track_changes_outlined,
        label: 'TID',
        onTap: () async {
          await showCreateTidDialog(
            context: context,
            tidsService: _tidsService,
            onCreated: () => _loadAll(force: true),
          );
        },
      ),
      (
        icon: Icons.storefront_outlined,
        label: 'Stand',
        onTap: () async {
          await showCreateStandDialog(
            context: context,
            standsService: _standsService,
            onCreated: (_) => _loadAll(force: true),
          );
        },
      ),
      (
        icon: Icons.group_outlined,
        label: 'Sub-afiliador',
        onTap: () async {
          await showCreateSubAfiliadoDialog(
            context: context,
            service: _subAfiliadosService,
            onCreated: (_) => _loadAll(force: true),
          );
        },
      ),
      (
        icon: Icons.emoji_events_outlined,
        label: 'Sorteo',
        onTap: () async {
          await showDialog<void>(
            context: context,
            builder: (dialogCtx) => Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.20)),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 680, maxHeight: 760),
                child: SingleChildScrollView(
                  child: CreateRaffleSection(
                    showHeader: false,
                    onCreated: () {
                      Navigator.of(dialogCtx).pop();
                      _loadAll(force: true);
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
      (
        icon: Icons.dynamic_form_outlined,
        label: 'Formulario',
        onTap: () async {
          await showCreateFormDialog(
            context: context,
            onCreated: (_) => _loadAll(force: true),
          );
        },
      ),
    ];

    const green = AppConstants.primaryGreen;
    return items
        .map(
          (item) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(ctx);
                item.onTap();
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: green.withValues(alpha: 0.08),
              highlightColor: green.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: green.withValues(alpha: 0.22)),
                      ),
                      child: Icon(item.icon, color: green, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: green.withValues(alpha: 0.16)),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  // ── Logout ────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿Cerrar sesión?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('¿Querés cerrar sesión?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppConstants.primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService().logout();
      if (mounted) context.go('/');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const bgColor = AppConstants.darkBg;

    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, roleSnap) {
        final role = roleSnap.data?.trim().toUpperCase();
        final isAffiliator = role == 'AFILIADOR';

        if (roleSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAffiliator) {
          return _AccessDeniedPage();
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _logout();
          },
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0C1A0E),
                      Color(0xFF080808),
                      Color(0xFF060606),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0x1429FF5E),
                      width: 1,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.primaryGreen.withValues(alpha: 0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.20),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/boombetlogo.png',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Panel de Afiliados',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'BOOMBET',
                        style: TextStyle(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.70),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                _AppBarIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: () => _loadAll(force: true),
                  tooltip: 'Recargar',
                ),
                const SizedBox(width: 8),
                _AppBarIconButton(
                  icon: Icons.logout_rounded,
                  onTap: _logout,
                  tooltip: 'Cerrar sesión',
                ),
                const SizedBox(width: 12),
              ],
              bottom: _TabBarWithSeparator(controller: _tabCtrl),
            ),
            body: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryGreen,
                    ),
                  )
                : _loadError != null
                    ? _ErrorState(
                        error: _loadError!,
                        onRetry: () => _loadAll(force: true),
                      )
                    : RefreshIndicator(
                        color: green,
                        backgroundColor: const Color(0xFF1A1A1A),
                        onRefresh: () => _loadAll(force: true),
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            EventosTab(
                              eventos: _eventos,
                              updatingIds: _updatingIds,
                              deletingIds: _deletingIds,
                              onToggleActive: _toggleActive,
                              onDelete: _deleteEvento,
                            ),
                            SinEventoTab(
                              tids: _tids,
                              sorteos: _sorteos,
                              stands: _stands,
                              subAfiliados: _subAfiliados,
                              formularios: _formularios,
                              eventoOptions: _eventoOptions,
                              standOptions: _standOptions,
                            ),
                          ],
                        ),
                      ),
            floatingActionButton: !_loading && _loadError == null
                ? ListenableBuilder(
                    listenable: _tabCtrl,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: 0.40),
                            blurRadius: 18,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _onFabPressed,
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        tooltip: _tabCtrl.index == 0
                            ? 'Nuevo evento completo'
                            : 'Crear entidad',
                        child: Icon(
                          _tabCtrl.index == 0
                              ? Icons.auto_awesome_rounded
                              : Icons.add_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
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
}

// ── Widgets auxiliares del AppBar ─────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.65),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarWithSeparator extends StatelessWidget
    implements PreferredSizeWidget {
  final TabController controller;
  const _TabBarWithSeparator({required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: green.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: green.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          dividerColor: Colors.transparent,
          labelColor: green,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.40),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(
              icon: Icon(Icons.event_note_outlined, size: 17),
              text: 'Eventos',
            ),
            Tab(
              icon: Icon(Icons.layers_outlined, size: 17),
              text: 'Sin evento',
            ),
          ],
        ),
        // Separador neon debajo del TabBar
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                green.withValues(alpha: 0.25),
                green.withValues(alpha: 0.50),
                green.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Pantallas de estado ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppConstants.errorRed.withValues(alpha: 0.60),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

