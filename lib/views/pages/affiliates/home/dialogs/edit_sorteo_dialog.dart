import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/views/pages/admin/raffles/create_raffle.dart';
import 'package:flutter/material.dart';

class EditSorteoDialog extends StatelessWidget {
  final RaffleModel raffle;

  const EditSorteoDialog({super.key, required this.raffle});

  static DateTime? _parseFecha(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20)),
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: 680, maxHeight: 760),
        child: SingleChildScrollView(
          child: CreateRaffleSection(
            showHeader: false,
            raffleId: raffle.id,
            initialText: raffle.text,
            initialCasinoGralId: raffle.casinoGralId,
            initialFechaFin: _parseFecha(raffle.fechaFin),
            initialMediaUrl: raffle.mediaUrl,
            initialCantidadGanadores: raffle.cantidadGanadores,
            initialPremios: raffle.premios,
            initialEmailPresentador: raffle.emailPresentador,
            initialInstrucciones: raffle.instrucciones,
            initialActivo: raffle.activo,
            onCreated: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
