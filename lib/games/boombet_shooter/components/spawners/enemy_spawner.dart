import 'dart:math';
import 'package:flame/components.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';

enum FormationType { single, row3, square4 }

/// Spawner de enemigos con formaciones, micro-olas y minibosses.
class EnemySpawner extends Component with HasGameRef<MyGame> {
  EnemySpawner({List<EnemyEntry>? enemyTypes}) : enemyTypes = enemyTypes ?? [];

  // Lista configurada desde MyGame
  List<EnemyEntry> enemyTypes;

  // Timings base
  double initialSpawnInterval = 1.5;
  double minSpawnInterval = 0.25;

  // Pesos para formaciones
  double singleWeight = 4;
  double row3Weight = 1;
  double square4Weight = 1;

  // Espaciados
  double horizontalSpacing = 32;
  double verticalSpacing = 26;

  // Zona segura para UI
  double safeZoneTop = 24;

  // Micro-olas
  bool enableMicroWaves = true;
  double microWaveInterval = 15;
  int microWaveEnemyGroups = 4;
  double microWaveDifficultyThreshold = 0.4;

  // MiniBoss
  bool enableMiniBoss = true;
  double minibossCooldown = 25;
  double _minibossTimer = 0;

  // Hyper Mode
  bool _hyperActive = false;
  double hyperSpawnMultiplier = 0.65;

  // Timers
  double _spawnTimer = 0;
  double _microWaveTimer = 0;
  bool _microWaveActive = false;
  int _microWaveCounter = 0;

  // Bounds
  late double _spawnY;
  late double _minX;
  late double _maxX;

  // Referencias
  DifficultyManager? _diff;
  GameManager? _gm;

  final _rand = Random();

  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();

    _spawnY = safeZoneTop;
    _minX = 0;
    _maxX = gameRef.size.x;

    _spawnTimer = initialSpawnInterval;
    _minibossTimer = minibossCooldown;
    _microWaveTimer = microWaveInterval;

    // Hyper Mode events
    final previousStart = _gm?.onHyperModeStart;
    final previousEnd = _gm?.onHyperModeEnd;

