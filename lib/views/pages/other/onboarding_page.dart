import 'package:flutter/foundation.dart';
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
      image: 'assets/images/screenshot_casinos.png',
      title: 'CASINOS',
      description: 'Explorá y accede facilmente a tus casinos afiliados.',
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
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final size = MediaQuery.of(context).size;
    final imageMaxHeight = isIOS
        ? (size.height * 0.44).clamp(220.0, 420.0)
        : 500.0;
    final imageMaxWidth = isIOS
        ? (size.width * 0.68).clamp(200.0, 280.0)
        : 280.0;
    final topSpacing = isIOS ? 8.0 : 20.0;
    final imageBottomSpacing = isIOS ? 24.0 : 48.0;
    final titleFontSize = isIOS ? 28.0 : 32.0;
    final descriptionFontSize = isIOS ? 15.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: isIOS
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            mainAxisSize: isIOS ? MainAxisSize.min : MainAxisSize.max,
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
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                slide.description,
                style: TextStyle(
                  fontSize: descriptionFontSize,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? Colors.white70
                      : AppConstants.textLight.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

        if (!isIOS) return content;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
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
