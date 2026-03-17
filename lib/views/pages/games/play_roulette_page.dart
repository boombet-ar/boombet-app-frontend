import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class PlayRoulettePage extends StatefulWidget {
  final String? codigoRuleta;
  final String? rouletteWsUrl;
  final String? qrRawValue;
  final String? qrParsedUri;

  const PlayRoulettePage({
    super.key,
    this.codigoRuleta,
    this.rouletteWsUrl,
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
  final AffiliationService _affiliationService = AffiliationService();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  bool _spinFinishedHandled = false;

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

    _listenRouletteMessages();
    _connectRouletteWebSocket();
  }

  void _listenRouletteMessages() {
    _wsSubscription = _affiliationService.messageStream.listen(
      (payload) {
        if (_spinFinishedHandled) return;

        // El servidor siempre manda spinFinished: true cuando termina el giro
        final spinFinishedValue = payload['spinFinished'];
        final isSpinFinished =
            spinFinishedValue == true ||
            spinFinishedValue?.toString().toLowerCase() == 'true';

        if (!isSpinFinished) return;

        _spinFinishedHandled = true;

        // Premio viene anidado en el campo 'premio' (puede estar ausente si falló)
        final premioRaw = payload['premio'];
        if (premioRaw is Map<String, dynamic>) {
          final nombre = premioRaw['nombre']?.toString();
          final idStandRaw = premioRaw['idStand'];
          if (nombre != null && nombre.isNotEmpty && idStandRaw != null) {
            final idStand =
                idStandRaw is int
                    ? idStandRaw
                    : int.tryParse(idStandRaw.toString());
            _handlePrizePayload(
              nombre: nombre,
              imgUrl: premioRaw['imgUrl']?.toString(),
              idStand: idStand,
            );
            return;
          }
        }

        // Sin premio válido: cerrar directamente
        _closeAfterSpinFinished();
      },
      onError: (error) {},
      onDone: () {},
    );
  }

  Future<void> _handlePrizePayload({
    required String nombre,
    String? imgUrl,
    int? idStand,
  }) async {
    String? standNombre;
    if (idStand != null && idStand > 0) {
      final stand = await StandsService().fetchStandById(idStand);
      standNombre = stand?.nombre;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder:
          (_) => _PrizeWonDialog(
            nombre: nombre,
            imgUrl: imgUrl,
            standNombre: standNombre,
          ),
    );

    _affiliationService.closeWebSocket();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(true);
  }

  Future<void> _closeAfterSpinFinished() async {
    _affiliationService.closeWebSocket();

    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true);
    }
  }

  Future<void> _connectRouletteWebSocket() async {
    final wsUrl = widget.rouletteWsUrl?.trim();
    if (wsUrl == null || wsUrl.isEmpty) {
      return;
    }

    try {
      await _affiliationService.connectToWebSocket(wsUrl: wsUrl);
      await _sendUsernameOnSocketConnected();
    } catch (e) {
      return;
    }
  }

  Future<void> _sendUsernameOnSocketConnected() async {
    final identity = await _resolveUserIdentityFromUsersMe();
    final username = identity['username']?.toString().trim() ?? '';
    final userId = identity['userId'];

    if (username.isEmpty || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener username/id desde /users/me'),
          ),
        );
      }
      return;
    }

    final sent = _affiliationService.sendMessage({
      'username': username,
      'userId': userId,
    });
    if (!sent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar username/id por WS')),
      );
    }
  }

  Future<Map<String, dynamic>> _resolveUserIdentityFromUsersMe() async {
    final url = '${ApiConfig.baseUrl}/users/me';
    try {
      final response = await HttpClient.get(
        url,
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const {};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        dynamic pickFirstId(Map<String, dynamic>? source) {
          if (source == null) return null;
          return source['id'] ?? source['usuario_id'] ?? source['user_id'];
        }

        dynamic normalizeId(dynamic value) {
          if (value == null) return null;
          if (value is int) return value;
          final parsed = int.tryParse(value.toString().trim());
          return parsed ?? value;
        }

        final rootUserId = normalizeId(pickFirstId(decoded));
        final rootData = decoded['data'];
        final dataUserId = normalizeId(
          rootData is Map<String, dynamic> ? pickFirstId(rootData) : null,
        );

        Map<String, dynamic>? datosJugador;
        final direct = decoded['datos_jugador'];
        if (direct is Map<String, dynamic>) {
          datosJugador = direct;
        } else {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            final nested = data['datos_jugador'];
            if (nested is Map<String, dynamic>) {
              datosJugador = nested;
            }
          }
        }

        if (datosJugador == null) {
          return const {};
        }

        final username = datosJugador['username']?.toString().trim() ?? '';
        final userId = rootUserId ?? dataUserId;

        if (username.isNotEmpty && userId != null) {
          return {'username': username, 'userId': userId};
        }
      }

      return const {};
    } catch (_) {
      return const {};
    }
  }

  Future<void> _sendSpinRoulette() async {
    final payload = {'spinRoulette': true};

    final sent = _affiliationService.sendMessage(payload);
    if (!sent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el giro por WS')),
        );
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _affiliationService.dispose();
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

                    const SizedBox(height: 28),

                    _buildSpinButton(),

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

  Widget _buildSpinButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [AppConstants.primaryGreen, Color(0xFF00D4FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _sendSpinRoulette,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppConstants.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.casino_outlined, size: 22),
        label: const Text(
          'Hace girar la ruleta!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
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

// ─────────────────────────────────────────────────────────────
// Premio ganado: popup
// ─────────────────────────────────────────────────────────────

class _PrizeWonDialog extends StatefulWidget {
  final String nombre;
  final String? imgUrl;
  final String? standNombre;

  const _PrizeWonDialog({
    required this.nombre,
    this.imgUrl,
    this.standNombre,
  });

  @override
  State<_PrizeWonDialog> createState() => _PrizeWonDialogState();
}

class _PrizeWonDialogState extends State<_PrizeWonDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => _buildCard(child!),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget content) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C2E), Color(0xFF16213E), Color(0xFF0D1B2A)],
        ),
        border: Border.all(
          color: AppConstants.primaryGreen.withOpacity(_glowAnim.value),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withOpacity(_glowAnim.value * 0.55),
            blurRadius: 50,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Confetti de fondo dentro del card
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(
                    animation: _confettiController.value,
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrophyBadge(),
          const SizedBox(height: 14),
          _buildTitle(),
          const SizedBox(height: 24),
          _buildPrizeImage(),
          const SizedBox(height: 20),
          _buildPrizeName(),
          if (widget.standNombre != null) ...[
            const SizedBox(height: 14),
            _buildStandChip(),
          ],
          const SizedBox(height: 30),
          _buildDismissButton(),
        ],
      ),
    );
  }

  Widget _buildTrophyBadge() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD700).withOpacity(0.95),
                const Color(0xFFFF8C00).withOpacity(0.5),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700)
                    .withOpacity(_glowAnim.value * 0.75),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 38,
            color: Color(0xFFFFD700),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              AppConstants.primaryGreen,
              Color(0xFFFFD700),
              AppConstants.primaryGreen,
            ],
            stops: [0.0, _glowController.value, 1.0],
          ).createShader(bounds),
          child: const Text(
            '¡GANASTE UN PREMIO!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildPrizeImage() {
    final imgUrl = widget.imgUrl;
    final hasImage = imgUrl != null && imgUrl.isNotEmpty;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen
                    .withOpacity(_glowAnim.value * 0.65),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: hasImage
            ? Image.network(
                imgUrl,
                width: 170,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackImageBox(),
              )
            : _fallbackImageBox(),
      ),
    );
  }

  Widget _fallbackImageBox() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppConstants.primaryGreen.withOpacity(0.12),
        border: Border.all(
          color: AppConstants.primaryGreen.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        size: 80,
        color: AppConstants.primaryGreen,
      ),
    );
  }

  Widget _buildPrizeName() {
    return Text(
      widget.nombre,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStandChip() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: AppConstants.primaryGreen.withOpacity(0.12),
            border: Border.all(
              color: AppConstants.primaryGreen
                  .withOpacity(_glowAnim.value * 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 17,
                color: AppConstants.primaryGreen,
              ),
              const SizedBox(width: 7),
              Text(
                'Retirá en: ${widget.standNombre}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDismissButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppConstants.primaryGreen, Color(0xFF00D4FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen
                    .withOpacity(_glowAnim.value * 0.65),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '¡Genial!  🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Confetti painter para el interior del popup
// ─────────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  final double animation;
  static const _colors = [
    AppConstants.primaryGreen,
    Color(0xFFFFD700),
    Color(0xFF00D4FF),
    Color(0xFFFF6B6B),
    Colors.white,
    Color(0xFFFF9EFF),
  ];

  _ConfettiPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99887);
    for (int i = 0; i < 22; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.6;
      final y = (baseY + animation * size.height * speed) % (size.height + 20);
      final color = _colors[random.nextInt(_colors.length)];
      final w = 4.0 + random.nextDouble() * 6;
      final h = 5.0 + random.nextDouble() * 9;
      final opacity = 0.15 + random.nextDouble() * 0.35;
      final angle = animation * math.pi * 2 * (random.nextDouble() * 4 - 2);

      final paint = Paint()..color = color.withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => animation != old.animation;
}
