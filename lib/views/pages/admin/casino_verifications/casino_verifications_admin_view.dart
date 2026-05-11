import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/pending_verification_model.dart';
import 'package:flutter/material.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

class CasinoVerificationsAdminView extends StatelessWidget {
  final List<PendingVerification> items;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> approvingIds;
  final Set<int> rejectingIds;
  final VoidCallback onRetry;
  final void Function(PendingVerification) onApprove;
  final void Function(PendingVerification) onReject;

  const CasinoVerificationsAdminView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.approvingIds,
    required this.rejectingIds,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: _green, strokeWidth: 2.5),
                ),
              )
            else if (errorMessage != null)
              _ErrorState(message: errorMessage!, onRetry: onRetry)
            else if (items.isEmpty)
              _EmptyState(onRetry: onRetry)
            else ...[
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VerificationTile(
                    item: item,
                    isApproving: approvingIds.contains(item.id),
                    isRejecting: rejectingIds.contains(item.id),
                    onApprove: () => onApprove(item),
                    onReject: () => onReject(item),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _InfoBar(total: items.length),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tile ───────────────────────────────────────────────────────────────────

class _VerificationTile extends StatelessWidget {
  final PendingVerification item;
  final bool isApproving;
  final bool isRejecting;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationTile({
    required this.item,
    required this.isApproving,
    required this.isRejecting,
    required this.onApprove,
    required this.onReject,
  });

  bool get _isBusy => isApproving || isRejecting;

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
            child: const Icon(Icons.person_outline_rounded, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.casinoUserId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.check_rounded,
            color: _green,
            isLoading: isApproving,
            isDisabled: _isBusy,
            onTap: onApprove,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.close_rounded,
            color: _errorRed,
            isLoading: isRejecting,
            isDisabled: _isBusy,
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isDisabled ? 0.12 : 0.30),
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: color.withValues(alpha: 0.7),
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: color.withValues(alpha: isDisabled ? 0.30 : 1.0),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Info bar ───────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final int total;
  const _InfoBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _green.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _green.withValues(alpha: 0.70), size: 16),
          const SizedBox(width: 10),
          Text(
            '$total verificación${total == 1 ? '' : 'es'} pendiente${total == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.50),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estados ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
              const Icon(Icons.error_outline_rounded, color: _errorRed, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No se pudieron cargar las verificaciones',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

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
          Icon(Icons.inbox_outlined, color: _green.withValues(alpha: 0.55), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No hay verificaciones pendientes.',
              style: TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(7),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
