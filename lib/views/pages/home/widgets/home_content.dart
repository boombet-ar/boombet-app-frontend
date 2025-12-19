import 'dart:async';
import 'dart:io';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/publicidad_model.dart';
import 'package:boombet_app/services/publicidad_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  late final HttpClient _mediaHttpClient;
  final Set<int> _videoListenerAttached = {};
  final Map<int, Timer> _videoEndTimers = {};
  static const Duration _videoAdvanceDelay = Duration(seconds: 3);

  int _currentCarouselPage = 0;
  Timer? _autoScrollTimer;
  List<Publicidad> _ads = [];
  bool _adsLoading = true;
  String? _adsError;

  @override
  void initState() {
    super.initState();
    _mediaHttpClient = HttpClient();
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
    _mediaHttpClient.close(force: true);
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
      final ads = await _publicidadService.getMyAds();
      debugPrint('📡 HOME ads fetched: ${ads.length}');
      for (var (idx, ad) in ads.indexed) {
        debugPrint(
          '   [$idx] mediaUrl="${ad.mediaUrl}" type="${ad.mediaType}" desc="${ad.description}"',
        );
      }
      setState(() {
        _ads = ads.where((a) => a.mediaUrl.isNotEmpty).toList();
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
    } catch (e) {
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
      return raw.replaceAll(' ', '%20');
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

  Future<bool> _fetchRemoteMediaIsVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      final request = await _mediaHttpClient.headUrl(uri);
      final response = await request.close();
      final contentType = response.headers.contentType;
      final isVideo = contentType?.primaryType == 'video';
      debugPrint(
        '🌐 Media HEAD ${url} contentType=${contentType?.mimeType} -> isVideo=$isVideo',
      );
      return isVideo;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch media HEAD for $url: $e');
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

    debugPrint('🎥 Initializing video controller for index=$index url=$url');
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    if (_videoListenerAttached.add(index)) {
      controller.addListener(() {
        _handleVideoValueChange(index, controller);
      });
    }
    _videoControllers[index] = controller;
    final init = controller
        .initialize()
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
          throw error;
        });
    _videoInitFutures[index] = init;
    return init;
  }

  Widget _buildMedia(Publicidad ad, int index) {
    final resolvedUrl = _resolveUrl(ad.mediaUrl);
    final fallbackVideo = _shouldTreatAsVideo(ad, resolvedUrl);
    debugPrint(
      '🖼️ Render media idx=$index raw="${ad.mediaUrl}" resolved="$resolvedUrl" type="${ad.mediaType}" fallbackVideo=$fallbackVideo',
    );

    return FutureBuilder<bool>(
      future: _resolveMediaType(resolvedUrl, fallbackVideo),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final isVideo = snapshot.data!;
        if (isVideo) {
          return _buildVideoWidget(resolvedUrl, index);
        }
        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) {
            debugPrint('❌ Image load error for $url: $error');
            return const Center(child: Icon(Icons.broken_image));
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
            fit: BoxFit.contain,
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
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(ad, index),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${index + 1}/${_ads.length}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(int index, Color primaryGreen, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(color: primaryGreen.withValues(alpha: 0.05)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPromoIcon(index), size: 48, color: primaryGreen),
                const SizedBox(height: 8),
                Text(
                  _getPromoTitle(index),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Próximamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  if (_ads.isNotEmpty && !_adsLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ads[_currentCarouselPage].description ??
                                'Publicidad',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 1.5,
                            color: primaryGreen.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PageView.builder(
                      controller: _carouselController,
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                                        foregroundColor: Colors.black,
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
                          return _buildAdCard(
                            ad,
                            index,
                            primaryGreen,
                            textColor,
                          );
                        }

                        return AnimatedContainer(
                          duration: AppConstants.shortDelay,
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryGreen.withValues(alpha: 0.3),
                                primaryGreen.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: _buildPlaceholderCard(
                            index,
                            primaryGreen,
                            textColor,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _ads.isNotEmpty ? _ads.length : 1,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _currentCarouselPage == index ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentCarouselPage == index
                              ? primaryGreen
                              : primaryGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPromoIcon(int index) {
    switch (index) {
      case 0:
        return Icons.casino;
      case 1:
        return Icons.local_offer;
      case 2:
        return Icons.card_giftcard;
      case 3:
        return Icons.event;
      case 4:
        return Icons.stars;
      default:
        return Icons.casino;
    }
  }

  String _getPromoTitle(int index) {
    switch (index) {
      case 0:
        return 'Casinos Afiliados';
      case 1:
        return 'Ofertas Especiales';
      case 2:
        return 'Premios Exclusivos';
      case 3:
        return 'Eventos';
      case 4:
        return 'Beneficios VIP';
      default:
        return 'Promoción';
    }
  }
}
