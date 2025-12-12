import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

/// DifficultyManager mejorado:
/// - difficulty01 siempre es 0..1 (ideal para UI)
/// - effectiveDifficulty puede superar 1.0 en Overdrive
/// - multiplicadores usan effectiveDifficulty en lugar de difficulty01
class DifficultyManager extends Component {
  DifficultyManager({
    this.timeToMaxDifficulty = 180, // 3 minutos
    this.enableOverdrive = true,
    this.overdriveRampDuration = 120, // +2 minutos para llegar a x1.5 real
    this.difficultyCurve = Curves.easeInOut,
  });

  // Singleton
  static DifficultyManager? _instance;
  static DifficultyManager get instance => _instance!;

  // Configuración general
  double timeToMaxDifficulty;
  bool enableOverdrive;
  double overdriveRampDuration;
  Curve difficultyCurve;

  // Estado
  double elapsedTime = 0;

  /// 0..1 (para UI, para game balance base)
  double difficulty01 = 0;

  /// 0..1.5 (incluye Overdrive real)
  double effectiveDifficulty = 0;

  // Multipliers dinámicos
  double enemySpeedMultiplier = 1;
  double shootIntervalMultiplier = 1;
  double spawnRateMultiplier = 1;
  double rareEnemyChance = 0;
  double minibossChance = 0;

  // Evento
  void Function(double)? onDifficultyChanged;
  double _lastDifficultyNotified = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _instance = this;
  }

  @override
  void update(double dt) {
    super.update(dt);

    elapsedTime += dt;

    // Fase normal (0..1)
    final tNorm = (elapsedTime / timeToMaxDifficulty).clamp(0.0, 1.0);
    final curved = difficultyCurve.transform(tNorm);

    difficulty01 = curved;

    // Overdrive (opcional)
    if (enableOverdrive) {
      final extraTime = max(0.0, elapsedTime - timeToMaxDifficulty);
      final od = (extraTime / overdriveRampDuration).clamp(0.0, 1.0);
      effectiveDifficulty = curved + od * 0.5; // 1.0 → 1.5
    } else {
      effectiveDifficulty = curved;
    }

    // Generar multipliers usando la dificultad extendida
    _applyDifficultyMultipliers();

    // Notificación (cada 5%)
    if ((difficulty01 - _lastDifficultyNotified).abs() >= 0.05) {
      _lastDifficultyNotified = difficulty01;
      onDifficultyChanged?.call(difficulty01);
    }
  }

  // ---------------------------------------------------------------------------
  // Multipliers derivados de effectiveDifficulty
  void _applyDifficultyMultipliers() {
final d = effectiveDifficulty.clamp(0.0, 1.5) as double;

    // enemigos más rápidos ×2.5 → ×4.0 en overdrive
    enemySpeedMultiplier =
        _lerp(1.0, 2.5, (d.clamp(0.0, 1.0) as double)) +
        _lerp(0.0, 1.5, ((d - 1.0).clamp(0.0, 0.5) as double) * 2.0);

    // disparan más seguido
    shootIntervalMultiplier = _lerp(1.0, 0.4, d);

    // más spawneo
    spawnRateMultiplier = _lerp(1.0, 3.5, d);

    // rare enemies
    rareEnemyChance = _lerp(0.0, 0.35, d);

    // miniboss chance
    minibossChance = _lerp(0.0, 0.2, d);

  }

  // ---------------------------------------------------------------------------
  // Helpers públicos
  double getEnemySpeed(double base) => base * enemySpeedMultiplier;

  double getEnemyShootInterval(double base) => base * shootIntervalMultiplier;

  double getSpawnInterval(double base) => base / spawnRateMultiplier;

  bool shouldSpawnRareEnemy() => Random().nextDouble() < rareEnemyChance;

  bool shouldSpawnMiniBoss() => Random().nextDouble() < minibossChance;

  // ---------------------------------------------------------------------------
  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
