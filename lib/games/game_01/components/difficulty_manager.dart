import 'dart:math';

class DifficultySnapshot {
  const DifficultySnapshot({
    required this.gap,
    required this.spawnInterval,
    required this.speed,
    required this.tubeWidthFactor,
  });

  final double gap;
  final double spawnInterval;
  final double speed;
  final double tubeWidthFactor;
}

class DifficultyManager {
  double _elapsed = 0;

  // Baseline values (start easy, ramp in ~35s for short runs)
  final double _baseGap = 180;
  final double _minGap = 125;

  final double _baseSpawn = 1.9;
  final double _minSpawn = 1.05;

  final double _baseSpeed = 200;
  final double _maxSpeed = 320;

  // Fixed wide pipes across all difficulty
  final double _baseTubeWidth = 2.3;
  final double _maxTubeWidth = 2.3;

  final double _rampDuration = 45.0;

  void update(double dt) {
    _elapsed += dt;
  }

  DifficultySnapshot get snapshot {
    final progress = min(_elapsed / _rampDuration, 1.0); // Hardest at ~45s

    final gap = _lerp(_baseGap, _minGap, progress);
    final spawnInterval = _lerp(_baseSpawn, _minSpawn, progress);
    final speed = _lerp(_baseSpeed, _maxSpeed, progress);
    final tubeWidthFactor = _lerp(_baseTubeWidth, _maxTubeWidth, progress);

    return DifficultySnapshot(
      gap: gap,
      spawnInterval: spawnInterval,
      speed: speed,
      tubeWidthFactor: tubeWidthFactor,
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
