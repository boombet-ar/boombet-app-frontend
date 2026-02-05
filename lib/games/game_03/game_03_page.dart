import 'package:boombet_app/games/game_03/game_03.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Game03Page extends StatefulWidget {
  const Game03Page({super.key});

  @override
  State<Game03Page> createState() => _Game03PageState();
}

class _Game03PageState extends State<Game03Page> {
  late Game03 game;

  @override
  void initState() {
    super.initState();
    game = Game03();
    game.setPanInputEnabled(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _restart() {
    game.restart();
  }

  @override
  Widget build(BuildContext context) {
    final gameView = GameWidget<Game03>(
      game: game,
      overlayBuilderMap: {
        Game03.overlayHud: (_, Game03 g) => _HudOverlay(game: g),
        Game03.overlayGameOver: (_, Game03 g) =>
            _GameOverOverlay(game: g, onRestart: _restart),
        Game03.overlayPause: (_, Game03 g) =>
            _PauseOverlay(game: g, onResume: g.resumeGame, onRestart: _restart),
        Game03.overlayMenu: (_, Game03 g) => _MenuOverlay(
          game: g,
          onPlay: g.startWithCountdown,
          onExit: () => Navigator.of(context).pop(),
        ),
        Game03.overlayCountdown: (_, Game03 g) => _CountdownOverlay(game: g),
      },
      initialActiveOverlays: const [Game03.overlayMenu],
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
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final Game03 game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PerfectFeedback(),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _GameControls(game: game),
          ),
        ),
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

class _GameControls extends StatelessWidget {
  const _GameControls({required this.game});

  final Game03 game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.keyboard_arrow_left,
          onTapDown: () => game.setInputXTarget(-1),
          onTapUp: game.stopInputX,
          onTapCancel: game.stopInputX,
        ),
        const SizedBox(width: 14),
        _ArrowButton(icon: Icons.keyboard_arrow_down, onTapDown: game.slamDown),
        const SizedBox(width: 14),
        _ArrowButton(
          icon: Icons.keyboard_arrow_right,
          onTapDown: () => game.setInputXTarget(1),
          onTapUp: game.stopInputX,
          onTapCancel: game.stopInputX,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _setPressed(true);
        widget.onTapDown();
      },
      onTapUp: (_) {
        _setPressed(false);
        widget.onTapUp?.call();
      },
      onTapCancel: () {
        _setPressed(false);
        widget.onTapCancel?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.greenAccent.withOpacity(0.85)
              : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(_pressed ? 0.7 : 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(_pressed ? 0.45 : 0.2),
              blurRadius: _pressed ? 10 : 6,
              spreadRadius: _pressed ? 0 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: _pressed ? Colors.black : Colors.white,
          size: 44,
        ),
      ),
    );
  }
}

class _PerfectFeedback extends StatelessWidget {
  const _PerfectFeedback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game, required this.onRestart});

  final Game03 game;
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

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.game,
    required this.onPlay,
    required this.onExit,
  });

  final Game03 game;
  final VoidCallback onPlay;
  final VoidCallback onExit;

  void _showHowToPlayDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: const Text(
            'Cómo jugar',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'ThaleahFat',
              letterSpacing: 1.2,
              fontSize: 22,
            ),
          ),
          content: const Text(
            '• Deslizá el dedo para mover al personaje.\n'
            '• Rebotá en plataformas para subir.\n'
            '• Si caes fuera de pantalla, perdes.\n',
            style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: primaryGreen,
                  fontFamily: 'ThaleahFat',
                  letterSpacing: 1.1,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Cómo jugar',
                        onPressed: () => _showHowToPlayDialog(context),
                        icon: const Icon(Icons.help_outline),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'JUMP TOWER',
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

  final Game03 game;

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

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.game,
    required this.onResume,
    required this.onRestart,
  });

  final Game03 game;
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

  final Game03 game;

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
