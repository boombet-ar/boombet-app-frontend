import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game_01.dart';

/// Trail de partículas constante que sigue al jugador
class ParticleTrail extends Component with HasGameRef<Game01> {
  ParticleTrail({required this.target});

  final PositionComponent target;
  double _timer = 0;
  static const double _spawnInterval = 0.04; // 25 partículas por segundo
  final Random _rand = Random();

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused || gameRef.isGameOver) return;

    _timer += dt;

    if (_timer >= _spawnInterval) {
      _timer = 0;
      _spawnTrailParticle();
    }
  }

  void _spawnTrailParticle() {
    if (!target.isMounted) return;

    final velocity = (target as dynamic).velocity ?? 0.0;
    final speed = velocity.abs() / 10; // Intensidad basada en velocidad
    final opacity = (0.3 + speed * 0.02).clamp(0.3, 0.7);

    gameRef.add(
      ParticleSystemComponent(
        position: target.position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: 1,
          lifespan: 0.4 + _rand.nextDouble() * 0.3,
          generator: (i) {
            final offset = Vector2(
              -8 + _rand.nextDouble() * 4,
              -4 + _rand.nextDouble() * 8,
            );
            return MovingParticle(
              from: offset,
              to: offset + Vector2(-20 - _rand.nextDouble() * 15, 0),
              curve: Curves.easeOut,
              child: CircleParticle(
                radius: 1.5 + _rand.nextDouble() * 1.5,
                paint: Paint()
                  ..color = const Color(0xFF00FFB3).withOpacity(opacity)
                  ..blendMode = BlendMode.plus,
              ),
            );
          },
        ),
      ),
    );
  }
}
