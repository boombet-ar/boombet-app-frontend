import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/games/games_content.dart';
import 'package:flutter/material.dart';

/// Página de juegos sin header duplicado; el header vive en `GamesContent`.
class GamesPage extends StatelessWidget {
  const GamesPage({super.key, this.firstGameTutorialTargetKey});

  final GlobalKey? firstGameTutorialTargetKey;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppConstants.darkBg,
      child: SizedBox.expand(
        child: GamesContent(
          firstGameTutorialTargetKey: firstGameTutorialTargetKey,
        ),
      ),
    );
  }
}
