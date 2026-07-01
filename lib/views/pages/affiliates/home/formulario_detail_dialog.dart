import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Abre el popup de detalle de un formulario desde cualquier parte de la app.
Future<void> showFormularioDetailDialog(
  BuildContext context, {
  required FormularioModel form,
  String? eventoNombre,
  String? sorteoLabel,
  String? mediaUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => FormularioDetailDialog(
      form: form,
      eventoNombre: eventoNombre,
      sorteoLabel: sorteoLabel,
      mediaUrl: mediaUrl,
    ),
  );
}

class FormularioDetailDialog extends StatelessWidget {
  final FormularioModel form;
  final String? eventoNombre;
  final String? sorteoLabel;
  final String? mediaUrl;

  const FormularioDetailDialog({
    super.key,
    required this.form,
    this.eventoNombre,
    this.sorteoLabel,
    this.mediaUrl,
  });

  String get _link {
    if (form.sorteoId != null || form.tidId != null) {
      return '${ApiConfig.menuUrl}sorteoForm?formId=${form.id}${ApiConfig.mediaUrlParam(mediaUrl)}';
    }
    return '${ApiConfig.menuUrl}sorteoForm?formId=${form.id}';
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text(
        'Link copiado',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppConstants.primaryGreen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    final link = _link;

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                border: Border(
                  bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.dynamic_form_outlined,
                      color: green,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Formulario #${form.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (form.sorteoId != null)
                    _Chip(
                      icon: Icons.emoji_events_outlined,
                      label: sorteoLabel != null
                          ? 'Sorteo: $sorteoLabel'
                          : 'Sorteo #${form.sorteoId}',
                    )
                  else if (form.tidId != null)
                    _Chip(
                      icon: Icons.track_changes_outlined,
                      label: 'TID #${form.tidId}',
                    ),
                ],
              ),
            ),

            // ── Cuerpo ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Contraseña',
                    value: form.contrasena?.isNotEmpty == true
                        ? form.contrasena!
                        : '—',
                  ),
                  if (eventoNombre != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.event_note_outlined,
                      label: 'Evento',
                      value: eventoNombre!,
                    ),
                  ],
                  if (link.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _copyLink(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(9),
                          border:
                              Border.all(color: green.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: green.withValues(alpha: 0.65),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                link,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: green.withValues(alpha: 0.80),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: green.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Botón cerrar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  backgroundColor: green.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: green.withValues(alpha: 0.18)),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: green.withValues(alpha: 0.55)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12.5,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: green.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: green),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: green,
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
