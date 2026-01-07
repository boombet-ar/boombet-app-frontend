import 'package:boombet_app/games/game_02/components/game_over_overlay.dart';
import 'package:boombet_app/games/game_02/game_02.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Game02Page extends StatefulWidget {
  const Game02Page({super.key});

  @override
  State<Game02Page> createState() => _Game02PageState();
}

class _Game02PageState extends State<Game02Page> {
  late Game02 _game;
  StackResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _game = Game02(onGameOver: _handleGameOver);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleGameOver(StackResult result) {
    setState(() {
      _lastResult = result;
    });
  }

  void _restartGame() {
    _game.overlays.remove(Game02.overlayGameOver);
    _game.restart();
    setState(() {
      _lastResult = null;
    });
  }

  Widget _buildGameView() {
    final gameView = GameWidget<Game02>(
      game: _game,
      overlayBuilderMap: {
        Game02.overlayGameOver: (_, __) => GameOverOverlay(
          score: _lastResult?.score ?? 0,
          best: _lastResult?.best ?? _game.bestScore,
          onRestart: _restartGame,
        ),
      },
    );

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(aspectRatio: 9 / 16, child: gameView),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: gameView),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameView();
  }
}
