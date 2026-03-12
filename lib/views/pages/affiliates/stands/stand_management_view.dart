import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

class StandManagementView extends StatelessWidget {
  final VoidCallback onCreate;
  final List<StandModel> items;
  final int totalItems;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> editingIds;
  final Set<int> deletingIds;
  final Set<int> togglingIds;
  final VoidCallback onRetry;
  final void Function(StandModel) onEdit;
  final void Function(StandModel) onDelete;
  final void Function(StandModel stand, bool value) onToggleActive;

  const StandManagementView({
    super.key,
    required this.onCreate,
    required this.items,
    required this.totalItems,
    required this.isLoading,
    required this.errorMessage,
    required this.editingIds,
    required this.deletingIds,
    required this.togglingIds,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SectionHeaderWidget(
          title: 'Stands / Puestos',
          subtitle: 'Listado de puestos registrados.',
          icon: Icons.storefront_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _StandCreateButton(
                label: 'Crear puesto',
                icon: Icons.add_business_outlined,
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
                _StandsError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _StandsEmpty(onRetry: onRetry)
              else ...[
                ...items.map((stand) {
                  final isEditing = editingIds.contains(stand.id);
                  final isDeleting = deletingIds.contains(stand.id);
                  final isToggling = togglingIds.contains(stand.id);
                  final isBusy = isEditing || isDeleting || isToggling;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StandListTile(
                      stand: stand,
                      accentColor: theme.colorScheme.primary,
                      isEditing: isEditing,
                      isDeleting: isDeleting,
                      isToggling: isToggling,
                      isBusy: isBusy,
                      onEdit: () => onEdit(stand),
                      onDelete: () => onDelete(stand),
                      onToggleActive: (value) => onToggleActive(stand, value),
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
                          '$totalItems puesto${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
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

class _StandCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _StandCreateButton({
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

class _StandsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StandsError({required this.message, required this.onRetry});

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
            'No se pudieron cargar los puestos.',
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

class _StandsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _StandsEmpty({required this.onRetry});

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
          Icon(Icons.storefront_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay puestos para mostrar.',
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

class _StandListTile extends StatelessWidget {
  final StandModel stand;
  final Color accentColor;
  final bool isEditing;
  final bool isDeleting;
  final bool isToggling;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggleActive;

  const _StandListTile({
    required this.stand,
    required this.accentColor,
    required this.isEditing,
    required this.isDeleting,
    required this.isToggling,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Icons.storefront_outlined,
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stand.nombre,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isToggling)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: stand.activo,
              activeTrackColor: AppConstants.primaryGreen,
              onChanged: isBusy ? null : onToggleActive,
            ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Editar puesto',
            onPressed: isBusy ? null : onEdit,
            icon: isEditing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : Icon(Icons.edit_outlined, color: accentColor),
          ),
          IconButton(
            tooltip: 'Eliminar puesto',
            onPressed: isBusy ? null : onDelete,
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
    );
  }
}
