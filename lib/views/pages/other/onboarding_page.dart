import 'package:flutter/material.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/widgets/form_fields.dart';

// ─── Constantes visuales ─────────────────────────────────────────────────────
const _scaffoldBg = Color(0xFF0A0A0A);
const _green = AppConstants.primaryGreen;

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      image: 'assets/images/screenshot_home.png',
      title: 'INICIO',
      description:
          'Enterate de las últimas novedades y promociones de tus casinos afiliados.',
    ),
    OnboardingSlide(
      image: 'assets/images/screenshot_discounts.png',
      title: 'DESCUENTOS',
      description: 'Conseguí increíbles descuentos y beneficios exclusivos.',
    ),
    OnboardingSlide(
      image: 'assets/images/screenshot_foros.png',
      title: 'FOROS',
      description:
          'Conectá con la comunidad de BoomBet y compartí tus experiencias.',
    ),
    OnboardingSlide(
      image: 'assets/images/screenshot_games.png',
      title: 'JUEGOS',
      description: 'Jugá y divertite con nuestros minijuegos exclusivos.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: Stack(
        children: [
          // Ambient glow background — radial verde en la base
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.9),
                  radius: 1.1,
                  colors: [
                    _green.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar: logo + skip ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/boombetlogo.png',
                        height: 26,
                      ),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Omitir',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.32),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Slides ────────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, i) =>
                        _OnboardingSlideWidget(slide: _slides[i]),
                  ),
                ),

                // ── Bottom: indicators + navigation ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicadores de página
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentPage == i ? 26 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? _green
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: _currentPage == i
                                  ? [
                                      BoxShadow(
                                        color: _green.withValues(alpha: 0.55),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botones
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: isLast
                            ? AppButton(
                                key: const ValueKey('last'),
                                label: '¡Empezar ahora!',
                                onPressed: widget.onComplete,
                                icon: Icons.rocket_launch_outlined,
                                borderRadius: AppConstants.borderRadius,
                                height: 54,
                              )
                            : Row(
                                key: const ValueKey('nav'),
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Contador de página
                                  Text(
                                    '${_currentPage + 1} / ${_slides.length}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.28),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  // Botón Siguiente — pill con glow
                                  _NextButton(onPressed: _nextPage),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón "Siguiente" custom pill ───────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_green, _green.withValues(alpha: 0.80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.42),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Siguiente',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slide widget ─────────────────────────────────────────────────────────────

class _OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;

  const _OnboardingSlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final compact = maxH < 560;

        final imageMaxH = (maxH * (compact ? 0.44 : 0.56)).clamp(180.0, 420.0);
        final imageMaxW = (maxW * (compact ? 0.72 : 0.68)).clamp(190.0, 300.0);
        final titleSize = (maxW * 0.085).clamp(24.0, 32.0);
        final descSize = (maxW * 0.043).clamp(13.0, 15.5);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: maxH - (compact ? 16 : 24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: compact ? 6 : 14),

                  // ── Screenshot con glow ───────────────────────────────────
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: imageMaxH,
                      maxWidth: imageMaxW,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.32),
                          blurRadius: 40,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: _green.withValues(alpha: 0.12),
                          blurRadius: 80,
                          spreadRadius: 8,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(slide.image, fit: BoxFit.contain),
                    ),
                  ),

                  SizedBox(height: compact ? 18 : 28),

                  // ── Título ────────────────────────────────────────────────
                  Text(
                    slide.title,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: _green,
                      letterSpacing: compact ? 1.6 : 2.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: compact ? 8 : 10),

                  // Acento subrayado verde con glow
                  Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withValues(alpha: 0.70),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: compact ? 12 : 16),

                  // ── Descripción ───────────────────────────────────────────
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW * 0.88),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 14 : 18,
                        vertical: compact ? 11 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        slide.description,
                        style: TextStyle(
                          fontSize: descSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.68),
                          height: compact ? 1.4 : 1.55,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class OnboardingSlide {
  final String image;
  final String title;
  final String description;

  OnboardingSlide({
    required this.image,
    required this.title,
    required this.description,
  });
}
