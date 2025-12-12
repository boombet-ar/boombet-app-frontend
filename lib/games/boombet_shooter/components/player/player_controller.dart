import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Controla el movimiento del jugador (adaptado desde Unity).
///
/// - Sigue el dedo / mouse fijando un `targetPosition`.
/// - Limita el movimiento a los bordes visibles del game (como el viewport de la cámara).
/// - Expone hooks de Hyper Mode para multiplicar la velocidad.
class PlayerController extends Component
    with HasGameRef, TapCallbacks, DragCallbacks {
  PlayerController({this.moveSpeed = 8.0, this.hyperMoveMultiplier = 1.2});

  // Velocidad base y multiplicador de Hyper Mode
  double moveSpeed;
  final double hyperMoveMultiplier;
  late double _baseMoveSpeed;

  // Límites de movimiento (min/max) calculados con el tamaño del sprite
  Vector2 _minBounds = Vector2.zero();
  Vector2 _maxBounds = Vector2.zero();

  // Mitad de ancho/alto del sprite
  double _halfWidth = 0;
  double _halfHeight = 0;

  // Posición objetivo hacia donde se mueve el jugador
  late Vector2 _targetPosition;

  // Referencia al componente padre (el sprite del player)
  SpriteComponent get _player => parent! as SpriteComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _baseMoveSpeed = moveSpeed;

    // Calcular la mitad del tamaño del sprite para evitar que salga de pantalla
    _halfWidth = _player.size.x * 0.5;
    _halfHeight = _player.size.y * 0.5;

    _recalculateBounds(gameRef.size);

    // Posición inicial como target
    _targetPosition = _player.position.clone();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalculateBounds(size);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _movePlayer(dt);
  }

  // ---------------------------------------------------------------------------
  // INPUT: Tap y Drag (touch/mouse) -> actualiza targetPosition
  // ---------------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) {
    _targetPosition = event.canvasPosition;
  }

  @override
  void onDragStart(DragStartEvent event) {
    _targetPosition = event.canvasPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _targetPosition = event.canvasDelta;
  }

  // ---------------------------------------------------------------------------
  // MOVIMIENTO
  // ---------------------------------------------------------------------------
  void _movePlayer(double dt) {
    final clampedX = _targetPosition.x.clamp(_minBounds.x, _maxBounds.x);
    final clampedY = _targetPosition.y.clamp(_minBounds.y, _maxBounds.y);
    final clampedTarget = Vector2(clampedX, clampedY);

    final current = _player.position;
    final toTarget = clampedTarget - current;
    final distance = toTarget.length;

    if (distance == 0) return;

    final maxStep = moveSpeed * dt;
    if (distance <= maxStep) {
      _player.position.setFrom(clampedTarget);
    } else {
      _player.position += toTarget.normalized() * maxStep;
    }
  }

  void _recalculateBounds(Vector2 gameSize) {
    _minBounds = Vector2(_halfWidth, _halfHeight);
    _maxBounds = Vector2(gameSize.x - _halfWidth, gameSize.y - _halfHeight);
  }

  // ---------------------------------------------------------------------------
  // HYPER MODE
  // ---------------------------------------------------------------------------
  void activateHyperMode() {
    moveSpeed = _baseMoveSpeed * hyperMoveMultiplier;
  }

  void deactivateHyperMode() {
    moveSpeed = _baseMoveSpeed;
  }
}
