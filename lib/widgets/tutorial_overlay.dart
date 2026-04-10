import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PASO 1 — Pantalla de bienvenida
// ─────────────────────────────────────────────────────────────────────────────

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onContinue;

  const TutorialOverlay({super.key, required this.onContinue});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;
  late final AnimationController _buttonPulseController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _glow;
  late final Animation<double> _buttonPulse;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _enterController, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.elasticOut),
    );
    _fadeOut = CurvedAnimation(parent: _exitController, curve: Curves.easeOut);
    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _buttonPulse = CurvedAnimation(
      parent: _buttonPulseController,
      curve: Curves.easeInOut,
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _exitController.forward();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeIn, _fadeOut]),
      builder: (context, _) {
        final opacity = _fadeIn.value * (1.0 - _fadeOut.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            child: SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WelcomeText(glow: _glow),
                        const SizedBox(height: 36),
                        _LogoWithGlow(glow: _glow),
                        const SizedBox(height: 64),
                        _ContinueButton(
                          pulse: _buttonPulse,
                          onPressed: _handleContinue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeText extends StatelessWidget {
  final Animation<double> glow;

  const _WelcomeText({required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        return Column(
          children: [
            Text(
              'BIENVENIDOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF29FF5E),
                letterSpacing: 4,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    color: const Color(0xFF29FF5E).withValues(
                      alpha: 0.5 + glow.value * 0.5,
                    ),
                    blurRadius: 24 + glow.value * 16,
                  ),
                  Shadow(
                    color: const Color(0xFF29FF5E).withValues(
                      alpha: 0.2 + glow.value * 0.3,
                    ),
                    blurRadius: 60 + glow.value * 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A LA APP OFICIAL DE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 3,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(
                      alpha: 0.1 + glow.value * 0.15,
                    ),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogoWithGlow extends StatelessWidget {
  final Animation<double> glow;

  const _LogoWithGlow({required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF29FF5E).withValues(
                  alpha: 0.25 + glow.value * 0.35,
                ),
                blurRadius: 40 + glow.value * 30,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF29FF5E).withValues(
                  alpha: 0.1 + glow.value * 0.15,
                ),
                blurRadius: 80 + glow.value * 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/boombetlogo.png',
            width: 220,
          ),
        );
      },
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final Animation<double> pulse;
  final VoidCallback onPressed;

  const _ContinueButton({required this.pulse, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF29FF5E).withValues(
                  alpha: 0.35 + pulse.value * 0.4,
                ),
                blurRadius: 16 + pulse.value * 14,
                spreadRadius: 1 + pulse.value * 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29FF5E),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 52,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASO 2+ — Tarjeta de tooltip para tutorial_coach_mark
// ─────────────────────────────────────────────────────────────────────────────

class TutorialStepCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  /// Si es null, se muestra [hint] en lugar del botón.
  final VoidCallback? onContinue;
  /// Texto de acción que se muestra cuando no hay botón (ej. "Tocá el botón").
  final String? hint;

  const TutorialStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel = 'Continuar',
    this.onContinue,
    this.hint,
  });

  @override
  State<TutorialStepCard> createState() => _TutorialStepCardState();
}

class _TutorialStepCardState extends State<TutorialStepCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF29FF5E).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF29FF5E).withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con franja verde
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF29FF5E).withValues(alpha: 0.18),
                      const Color(0xFF29FF5E).withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29FF5E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color(0xFF29FF5E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF29FF5E),
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Descripción
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.55,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.onContinue != null)
                      // Botón Continuar
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF29FF5E).withValues(
                                    alpha: 0.28 + _pulse.value * 0.32,
                                  ),
                                  blurRadius: 12 + _pulse.value * 10,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: widget.onContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF29FF5E),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.buttonLabel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    else if (widget.hint != null)
                      // Hint de acción (cuando el usuario tiene que tocar el elemento)
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF29FF5E).withValues(
                                alpha: 0.06 + _pulse.value * 0.06,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF29FF5E).withValues(
                                  alpha: 0.25 + _pulse.value * 0.25,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: const Color(0xFF29FF5E).withValues(
                                    alpha: 0.7 + _pulse.value * 0.3,
                                  ),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.hint!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF29FF5E).withValues(
                                      alpha: 0.7 + _pulse.value * 0.3,
                                    ),
                                    letterSpacing: 0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY INFORMATIVO DE PÁGINA — overlay full-screen sin logo (para vistas)
