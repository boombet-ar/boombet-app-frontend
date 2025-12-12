import 'dart:async';
import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/player/player_powerups.dart';
import '../game.dart';

/// GameManager adaptado de Unity.
/// Maneja score, combo, hyper mode y eventos mediante Streams.
class GameManager extends Component with HasGameRef<MyGame> {
  GameManager();

  // =====================================================
  // SINGLETON (igual a Unity)
  // =====================================================
  static GameManager? _instance;
  static GameManager get instance => _instance!;

  // =====================================================
  // STREAMS PARA EVENTOS (REEMPLAZA ONHyperModeStart/End DE UNITY)
  // =====================================================
  final StreamController<void> _hyperActivateStream =
      StreamController.broadcast();
  final StreamController<void> _hyperDeactivateStream =
      StreamController.broadcast();

  Stream<void> get onHyperActivate => _hyperActivateStream.stream;
  Stream<void> get onHyperDeactivate => _hyperDeactivateStream.stream;

  // Eventos normales (opcional)
  void Function()? onHyperModeStart;
  void Function()? onHyperModeEnd;

  // =====================================================
  // SCORE
  // =====================================================
  int currentScore = 0;
  int highScore = 0;

  void Function(int)? onScoreChanged;
  void Function(int)? onHighScoreChanged;

  static const _highScoreKey = 'HIGH_SCORE';

  // =====================================================
  // COMBO
  // =====================================================
  int currentCombo = 0;
  int maxCombo = 0;

  double comboTimeout = 2.5;
  double _comboTimer = 0;

  void Function(int combo, int maxCombo)? onComboChanged;

  // =====================================================
  // GAME OVER
  // =====================================================
  bool isGameOver = false;

  void Function()? onGameOver;

  // =====================================================
  // HYPER MODE
  // =====================================================
  bool hyperModeActive = false;
  int comboRequiredForHyper = 25;
  double hyperModeDuration = 5;
  double _hyperTimer = 0;

  double hyperFireRateMultiplier = 1.5;
  double hyperMoveSpeedMultiplier = 1.2;

  // =====================================================
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _instance = this;

    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt(_highScoreKey) ?? 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // COMBO TIMEOUT
    if (currentCombo > 0 && !hyperModeActive) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        resetCombo();
      }
    }

    // HYPER MODE TIMER
    if (hyperModeActive) {
      _hyperTimer -= dt;
      if (_hyperTimer <= 0) {
        deactivateHyperMode();
      }
    }
  }

  // =====================================================
  // SCORE
  // =====================================================
  void resetScore() {
    currentScore = 0;
    onScoreChanged?.call(currentScore);
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, highScore);
  }

  void addScore(int amount) {
    if (isGameOver || amount <= 0) return;

    var finalAmount = amount;

    // Score multiplier (powerup)
    final pp = _findPlayerPowerups();
    if (pp?.hasScoreMultiplier == true) {
      finalAmount *= 2;
    }

    currentScore += finalAmount;
    onScoreChanged?.call(currentScore);

    if (currentScore > highScore) {
      highScore = currentScore;
      _saveHighScore();
      onHighScoreChanged?.call(highScore);
    }
  }

  // =====================================================
  // COMBO
  // =====================================================
  void registerEnemyKill(int baseScore, {bool countsForCombo = true}) {
    if (isGameOver) return;

    if (countsForCombo) {
      currentCombo++;
      if (currentCombo > maxCombo) {
        maxCombo = currentCombo;
      }

      _comboTimer = comboTimeout;

      if (!hyperModeActive) {
        _tryActivateHyperMode();
      }
    }

    final mult = getComboMultiplier(currentCombo);
    final finalScore = (baseScore * mult).round();
    addScore(finalScore);

    onComboChanged?.call(currentCombo, maxCombo);
  }

  double getComboMultiplier(int combo) {
    if (combo < 5) return 1.0;
    if (combo < 10) return 1.2;
    if (combo < 20) return 1.5;
    if (combo < 30) return 1.7;
    return 2.0;
  }

  void resetCombo() {
    currentCombo = 0;
    _comboTimer = 0;
    onComboChanged?.call(currentCombo, maxCombo);
  }

  // =====================================================
  // HYPER MODE
  // =====================================================
  void _tryActivateHyperMode() {
    if (hyperModeActive) return;
    if (currentCombo >= comboRequiredForHyper) {
      activateHyperMode();
    }
  }

  void activateHyperMode() {
    if (hyperModeActive) return;

    hyperModeActive = true;
    _hyperTimer = hyperModeDuration;

    // STREAM EVENT
    _hyperActivateStream.add(null);

    // CALLBACK EVENT (legacy)
    onHyperModeStart?.call();
  }

  void deactivateHyperMode() {
    if (!hyperModeActive) return;

    hyperModeActive = false;
    _hyperTimer = 0;

    // STREAM EVENT
    _hyperDeactivateStream.add(null);

    // CALLBACK EVENT (legacy)
    onHyperModeEnd?.call();
  }

  // =====================================================
  // GAME OVER
  // =====================================================
  void playerDied() {
    if (isGameOver) return;

    isGameOver = true;
    deactivateHyperMode();
    onGameOver?.call();
  }

  // =====================================================
  // RETRY
  // =====================================================
  void retry() {
    isGameOver = false;
    resetScore();
    resetCombo();
    deactivateHyperMode();
  }

  // =====================================================
  // HELPERS
  // =====================================================
  PlayerPowerups? _findPlayerPowerups() {
    return gameRef.children
        .expand((c) => c.children)
        .whereType<PlayerPowerups>()
        .firstOrNull;
  }

  @override
  void onRemove() {
    _hyperActivateStream.close();
    _hyperDeactivateStream.close();
    super.onRemove();
  }

  // =====================================================
  // HEALTH EVENTS (para PlayerHealth)
  // =====================================================
  void Function(int)? onHealthChanged;

}
