import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends ParallaxComponent with HasGameRef<FlameGame> {
  ParallaxBackground() : super();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    parallax = await Parallax.load(
      [
        ParallaxImageData('games/game_01/backgrounds/bg_far.png'),
        ParallaxImageData('games/game_01/backgrounds/bg_mid.png'),
        ParallaxImageData('games/game_01/backgrounds/bg_near.png'),
      ],
      baseVelocity: Vector2(24, 0),
      velocityMultiplierDelta: Vector2(0.45, 0),
    );

    size = gameRef.size; // ✅ ahora sí existe
    anchor = Anchor.topLeft;
    position = Vector2.zero();
  }
}
