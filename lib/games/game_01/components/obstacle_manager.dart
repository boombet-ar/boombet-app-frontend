import 'package:boombet_app/games/game_01/game_01.dart';
import 'package:flame/components.dart';
import 'difficulty_manager.dart';
import 'obstacle_pair.dart';

class ObstacleManager extends Component with HasGameRef<Game01> {
  ObstacleManager(
    this.gameSize, {
    required this.topSprite,
    required this.midSprite,
  });

  final Vector2 gameSize;
  final Sprite topSprite;
  final Sprite midSprite;

  double timer = 0;
  final DifficultyManager difficulty = DifficultyManager();

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isPaused || game.isGameOver) return;

    difficulty.update(dt);
    final diff = difficulty.snapshot;
    timer += dt;

    if (timer >= diff.spawnInterval) {
      add(
        ObstaclePair(
          gameSize: gameSize,
          topSprite: topSprite,
          midSprite: midSprite,
          gap: diff.gap,
          speed: diff.speed,
          tubeWidthFactor: diff.tubeWidthFactor,
        ),
      );
      timer = 0;
    }
  }
}
