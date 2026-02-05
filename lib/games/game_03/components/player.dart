import 'package:flame/components.dart';

class PlayerComponent extends SpriteComponent {
  PlayerComponent({
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
    required this.jumpVelocity,
    required this.moveSpeed,
  }) : super(
         position: position,
         size: size,
         sprite: sprite,
         anchor: Anchor.topLeft,
       );

  final double jumpVelocity;
  final double moveSpeed;
  final Vector2 velocity = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);

    final tiltFactor = (velocity.x / moveSpeed).clamp(-1.0, 1.0) as double;
    angle = tiltFactor * 0.22;

    final fallFactor =
        (velocity.y / (jumpVelocity * 1.2)).clamp(0.0, 1.0) as double;
    final squash = 1.0 - (0.18 * fallFactor);
    final stretch = 1.0 + (0.12 * fallFactor);
    scale = Vector2(stretch, squash);
  }
}
