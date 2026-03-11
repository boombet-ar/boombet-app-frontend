import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventManagementView extends StatelessWidget {
  final VoidCallback onCreate;
  final List<EventoModel> items;
  final int totalItems;
  final bool isLoading;
  final String? errorMessage;
  final int page;
  final int totalPages;
  final int pageSize;
  final bool isFirstPage;
  final bool isLastPage;
  final Set<int> updatingIds;
  final Set<int> deletingIds;
  final VoidCallback onRetry;
  final ValueChanged<int> onGoToPage;
  final void Function(EventoModel, bool) onToggleActive;
  final void Function(EventoModel) onDelete;
  final void Function(EventoModel) onViewAffiliations;

  const EventManagementView({
    super.key,
    required this.onCreate,
    required this.items,
    required this.totalItems,
    required this.isLoading,
    required this.errorMessage,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.isFirstPage,
    required this.isLastPage,
    required this.updatingIds,
    required this.deletingIds,
    required this.onRetry,
    required this.onGoToPage,
    required this.onToggleActive,
    required this.onDelete,
    required this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Eventos',
          subtitle: 'Listado de eventos registrados.',
          icon: Icons.event_note_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _EventCreateButton(
                label: 'Crear evento',
                icon: Icons.add_circle_outline,
                onTap: onCreate,
              ),
              const SizedBox(height: 16),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                )
              else if (errorMessage != null)
                _EventsError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _EventsEmpty(onRetry: onRetry)
              else ...[
                ...items.map((evento) {
                  final accent = theme.colorScheme.primary;
                  final isUpdating = updatingIds.contains(evento.id);
                  final isDeleting = deletingIds.contains(evento.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventListTile(
                      evento: evento,
                      accentColor: accent,
                      onViewAffiliations: () => onViewAffiliations(evento),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: evento.activo,
                            onChanged: isUpdating || isDeleting
                                ? null
                                : (value) => onToggleActive(evento, value),
                            activeColor: accent,
                          ),
                          IconButton(
                            tooltip: 'Eliminar evento',
                            onPressed: isDeleting || isUpdating
                                ? null
                                : () => onDelete(evento),
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppConstants.errorRed,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    color: AppConstants.errorRed,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.darkAccent,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mostrando $totalItems evento${totalItems == 1 ? '' : 's'} · Página ${page + 1}${totalPages > 0 ? " de $totalPages" : ""}${pageSize > 0 ? " · $pageSize por página" : ""}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
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
    );
  }
}

class _EventCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _EventCreateButton({
    required this.label,
    required this.icon,
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
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
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
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _EventsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EventsError({required this.message, required this.onRetry});

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
            'No se pudieron cargar los eventos.',
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

class _EventsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _EventsEmpty({required this.onRetry});

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
              'No hay eventos para mostrar.',
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

String _formatFechaFin(String? fechaFin) {
  if (fechaFin == null || fechaFin.isEmpty) return 'Sin fecha de fin';
  try {
    final dt = DateTime.parse(fechaFin).toLocal();
    return 'Fin: ${DateFormat('dd/MM/yyyy').format(dt)}';
  } catch (_) {
    return 'Fin: $fechaFin';
  }
}

class _EventListTile extends StatelessWidget {
  final EventoModel evento;
  final Color accentColor;
  final Widget? trailingWidget;
  final VoidCallback? onViewAffiliations;

  const _EventListTile({
    required this.evento,
    required this.accentColor,
    this.trailingWidget,
    this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_note_outlined,
              color: accentColor,
              size: 20,
            ),
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
                const SizedBox(height: 2),
                Text(
                  _formatFechaFin(evento.fechaFin),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onViewAffiliations,
                  icon: Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: accentColor,
                  ),
                  label: Text(
                    'Ver detalles del evento',
                    style: TextStyle(color: accentColor, fontSize: 12),
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
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}
