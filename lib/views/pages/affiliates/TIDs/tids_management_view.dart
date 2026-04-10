import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:flutter/material.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

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
  final void Function(TidModel) onShowQr;
  final Map<int, String> eventoNames;
  final Map<int, String> standNames;

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
    required this.onShowQr,
    this.eventoNames = const {},
    this.standNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      eventoNames: eventoNames,
                      standNames: standNames,
                      onViewAffiliations: () => onViewAffiliations(tid),
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QrIconButton(
                            isDisabled: isEditing || isDeleting,
                            onPressed: () => onShowQr(tid),
                          ),
                          _EditIconButton(
                            isEditing: isEditing,
                            isDisabled: isEditing || isDeleting,
                            onPressed: () => onEdit(tid),
                          ),
                          _DeleteIconButton(
                            isDeleting: isDeleting,
                            isDisabled: isDeleting || isEditing,
                            onPressed: () => onDelete(tid),
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
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
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
                          '$totalItems TID${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
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
                  'Crear TID',
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

class _TidsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TidsError({required this.message, required this.onRetry});

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
                'No se pudieron cargar los TIDs',
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

class _TidsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _TidsEmpty({required this.onRetry});

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
              'No hay TIDs para mostrar.',
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

// ── Helpers ────────────────────────────────────────────────────────────────────

String _eventoLabel(TidModel tid, Map<int, String> eventoNames) {
  if (tid.idEvento == 0) return 'Sin evento';
  if (tid.eventoNombre != null && tid.eventoNombre!.trim().isNotEmpty) {
    return 'Evento: ${tid.eventoNombre}';
  }
  final nombre = eventoNames[tid.idEvento];
  if (nombre != null && nombre.trim().isNotEmpty) return 'Evento: $nombre';
  return 'Evento #${tid.idEvento}';
}

String? _standLabel(TidModel tid, Map<int, String> standNames) {
  if (tid.idStand == null) return null;
  final nombre = standNames[tid.idStand];
  if (nombre != null && nombre.trim().isNotEmpty) return 'Stand: $nombre';
  return null;
}

// ── Tile de TID ────────────────────────────────────────────────────────────────

class _TidListTile extends StatelessWidget {
  final TidModel tid;
  final Map<int, String> eventoNames;
  final Map<int, String> standNames;
  final Widget? trailingWidget;
  final VoidCallback? onViewAffiliations;

  const _TidListTile({
    required this.tid,
    this.eventoNames = const {},
    this.standNames = const {},
    this.trailingWidget,
    this.onViewAffiliations,
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
              Icons.track_changes_outlined,
              color: _green,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tid.tid.isNotEmpty ? tid.tid : 'Sin TID',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _eventoLabel(tid, eventoNames),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                  ),
                ),
                if (_standLabel(tid, standNames) case final standLbl?) ...[
                  const SizedBox(height: 1),
                  Text(
                    standLbl,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onViewAffiliations,
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
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
        ],
      ),
    );
  }
}

// ── Botón QR ───────────────────────────────────────────────────────────────────

class _QrIconButton extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onPressed;

  const _QrIconButton({
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ver QR del TID',
      onPressed: isDisabled ? null : onPressed,
      icon: Icon(
        Icons.qr_code_rounded,
        color: isDisabled ? _green.withValues(alpha: 0.30) : _green,
        size: 20,
      ),
    );
  }
}

// ── Botón editar ───────────────────────────────────────────────────────────────

class _EditIconButton extends StatelessWidget {
  final bool isEditing;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _EditIconButton({
    required this.isEditing,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Editar TID',
      onPressed: isDisabled ? null : onPressed,
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
              color: isDisabled ? _green.withValues(alpha: 0.30) : _green,
              size: 20,
            ),
    );
  }
}

// ── Botón borrar ───────────────────────────────────────────────────────────────

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
      tooltip: 'Eliminar TID',
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
              color: isDisabled ? _errorRed.withValues(alpha: 0.30) : _errorRed,
              size: 20,
            ),
    );
  }
}
