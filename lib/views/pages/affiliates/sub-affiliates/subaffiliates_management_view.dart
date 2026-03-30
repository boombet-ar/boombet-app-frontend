import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/sub_afiliado_model.dart';
import 'package:flutter/material.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

class SubAfiliadosManagementView extends StatelessWidget {
  final VoidCallback onCreate;
  final List<SubAfiliadoModel> items;
  final int totalItems;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> deletingIds;
  final Set<int> togglingIds;
  final VoidCallback onRetry;
  final void Function(SubAfiliadoModel) onDelete;
  final void Function(SubAfiliadoModel) onToggleActivo;
  final void Function(SubAfiliadoModel) onViewTotal;

  const SubAfiliadosManagementView({
    super.key,
    required this.onCreate,
    required this.items,
    required this.totalItems,
    required this.isLoading,
    required this.errorMessage,
    required this.deletingIds,
    required this.togglingIds,
    required this.onRetry,
    required this.onDelete,
    required this.onToggleActivo,
    required this.onViewTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _SubAfiliadoCreateButton(onTap: onCreate),
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
                _SubAfiliadosError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _SubAfiliadosEmpty(onRetry: onRetry)
              else ...[
                ...items.map((sub) {
                  final isDeleting = deletingIds.contains(sub.id);
                  final isToggling = togglingIds.contains(sub.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SubAfiliadoListTile(
                      subAfiliado: sub,
                      isDeleting: isDeleting,
                      isToggling: isToggling,
                      onDelete: () => onDelete(sub),
                      onToggleActivo: () => onToggleActivo(sub),
                      onViewTotal: () => onViewTotal(sub),
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
                          '$totalItems sub-afiliado${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
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

class _SubAfiliadoCreateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SubAfiliadoCreateButton({required this.onTap});

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
                child: const Icon(
                  Icons.person_add_outlined,
                  color: _green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Agregar sub-afiliadores',
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

class _SubAfiliadosError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SubAfiliadosError({required this.message, required this.onRetry});

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
              const Expanded(
                child: Text(
                  'No se pudieron cargar los sub-afiliadores',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
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

class _SubAfiliadosEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _SubAfiliadosEmpty({required this.onRetry});

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
            Icons.group_off_outlined,
            color: _green.withValues(alpha: 0.55),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay sub-afiliadores para mostrar.',
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

// ── Tile de sub-afiliado ───────────────────────────────────────────────────────

class _SubAfiliadoListTile extends StatelessWidget {
  final SubAfiliadoModel subAfiliado;
  final bool isDeleting;
  final bool isToggling;
  final VoidCallback onDelete;
  final VoidCallback onToggleActivo;
  final VoidCallback onViewTotal;

  const _SubAfiliadoListTile({
    required this.subAfiliado,
    required this.isDeleting,
    required this.isToggling,
    required this.onDelete,
    required this.onToggleActivo,
    required this.onViewTotal,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = isDeleting || isToggling;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          // ── Ícono ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.20)),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subAfiliado.nombre.isNotEmpty
                      ? subAfiliado.nombre
                      : 'Sin nombre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                TextButton.icon(
                  onPressed: onViewTotal,
                  icon: const Icon(
                    Icons.people_outline,
                    size: 13,
                    color: _green,
                  ),
                  label: const Text(
                    'Ver total de afiliaciones',
                    style: TextStyle(color: _green, fontSize: 11.5),
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

          // ── Controles ─────────────────────────────────────────────────
          // Switch activo
          if (isToggling)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            )
          else
            Transform.scale(
              scale: 0.80,
              child: Switch(
                value: subAfiliado.activo,
                onChanged: isBusy ? null : (_) => onToggleActivo(),
                activeColor: _green,
                inactiveThumbColor: Colors.white.withValues(alpha: 0.40),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
              ),
            ),

          // Eliminar
          if (isDeleting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _errorRed,
              ),
            )
          else
            IconButton(
              tooltip: 'Eliminar',
              onPressed: isBusy ? null : onDelete,
              icon: Icon(
                Icons.person_remove_outlined,
                size: 20,
                color: isBusy ? _errorRed.withValues(alpha: 0.30) : _errorRed,
              ),
            ),
        ],
      ),
    );
  }
}
