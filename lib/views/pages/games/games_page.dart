import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/games/games_content.dart';
import 'package:flutter/material.dart';

/// Página de juegos sin header duplicado; el header vive en `GamesContent`.
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppConstants.darkBg,
      child: SizedBox.expand(
        child: GamesContent(),
      ),
    );
  }
}
