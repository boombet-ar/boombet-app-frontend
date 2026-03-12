import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandsToolsPage extends StatelessWidget {
  const StandsToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

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
                  accentColor: accentColor,
                  onTap: () => context.go('/stand-tools/prizes'),
                ),
                const SizedBox(height: 12),
                _StandPrimaryActionButton(
                  title: 'Ruletas',
                  subtitle: 'Ver ruletas disponibles en el puesto',
                  icon: Icons.casino_outlined,
                  accentColor: accentColor,
                  onTap: () => context.go('/stand-tools/roulettes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _StandPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
