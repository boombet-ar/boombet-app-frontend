import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

class AffiliatesManagementeView extends StatelessWidget {
  final VoidCallback onCreate;
  final List<AfiliadorModel> items;
  final bool isLoading;
  final String? errorMessage;
  final int totalElements;
  final int page;
  final int totalPages;
  final int pageSize;
  final bool isFirstPage;
  final bool isLastPage;
  final Set<int> updatingIds;
  final Set<int> deletingIds;
  final VoidCallback onRetry;
  final ValueChanged<int> onGoToPage;
  final void Function(AfiliadorModel, bool) onToggleActive;
  final void Function(AfiliadorModel) onDelete;

  const AffiliatesManagementeView({
    super.key,
    required this.onCreate,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.totalElements,
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _AffiliatorTypeVisual getTypeVisual(String type) {
      final normalized = type.trim().toUpperCase();
      final scheme = theme.colorScheme;

      final isEvento = normalized.contains('EVENTO');
      final isRuleta = normalized.contains('RULETA');

      if (isEvento) {
        return _AffiliatorTypeVisual(
          icon: Icons.celebration_outlined,
          color: scheme.error,
        );
      }

      if (isRuleta) {
        return _AffiliatorTypeVisual(
          icon: Icons.casino_outlined,
          color: AppConstants.warningOrange,
        );
      }

      return _AffiliatorTypeVisual(
        icon: Icons.person_outline,
        color: scheme.primary,
      );
    }

    final listItems = items.map((item) {
      final typeVisual = getTypeVisual(item.tipoAfiliador);
      final tipo = item.tipoAfiliador.trim().isEmpty
          ? 'SIN TIPO'
          : item.tipoAfiliador;

      return _AdminListItemData(
        title: item.nombre,
        subtitle:
            'Tipo: $tipo • Código: ${item.tokenAfiliador}\nAfiliaciones: ${item.cantAfiliaciones}',
        trailing: item.activo ? 'Activo' : 'Inactivo',
        leadingIcon: typeVisual.icon,
        accentColor: typeVisual.color,
      );
    }).toList();

    final lastIndex = totalPages > 0 ? totalPages - 1 : page;
    final canGoBack = page > 0 && !isFirstPage;
    final canGoForward = totalPages > 0 ? page < lastIndex : !isLastPage;

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Afiliadores',
          subtitle: 'Listado de afiliadores registrados.',
          icon: Icons.group_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _AdminCreateButton(
                label: 'Crear afiliador',
                icon: Icons.person_add_alt_1,
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
                _AdminAffiliatorsError(message: errorMessage!, onRetry: onRetry)
              else if (listItems.isEmpty)
                _AdminAffiliatorsEmpty(onRetry: onRetry)
              else ...[
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final afiliador = entry.value;
                  final item = listItems[index];
                  final itemAccentColor = item.accentColor;
                  final isUpdating = updatingIds.contains(afiliador.id);
                  final isDeleting = deletingIds.contains(afiliador.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminListTile(
                      item: item,
                      accentColor: itemAccentColor,
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: itemAccentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              afiliador.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: itemAccentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: afiliador.activo,
                            onChanged: isUpdating || isDeleting
                                ? null
                                : (value) => onToggleActive(afiliador, value),
                            activeColor: itemAccentColor,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Eliminar afiliador',
                            onPressed: isDeleting || isUpdating
                                ? null
                                : () => onDelete(afiliador),
                            icon: isDeleting
                                ? SizedBox(
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
                    color: isDark
                        ? AppConstants.darkAccent
                        : AppConstants.lightSurfaceVariant,
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
                          'Mostrando $totalElements afiliadores · Página ${page + 1}${totalPages > 0 ? " de $totalPages" : ""}${pageSize > 0 ? " · $pageSize por página" : ""}',
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
                if (totalPages > 1 || (!isLastPage && totalElements > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : AppConstants.lightAccent,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Center(
                      child: PaginationBar(
                        currentPage: page + 1,
                        canGoPrevious: canGoBack,
                        canGoNext: canGoForward,
                        onPrev: () => onGoToPage(page - 1),
                        onNext: () => onGoToPage(page + 1),
                        primaryColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminCreateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppConstants.darkAccent
              : AppConstants.lightSurfaceVariant,
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

class _AdminAffiliatorsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminAffiliatorsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudieron cargar los afiliadores.',
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

class _AdminAffiliatorsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _AdminAffiliatorsEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
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
              'No hay afiliadores para mostrar.',
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

class _AffiliatorTypeVisual {
  final IconData icon;
  final Color color;

  const _AffiliatorTypeVisual({required this.icon, required this.color});
}

class _AdminListItemData {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData leadingIcon;
  final Color accentColor;

  const _AdminListItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.leadingIcon = Icons.folder_shared,
    this.accentColor = AppConstants.primaryGreen,
  });
}

class _AdminListTile extends StatelessWidget {
  final _AdminListItemData item;
  final Color accentColor;
  final Widget? trailingWidget;

  const _AdminListTile({
    required this.item,
    required this.accentColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
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
            child: Icon(item.leadingIcon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailingWidget ??
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.trailing,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
