import 'package:flame/components.dart';

import '../interfaces/powerup_type.dart';
import 'powerup_pickup.dart';

/// Factory/builder para crear powerups específicos.
/// Facilita la creación de pickups tipados sin repetir código.
class PowerupFactory {
  static PowerupPickup createDoubleShot({Vector2? position}) {
    final powerup = PowerupPickup(
      type: PowerupType.doubleShot,
      duration: 8.0,
      fallSpeed: 60,
      size: Vector2(24, 24),
    );
    if (position != null) {
      powerup.position = position;
    }
    return powerup;
  }

  static PowerupPickup createRapidFire({Vector2? position}) {
    final powerup = PowerupPickup(
      type: PowerupType.rapidFire,
      duration: 8.0,
      fallSpeed: 60,
      size: Vector2(24, 24),
    );
    if (position != null) {
      powerup.position = position;
    }
    return powerup;
  }

  static PowerupPickup createScoreMultiplier({Vector2? position}) {
    final powerup = PowerupPickup(
      type: PowerupType.scoreMultiplier,
      duration: 8.0,
      fallSpeed: 60,
      size: Vector2(24, 24),
    );
    if (position != null) {
      powerup.position = position;
    }
    return powerup;
  }

  /// Crea un powerup aleatorio de los 3 tipos disponibles.
  static PowerupPickup createRandom({Vector2? position}) {
    final types = [
      PowerupType.doubleShot,
      PowerupType.rapidFire,
      PowerupType.scoreMultiplier,
    ];
    final randomType = types[DateTime.now().millisecond % types.length];

    final powerup = PowerupPickup(
      type: randomType,
      duration: 8.0,
      fallSpeed: 60,
      size: Vector2(24, 24),
    );
    if (position != null) {
      powerup.position = position;
    }
    return powerup;
  }

  /// Retorna una función builder para usar en enemigos (EnemyEntry).
  /// Ejemplo: `builder: PowerupFactory.doubleShot`
  static PositionComponent Function() doubleShot = () => createDoubleShot();
  static PositionComponent Function() rapidFire = () => createRapidFire();
  static PositionComponent Function() scoreMultiplier = () =>
      createScoreMultiplier();
  static PositionComponent Function() random = () => createRandom();
}
