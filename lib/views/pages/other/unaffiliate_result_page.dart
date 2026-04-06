import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnaffiliateResultPage extends StatelessWidget {
  final bool preview;

  const UnaffiliateResultPage({super.key, this.preview = false});

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0E0E0E);
    const green = AppConstants.primaryGreen;
    const red = Color(0xFFFF4D4D);

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
                // Ícono de desafiliación
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: red.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: red,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),

                // Línea decorativa separadora
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      color: red.withValues(alpha: 0.20),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 28,
                      height: 1,
                      color: red.withValues(alpha: 0.20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'Fuiste desafiliado de BoomBet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: red.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Text(
                    'Lamentamos que te vayas. Te desafiliamos de nuestra plataforma.\n\nEsto no te desafilia de los casinos asociados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.60),
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
                  backgroundColor: green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
