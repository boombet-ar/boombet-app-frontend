import 'dart:ui' show FilterQuality, Paint;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

class ColumnComponent extends PositionComponent with CollisionCallbacks {
  ColumnComponent({
    required this.capNearGap,
    required this.mid,
    required this.capFarFromGap,
    required this.heightPx,
    this.speed = 200,
  });

  final Sprite capNearGap;
  final Sprite mid;
  final Sprite capFarFromGap;

  final double heightPx;
  final double speed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final width = mid.srcSize.x;
    final capNearH = capNearGap.srcSize.y;
    final midH = mid.srcSize.y;
    final capFarH = capFarFromGap.srcSize.y;

    size = Vector2(width, heightPx);
    anchor = Anchor.topLeft;

    // ✅ HITBOX EXACTA DEL TAMAÑO TOTAL
    add(
      RectangleHitbox(
        size: size,
        position: Vector2.zero(),
        collisionType: CollisionType.passive,
      )..debugMode = true,
    );

    SpriteComponent part(Sprite s, double y) {
      return SpriteComponent(
        sprite: s,
        position: Vector2(0, y),
        size: Vector2(width, s.srcSize.y),
        anchor: Anchor.topLeft,
        paint: Paint()..filterQuality = FilterQuality.none,
      );
    }

    double y = 0;

    // Cap lejano al gap
    add(part(capFarFromGap, y));
    y += capFarH;

    // Mid tileable
    while (y + capNearH < heightPx) {
      add(part(mid, y));
      y += midH;
    }

    // Cap cercano al gap
    add(part(capNearGap, heightPx - capNearH));
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.x -= speed * dt;

    if (position.x + size.x < 0) {
      removeFromParent();
    }
  }
}
