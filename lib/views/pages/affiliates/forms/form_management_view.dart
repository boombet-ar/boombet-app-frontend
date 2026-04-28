import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _green = AppConstants.primaryGreen;
const _cardBg = Color(0xFF141414);
const _errorRed = AppConstants.errorRed;

class FormsManagementView extends StatelessWidget {
  final List<FormularioModel> items;
  final int totalItems;
  final bool isLoading;
  final String? errorMessage;
  final Set<int> deletingIds;
  final VoidCallback onRetry;
  final void Function(FormularioModel) onDelete;
  final Map<int, String> tidCodesById;
  final Map<int, String> sorteoCodesById;

  const FormsManagementView({
    super.key,
    required this.items,
    required this.totalItems,
    required this.isLoading,
    required this.errorMessage,
    required this.deletingIds,
    required this.onRetry,
    required this.onDelete,
    required this.tidCodesById,
    required this.sorteoCodesById,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
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
                _FormsError(message: errorMessage!, onRetry: onRetry)
              else if (items.isEmpty)
                _FormsEmpty(onRetry: onRetry)
              else ...[
                ...items.map((form) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FormListTile(
                        item: form,
                        isDeleting: deletingIds.contains(form.id),
                        onDelete: () => onDelete(form),
                        tidLabel: form.tidId != null
                            ? (tidCodesById[form.tidId] ?? '#${form.tidId}')
                            : null,
                        sorteoLabel: form.sorteoId != null
                            ? (sorteoCodesById[form.sorteoId] ??
                                '#${form.sorteoId}')
                            : null,
                      ),
                    )),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: _green.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: _green.withValues(alpha: 0.70), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$totalItems formulario${totalItems == 1 ? '' : 's'} registrado${totalItems == 1 ? '' : 's'}',
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

class _FormCreateButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FormCreateButton({required this.onTap});

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
                child: const Icon(Icons.dynamic_form_outlined,
                    color: _green, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Crear formulario',
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
                child:
                    const Icon(Icons.add_rounded, color: _green, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de formulario ─────────────────────────────────────────────────────────

class _FormListTile extends StatefulWidget {
  final FormularioModel item;
  final bool isDeleting;
  final VoidCallback onDelete;
  final String? tidLabel;
  final String? sorteoLabel;

  const _FormListTile({
    required this.item,
    required this.isDeleting,
    required this.onDelete,
    this.tidLabel,
    this.sorteoLabel,
  });

  @override
  State<_FormListTile> createState() => _FormListTileState();
}

class _FormListTileState extends State<_FormListTile> {
  bool _passwordVisible = false;

  void _copyPassword() {
    final pwd = widget.item.contrasena ?? '';
    if (pwd.isEmpty) return;
    Clipboard.setData(ClipboardData(text: pwd));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Contraseña copiada',
          style:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      backgroundColor: _green,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  String _buildLink() {
    if (widget.item.sorteoId != null || widget.item.tidId != null) {
      return '${ApiConfig.menuUrl}sorteoForm?formId=${widget.item.id}';
    }
    return '';
  }

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Link copiado al portapapeles',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      backgroundColor: _green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pwd = widget.item.contrasena ?? '';
    final displayPwd =
        _passwordVisible ? pwd : ('•' * pwd.length.clamp(6, 20));
    final link = _buildLink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila superior: ícono + ID + badge vinculo + delete ──────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.20)),
                ),
                child: const Icon(Icons.dynamic_form_outlined,
                    color: _green, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Formulario #${widget.item.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const Spacer(),
              // Badge: TID o Sorteo
              if (widget.tidLabel != null)
                _VinculoBadge(
                  icon: Icons.track_changes_outlined,
                  label: 'TID',
                  value: widget.tidLabel!,
                )
              else if (widget.sorteoLabel != null)
                _VinculoBadge(
                  icon: Icons.emoji_events_outlined,
                  label: 'Sorteo',
                  value: widget.sorteoLabel!,
                ),
              const SizedBox(width: 8),
              if (widget.isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _errorRed),
                )
              else
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                      border:
                          Border.all(color: _errorRed.withValues(alpha: 0.30)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _errorRed, size: 15),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Contraseña ─────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: _green.withValues(alpha: 0.60)),
                const SizedBox(width: 7),
                Text(
                  'Contraseña: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                  ),
                ),
                Expanded(
                  child: Text(
                    pwd.isEmpty ? '—' : displayPwd,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pwd.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                    child: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: _green.withValues(alpha: 0.60),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _copyPassword,
                    child: Icon(Icons.copy_outlined,
                        size: 15, color: _green.withValues(alpha: 0.60)),
                  ),
                ],
              ],
            ),
          ),

          if (link.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _copyLink(context, link),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 13, color: _green.withValues(alpha: 0.60)),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        link,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _green.withValues(alpha: 0.80),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded,
                        size: 12, color: _green.withValues(alpha: 0.55)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Badge de vínculo ───────────────────────────────────────────────────────────

class _VinculoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VinculoBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _green.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: _green.withValues(alpha: 0.70)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label: $value',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _green.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error ──────────────────────────────────────────────────────────────────────

class _FormsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FormsError({required this.message, required this.onRetry});

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
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: _errorRed, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudieron cargar los formularios',
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
          Text(message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 12,
                height: 1.4,
              )),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _errorRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _errorRed.withValues(alpha: 0.30)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _errorRed, size: 14),
                    SizedBox(width: 6),
                    Text('Reintentar',
                        style: TextStyle(
                            color: _errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
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

// ── Vacío ──────────────────────────────────────────────────────────────────────

class _FormsEmpty extends StatelessWidget {
  final VoidCallback onRetry;
  const _FormsEmpty({required this.onRetry});

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
          Icon(Icons.dynamic_form_outlined,
              color: _green.withValues(alpha: 0.55), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay formularios para mostrar.',
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
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border:
                      Border.all(color: _green.withValues(alpha: 0.20)),
                ),
                child: const Text('Refrescar',
                    style: TextStyle(
                        color: _green,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
