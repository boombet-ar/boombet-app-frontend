import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/publicidad_model.dart';
import 'package:boombet_app/services/publicidad_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/profile_page.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class HomeContent extends StatefulWidget {
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _carouselController = PageController();
  final PublicidadService _publicidadService = PublicidadService();
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, Future<void>> _videoInitFutures = {};
  final Map<String, Future<bool>> _mediaTypeCache = {};
  final Set<int> _videoListenerAttached = {};
  final Map<int, Timer> _videoEndTimers = {};
  static const Duration _videoAdvanceDelay = Duration(seconds: 3);
  static const double _adAspectRatio =
      9 / 17; // Slightly taller viewport for ads

  int _currentCarouselPage = 0;
  Timer? _autoScrollTimer;
  List<Publicidad> _ads = [];
  bool _adsLoading = true;
  String? _adsError;

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _carouselController.hasClients) {
        final total = _ads.isNotEmpty ? _ads.length : 1;
        final nextPage = (_currentCarouselPage + 1) % total;
        _carouselController.animateToPage(
          nextPage,
          duration: AppConstants.mediumDelay,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _autoScrollTimer?.cancel();
    _carouselController.dispose();
    _videoListenerAttached.clear();
    _videoEndTimers.values.forEach((timer) => timer.cancel());
    _videoEndTimers.clear();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    setState(() {
      _adsLoading = true;
      _adsError = null;
    });

    try {
      debugPrint('📡 [${kIsWeb ? "WEB" : "MOBILE"}] Fetching ads...');
      final ads = await _publicidadService.getMyAds();
      debugPrint('📡 HOME ads fetched: ${ads.length}');
      for (var (idx, ad) in ads.indexed) {
        debugPrint(
          '   [$idx] mediaUrl="${ad.mediaUrl}" type="${ad.mediaType}" desc="${ad.description}"',
        );
      }

      final filteredAds = ads.where((a) => a.mediaUrl.isNotEmpty).toList();
      debugPrint('📡 Filtered ads (non-empty mediaUrl): ${filteredAds.length}');

      if (filteredAds.isEmpty) {
        debugPrint('⚠️ No ads with valid mediaUrl');
      }

      setState(() {
        _ads = filteredAds;
        _currentCarouselPage = 0;
        _adsLoading = false;
      });
      if (_carouselController.hasClients && _ads.isNotEmpty) {
        _carouselController.jumpToPage(0);
      }
      _restartAutoScroll();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_preloadVideoAds());
        unawaited(_prepareVideoForPage(0));
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching ads: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _adsError = 'No se pudieron cargar las publicidades: $e';
        _adsLoading = false;
      });
    }
  }

  void _restartAutoScroll() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m3u8');
  }

  bool _shouldTreatAsVideo(Publicidad ad, String resolvedUrl) {
    final mediaType = ad.mediaType.toUpperCase();
    return ad.isVideo ||
        mediaType.contains('VIDEO') ||
        _isVideoUrl(resolvedUrl);
  }

  Future<void> _preloadVideoAds() async {
    if (_ads.isEmpty) return;
    debugPrint('[AD VIDEO] Preload start for ${_ads.length} ads');
    for (final entry in _ads.indexed) {
      final index = entry.$1;
      final ad = entry.$2;
      final resolvedUrl = _resolveUrl(ad.mediaUrl);
      final shouldVideo = _shouldTreatAsVideo(ad, resolvedUrl);
      if (!shouldVideo) continue;
      final isVideo = await _resolveMediaType(resolvedUrl, shouldVideo);
      if (!isVideo) {
        debugPrint(
          '[AD VIDEO] Preload skip idx=$index url=$resolvedUrl (not detected as video)',
        );
        continue;
      }
      unawaited(_initAndPauseVideo(index, resolvedUrl));
    }
  }

  Future<void> _initAndPauseVideo(int index, String url) async {
    try {
      final controller = await _ensureVideoController(index, url);
      if (!controller.value.isInitialized) return;
      await controller.pause();
      await controller.seekTo(Duration.zero);
      debugPrint('[AD VIDEO] Preloaded idx=$index and paused at start');
    } catch (e) {
      debugPrint('[AD VIDEO] Preload failed idx=$index url=$url error=$e');
    }
  }

  Future<void> _prepareVideoForPage(int index) async {
    if (_ads.isEmpty || index < 0 || index >= _ads.length) return;
    final ad = _ads[index];
    final resolvedUrl = _resolveUrl(ad.mediaUrl);
    if (!_shouldTreatAsVideo(ad, resolvedUrl)) return;
    _autoScrollTimer?.cancel();
    try {
      final controller = await _ensureVideoController(index, resolvedUrl);
      if (!controller.value.isInitialized) return;
      await controller.seekTo(Duration.zero);
      controller.play();
      _cancelVideoEndTimer(index);
      _restartAutoScroll();
      debugPrint('[AD VIDEO] Play on enter idx=$index');
    } catch (error) {
      debugPrint('❌ Preparing video page $index failed: $error');
    }
  }

  void _advanceCarouselAfterVideo(int index) {
    if (!_carouselController.hasClients || _ads.isEmpty) return;
    final nextPage = (index + 1) % _ads.length;
    _carouselController.animateToPage(
      nextPage,
      duration: AppConstants.mediumDelay,
      curve: Curves.easeInOut,
    );
  }

  void _handleVideoValueChange(int index, VideoPlayerController controller) {
    final value = controller.value;
    if (!value.isInitialized) return;
    if (_currentCarouselPage != index) {
      return;
    }
    final duration = value.duration;
    if (duration == Duration.zero) return;
    final isNearEnd =
        value.position >= duration - const Duration(milliseconds: 250);
    if (isNearEnd && !_videoEndTimers.containsKey(index)) {
      debugPrint('[AD VIDEO] End detected idx=$index scheduling advance');
      _videoEndTimers[index] = Timer(_videoAdvanceDelay, () {
        _videoEndTimers.remove(index);
        if (_currentCarouselPage != index) return;
        _advanceCarouselAfterVideo(index);
      });
      unawaited(
        controller.seekTo(Duration.zero).then((_) => controller.play()),
      );
    }
  }

  void _cancelVideoEndTimer(int index) {
    final timer = _videoEndTimers.remove(index);
    timer?.cancel();
  }

  Future<void> _pauseAndResetVideo(int index) async {
    final controller = _videoControllers[index];
    if (controller == null) return;
    try {
      await controller.pause();
      await controller.seekTo(Duration.zero);
      debugPrint('[AD VIDEO] Pause+reset idx=$index');
    } catch (e) {
      debugPrint('[AD VIDEO] Pause+reset failed idx=$index error=$e');
    }
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      // Parsear la URL y codificar correctamente cada componente
      try {
        final uri = Uri.parse(raw);
        // Reconstruir la URL con path segments correctamente codificados
        final encodedUri = Uri(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port,
          pathSegments: uri.pathSegments,
        );
        debugPrint('🔧 URL encoded: $raw -> ${encodedUri.toString()}');
        return encodedUri.toString();
      } catch (e) {
        debugPrint('⚠️ Error parsing URL $raw: $e');
        // Fallback: reemplazar espacios manualmente
        return raw.replaceAll(' ', '%20');
      }
    }
    final base = ApiConfig.baseUrl;
    final baseUri = Uri.parse(base);
    final path = baseUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    final joined = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: raw.startsWith('/') ? raw : '$path/$raw',
    );
    return joined.toString();
  }

  String _proxyImageForWeb(String url) {
    if (!kIsWeb) return url;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return url;
    try {
      // No doble codificar: la URL ya viene con %20.
      // Weserv acepta la URL completa tal cual en el query param.
      final proxied = '$proxyBase$url';
      debugPrint('🌀 Web image proxy: $url -> $proxied');
      return proxied;
    } catch (e) {
      debugPrint('⚠️ Proxy failed for $url: $e');
      return url;
    }
  }

  Future<bool> _fetchRemoteMediaIsVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http
          .head(uri)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('', 408),
          );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type']?.toLowerCase();
        final isVideo = contentType?.startsWith('video/') ?? false;
        debugPrint(
          '🌐 Media HEAD $url contentType=$contentType -> isVideo=$isVideo',
        );
        return isVideo;
      }

      debugPrint('⚠️ HEAD request failed for $url: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch media HEAD for $url: $e');
      // En web, si falla el HEAD, intentar detectar por extensión
      if (kIsWeb) {
        return _isVideoUrl(url);
      }
      return false;
    }
  }

  Future<bool> _resolveMediaType(String url, bool fallbackVideo) {
    return _mediaTypeCache.putIfAbsent(url, () async {
      if (_isLikelyVideoFromUrl(url)) {
        debugPrint('🎯 Forced video based on URL pattern: $url');
        return true;
      }
      final isVideo = await _fetchRemoteMediaIsVideo(url);
      return isVideo || fallbackVideo;
    });
  }

  bool _isLikelyVideoFromUrl(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      return path.endsWith('.mp4');
    } catch (_) {
      return url.toLowerCase().endsWith('.mp4');
    }
  }

  Future<VideoPlayerController> _ensureVideoController(int index, String url) {
    final existing = _videoControllers[index];
    final existingInit = _videoInitFutures[index];
    if (existing != null) {
      if (existingInit != null && !existing.value.isInitialized) {
        debugPrint('[AD VIDEO] Awaiting existing init idx=$index');
        return existingInit.then((_) => existing);
      }
      return Future.value(existing);
    }

    debugPrint(
      '🎥 Initializing video controller for index=$index url=$url (web: $kIsWeb)',
    );
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    if (_videoListenerAttached.add(index)) {
      controller.addListener(() {
        _handleVideoValueChange(index, controller);
      });
    }
    _videoControllers[index] = controller;
    final init = controller
        .initialize()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⏱️ Video initialization timeout for index=$index');
            throw TimeoutException('Video initialization timeout');
          },
        )
        .then((_) {
          debugPrint(
            '✅ Video initialized successfully for index=$index duration=${controller.value.duration}',
          );
          controller.setLooping(false);
          controller.pause();
          return controller;
        })
        .catchError((error) {
          debugPrint('❌ Video initialization error for index=$index: $error');
          if (kIsWeb) {
            debugPrint(
              '⚠️ Web video error - esto puede ser CORS o formato no soportado',
            );
          }
          throw error;
        });

    _videoInitFutures[index] = init.then((_) {});
    return init;
  }

  Widget _buildMedia(Publicidad ad, int index) {
    final resolvedUrl = _resolveUrl(ad.mediaUrl);
    final fallbackVideo = _shouldTreatAsVideo(ad, resolvedUrl);

    return FutureBuilder<bool>(
      future: _resolveMediaType(resolvedUrl, fallbackVideo),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final isVideo = snapshot.data!;
        if (isVideo) {
          // En web usar la URL directa; los proxys suelen romper streaming MP4.
          final videoUrl = resolvedUrl;
          if (kIsWeb && !videoUrl.contains(Uri.parse(ApiConfig.baseUrl).host)) {
            debugPrint(
              '⚠️ Web: video desde dominio externo puede tener problemas de CORS',
            );
          }
          return _buildVideoWidget(videoUrl, index);
        }
        final displayUrl = kIsWeb
            ? _proxyImageForWeb(resolvedUrl)
            : resolvedUrl;
        return CachedNetworkImage(
          imageUrl: displayUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) {
            debugPrint('❌ Image load error for $url: $error');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 48),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Imagen no disponible\n(puede ser un problema de CORS)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoWidget(String url, int index) {
    final initFuture = _ensureVideoController(index, url);
    return FutureBuilder<VideoPlayerController>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final controller = snapshot.data!;
        if (_currentCarouselPage == index && controller.value.isInitialized) {
          unawaited(
            controller.seekTo(Duration.zero).then((_) {
              controller.play();
              debugPrint('[AD VIDEO] Auto-play from builder idx=$index');
              _restartAutoScroll();
            }),
          );
        }
        return Center(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdCard(
    Publicidad ad,
    int index,
    Color primaryGreen,
    Color textColor,
  ) {
    return AnimatedContainer(
      duration: AppConstants.shortDelay,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withValues(alpha: 0.08),
            primaryGreen.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.16),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(ad, index),
            // Simplify: keep media clean without overlays or counters.
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final isWeb = kIsWeb;

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Inicio',
          subtitle: 'Anuncios y novedades personalizadas',
          icon: Icons.campaign,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isWeb
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildCarouselPanel(
                          primaryGreen: primaryGreen,
                          textColor: textColor,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickActionsPanel(
                          primaryGreen: primaryGreen,
                          textColor: textColor,
                          isDark: isDark,
                          onGoToDiscounts: () => selectedPageNotifier.value = 1,
                          onGoToRaffles: () => selectedPageNotifier.value = 2,
                          onGoToForum: () => selectedPageNotifier.value = 3,
                          onGoToGames: () => selectedPageNotifier.value = 4,
                          onGoToCasinos: () => selectedPageNotifier.value = 5,
                          onGoToProfile: () {
                            Navigator.push(
                              context,
                              ScaleRoute(page: ProfilePage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : _buildCarouselPanel(
                  primaryGreen: primaryGreen,
                  textColor: textColor,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCarouselPanel({
    required Color primaryGreen,
    required Color textColor,
    required EdgeInsetsGeometry margin,
  }) {
    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: Column(
          children: [
            if (_ads.isNotEmpty && !_adsLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen.withValues(alpha: 0.14),
                        primaryGreen.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.25),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryGreen.withValues(alpha: 0.16),
                        ),
                        child: Icon(Icons.campaign, color: textColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Publicidad destacada',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _ads[_currentCarouselPage].description ??
                                  'Publicidad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.35,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _adAspectRatio,
                  child: PageView.builder(
                    controller: _carouselController,
                    scrollBehavior: kIsWeb
                        ? MaterialScrollBehavior().copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          )
                        : null,
                    onPageChanged: (index) {
                      final previousIndex = _currentCarouselPage;
                      setState(() {
                        _currentCarouselPage = index;
                      });
                      _cancelVideoEndTimer(previousIndex);
                      unawaited(_pauseAndResetVideo(previousIndex));
                      unawaited(_prepareVideoForPage(index));
                    },
                    itemCount: _ads.isNotEmpty ? _ads.length : 1,
                    itemBuilder: (context, index) {
                      if (_adsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_adsError != null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 36,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      _adsError!,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: _fetchAds,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reintentar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: AppConstants.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      if (_ads.isNotEmpty) {
                        final ad = _ads[index];
                        debugPrint(
                          '🎞️ Showing ad index=$index url=${ad.mediaUrl}',
                        );
                        return _buildAdCard(ad, index, primaryGreen, textColor);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: primaryGreen.withValues(alpha: 0.08),
                          border: Border.all(
                            color: primaryGreen.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay ninguna publicidad para mostrar actualmente',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _ads.isNotEmpty ? _ads.length : 1,
                (index) => GestureDetector(
                  onTap: () {
                    if (_carouselController.hasClients && _ads.isNotEmpty) {
                      _carouselController.animateToPage(
                        index,
                        duration: AppConstants.mediumDelay,
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: AppConstants.shortDelay,
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: _currentCarouselPage == index ? 34 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: _currentCarouselPage == index
                              ? [
                                  primaryGreen,
                                  primaryGreen.withValues(alpha: 0.7),
                                ]
                              : [
                                  primaryGreen.withValues(alpha: 0.25),
                                  primaryGreen.withValues(alpha: 0.18),
                                ],
                        ),
                        boxShadow: _currentCarouselPage == index
                            ? [
                                BoxShadow(
                                  color: primaryGreen.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.primaryGreen,
    required this.textColor,
    required this.isDark,
    required this.onGoToDiscounts,
    required this.onGoToRaffles,
    required this.onGoToForum,
    required this.onGoToGames,
    required this.onGoToCasinos,
    required this.onGoToProfile,
  });

  final Color primaryGreen;
  final Color textColor;
  final bool isDark;

  final VoidCallback onGoToDiscounts;
  final VoidCallback onGoToRaffles;
  final VoidCallback onGoToForum;
  final VoidCallback onGoToGames;
  final VoidCallback onGoToCasinos;
  final VoidCallback onGoToProfile;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0A) : AppConstants.lightBg;
    final panelBorder = isDark
        ? primaryGreen.withValues(alpha: 0.18)
        : AppConstants.borderLight.withValues(alpha: 0.85);

    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        const gridSpacing = 8.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: squareSide,
            height: squareSide,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen.withValues(alpha: isDark ? 0.14 : 0.10),
                    bg.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(color: panelBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryGreen.withValues(alpha: 0.16),
                          ),
                          child: Icon(
                            Icons.grid_view,
                            color: textColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accesos rápidos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Saltá directo a cualquier sección',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          // Calcula cuántas “filas” entran, así la grilla rellena el
                          // cuadrado completo sin dejar huecos abajo y sin scroll.
                          final cell = gridConstraints.maxWidth / 12;
                          final rows =
                              ((gridConstraints.maxHeight + gridSpacing) /
                                      (cell + gridSpacing))
                                  .floor()
                                  .clamp(7, 18);

                          const minBottomRows = 3;
                          final maxLargeRows = math.max(
                            4,
                            rows - minBottomRows,
                          );
                          final largeRows = (rows * 0.58).round().clamp(
                            4,
                            maxLargeRows,
                          );
                          final bottomRows = math.max(
                            minBottomRows,
                            rows - largeRows,
                          );

                          final rightTopRows = (largeRows * 0.55).round().clamp(
                            2,
                            largeRows - 2,
                          );
                          final rightBottomRows = largeRows - rightTopRows;

                          final forumRows = bottomRows;
                          final casinosRows = (bottomRows - 1).clamp(
                            3,
                            bottomRows,
                          );
                          final profileRows = bottomRows;

                          return StaggeredGrid.count(
                            // Asimétrico, “mosaico caótico” y no scrolleable.
                            crossAxisCount: 12,
                            mainAxisSpacing: gridSpacing,
                            crossAxisSpacing: gridSpacing,
                            children: [
                              // Bloque grande: ancla visual.
                              StaggeredGridTile.count(
                                crossAxisCellCount: 7,
                                mainAxisCellCount: largeRows,
                                child: _QuickActionTile(
                                  title: 'Juegos',
                                  subtitle: 'Minijuegos',
                                  icon: Icons.videogame_asset,
                                  accent:
                                      Color.lerp(
                                        primaryGreen,
                                        Colors.purple,
                                        0.22,
                                      ) ??
                                      primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToGames,
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 5,
                                mainAxisCellCount: rightTopRows,
                                child: _QuickActionTile(
                                  title: 'Descuentos',
                                  subtitle: 'Cupones y ofertas',
                                  icon: Icons.local_offer,
                                  accent: primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToDiscounts,
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 5,
                                mainAxisCellCount: rightBottomRows,
                                child: _QuickActionTile(
                                  title: 'Sorteos',
                                  subtitle: 'Participá',
                                  icon: Icons.card_giftcard,
                                  accent:
                                      Color.lerp(
                                        primaryGreen,
                                        Colors.amber,
                                        0.25,
                                      ) ??
                                      primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToRaffles,
                                ),
                              ),

                              // Bloque inferior: tres tiles con alturas distintas.
                              StaggeredGridTile.count(
                                crossAxisCellCount: 4,
                                mainAxisCellCount: forumRows,
                                child: _QuickActionTile(
                                  title: 'Foro',
                                  subtitle: 'Comunidad',
                                  icon: Icons.forum,
                                  accent:
                                      Color.lerp(
                                        primaryGreen,
                                        Colors.cyan,
                                        0.22,
                                      ) ??
                                      primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToForum,
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 4,
                                mainAxisCellCount: casinosRows,
                                child: _QuickActionTile(
                                  title: 'Casinos',
                                  subtitle: 'Afiliados',
                                  icon: Icons.casino,
                                  accent:
                                      Color.lerp(
                                        primaryGreen,
                                        Colors.teal,
                                        0.20,
                                      ) ??
                                      primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToCasinos,
                                ),
                              ),
                              StaggeredGridTile.count(
                                crossAxisCellCount: 4,
                                mainAxisCellCount: profileRows,
                                child: _QuickActionTile(
                                  title: 'Perfil',
                                  subtitle: 'Tu cuenta',
                                  icon: Icons.person,
                                  accent:
                                      Color.lerp(
                                        primaryGreen,
                                        Colors.blue,
                                        0.18,
                                      ) ??
                                      primaryGreen,
                                  isDark: isDark,
                                  onTap: onGoToProfile,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : AppConstants.textLight;
    final fgSoft = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : AppConstants.textLight.withValues(alpha: 0.9);
    final surfaceVariant = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppConstants.lightSurfaceVariant;
    final borderColor = isDark
        ? accent.withValues(alpha: 0.22)
        : AppConstants.borderLight.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.22 : 0.16),
                accent.withValues(alpha: isDark ? 0.08 : 0.06),
              ],
            ),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Icon(
                    icon,
                    size: 74,
                    color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.10),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.9),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 17, color: fg),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: fgSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
