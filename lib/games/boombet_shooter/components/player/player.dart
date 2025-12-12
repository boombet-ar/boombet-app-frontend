// player.dart
import 'dart:developer';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../game.dart';

import 'player_controller.dart';
import 'player_health.dart';
import 'player_powerups.dart';
import 'player_shooting.dart';

class Player extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  Player() : super(size: Vector2(32, 32), anchor: Anchor.center, priority: 10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    // ============================================================
    // 1) Cargar sprite correctamente (ruta relativa a assets declarados)
    // ============================================================
    try {
      sprite = await Sprite.load(
        'games/boombet_shooter/sprites/player/player.png',
      );
      debugPrint('Player sprite loaded successfully');
    } catch (e) {
      debugPrint('Error loading player sprite: $e');
      sprite = await _solidColorSprite(const Color(0xFF00FF00));
    }

    // ============================================================
    // 2) Agregar Hitbox (cuadrado) — versión correcta Flame
    // ============================================================
    add(
      RectangleHitbox.relative(
        Vector2(0.85, 0.85), // 85% del tamaño → mejor colisiones
        parentSize: size,
        collisionType: CollisionType.active,
      ),
    );

    // ============================================================
    // 3) Agregar los 4 componentes Unity-style
    // ============================================================
    add(PlayerController());
    add(PlayerHealth());
    add(PlayerPowerups());
    add(PlayerShooting());

    // ============================================================
    // 4) Posición inicial similar a Unity
    // ============================================================
    position = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.8);

    debugMode = true; // TEMPORAL: mostrar hitbox para debug
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
