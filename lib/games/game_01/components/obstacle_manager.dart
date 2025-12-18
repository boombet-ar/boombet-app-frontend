import 'package:boombet_app/games/game_01/game_01.dart';
import 'package:flame/components.dart';
import 'obstacle_pair.dart';

class ObstacleManager extends Component with HasGameRef<Game01> {
  ObstacleManager(
    this.gameSize, {
    required this.topSprite,
    required this.midSprite,
    required this.bottomSprite,
  });

  final Vector2 gameSize;
  final Sprite topSprite;
  final Sprite midSprite;
  final Sprite bottomSprite;

  double timer = 0;
  final double spawnInterval = 2;

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameOver) return;

    timer += dt;

    if (timer >= spawnInterval) {
      add(
        ObstaclePair(
          gameSize: gameSize,
          topSprite: topSprite,
          midSprite: midSprite,
          bottomSprite: bottomSprite,
        ),
      );
      timer = 0;
    }
  }
}