    _gm?.onHyperModeStart = () {
      previousStart?.call();
      _hyperActive = true;
    };
    _gm?.onHyperModeEnd = () {
      previousEnd?.call();
      _hyperActive = false;
    };
  }

  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    final d = _diff?.difficulty01 ?? 0;

    // MiniBoss timer
    _minibossTimer -= dt;
    if (enableMiniBoss && _minibossTimer <= 0) {
      _trySpawnMiniBoss();
      _minibossTimer = minibossCooldown / _lerp(1, 2.0, d);
    }

    // MicroWave start
    if (enableMicroWaves && d >= microWaveDifficultyThreshold) {
      _microWaveTimer -= dt;
      if (!_microWaveActive && _microWaveTimer <= 0) {
        _microWaveActive = true;
        _microWaveCounter = microWaveEnemyGroups;
        _microWaveTimer = microWaveInterval;
      }
    }

    // Spawn enemigos
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      if (_microWaveActive) {
        _spawnWave();
        _microWaveCounter--;
        if (_microWaveCounter <= 0) {
          _microWaveActive = false;
        }
        _spawnTimer = minSpawnInterval;
      } else {
        _spawnWave();

        double next =
            _diff?.getSpawnInterval(initialSpawnInterval) ??
            initialSpawnInterval;

        if (_hyperActive) next *= hyperSpawnMultiplier;

        _spawnTimer = next.clamp(minSpawnInterval, initialSpawnInterval);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MINI BOSS
  void _trySpawnMiniBoss() {
    if (_diff != null && !_diff!.shouldSpawnMiniBoss()) return;

    for (final entry in enemyTypes) {
      if (entry.isMiniBoss && entry.builder != null) {
        _spawnEnemy(
          entry.builder!(),
          Vector2(_randInRange(_minX, _maxX), _spawnY),
        );
        return;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // WAVE LOGIC
  void _spawnWave() {
    switch (_getDynamicFormation()) {
      case FormationType.single:
        _spawnSingle();
        break;
      case FormationType.row3:
        _spawnRow3();
        break;
      case FormationType.square4:
        _spawnSquare4();
        break;
    }
  }

  FormationType _getDynamicFormation() {
    final d = _diff?.difficulty01 ?? 0;

    final wSingle = _lerp(singleWeight, singleWeight * 0.2, d);
    final wRow = _lerp(row3Weight, row3Weight * 2.5, d);
    final wSquare = _lerp(square4Weight, square4Weight * 3.0, d);

    final total = wSingle + wRow + wSquare;
    final r = _rand.nextDouble() * total;

    if (r < wSingle) return FormationType.single;
    if (r < wSingle + wRow) return FormationType.row3;
    return FormationType.square4;
  }

  // ---------------------------------------------------------------------------
  // Selección de tipo de enemigo
  EnemyEntry? _getRandomEnemy({bool formationsOnly = false}) {
    final d = _diff?.difficulty01 ?? 0;

    double total = 0;
    for (final e in enemyTypes) {
      if (e.builder == null) continue;
      if (formationsOnly && !e.allowInFormations) continue;

      double w = e.weight;
      if (e.isRare) w *= _lerp(1, 4, d);

      total += w;
    }

    if (total <= 0) return null;

    double r = _rand.nextDouble() * total;

    for (final e in enemyTypes) {
      if (e.builder == null) continue;
      if (formationsOnly && !e.allowInFormations) continue;

      double w = e.weight;
      if (e.isRare) w *= _lerp(1, 4, d);

      if (r < w) return e;
      r -= w;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // FORMACIONES
  void _spawnSingle() {
    final entry = _getRandomEnemy(formationsOnly: false);
    if (entry?.builder == null) return;

    final x = _randInRange(_minX, _maxX);
    _spawnEnemy(entry!.builder!(), Vector2(x, _spawnY));
  }

  void _spawnRow3() {
    final entry = _getRandomEnemy(formationsOnly: true);
    if (entry?.builder == null) return;

    final minCenter = _minX + horizontalSpacing;
    final maxCenter = _maxX - horizontalSpacing;
    final centerX = (maxCenter <= minCenter)
        ? (_minX + _maxX) / 2
        : _randInRange(minCenter, maxCenter);

    _spawnEnemy(
      entry!.builder!(),
      Vector2(centerX - horizontalSpacing, _spawnY),
    );
    _spawnEnemy(entry.builder!(), Vector2(centerX, _spawnY));
    _spawnEnemy(
      entry.builder!(),
      Vector2(centerX + horizontalSpacing, _spawnY),
    );
  }

  void _spawnSquare4() {
    final entry = _getRandomEnemy(formationsOnly: true);
    if (entry?.builder == null) return;

    final minCenter = _minX + horizontalSpacing;
    final maxCenter = _maxX - horizontalSpacing;
    final centerX = (maxCenter <= minCenter)
        ? (_minX + _maxX) / 2
        : _randInRange(minCenter, maxCenter);

    final left = centerX - horizontalSpacing / 2;
    final right = centerX + horizontalSpacing / 2;
    final top = _spawnY;
    final bottom = _spawnY + verticalSpacing;

    _spawnEnemy(entry!.builder!(), Vector2(left, top));
    _spawnEnemy(entry.builder!(), Vector2(right, top));
    _spawnEnemy(entry.builder!(), Vector2(left, bottom));
    _spawnEnemy(entry.builder!(), Vector2(right, bottom));
  }

  // ---------------------------------------------------------------------------
  void _spawnEnemy(PositionComponent enemy, Vector2 position) {
    enemy.position = position;
    gameRef.add(enemy);
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  double _randInRange(double min, double max) =>
      min + _rand.nextDouble() * (max - min);

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Entrada a la tabla de enemigos
class EnemyEntry {
  EnemyEntry({
    required this.builder,
    this.weight = 1,
    this.allowInFormations = true,
    this.isMiniBoss = false,
    this.isRare = false,
  });

  final PositionComponent Function()? builder;
  final double weight;
  final bool allowInFormations;
  final bool isMiniBoss;
  final bool isRare;
}
