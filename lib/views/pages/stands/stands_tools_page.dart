import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandsToolsPage extends StatelessWidget {
  const StandsToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              'Para volver atrás tenés que cerrar sesión. ¿Querés hacerlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (shouldLogout == true && context.mounted) {
          await AuthService().logout();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.darkBg,
        body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              children: [
                _StandPrimaryActionButton(
                  title: 'Premios',
                  subtitle: 'Consultar y gestionar premios del puesto',
                  icon: Icons.card_giftcard_outlined,
                  onTap: () => context.push('/stand-tools/prizes'),
                ),
                const SizedBox(height: 12),
                _StandPrimaryActionButton(
                  title: 'Ruletas',
                  subtitle: 'Ver ruletas disponibles en el puesto',
                  icon: Icons.casino_outlined,
                  onTap: () => context.push('/stand-tools/roulettes'),
                ),
                const SizedBox(height: 12),
                _StandPrimaryActionButton(
                  title: 'Escanear QR',
                  subtitle: 'Escanear código QR de un cliente',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => context.push('/stand-tools/scanner'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (dlgCtx) => AlertDialog(
                          title: const Text('¿Cerrar sesión?'),
                          content: const Text('¿Querés cerrar sesión?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dlgCtx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dlgCtx).pop(true),
                              child: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      );
                      if (shouldLogout == true && context.mounted) {
                        await AuthService().logout();
                        if (context.mounted) {
                          context.go('/');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.errorRed,
                      side: BorderSide(
                        color: AppConstants.errorRed.withValues(alpha: 0.40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ── Primary Action Button ────────────────────────────────────────────────────

class _StandPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _StandPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: green.withValues(alpha: 0.20)),
                ),
                child: Icon(icon, color: green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: green.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
