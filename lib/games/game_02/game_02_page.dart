import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:boombet_app/games/game_02/game_02.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Game02Page extends StatefulWidget {
  const Game02Page({super.key});

  @override
  State<Game02Page> createState() => _Game02PageState();
}

class _Game02PageState extends State<Game02Page> {
  late Game02 game;

  @override
  void initState() {
    super.initState();
    game = Game02(onGameOver: (_) {});
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void restartGame() {
    setState(() {
      game = Game02(onGameOver: (_) {});
    });
  }

  Widget _buildGameView() {
    final gameView = GameWidget<Game02>(
      game: game,
      overlayBuilderMap: {
        Game02.overlayHud: (_, Game02 g) => _HudOverlay(game: g),
        Game02.overlayGameOver: (_, Game02 g) =>
            _GameOverOverlay(game: g, onRestart: restartGame),
        Game02.overlayPause: (_, Game02 g) => _PauseOverlay(
          game: g,
          onResume: g.resumeGame,
          onRestart: restartGame,
        ),
        Game02.overlayMenu: (_, Game02 g) => _MenuOverlay(
          game: g,
          onPlay: g.startWithCountdown,
          onExit: () => Navigator.of(context).pop(),
        ),
        Game02.overlayCountdown: (_, Game02 g) => _CountdownOverlay(game: g),
      },
      initialActiveOverlays: const [Game02.overlayMenu],
    );

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: AspectRatio(aspectRatio: 9 / 16, child: gameView),
          ),
        ),
      );
    }

    return Scaffold(body: gameView);
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameView();
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final Game02 game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PerfectCelebrationOverlay(game: game),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: _PauseButton(onPressed: game.pauseGame),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SCORE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              fontFamily: 'ThaleahFat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          ValueListenableBuilder<int>(
                            valueListenable: game.scoreNotifier,
                            builder: (context, score, _) {
                              return Text(
                                '$score',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                  fontFamily: 'ThaleahFat',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PerfectFeedback(game: game),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerfectCelebrationOverlay extends StatefulWidget {
  const _PerfectCelebrationOverlay({required this.game});

  final Game02 game;

  @override
  State<_PerfectCelebrationOverlay> createState() =>
      _PerfectCelebrationOverlayState();
}

class _PerfectCelebrationOverlayState extends State<_PerfectCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastTick = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _trigger() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.perfectCelebrationTick,
      builder: (context, tick, _) {
        if (tick != _lastTick) {
          _lastTick = tick;
          if (tick > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _trigger();
            });
          }
        }

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              if (t <= 0) return const SizedBox.shrink();

              final flashIn = (1 - (t / 0.18)).clamp(0.0, 1.0);
              final flashOut = ((t - 0.18) / 0.82).clamp(0.0, 1.0);
              final flash = (flashIn * (1 - flashOut)).clamp(0.0, 1.0);

              // Screen shake for a dopamine hit (very subtle).
              final shake = math.sin(t * math.pi * 10) * (1 - t) * 6;

              return Transform.translate(
                offset: Offset(shake, -shake * 0.35),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Flash wash.
                    Opacity(
                      opacity: 0.32 * flash,
                      child: const ColoredBox(color: Color(0xFF6CFF6C)),
                    ),
                    // Vignette-ish glow.
                    Opacity(
                      opacity: 0.9 * (1 - t),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              const Color(0xFF6CFF6C).withOpacity(0.22),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.75],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PerfectFeedback extends StatefulWidget {
  const _PerfectFeedback({required this.game});

  final Game02 game;

  @override
  State<_PerfectFeedback> createState() => _PerfectFeedbackState();
}

class _PerfectFeedbackState extends State<_PerfectFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  void _onTick() {
    _controller.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    widget.game.perfectFeedbackTick.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _PerfectFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.perfectFeedbackTick.removeListener(_onTick);
      widget.game.perfectFeedbackTick.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.game.perfectFeedbackTick.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Center(
        child: ValueListenableBuilder<String?>(
          valueListenable: widget.game.scoreFeedbackText,
          builder: (_, text, __) {
            final isVisible = text != null && text!.isNotEmpty;
            if (!isVisible) {
              // Reservar espacio estable y evitar layout jump.
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = _controller.value;

                // Pop rápido con overshoot + decay
                final pop = Curves.easeOutBack.transform(
                  (t / 0.22).clamp(0.0, 1.0),
                );
                final settle = Curves.easeOut.transform(
                  ((t - 0.22) / 0.18).clamp(0.0, 1.0),
                );
                final scale = ui.lerpDouble(0.65, 1.25, pop) ?? 1.0;
                final scale2 = ui.lerpDouble(1.25, 1.05, settle) ?? 1.0;
                final finalScale = (t < 0.22) ? scale : scale2;

                // Wiggle corto al inicio
                final wiggleT = (t / 0.45).clamp(0.0, 1.0);
                final wiggle =
                    math.sin(wiggleT * math.pi * 10) * (1.0 - wiggleT) * 0.06;

                // Fade-out al final
                final fade =
                    1.0 -
                    Curves.easeIn.transform(
                      ((t - 0.78) / 0.22).clamp(0.0, 1.0),
                    );

                // Glow pulsante
                final glowPulse = 0.6 + 0.4 * math.sin(t * math.pi * 6);
                final glowColor = Colors.greenAccent.withOpacity(0.9 * fade);

                return Transform.rotate(
                  angle: wiggle,
                  child: Transform.scale(
                    scale: finalScale,
                    child: ValueListenableBuilder<int>(
                      valueListenable: widget.game.perfectStreak,
                      builder: (_, streak, __) {
                        final showStreak = streak >= 2;
                        final baseStyle = TextStyle(
                          color: Colors.white.withOpacity(fade),
                          fontSize: 28,
                          fontFamily: 'ThaleahFat',
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: glowColor.withOpacity(0.9),
                              blurRadius: 22 * glowPulse,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: glowColor.withOpacity(0.45),
                              blurRadius: 44 * glowPulse,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        );

                        return Text.rich(
                          TextSpan(
                            text: text!,
                            children: [
                              if (showStreak)
                                TextSpan(
                                  text: ' x$streak',
                                  style: baseStyle.copyWith(
                                    color: const Color(
                                      0xFF6CFF6C,
                                    ).withOpacity(fade),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: baseStyle,
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.game,
    required this.onPlay,
    required this.onExit,
  });

  final Game02 game;
  final VoidCallback onPlay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'assets/images/pixel_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryGreen.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.favorite,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'BOOMBET',
                          style: TextStyle(
                            fontFamily: 'ThaleahFat',
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'TOWER STACK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontFamily: 'ThaleahFat',
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<int>(
                valueListenable: game.bestScoreNotifier,
                builder: (_, value, __) => Text(
                  'MEJOR SCORE  $value',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontFamily: 'ThaleahFat',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _VolumeControls(game: game),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'JUGAR',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'SALIR',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.game});

  final Game02 game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: game.countdown,
      builder: (context, value, child) {
        if (value == null) return const SizedBox.shrink();

        return IgnorePointer(
          child: Container(
            color: Colors.black.withOpacity(0.45),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey<int>(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 88,
                  fontFamily: 'ThaleahFat',
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                    Shadow(
                      color: Colors.greenAccent,
                      blurRadius: 16,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.65),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.2),
          ),
          elevation: 4,
          shadowColor: Colors.greenAccent.withOpacity(0.4),
        ),
        child: const Icon(Icons.pause, size: 22),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game, required this.onRestart});

  final Game02 game;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontFamily: 'ThaleahFat',
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: game.scoreNotifier,
              builder: (_, value, __) => Text(
                'FINAL SCORE  $value',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 20,
                  fontFamily: 'ThaleahFat',
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RESTART',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'EXIT',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.game,
    required this.onResume,
    required this.onRestart,
  });

  final Game02 game;
  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.35),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontFamily: 'ThaleahFat',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _VolumeControls(game: game),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: onResume,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RESUME',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onRestart,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RESTART',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70, width: 1.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'EXIT',
                    style: TextStyle(
                      fontFamily: 'ThaleahFat',
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeControls extends StatelessWidget {
  const _VolumeControls({required this.game});

  final Game02 game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note,
                color: Colors.greenAccent.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'MÚSICA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'ThaleahFat',
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: ValueListenableBuilder<double>(
                  valueListenable: game.musicVolume,
                  builder: (_, value, __) => SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.greenAccent,
                      overlayColor: Colors.greenAccent.withOpacity(0.3),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (newValue) => game.setMusicVolume(newValue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: Colors.greenAccent.withOpacity(0.8),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'EFECTOS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'ThaleahFat',
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: ValueListenableBuilder<double>(
                  valueListenable: game.sfxVolume,
                  builder: (_, value, __) => SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.greenAccent,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.greenAccent,
                      overlayColor: Colors.greenAccent.withOpacity(0.3),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (newValue) => game.setSfxVolume(newValue),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
