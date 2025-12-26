import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Componente para crear shake de cámara
class CameraShake {
  static Vector2 offset = Vector2.zero();
  static double _intensity = 0;
  static double _duration = 0;
  static double _elapsed = 0;
  static final Random _rand = Random();

  /// Inicia un shake de cámara
  /// [intensity] - Intensidad del shake (0-1)
  /// [duration] - Duración en segundos
  static void shake({double intensity = 0.5, double duration = 0.3}) {
    _intensity = intensity * 8; // Multiplicador para amplitud
    _duration = duration;
    _elapsed = 0;
  }

  /// Actualiza el shake (llamar en cada frame)
  static void update(double dt) {
    if (_elapsed >= _duration) {
      offset = Vector2.zero();
      return;
    }

    _elapsed += dt;
    final progress = _elapsed / _duration;
    final currentIntensity = _intensity * (1 - progress); // Decay

    offset = Vector2(
      (_rand.nextDouble() - 0.5) * currentIntensity * 2,
      (_rand.nextDouble() - 0.5) * currentIntensity * 2,
    );
  }

  /// Resetea el shake
  static void reset() {
    offset = Vector2.zero();
    _intensity = 0;
    _duration = 0;
    _elapsed = 0;
  }
}
