import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

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

                // Info bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: _green.withValues(alpha: 0.12)),
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
                          '$totalItems puesto${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
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

// ── Botón crear ────────────────────────────────────────────────────────────────

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
              const Expanded(
                child: Text(
                  'Crear puesto',
                  style: TextStyle(
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

class _StandsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _StandsError({required this.message, required this.onRetry});

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
              const Icon(
                Icons.error_outline_rounded,
                color: _errorRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'No se pudieron cargar los puestos',
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
                  border: Border.all(
                    color: _errorRed.withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _errorRed, size: 14),
                    SizedBox(width: 6),
                    Text(
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

class _StandsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _StandsEmpty({required this.onRetry});

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
              'No hay puestos para mostrar.',
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

// ── Tile de stand ──────────────────────────────────────────────────────────────

class _StandListTile extends StatelessWidget {
  final StandModel stand;
  final bool isEditing;
  final bool isDeleting;
  final bool isToggling;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggleActive;

  const _StandListTile({
    required this.stand,
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
            child: const Icon(
              Icons.storefront_outlined,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stand.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          if (isToggling)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _green,
              ),
            )
          else
            Switch.adaptive(
              value: stand.activo,
              activeColor: _green,
              onChanged: isBusy ? null : onToggleActive,
            ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Editar puesto',
            onPressed: isBusy ? null : onEdit,
            icon: isEditing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _green,
                    ),
                  )
                : Icon(
                    Icons.edit_outlined,
                    color: isBusy ? _green.withValues(alpha: 0.30) : _green,
                    size: 20,
                  ),
          ),
          IconButton(
            tooltip: 'Eliminar puesto',
            onPressed: isBusy ? null : onDelete,
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
                    color: isBusy
                        ? _errorRed.withValues(alpha: 0.30)
                        : _errorRed,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}
