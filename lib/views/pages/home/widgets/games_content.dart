import 'package:boombet_app/games/game_01/game_01_page.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';

class GamesContent extends StatelessWidget {
  const GamesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final games = [
      (
        title: 'Space Runner',
        subtitle: 'Arcade de reflejos',
        description:
            'Esquiva columnas, suma puntos y pausa cuando necesites un respiro.',
        badge: 'Nuevo',
        onPlay: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const Game01Page())),
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeaderWidget(
            title: 'Juegos',
            subtitle:
                'Explora los minijuegos de BoomBet y participa por grandes premios!',
            icon: Icons.videogame_asset,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: games
                  .map(
                    (g) => _GameCard(
                      title: g.title,
                      subtitle: g.subtitle,
                      description: g.description,
                      badge: g.badge,
                      primaryGreen: primaryGreen,
                      textColor: textColor,
                      onPlay: g.onPlay,
                      isDark: isDark,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.badge,
    required this.primaryGreen,
    required this.textColor,
    required this.onPlay,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Color primaryGreen;
  final Color textColor;
  final VoidCallback onPlay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryGreen.withValues(alpha: isDark ? 0.24 : 0.18),
              primaryGreen.withValues(alpha: isDark ? 0.1 : 0.08),
            ],
          ),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.videogame_asset, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        badge,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.38,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_esports,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jugar ahora',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.north_east,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 74,
                  width: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.9,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/pixel_logo.png',
                      fit: BoxFit.contain,
                    ),
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
