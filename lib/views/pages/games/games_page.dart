import 'package:boombet_app/views/pages/home/widgets/games_content.dart';
import 'package:flutter/material.dart';

/// Página de juegos sin header duplicado; el header vive en `GamesContent`.
class GamesPage extends StatelessWidget {
  const GamesPage({super.key, this.firstGameTutorialTargetKey});

  final GlobalKey? firstGameTutorialTargetKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0A0A0A),
      child: GamesContent(
        firstGameTutorialTargetKey: firstGameTutorialTargetKey,
      ),
    );
  }
}
