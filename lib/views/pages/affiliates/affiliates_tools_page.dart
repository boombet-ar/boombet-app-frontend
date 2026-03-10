import 'dart:developer';
import 'dart:math' show max;

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/create_tid.dart';
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
  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
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
                options: kDefaultEventoOptions,
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

class EventosPage extends StatelessWidget {
  const EventosPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const Center(
        child: Text(
          'Vista Eventos pendiente de implementación.',
          style: TextStyle(color: AppConstants.textDark),
        ),
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
