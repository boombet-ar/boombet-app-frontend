import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Card expandible para un evento en la home del panel de afiliados.
///
/// Muestra conteos de entidades asociadas y botones de acción rápida.
class EventoCard extends StatefulWidget {
  final EventoModel evento;
  /// Llamado cuando se elimina el evento.
  final void Function(EventoModel)? onDelete;
  final void Function(EventoModel, bool)? onToggleActive;
  final bool isUpdating;
  final bool isDeleting;

  const EventoCard({
    super.key,
    required this.evento,
    this.onDelete,
    this.onToggleActive,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  @override
  State<EventoCard> createState() => _EventoCardState();
}

class _EventoCardState extends State<EventoCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  static final _dateFmt = DateFormat('dd/MM/yy');

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final ev = widget.evento;
    final isActive = ev.activo;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: _expanded
                ? green.withValues(alpha: 0.28)
                : green.withValues(alpha: 0.11),
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: green.withValues(alpha: 0.07),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (siempre visible) ─────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    // Ícono + estado
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? green.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isActive
                              ? green.withValues(alpha: 0.20)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.event_note_outlined,
                        color: isActive
                            ? green
                            : Colors.white.withValues(alpha: 0.30),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre + fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _StatusBadge(active: isActive),
                              if (ev.fechaFin != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Fin: ${_formatFecha(ev.fechaFin!)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: green.withValues(alpha: 0.55),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Contenido expandido ──────────────────────────────────────
            if (_expanded) ...[
              Divider(
                height: 1,
                color: green.withValues(alpha: 0.10),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones secundarios
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '/affiliates-tools/eventos/${ev.id}',
                              extra: ev,
                            ),
                            icon: const Icon(Icons.bar_chart_rounded, size: 14),
                            label: const Text('Estadísticas',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.white.withValues(alpha: 0.65),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Toggle activo
                        if (widget.onToggleActive != null)
                          _IconAction(
                            icon: isActive
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            color: isActive
                                ? Colors.orange.withValues(alpha: 0.70)
                                : green.withValues(alpha: 0.70),
                            loading: widget.isUpdating,
                            onTap: () =>
                                widget.onToggleActive!(ev, !isActive),
                          ),
                        const SizedBox(width: 8),
                        // Eliminar
                        if (widget.onDelete != null)
                          _IconAction(
                            icon: Icons.delete_outline_rounded,
                            color: AppConstants.errorRed.withValues(alpha: 0.70),
                            loading: widget.isDeleting,
                            onTap: () => widget.onDelete!(ev),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fechaStr) {
    try {
      final dt = DateTime.parse(fechaStr);
      return _dateFmt.format(dt);
    } catch (_) {
      return fechaStr;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? green.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active
              ? green.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: green.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.65),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            active ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: active ? green : Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;
  const _IconAction({
    required this.icon,
    required this.color,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, color: color, size: 16),
      ),
    );
  }
}
