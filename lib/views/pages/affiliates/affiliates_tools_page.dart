import 'dart:developer';
import 'dart:math' show max;

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/services/eventos_service.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/create_tid.dart';
import 'package:boombet_app/views/pages/affiliates/events/create_event.dart';
import 'package:boombet_app/views/pages/affiliates/events/event_management_view.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/tids_management_view.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
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

    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        final role = snapshot.data?.trim().toUpperCase();
        final isAffiliator = role == 'AFILIADOR';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: const MainAppBar(
              title: 'Herramientas Afiliador',
              showBackButton: false,
              showLogo: true,
              showSettings: false,
              showProfileButton: false,
              showLogoutButton: true,
              showFaqButton: false,
              showExitButton: false,
              showAdminTools: false,
              showAffiliatesTools: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAffiliator) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: const MainAppBar(
              title: 'Herramientas Afiliador',
              showBackButton: false,
              showLogo: true,
              showSettings: false,
              showProfileButton: false,
              showLogoutButton: true,
              showFaqButton: false,
              showExitButton: false,
              showAdminTools: false,
              showAffiliatesTools: false,
            ),
            body: Center(
              child: Text(
                'Acceso restringido. Solo afiliadores.',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const MainAppBar(
            title: 'Herramientas Afiliador',
            showBackButton: false,
            showLogo: true,
            showSettings: false,
            showProfileButton: false,
            showLogoutButton: true,
            showFaqButton: false,
            showExitButton: false,
            showAdminTools: false,
            showAffiliatesTools: false,
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SectionHeaderWidget(
                title: 'Panel de afiliador',
                subtitle: 'Acceso rápido a herramientas de seguimiento.',
                icon: Icons.manage_search_outlined,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  children: [
                    _AffiliatorPrimaryActionButton(
                      title: 'TIDs (Tracking IDs)',
                      subtitle: 'Administrar y consultar tracking IDs',
                      icon: Icons.track_changes_outlined,
                      accentColor: Theme.of(context).colorScheme.primary,
                      onTap: () => context.go('/affiliates-tools/tids'),
                    ),
                    const SizedBox(height: 12),
                    _AffiliatorPrimaryActionButton(
                      title: 'Eventos',
                      subtitle: 'Gestionar eventos y estadísticas',
                      icon: Icons.event_note_outlined,
                      accentColor: Theme.of(context).colorScheme.primary,
                      onTap: () => context.go('/affiliates-tools/eventos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
  List<EventoOption> _eventoOptions = kDefaultEventoOptions;
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
    final textColor =
        isDark ? AppConstants.textDark : AppConstants.lightLabelText;

    final tidController = TextEditingController(text: tid.tid);
    // Tratar idEvento == 0 como "sin evento"
    int? selectedEventoId = tid.idEvento == 0 ? null : tid.idEvento;

    final result = await showDialog<(String, int?)>(

      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Editar TID', style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tidController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'TID',
                  labelStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EventoDropdown(
                options: _eventoOptions,
                selectedId: selectedEventoId,
                accent: theme.colorScheme.primary,
                textColor: textColor,
                bgColor: dialogBg,
                onChanged: (v) =>
                    setDialogState(() => selectedEventoId = v),
              ),
            ],
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
              onPressed: () => Navigator.pop(
                dialogContext,
                (tidController.text.trim(), selectedEventoId),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(color: AppConstants.primaryGreen),
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

    if (newTid.isEmpty) return;

    setState(() => _editingIds.add(tid.id));

    try {
      final updated = await _tidsService.updateTid(
        id: tid.id,
        tid: newTid,
        idEvento: newIdEvento,
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg =
        isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
    final textColor =
        isDark ? AppConstants.textDark : AppConstants.lightLabelText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Eliminar TID', style: TextStyle(color: textColor)),
        content: Text(
          '¿Querés eliminar el TID "${tid.tid}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
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
        if (_currentPage > 1 && (_currentPage - 1) * _pageSize >= _tids.length) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
    final textColor = isDark ? AppConstants.textDark : AppConstants.lightLabelText;

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
              }).catchError((e) {
                setDialogState(() {
                  fetchError = 'No se pudo obtener la cantidad.';
                  isFetching = false;
                });
              });
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              title: Text(tid.tid, style: TextStyle(color: textColor)),
              content: totalJugadores != null
                  ? Text(
                      'Cantidad de afiliaciones: $totalJugadores',
                      style: TextStyle(color: textColor),
                    )
                  : fetchError != null
                      ? Text(
                          fetchError!,
                          style: const TextStyle(color: AppConstants.errorRed),
                        )
                      : const SizedBox(
                          height: 40,
                          child: Center(child: CircularProgressIndicator()),
                        ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: AppConstants.primaryGreen),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'TIDs (Tracking IDs)',
        showBackButton: true,
        onBackPressed: () => context.go('/affiliates-tools'),
        showLogo: true,
        showSettings: false,
        showProfileButton: false,
        showLogoutButton: false,
        showFaqButton: false,
        showExitButton: false,
        showAdminTools: false,
        showAffiliatesTools: false,
      ),
      backgroundColor: AppConstants.darkBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          TidsManagementView(
            onCreate: () => showCreateTidDialog(
              context: context,
              tidsService: _tidsService,
              eventoOptions: _eventoOptions,
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
      _replaceEventoInList(EventoModel(
        id: evento.id,
        nombre: evento.nombre,
        activo: isActive,
        fechaFin: evento.fechaFin,
        idAfiliador: evento.idAfiliador,
      ));
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
    final textColor = isDark ? AppConstants.textDark : AppConstants.lightLabelText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Eliminar evento', style: TextStyle(color: textColor)),
        content: Text(
          '¿Querés eliminar "${evento.nombre}"? Esta acción no se puede deshacer.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppConstants.primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppConstants.errorRed)),
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
        if (_currentPage > 1 && (_currentPage - 1) * _pageSize >= _eventos.length) {
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
    context.go('/affiliates-tools/eventos/${evento.id}', extra: evento);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MainAppBar(
        title: 'Eventos',
        showBackButton: true,
        onBackPressed: () => context.go('/affiliates-tools'),
        showLogo: true,
        showSettings: false,
        showProfileButton: false,
        showLogoutButton: false,
        showFaqButton: false,
        showExitButton: false,
        showAdminTools: false,
        showAffiliatesTools: false,
      ),
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
    );
  }
}

class _AffiliatorPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _AffiliatorPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
