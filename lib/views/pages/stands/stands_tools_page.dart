import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/other/qr_scanner_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandsToolsPage extends StatelessWidget {
  const StandsToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: const MainAppBar(
        title: 'Panel del Stand',
        showBackButton: false,
        showLogo: true,
        showSettings: false,
        showProfileButton: false,
        showLogoutButton: true,
        showFaqButton: false,
        showExitButton: false,
        showAdminTools: false,
        showAffiliatesTools: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SectionHeaderWidget(
            title: 'Panel del Stand',
            subtitle: 'Acceso rápido a las herramientas del puesto.',
            icon: Icons.storefront_outlined,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              children: [
                _StandPrimaryActionButton(
                  title: 'Premios',
                  subtitle: 'Consultar y gestionar premios del puesto',
                  icon: Icons.card_giftcard_outlined,
                  onTap: () => context.go('/stand-tools/prizes'),
                ),
                const SizedBox(height: 12),
                _StandPrimaryActionButton(
                  title: 'Ruletas',
                  subtitle: 'Ver ruletas disponibles en el puesto',
                  icon: Icons.casino_outlined,
                  onTap: () => context.go('/stand-tools/roulettes'),
                ),
                const SizedBox(height: 12),
                _StandPrimaryActionButton(
                  title: 'Escanear QR',
                  subtitle: 'Escanear código QR de un cliente',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => Navigator.push(
                    context,
                    FadeRoute(page: const QrScannerPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
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
