import 'dart:ui' show FilterQuality, Paint;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game_01.dart';

class ColumnComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<Game01> {
  ColumnComponent({
    required this.capNearGap,
    required this.mid,
    required this.capFarFromGap,
    required this.heightPx,
    this.widthFactor = 2.3,
    this.midWidthFactor = 0.82,
    this.speed = 200,
  });

  final Sprite capNearGap;
  final Sprite mid;
  final Sprite capFarFromGap;

  final double heightPx;
  final double widthFactor;
  final double midWidthFactor;
  final double speed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final width = mid.srcSize.x * widthFactor;
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
      )..debugMode = false,
    );

    SpriteComponent part(
      Sprite s,
      double y, {
      double? widthOverride,
      double xOffset = 0,
    }) {
      return SpriteComponent(
        sprite: s,
        position: Vector2(xOffset, y),
        size: Vector2(widthOverride ?? width, s.srcSize.y),
        anchor: Anchor.topLeft,
        paint: Paint()..filterQuality = FilterQuality.none,
      );
    }

    double y = 0;

    // Cap lejano al gap (ancho completo)
    add(part(capFarFromGap, y));
    y += capFarH;

    // Mid estrechado para dar forma de tubo
    final midW = width * midWidthFactor;
    final midX = (width - midW) / 2;

    // Mid tileable
    while (y + capNearH < heightPx) {
      add(part(mid, y, widthOverride: midW, xOffset: midX));
      y += midH;
    }

    // Si queda un espacio pequeño, rellenar con un tile extra antes del cap
    if (y < heightPx - capNearH) {
      add(part(mid, y, widthOverride: midW, xOffset: midX));
    }

    // Cap cercano al gap
    add(part(capNearGap, heightPx - capNearH));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused || gameRef.isGameOver) {
      return;
    }

    position.x -= speed * dt;

    if (position.x + size.x < 0) {
      removeFromParent();
    }
  }
}
