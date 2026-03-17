import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/eventos_service.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  bool _isLoading = false;
  String? _error;
  List<TidModel> _tids = [];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final nombre =
        widget.evento?.nombre.isNotEmpty == true
            ? widget.evento!.nombre
            : 'Evento #${widget.eventoId}';

    return Scaffold(
      appBar: MainAppBar(
        title: nombre,
        showBackButton: true,
        onBackPressed: () => context.go('/affiliates-tools/eventos'),
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
          SectionHeaderWidget(
            title: 'Detalles del evento',
            subtitle: nombre,
            icon: Icons.event_note_outlined,
          ),
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

  const _DetailTidTile({
    required this.tid,
    required this.accent,
    required this.isDeleting,
    required this.isRemoving,
    required this.onDelete,
    required this.onRemoveFromEvento,
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
            child: Text(
              tid.tid.isNotEmpty ? tid.tid : 'Sin TID',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
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
