import 'dart:ui';

import 'package:flame/components.dart';

import 'platform.dart';

class MovingPlatformComponent extends PlatformComponent {
  MovingPlatformComponent({
    required Vector2 position,
    required Vector2 size,
    required this.speed,
    this.direction = 1,
    bool isBreakable = true,
  }) : super(
         position: position,
         size: size,
         isBreakable: isBreakable,
         breaksOnTouch: false,
         color: const Color(0xFF3FA9F5),
       );

  final double speed;
  int direction;
}
