import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game.dart';
import '../../managers/game_manager.dart';

class PlayerHealth extends Component with HasGameRef<MyGame> {
  PlayerHealth({
    this.maxHealth = 3,
    this.invulnerabilityDuration = 0.5,
    this.flashDuration = 0.1,
    this.flashColor = const Color.fromRGBO(255, 51, 51, 1),
  });

  int maxHealth;
  late int currentHealth;

  double invulnerabilityDuration;
  bool isInvulnerable = false;

  double flashDuration;
  Color flashColor;
  bool _isRedFlashing = false;

  double _invulTime = 0;
  double _flashTime = 0;
  bool _blinkVisible = true;

  SpriteComponent get _player => parent! as SpriteComponent;
  late Color _originalColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _originalColor = _player.paint.color;
    currentHealth = maxHealth;

    // 🔥 Notificar vida inicial
    GameManager.instance.onHealthChanged?.call(currentHealth);
  }

  void takeDamage(int amount) {
    if (amount <= 0 || isInvulnerable) return;

    currentHealth -= amount;

    // 🔥 Notificar HUD
    GameManager.instance.onHealthChanged?.call(currentHealth);

    // 🔥 Reset combo como Unity
    GameManager.instance.resetCombo();

    _startRedFlash();

    if (currentHealth <= 0) {
      _die();
      return;
    }

    // invulnerabilidad
    isInvulnerable = true;
    _invulTime = invulnerabilityDuration;
  }

  void _die() {
    GameManager.instance.playerDied();
    parent?.removeFromParent();
  }

  void _startRedFlash() {
    _isRedFlashing = true;
    _flashTime = flashDuration;
    _player.paint.color = flashColor;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isRedFlashing) {
      _flashTime -= dt;
      if (_flashTime <= 0) {
        _isRedFlashing = false;
        if (!isInvulnerable) _player.paint.color = _originalColor;
      }
    }

    if (isInvulnerable) {
      _invulTime -= dt;

      // blink tipo Unity
      _blinkVisible = !_blinkVisible;
      _player.paint.color = _blinkVisible
          ? _originalColor.withOpacity(0.25)
          : _originalColor;

      if (_invulTime <= 0) {
        isInvulnerable = false;
        _player.paint.color = _originalColor;
      }
    }
  }
}
