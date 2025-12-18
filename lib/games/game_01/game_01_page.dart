import 'package:boombet_app/games/game_01/game_01.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class Game01Page extends StatefulWidget {
  const Game01Page({super.key});

  @override
  State<Game01Page> createState() => _Game01PageState();
}

class _Game01PageState extends State<Game01Page> {
  late Game01 game;

  @override
  void initState() {
    super.initState();
    game = Game01();
  }

  void restartGame() {
    setState(() {
      game = Game01();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GameWidget(
          game: game,
          overlayBuilderMap: {
            'hud': (_, Game01 g) => _HudOverlay(game: g),
            'gameOver': (_, Game01 g) => _GameOverOverlay(
                  game: g,
                  onRestart: restartGame,
                ),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final Game01 game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ValueListenableBuilder<int>(
          valueListenable: game.score,
          builder: (_, value, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Score: $value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.game,
    required this.onRestart,
  });

  final Game01 game;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: game.score,
              builder: (_, value, __) => Text(
                'Final score: $value',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onRestart,
                  child: const Text('Restart'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
