import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/views/pages/affiliates/home/evento_card.dart';
import 'package:flutter/material.dart';

/// Tab "Eventos" de la home del panel de afiliados.
class EventosTab extends StatelessWidget {
  final List<EventoModel> eventos;
  final Set<int> updatingIds;
  final Set<int> deletingIds;
  final void Function(EventoModel, bool) onToggleActive;
  final void Function(EventoModel) onDelete;

  const EventosTab({
    super.key,
    required this.eventos,
    required this.updatingIds,
    required this.deletingIds,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) {
      return const _EmptyEventsState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: eventos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final ev = eventos[i];
        return EventoCard(
          evento: ev,
          isUpdating: updatingIds.contains(ev.id),
          isDeleting: deletingIds.contains(ev.id),
          onToggleActive: onToggleActive,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState();

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: green.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.20),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.event_note_outlined,
                color: green,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin eventos todavía',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tocá el ✦ para crear tu primer evento\ncompleto con sorteo, formulario y TIDs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 13,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            // Hint visual — flecha apuntando al FAB
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: green.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: green.withValues(alpha: 0.70),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Wizard de creación',
                        style: TextStyle(
                          color: green.withValues(alpha: 0.80),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
