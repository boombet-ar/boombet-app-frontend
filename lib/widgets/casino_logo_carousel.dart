import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CasinoLogoCarousel extends StatefulWidget {
  const CasinoLogoCarousel({
    super.key,
    this.logos = defaultLogos,
    this.comingSoonLogos = defaultComingSoonLogos,
    this.height = 62,
    this.title = 'Powered By',
    this.autoPlayInterval = Duration.zero,
    this.animationDuration = const Duration(milliseconds: 1150),
  });

  static const List<String> defaultLogos = [
    'assets/images/bplay_logo.webp',
    'assets/images/betano_logo.png',
    'assets/images/sportsbet_logo.webp',
    'assets/images/betponcho_logo.svg',
    'assets/images/betsson_logo.svg',
    'assets/images/betnor_logo.png',
    'assets/images/easybet_logo.svg',
  ];

  static const List<String> defaultComingSoonLogos = [
    'assets/images/betnor_logo.png',
    'assets/images/easybet_logo.svg',
  ];

  final List<String> logos;
  final List<String> comingSoonLogos;
  final double height;
  final String title;
  final Duration autoPlayInterval;
  final Duration animationDuration;

  @override
  State<CasinoLogoCarousel> createState() => _CasinoLogoCarouselState();
}

class _CasinoLogoCarouselState extends State<CasinoLogoCarousel> {
  late final PageController _controller;
  late final List<String> _shuffledLogos;
  bool _autoPlayRunning = false;
  static const double _webReferenceViewport = 600;

  int get _initialPage => _shuffledLogos.length * 1000;
  double get _viewportFraction => kIsWeb ? 0.38 : 0.55;

  List<String> _buildShuffledLogos() {
    final rng = Random();
    final coming = widget.comingSoonLogos.toSet();
    final list = [...widget.logos];
    // Retry shuffle until no two coming-soon logos are adjacent (including wrap-around).
    do {
      list.shuffle(rng);
    } while (_hasAdjacentComingSoon(list, coming));
    return list;
  }

  bool _hasAdjacentComingSoon(List<String> list, Set<String> coming) {
    final n = list.length;
    for (var i = 0; i < n; i++) {
      if (coming.contains(list[i]) && coming.contains(list[(i + 1) % n])) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _shuffledLogos = _buildShuffledLogos();
    _controller = PageController(
      viewportFraction: _viewportFraction,
      initialPage: _initialPage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoPlay();
    });
  }

  double _maxCardWidth(double availableWidth) {
    if (!kIsWeb) return availableWidth;
    if (availableWidth >= 1400) return 220;
    if (availableWidth >= 1100) return 205;
    if (availableWidth >= 800) return 190;
    if (availableWidth >= 600) return 176;
    return 168;
  }

  @override
  void didUpdateWidget(covariant CasinoLogoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlayInterval != widget.autoPlayInterval ||
        oldWidget.animationDuration != widget.animationDuration ||
        oldWidget.logos.length != widget.logos.length ||
        oldWidget.comingSoonLogos.length != widget.comingSoonLogos.length) {
      _autoPlayRunning = false;
      _startAutoPlay();
    }
  }

  Future<void> _startAutoPlay() async {
    if (_autoPlayRunning || widget.logos.length <= 1) return;
    _autoPlayRunning = true;

    while (mounted && _controller.hasClients && _autoPlayRunning) {
      final currentPage = _controller.page?.round() ?? _controller.initialPage;
      await _controller.animateToPage(
        currentPage + 1,
        duration: _effectiveAnimationDuration(),
        curve: Curves.linear,
      );
      if (!mounted || !_autoPlayRunning) break;
      if (widget.autoPlayInterval > Duration.zero) {
        await Future.delayed(widget.autoPlayInterval);
      }
    }

    _autoPlayRunning = false;
  }

  Duration _effectiveAnimationDuration() {
    // Mobile keeps existing behavior.
    if (!kIsWeb) return widget.animationDuration;
    if (!_controller.hasClients) return widget.animationDuration;

    final baseMs = widget.animationDuration.inMilliseconds;
    if (baseMs <= 0) return widget.animationDuration;

    final viewport = _controller.position.viewportDimension;
    if (viewport <= 0) return widget.animationDuration;

    // Keep speed (px/s) constant across responsive web sizes.
    final factor = (viewport / _webReferenceViewport).clamp(0.85, 3.0);
    return Duration(milliseconds: (baseMs * factor).round());
  }

  @override
  void dispose() {
    _autoPlayRunning = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logos = _shuffledLogos;
    if (logos.isEmpty) return const SizedBox.shrink();

    final textColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: textColor.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxCardWidth = _maxCardWidth(constraints.maxWidth);
              return PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final asset = logos[index % logos.length];
                  final isComingSoon = widget.comingSoonLogos.contains(asset);
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: maxCardWidth,
                        height: widget.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: isComingSoon
                                      ? ImageFiltered(
                                          imageFilter: ImageFilter.blur(
                                            sigmaX: 6.0,
                                            sigmaY: 6.0,
                                          ),
                                          child: Opacity(
                                            opacity: 0.30,
                                            child: _buildLogoAsset(asset),
                                          ),
                                        )
                                      : _buildLogoAsset(asset),
                                ),
                                if (isComingSoon)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 3,
                                        children: [
                                          Icon(
                                            Icons.lock_rounded,
                                            size: 13,
                                            color: Colors.white.withValues(alpha: 0.55),
                                          ),
                                          Text(
                                            'Próximamente',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.80),
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogoAsset(String assetPath) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(assetPath, fit: BoxFit.contain);
    }
    return Image.asset(assetPath, fit: BoxFit.contain);
  }
}
