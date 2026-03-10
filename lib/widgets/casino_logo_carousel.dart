import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CasinoLogoCarousel extends StatefulWidget {
  const CasinoLogoCarousel({
    super.key,
    this.logos = defaultLogos,
    this.height = 62,
    this.title = 'Powered By',
    this.autoPlayInterval = Duration.zero,
    this.animationDuration = const Duration(milliseconds: 1150),
  });

  static const List<String> defaultLogos = [
    'assets/images/bplay_logo.webp',
    'assets/images/sportsbet_logo.webp',
    'assets/images/betsson_logo.svg',
  ];

  final List<String> logos;
  final double height;
  final String title;
  final Duration autoPlayInterval;
  final Duration animationDuration;

  @override
  State<CasinoLogoCarousel> createState() => _CasinoLogoCarouselState();
}

class _CasinoLogoCarouselState extends State<CasinoLogoCarousel> {
  late final PageController _controller;
  bool _autoPlayRunning = false;

  int get _initialPage => widget.logos.length * 1000;
  double get _viewportFraction => kIsWeb ? 0.38 : 0.55;

  @override
  void initState() {
    super.initState();
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
        oldWidget.logos.length != widget.logos.length) {
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
        duration: widget.animationDuration,
        curve: Curves.linear,
      );
      if (!mounted || !_autoPlayRunning) break;
      if (widget.autoPlayInterval > Duration.zero) {
        await Future.delayed(widget.autoPlayInterval);
      }
    }

    _autoPlayRunning = false;
  }

  @override
  void dispose() {
    _autoPlayRunning = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logos = widget.logos;
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: _buildLogoAsset(asset),
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