// ─────────────────────────────────────────────────────────────────────────────

class TutorialPageOverlay extends StatefulWidget {
  final IconData icon;
  final String description;
  final VoidCallback onContinue;

  const TutorialPageOverlay({
    super.key,
    required this.icon,
    required this.description,
    required this.onContinue,
  });

  @override
  State<TutorialPageOverlay> createState() => _TutorialPageOverlayState();
}

class _TutorialPageOverlayState extends State<TutorialPageOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _glow;
  late final Animation<double> _pulse;

  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _fadeOut = CurvedAnimation(parent: _exitController, curve: Curves.easeIn);
    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _exitController.forward();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeIn, _fadeOut]),
      builder: (context, _) {
        final opacity = _fadeIn.value * (1.0 - _fadeOut.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            color: Colors.black.withValues(alpha: 0.82),
            child: Center(
              child: ScaleTransition(
                scale: _scaleIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF29FF5E).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF29FF5E).withValues(alpha: 0.1),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header con ícono animado
                          AnimatedBuilder(
                            animation: _glow,
                            builder: (context, _) => Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF29FF5E).withValues(
                                      alpha: 0.12 + _glow.value * 0.08,
                                    ),
                                    const Color(0xFF141414),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF29FF5E).withValues(
                                      alpha: 0.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF29FF5E,
                                        ).withValues(
                                          alpha: 0.2 + _glow.value * 0.3,
                                        ),
                                        blurRadius: 24 + _glow.value * 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: const Color(0xFF29FF5E),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Texto y botón
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Column(
                              children: [
                                Text(
                                  widget.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.6,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, _) => Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF29FF5E,
                                          ).withValues(
                                            alpha: 0.3 + _pulse.value * 0.35,
                                          ),
                                          blurRadius: 14 + _pulse.value * 10,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleContinue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF29FF5E),
                                        foregroundColor: Colors.black,
                                        minimumSize: const Size(
                                          double.infinity,
                                          52,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'CONTINUAR',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2.5,
                                          color: Colors.black,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// TUTORIAL SWIPE NAVBAR
// ─────────────────────────────────────────────────────────────────────────────

class NavbarSwipeTutorial extends StatefulWidget {
  const NavbarSwipeTutorial({super.key});

  @override
  State<NavbarSwipeTutorial> createState() => _NavbarSwipeTutorialState();
}

class _NavbarSwipeTutorialState extends State<NavbarSwipeTutorial>
    with TickerProviderStateMixin {
  late final AnimationController _swipeController;
  late final AnimationController _glowController;
  late final Animation<double> _swipeX;
  late final Animation<double> _swipeOpacity;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _swipeX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: -0.72)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 58,
      ),
      TweenSequenceItem(tween: ConstantTween(-0.72), weight: 14),
      TweenSequenceItem(tween: ConstantTween(0.72), weight: 28),
    ]).animate(_swipeController);

    _swipeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 14),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 28),
    ]).animate(_swipeController);

    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navbarHeight = 77.0;
    final totalNavbarHeight = navbarHeight + bottomPadding;

    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedBuilder(
            animation: _glow,
            builder: (context, _) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF29FF5E)
                          .withValues(alpha: 0.35 + _glow.value * 0.38),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF29FF5E)
                            .withValues(alpha: 0.12 + _glow.value * 0.22),
                        blurRadius: 18 + _glow.value * 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        color: const Color(0xFF29FF5E)
                            .withValues(alpha: 0.7 + _glow.value * 0.3),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '¡Desliza para ver más!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF29FF5E)
                              .withValues(alpha: 0.8 + _glow.value * 0.2),
                          letterSpacing: 0.4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: totalNavbarHeight,
            child: Stack(
              children: [
                Container(color: Colors.black.withValues(alpha: 0.58)),
                AnimatedBuilder(
                  animation: _swipeController,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment(
                            (_swipeX.value + 0.20).clamp(-1.0, 1.0),
                            -0.25,
                          ),
                          child: Opacity(
                            opacity: _swipeOpacity.value * 0.13,
                            child: const Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFF29FF5E),
                              size: 26,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(
                            (_swipeX.value + 0.10).clamp(-1.0, 1.0),
                            -0.25,
                          ),
                          child: Opacity(
                            opacity: _swipeOpacity.value * 0.32,
                            child: const Icon(
                              Icons.touch_app_rounded,
                              color: Color(0xFF29FF5E),
                              size: 33,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(_swipeX.value, -0.25),
                          child: Opacity(
                            opacity: _swipeOpacity.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ImageFiltered(
                                  imageFilter: ui.ImageFilter.blur(
                                    sigmaX: 7,
                                    sigmaY: 7,
                                  ),
                                  child: Icon(
                                    Icons.touch_app_rounded,
                                    color: const Color(0xFF29FF5E)
                                        .withValues(alpha: 0.8),
                                    size: 52,
                                  ),
                                ),
                                const Icon(
                                  Icons.touch_app_rounded,
                                  color: Color(0xFF29FF5E),
                                  size: 42,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA FINAL
// ─────────────────────────────────────────────────────────────────────────────

class TutorialFinalOverlay extends StatefulWidget {
  final VoidCallback onContinue;
  const TutorialFinalOverlay({super.key, required this.onContinue});
  @override
  State<TutorialFinalOverlay> createState() => _TutorialFinalOverlayState();
}

class _TutorialFinalOverlayState extends State<TutorialFinalOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final AnimationController _glowController;
  late final AnimationController _buttonPulseController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeOut;
  late final Animation<double> _glow;
  late final Animation<double> _buttonPulse;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _exitController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _glowController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _buttonPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _fadeIn      = CurvedAnimation(parent: _enterController, curve: Curves.easeIn);
    _scaleIn     = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _enterController, curve: Curves.elasticOut));
    _fadeOut     = CurvedAnimation(parent: _exitController, curve: Curves.easeOut);
    _glow        = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _buttonPulse = CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut);
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    _glowController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _exitController.forward();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeIn, _fadeOut]),
      builder: (context, _) {
        final opacity = _fadeIn.value * (1.0 - _fadeOut.value);
        return Opacity(
          opacity: opacity,
          child: Container(
            color: Colors.black.withValues(alpha: 0.95),
            child: SafeArea(
              child: Center(
                child: ScaleTransition(
                  scale: _scaleIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, _) => Column(
                            children: [
                              Text(
                                '¿ESTÁS PREPARADO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF29FF5E),
                                  letterSpacing: 3,
                                  decoration: TextDecoration.none,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF29FF5E).withValues(alpha: 0.5 + _glow.value * 0.5),
                                      blurRadius: 24 + _glow.value * 16,
                                    ),
                                    Shadow(
                                      color: const Color(0xFF29FF5E).withValues(alpha: 0.2 + _glow.value * 0.3),
                                      blurRadius: 60 + _glow.value * 30,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'PARA INICIAR TU VIAJE EN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 2.5,
                                  decoration: TextDecoration.none,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withValues(alpha: 0.1 + _glow.value * 0.15),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, _) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF29FF5E).withValues(alpha: 0.25 + _glow.value * 0.35),
                                  blurRadius: 40 + _glow.value * 30,
                                  spreadRadius: 4,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF29FF5E).withValues(alpha: 0.1 + _glow.value * 0.15),
                                  blurRadius: 80 + _glow.value * 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset('assets/images/boombetlogo.png', width: 200),
                          ),
                        ),
                        const SizedBox(height: 56),
                        AnimatedBuilder(
                          animation: _buttonPulse,
                          builder: (context, _) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF29FF5E).withValues(alpha: 0.35 + _buttonPulse.value * 0.4),
                                  blurRadius: 16 + _buttonPulse.value * 14,
                                  spreadRadius: 1 + _buttonPulse.value * 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF29FF5E),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text(
                                '¡ESTOY PREPARADO!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.black,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
