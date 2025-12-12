import 'dart:async';
import 'package:boombet_app/games/boombet_shooter/components/player/player_shooting.dart';
import 'package:flame/components.dart';

import '../interfaces/powerup_type.dart';

class PowerupData {
  PowerupData({required this.type, required this.duration});
  final PowerupType type;
  final double duration;
}

class PlayerPowerups extends Component {
  PlayerPowerups();

  PlayerShooting? _playerShooting;
  late double _baseFireRate;

  bool hasDoubleShot = false;
  bool hasRapidFire = false;
  bool hasScoreMultiplier = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Buscar PlayerShooting dentro del Player
    _playerShooting = parent?.children.whereType<PlayerShooting>().firstOrNull;

    _baseFireRate = _playerShooting?.fireRate ?? 0.25;
  }

  /// ESTA ES LA FIRMA CORRECTA
  void activatePowerup(PowerupData data) {
    switch (data.type) {
      case PowerupType.doubleShot:
        _doubleShotRoutine(data.duration);
        break;
      case PowerupType.rapidFire:
        _rapidFireRoutine(data.duration);
        break;
      case PowerupType.scoreMultiplier:
        _scoreMultiplierRoutine(data.duration);
        break;
    }
  }

  Future<void> _doubleShotRoutine(double duration) async {
    hasDoubleShot = true;
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
    hasDoubleShot = false;
  }

  Future<void> _rapidFireRoutine(double duration) async {
    hasRapidFire = true;

    if (_playerShooting != null) {
      _playerShooting!.fireRate = _baseFireRate * 0.5;
    }

    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
    hasRapidFire = false;

    if (_playerShooting != null) {
      _playerShooting!.fireRate = _baseFireRate;
    }
  }

  Future<void> _scoreMultiplierRoutine(double duration) async {
    hasScoreMultiplier = true;
    await Future.delayed(Duration(milliseconds: (duration * 1000).round()));
    hasScoreMultiplier = false;
  }
}
