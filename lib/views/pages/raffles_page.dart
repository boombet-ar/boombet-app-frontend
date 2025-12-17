import 'package:boombet_app/views/pages/home_page.dart' show buildSectionHeader;
import 'package:flutter/material.dart';

class RafflesPage extends StatelessWidget {
  const RafflesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader(
              'Sorteos',
              'Próximamente disponibles',
              Icons.card_giftcard,
              primaryGreen,
              isDark,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: _ComingSoonCard(
                icon: Icons.hourglass_bottom,
                title: 'Estamos armando los sorteos',
                subtitle:
                    'Muy pronto vas a poder participar por premios exclusivos. Déjanos pulir la experiencia para que valga la pena.',
                accent: primaryGreen,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;

  const _ComingSoonCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgStart = isDark ? Colors.grey[900]! : Colors.white;
    final bgEnd = isDark ? Colors.grey[850]! : Colors.grey[100]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgStart, bgEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximamente',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Funcionalidad en preparación',
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Notificaremos cuando esté listo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
