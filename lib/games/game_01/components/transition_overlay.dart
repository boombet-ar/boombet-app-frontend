import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Overlay para transiciones suaves con fade
class TransitionOverlay extends PositionComponent {
  TransitionOverlay({
    required Vector2 size,
    required this.duration,
    this.fadeIn = true,
    this.onComplete,
  }) : super(size: size, anchor: Anchor.topLeft, position: Vector2.zero());

  final double duration;
  final bool fadeIn;
  final VoidCallback? onComplete;

  double _elapsed = 0;
  bool _completed = false;

  @override
  void update(double dt) {
    super.update(dt);

    if (_completed) return;

    _elapsed += dt;

    if (_elapsed >= duration) {
      _elapsed = duration;
      _completed = true;
      onComplete?.call();

      // Auto-remover después del fade out
      if (!fadeIn) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (isMounted) removeFromParent();
        });
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final opacity = fadeIn ? (1 - progress) : progress;

    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
