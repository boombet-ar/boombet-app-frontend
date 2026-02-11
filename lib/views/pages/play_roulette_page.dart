import 'dart:math' as math;

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class PlayRoulettePage extends StatefulWidget {
  final String? codigoRuleta;
  final String? qrRawValue;
  final String? qrParsedUri;

  const PlayRoulettePage({
    super.key,
    this.codigoRuleta,
    this.qrRawValue,
    this.qrParsedUri,
  });

  @override
  State<PlayRoulettePage> createState() => _PlayRoulettePageState();
}

class _PlayRoulettePageState extends State<PlayRoulettePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particlesController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: Stack(
          children: [
            // Animated background particles
            _buildParticlesBackground(),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingXLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Animated roulette icon with glow
                    _buildAnimatedRouletteIcon(),

                    const SizedBox(height: 40),

                    // Success message with gradient
                    _buildSuccessMessage(isDark),

                    const SizedBox(height: 24),

                    // Subtitle
                    _buildSubtitle(isDark),

                    const SizedBox(height: 40),

                    // Decorative elements
                    _buildDecorativeStars(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticlesBackground() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(animation: _particlesController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedRouletteIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppConstants.primaryGreen.withOpacity(_glowAnimation.value),
                  AppConstants.primaryGreen.withOpacity(
                    _glowAnimation.value * 0.3,
                  ),
                  Colors.transparent,
                ],
                stops: const [0.3, 0.6, 1.0],
              ),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppConstants.primaryGreen,
                            const Color(0xFF00D4FF),
                            AppConstants.primaryGreen,
                            const Color(0xFFFFD700),
                            AppConstants.primaryGreen,
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryGreen.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.darkBg,
                        ),
                        child: const Icon(
                          Icons.casino,
                          size: 70,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessMessage(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppConstants.primaryGreen,
              const Color(0xFF00E5FF),
              AppConstants.primaryGreen,
            ],
            stops: [0.0, _pulseController.value, 1.0],
          ).createShader(bounds),
          child: Text(
            '¡FELICIDADES!',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppConstants.primaryGreen.withOpacity(0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildSubtitle(bool isDark) {
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstants.primaryGreen.withOpacity(0.2),
                const Color(0xFF00D4FF).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.primaryGreen.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Ya podés jugar en la',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppConstants.primaryGreen, const Color(0xFF00E5FF)],
                ).createShader(bounds),
                child: const Text(
                  '🎰 RULETA 🎰',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Probá tu suerte ahora!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDecorativeStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final phase = (_pulseController.value + delay) % 1.0;
            final scale = 0.7 + (math.sin(phase * 2 * math.pi) * 0.3);
            final opacity = 0.4 + (math.sin(phase * 2 * math.pi) * 0.4);

            return Transform.scale(
              scale: scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  index.isEven ? Icons.star : Icons.star_border,
                  size: 30,
                  color: AppConstants.primaryGreen.withOpacity(opacity),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animation;

  _ParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.5 + random.nextDouble() * 0.5;
      final y = (baseY + animation * size.height * speed) % size.height;
      final size1 = 2 + random.nextDouble() * 3;
      final opacity = 0.1 + random.nextDouble() * 0.3;

      paint.color = AppConstants.primaryGreen.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), size1, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      animation != oldDelegate.animation;
}
