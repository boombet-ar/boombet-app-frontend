import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class Ground extends PositionComponent with CollisionCallbacks {
  Ground({required double y, required double width, double height = 24}) {
    position = Vector2(0, y);
    size = Vector2(width, height);
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox()
        ..collisionType = CollisionType.passive
        ..debugMode = false,
    );
  }
}
