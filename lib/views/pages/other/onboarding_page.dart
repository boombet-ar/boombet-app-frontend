import 'package:flutter/material.dart';

import 'package:boombet_app/config/app_constants.dart';

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
          'Enterate de las ultimas novedades y promociones de tus casinos afiliados.',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : AppConstants.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Page view con las diapositivas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingSlideWidget(
                    slide: _slides[index],
                    primaryGreen: primaryGreen,
                  );
                },
              ),
            ),

            // Indicadores de página
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? primaryGreen
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Omitir
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Omitir',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : AppConstants.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Botón Siguiente
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Comenzar'
                          : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;
  final Color primaryGreen;

  const _OnboardingSlideWidget({
    required this.slide,
    required this.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final compactWidth = maxWidth < 360;
        final compactHeight = maxHeight < 560;

        final imageMaxHeight = (maxHeight * (compactHeight ? 0.44 : 0.56))
            .clamp(180.0, 420.0);
        final imageMaxWidth = (maxWidth * (compactWidth ? 0.72 : 0.68)).clamp(
          190.0,
          300.0,
        );
        final topSpacing = compactHeight ? 6.0 : 14.0;
        final imageBottomSpacing = compactHeight ? 14.0 : 28.0;
        final titleFontSize = (maxWidth * 0.085).clamp(24.0, 32.0);
        final descriptionFontSize = (maxWidth * 0.043).clamp(13.0, 16.0);

        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topSpacing),
              // Screenshot del mockup del teléfono
              Container(
                constraints: BoxConstraints(
                  maxHeight: imageMaxHeight,
                  maxWidth: imageMaxWidth,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(slide.image, fit: BoxFit.contain),
                ),
              ),

              SizedBox(height: imageBottomSpacing),

              // Título
              Text(
                slide.title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: primaryGreen,
                  letterSpacing: compactWidth ? 1.4 : 2,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: compactHeight ? 10 : 16),

              // Descripción
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth * 0.9),
                child: Text(
                  slide.description,
                  style: TextStyle(
                    fontSize: descriptionFontSize,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white70
                        : AppConstants.textLight.withValues(alpha: 0.7),
                    height: compactHeight ? 1.35 : 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: compactHeight ? 8 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (compactHeight ? 16 : 24),
            ),
            child: content,
          ),
        );
      },
    );
  }
}

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
