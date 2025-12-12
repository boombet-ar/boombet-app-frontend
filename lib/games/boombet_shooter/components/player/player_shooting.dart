import 'dart:async';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import '../../game.dart';
import '../../managers/game_manager.dart';
import 'player_powerups.dart';

/// Tag para identificar balas del jugador
mixin PlayerBulletTag {}

class PlayerShooting extends Component with HasGameRef<MyGame> {
  PlayerShooting({
    double fireRate = 0.25,
    this.bulletSpeed = 400,
    Vector2? bulletOffset,
  }) : _baseFireRate = fireRate,
       bulletOffset = bulletOffset ?? Vector2(0, -20);

  // -------------------------------------------------------------------
  // FIRE RATE (NORMAL + HYPER MODE)
  // -------------------------------------------------------------------
  final double _baseFireRate;
  late double _currentFireRate;
  double get fireRate => _currentFireRate;
  set fireRate(double v) => _currentFireRate = v;

  // -------------------------------------------------------------------
  // BULLET CONFIG
  // -------------------------------------------------------------------
  final double bulletSpeed;
  final Vector2 bulletOffset;

  double _fireTimer = 0;
  late Sprite _bulletSprite;

  // Powerups (double shot, rapid fire, etc.)
  PlayerPowerups? _powerups;
  bool _powerupsResolved = false;

  SpriteComponent get _player => parent! as SpriteComponent;

  // Hyper mode subscriptions
  StreamSubscription? _hyperOn;
  StreamSubscription? _hyperOff;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fire rate inicial
    _currentFireRate = _baseFireRate;
    _fireTimer = _currentFireRate;

    // Load bullet sprite with fallback
    try {
      _bulletSprite = await Sprite.load(
        'games/boombet_shooter/sprites/player/bullet_player.png',
      );
    } catch (_) {
      _bulletSprite = await _solidColorSprite(const Color(0xFFFFFFFF));
    }

    // --------------------------------------------------------------
    // Suscribirse a Hyper Mode del GameManager
    // --------------------------------------------------------------
    final gm = GameManager.instance;

    _hyperOn = gm.onHyperActivate.listen((_) => _activateHyperMode());
    _hyperOff = gm.onHyperDeactivate.listen((_) => _deactivateHyperMode());
  }

  @override
  void onRemove() {
    _hyperOn?.cancel();
    _hyperOff?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Resolver powerups solo una vez
    if (!_powerupsResolved) {
      _powerups = parent?.children.whereType<PlayerPowerups>().firstOrNull;
      if (_powerups != null) _powerupsResolved = true;
    }

    // ----------------------------------------------------
    // Fire timer
    // ----------------------------------------------------
    _fireTimer -= dt;
    if (_fireTimer <= 0) {
      _fireTimer += _currentFireRate;
      _shoot();
    }
  }

  // -------------------------------------------------------------------
  // SHOOT — igual a Unity pero en Flame
  // -------------------------------------------------------------------
  void _shoot() {
    final doubleShot = _powerups?.hasDoubleShot ?? false;

    final offsets = doubleShot
        ? [Vector2(-10, -20), Vector2(10, -20)]
        : [bulletOffset];

    for (final o in offsets) {
      final bullet = _PlayerBullet(
        sprite: _bulletSprite,
        speed: bulletSpeed,
        size: Vector2(12, 24),
      );

      bullet.position = _player.position + o;
      gameRef.add(bullet);
    }
  }

  // -------------------------------------------------------------------
  // HYPER MODE — MODIFICA LA CADENCIA DE DISPARO 🔥
  // -------------------------------------------------------------------
  void _activateHyperMode() {
    _currentFireRate =
        _baseFireRate / GameManager.instance.hyperFireRateMultiplier;
  }

  void _deactivateHyperMode() {
    _currentFireRate = _baseFireRate;
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

// ======================================================================
// BULLET
// ======================================================================
class _PlayerBullet extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks, PlayerBulletTag {
  _PlayerBullet({required Sprite sprite, required this.speed, Vector2? size})
    : super(
        sprite: sprite,
        size: size ?? Vector2(12, 24),
        anchor: Anchor.center,
        priority: 30,
      );

  final double speed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.add(Vector2(0, -speed * dt));

    if (position.y + size.y < 0) {
      removeFromParent();
    }
  }
}
