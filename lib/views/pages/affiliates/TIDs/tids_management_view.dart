import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

class TidsManagementView extends StatelessWidget {
  final VoidCallback onCreate;
  final List<TidModel> items;
  final int totalItems;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> editingIds;
  final Set<int> deletingIds;
  final VoidCallback onRetry;
  final void Function(TidModel) onEdit;
  final void Function(TidModel) onDelete;
  final void Function(TidModel) onViewAffiliations;
  final Map<int, String> eventoNames;

  const TidsManagementView({
    super.key,
    required this.onCreate,
    required this.items,
    required this.totalItems,
    required this.isLoading,
    required this.errorMessage,
    required this.editingIds,
    required this.deletingIds,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
    required this.onViewAffiliations,
    this.eventoNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Tracking IDs',
          subtitle: 'Listado de TIDs registrados.',
          icon: Icons.track_changes_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _TidCreateButton(
                label: 'Crear TID',
                icon: Icons.add_link,
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
                _TidsError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _TidsEmpty(onRetry: onRetry)
              else ...[
                ...items.map((tid) {
                  final isEditing = editingIds.contains(tid.id);
                  final isDeleting = deletingIds.contains(tid.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TidListTile(
                      tid: tid,
                      accentColor: theme.colorScheme.primary,
                      eventoNames: eventoNames,
                      onViewAffiliations: () => onViewAffiliations(tid),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar TID',
                            onPressed: isEditing || isDeleting
                                ? null
                                : () => onEdit(tid),
                            icon: isEditing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.edit_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar TID',
                            onPressed: isDeleting || isEditing
                                ? null
                                : () => onDelete(tid),
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
                          '${totalItems} TID${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
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

class _TidCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TidCreateButton({
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

class _TidsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TidsError({required this.message, required this.onRetry});

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

class _TidsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _TidsEmpty({required this.onRetry});

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
              'No hay TIDs para mostrar.',
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

String _eventoLabel(TidModel tid, Map<int, String> eventoNames) {
  if (tid.idEvento == 0) return 'Sin evento';
  if (tid.eventoNombre != null && tid.eventoNombre!.trim().isNotEmpty) {
    return 'Evento: ${tid.eventoNombre}';
  }
  final nombre = eventoNames[tid.idEvento];
  if (nombre != null && nombre.trim().isNotEmpty) return 'Evento: $nombre';
  return 'Evento #${tid.idEvento}';
}

class _TidListTile extends StatelessWidget {
  final TidModel tid;
  final Color accentColor;
  final Map<int, String> eventoNames;
  final Widget? trailingWidget;
  final VoidCallback? onViewAffiliations;

  const _TidListTile({
    required this.tid,
    required this.accentColor,
    this.eventoNames = const {},
    this.trailingWidget,
    this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              Icons.track_changes_outlined,
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
                  tid.tid.isNotEmpty ? tid.tid : 'Sin TID',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eventoLabel(tid, eventoNames),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onViewAffiliations,
                  icon: Icon(Icons.people_outline, size: 14, color: accentColor),
                  label: Text(
                    'Ver cantidad de afiliaciones',
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
