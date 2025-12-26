import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import '../game_01.dart';

class ParallaxBackground extends ParallaxComponent {
  ParallaxBackground() : super();

  static const double _baseVelocity = 24.0;
  static const double _velocityMultiplier = 0.45;

  Game01 get game => parent as Game01;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    parallax = await Parallax.load(
      [
        ParallaxImageData('games/game_01/backgrounds/bg_far.png'),
        ParallaxImageData('games/game_01/backgrounds/bg_mid.png'),
        ParallaxImageData('games/game_01/backgrounds/bg_near.png'),
      ],
      baseVelocity: Vector2(_baseVelocity, 0),
      velocityMultiplierDelta: Vector2(_velocityMultiplier, 0),
    );

    size = game.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Ajustar velocidad del parallax según la velocidad del jugador
    if (game.player != null && !game.isGameOver && !game.isPaused) {
      final playerVelocity = game.player!.velocity.abs();
      final speedFactor = (playerVelocity / 600).clamp(0.5, 2.0);

      parallax?.baseVelocity = Vector2(_baseVelocity * speedFactor, 0);
    }
  }
}
