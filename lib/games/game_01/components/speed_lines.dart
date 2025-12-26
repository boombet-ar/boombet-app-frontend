import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_01.dart';

/// Líneas de velocidad que aparecen cuando el jugador va rápido
class SpeedLines extends Component with HasGameRef<Game01> {
  final List<_SpeedLine> _lines = [];
  double _spawnTimer = 0;
  static const int _maxLines = 12;
  final Random _rand = Random();

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused || gameRef.isGameOver || gameRef.player == null) {
      return;
    }

    final velocity = gameRef.player!.velocity.abs();
    final speedFactor = (velocity / 800).clamp(0.0, 1.0);

    if (speedFactor < 0.3) {
      _lines.clear();
      return;
    }

    _spawnTimer += dt;
    final spawnRate = 0.05 - (speedFactor * 0.03); // Más rápido = más líneas

    if (_spawnTimer >= spawnRate && _lines.length < _maxLines) {
      _spawnTimer = 0;
      _spawnLine(speedFactor);
    }

    _lines.removeWhere((line) => !line.update(dt));
  }

  void _spawnLine(double speedFactor) {
    final y = _rand.nextDouble() * gameRef.size.y;
    final length = 30 + _rand.nextDouble() * 40 * speedFactor;
    final speed = 300 + _rand.nextDouble() * 200 * speedFactor;
    final opacity = (0.2 + speedFactor * 0.4).clamp(0.2, 0.6);

    _lines.add(
      _SpeedLine(
        startX: gameRef.size.x,
        y: y,
        length: length,
        speed: speed,
        opacity: opacity,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final line in _lines) {
      line.render(canvas);
    }
  }
}

class _SpeedLine {
  _SpeedLine({
    required this.startX,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
  }) : x = startX;

  double x;
  final double startX;
  final double y;
  final double length;
  final double speed;
  final double opacity;
  double life = 1.0;

  bool update(double dt) {
    x -= speed * dt;
    life -= dt * 2;
    return x + length > 0 && life > 0;
  }

  void render(Canvas canvas) {
    final currentOpacity = (opacity * life).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(currentOpacity)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, y), Offset(x + length, y), paint);
  }
}
