import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:flutter/material.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

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
  final void Function(AfiliadorModel) onViewAffiliations;

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
    required this.onViewAffiliations,
  });

  @override
  Widget build(BuildContext context) {
    final lastIndex = totalPages > 0 ? totalPages - 1 : page;
    final canGoBack = page > 0 && !isFirstPage;
    final canGoForward = totalPages > 0 ? page < lastIndex : !isLastPage;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _AdminCreateButton(
                label: 'Crear afiliador',
                icon: Icons.person_add_alt_1_outlined,
                onTap: onCreate,
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _green,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              else if (errorMessage != null)
                _AdminAffiliatorsError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _AdminAffiliatorsEmpty(onRetry: onRetry)
              else ...[
                ...items.map((afiliador) {
                  final isUpdating = updatingIds.contains(afiliador.id);
                  final isDeleting = deletingIds.contains(afiliador.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminListTile(
                      item: _AdminListItemData(title: afiliador.nombre),
                      subtitleWidget: TextButton.icon(
                        onPressed: () => onViewAffiliations(afiliador),
                        icon: const Icon(
                          Icons.people_outline,
                          size: 13,
                          color: _green,
                        ),
                        label: const Text(
                          'Ver afiliaciones',
                          style: TextStyle(color: _green, fontSize: 11.5),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: afiliador.activo,
                            onChanged: isUpdating || isDeleting
                                ? null
                                : (value) => onToggleActive(afiliador, value),
                            activeColor: _green,
                          ),
                          _DeleteIconButton(
                            isDeleting: isDeleting,
                            isDisabled: isDeleting || isUpdating,
                            onPressed: () => onDelete(afiliador),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Info bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                      color: _green.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: _green.withValues(alpha: 0.70),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$totalElements afiliadores · Pág. ${page + 1}${totalPages > 0 ? " / $totalPages" : ""}${pageSize > 0 ? " · $pageSize por pág." : ""}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pagination
                if (totalPages > 1 || (!isLastPage && totalElements > 0)) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                        color: _green.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Center(
                      child: PaginationBar(
                        currentPage: page + 1,
                        canGoPrevious: canGoBack,
                        canGoNext: canGoForward,
                        onPrev: () => onGoToPage(page - 1),
                        onNext: () => onGoToPage(page + 1),
                        primaryColor: _green,
                        textColor: Colors.white,
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

// ── Botón crear ────────────────────────────────────────────────────────────────

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: _green.withValues(alpha: 0.08),
        highlightColor: _green.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: _green.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: _green, size: 18),
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
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: _green, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Estado de error ────────────────────────────────────────────────────────────

class _AdminAffiliatorsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminAffiliatorsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _errorRed.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: _errorRed, size: 18),
              const SizedBox(width: 8),
              const Text(
                'No se pudieron cargar los afiliadores',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _errorRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _errorRed.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: _errorRed,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Reintentar',
                      style: TextStyle(
                        color: _errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _AdminAffiliatorsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _AdminAffiliatorsEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _green.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: _green.withValues(alpha: 0.55),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay afiliadores para mostrar.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 12.5,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _green.withValues(alpha: 0.20)),
                ),
                child: const Text(
                  'Refrescar',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de afiliador ──────────────────────────────────────────────────────────

class _AdminListItemData {
  final String title;
  final IconData leadingIcon;

  const _AdminListItemData({
    required this.title,
    this.leadingIcon = Icons.person_outline_rounded,
  });
}

class _AdminListTile extends StatelessWidget {
  final _AdminListItemData item;
  final Widget? trailingWidget;
  final Widget? subtitleWidget;

  const _AdminListTile({
    required this.item,
    this.trailingWidget,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.20)),
            ),
            child: Icon(item.leadingIcon, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (subtitleWidget != null) ...[
                  const SizedBox(height: 2),
                  subtitleWidget!,
                ],
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}

// ── Botón de borrar ────────────────────────────────────────────────────────────

class _DeleteIconButton extends StatelessWidget {
  final bool isDeleting;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _DeleteIconButton({
    required this.isDeleting,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Eliminar afiliador',
      onPressed: isDisabled ? null : onPressed,
      icon: isDeleting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _errorRed,
              ),
            )
          : Icon(
              Icons.delete_outline_rounded,
              color: isDisabled
                  ? _errorRed.withValues(alpha: 0.30)
                  : _errorRed,
              size: 20,
            ),
    );
  }
}
