import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoCasinosAvailablePage extends StatelessWidget {
  final bool preview;

  const NoCasinosAvailablePage({super.key, this.preview = false});

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0E0E0E);
    const green = AppConstants.primaryGreen;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícono
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: green.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_off_outlined,
                    color: green,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                const Text(
                  'No hay casinos disponibles\nen tu provincia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: green,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje informativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: green.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    'Igualmente te vamos a afiliar a BoomBet y, cuando haya casinos disponibles, la afiliación se va a completar automáticamente.\n\nDe todas formas, tendrás acceso a todos los beneficios que incluye la app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label: 'Volver al login',
                  onPressed: preview
                      ? () {}
                      : () => context.go('/'),
                  disabled: preview,
                  icon: Icons.arrow_back_rounded,
                  borderRadius: AppConstants.borderRadius,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
