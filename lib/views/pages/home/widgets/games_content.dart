import 'package:boombet_app/games/game_01/game_01_page.dart';
import 'package:boombet_app/games/game_02/game_02_page.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GamesContent extends StatelessWidget {
  const GamesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final isWeb = kIsWeb;

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
        asset: 'assets/icons/game_01_icon.png',
      ),
      (
        title: 'Tower Stack',
        subtitle: 'Equilibrio y ritmo',
        description:
            'Apila bloques en movimiento para construir la torre más alta posible.',
        badge: 'Arcade',
        onPlay: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const Game02Page())),
        asset: 'assets/icons/game_02_icon.png',
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
            child: isWeb
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final maxExtent = (constraints.maxWidth * 0.33).clamp(
                        260.0,
                        420.0,
                      );

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: games.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxExtent,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final g = games[index];
                          return _GameGridCard(
                            title: g.title,
                            subtitle: g.subtitle,
                            badge: g.badge,
                            primaryGreen: primaryGreen,
                            onPlay: g.onPlay,
                            isDark: isDark,
                            asset: g.asset,
                          );
                        },
                      );
                    },
                  )
                : Column(
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
                            asset: g.asset,
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

class _GameGridCard extends StatelessWidget {
  const _GameGridCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.primaryGreen,
    required this.onPlay,
    required this.isDark,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color primaryGreen;
  final VoidCallback onPlay;
  final bool isDark;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : AppConstants.textLight;
    final fgSoft = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppConstants.textLight;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppConstants.borderLight.withValues(alpha: 0.7);
    final surfaceVariant = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppConstants.lightSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPlay,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryGreen.withValues(alpha: isDark ? 0.22 : 0.16),
                primaryGreen.withValues(alpha: isDark ? 0.1 : 0.07),
              ],
            ),
            border: Border.all(
              color: primaryGreen.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    color: surfaceVariant,
                    child: Image.asset(asset, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fgSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppConstants.lightSurfaceVariant,
                  border: Border.all(color: borderColor, width: 0.9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_esports, size: 18, color: fg),
                    const SizedBox(width: 8),
                    Text(
                      'Jugar',
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.north_east, size: 16, color: fg),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    required this.asset,
  });

  final String title;
  final String subtitle;
  final String description;
  final String badge;
  final Color primaryGreen;
  final Color textColor;
  final VoidCallback onPlay;
  final bool isDark;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final accentBg = isDark
        ? Colors.black.withValues(alpha: 0.08)
        : AppConstants.lightSurfaceVariant;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : AppConstants.borderLight.withValues(alpha: 0.7);
    final fg = isDark ? Colors.white : AppConstants.textLight;
    final fgSoft = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppConstants.textLight;

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
                    color: accentBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
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
                Icon(Icons.auto_awesome, color: fg, size: 18),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: fgSoft,
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
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.38,
                          color: fgSoft,
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
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppConstants.lightSurfaceVariant,
                          border: Border.all(color: borderColor, width: 0.9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_esports, size: 18, color: fg),
                            const SizedBox(width: 8),
                            Text(
                              'Jugar ahora',
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.north_east, size: 16, color: fg),
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppConstants.lightSurfaceVariant,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppConstants.borderLight.withValues(alpha: 0.7),
                      width: 0.9,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(asset, fit: BoxFit.contain),
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
