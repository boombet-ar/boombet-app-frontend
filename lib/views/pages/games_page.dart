import 'package:boombet_app/views/pages/home/widgets/games_content.dart';
import 'package:flutter/material.dart';

/// Página de juegos sin header duplicado; el header vive en `GamesContent`.
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      child: const GamesContent(),
    );
  }
}
