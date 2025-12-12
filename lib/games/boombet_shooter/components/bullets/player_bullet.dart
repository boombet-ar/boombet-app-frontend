import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../game.dart';
import '../player/player_shooting.dart' show PlayerBulletTag;

class PlayerBullet extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks, PlayerBulletTag {
  PlayerBullet({
    double speed = 400,
    int damage = 1,
    Vector2? size,
    this.spritePath = 'games/boombet_shooter/sprites/player/bullet_player.png',
  }) : speed = speed,
       damage = damage,
       super(
         size: size ?? Vector2(12, 24),
         anchor: Anchor.center,
         priority: 50,
       );

  final double speed;
  final int damage;
  final String spritePath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFFFFFFFF));
    }

    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y -= speed * dt;

    if (position.y + size.y * 0.5 < 0) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // El daño lo maneja el enemigo → acá solo desaparece la bala
    removeFromParent();
  }

  Future<Sprite> _solidColorSprite(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 8), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    return Sprite(image);
  }
}
