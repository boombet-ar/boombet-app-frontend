import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/publicidad_model.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/publicidad_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/profile/profile_page.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
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
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.boombet.app';

  int _currentCarouselPage = 0;
  Timer? _autoScrollTimer;
  List<Publicidad> _ads = [];
  bool _adsLoading = true;
  String? _adsError;
  bool _rouletteChecked = false;
  bool _rouletteDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchAds();
    rouletteTriggerAfterTutorialNotifier.addListener(_onRouletteTriggerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowRouletteOnce();
    });
  }

  void _onRouletteTriggerChanged() {
    if (!mounted) return;
    if (rouletteTriggerAfterTutorialNotifier.value) {
      _checkAndShowRouletteOnce();
    }
  }

  Future<void> _checkAndShowRouletteOnce() async {
    if (kIsWeb) return;
    if (_rouletteChecked) return;

    if (!rouletteTriggerAfterTutorialNotifier.value) {
      return;
    }

    if (loginTutorialActiveNotifier.value) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _checkAndShowRouletteOnce();
        }
      });
      return;
    }

    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null && !currentRoute.isCurrent) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          _checkAndShowRouletteOnce();
        }
      });
      return;
    }

    try {
      final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
      if (isFirstLogin == false) return;

      await loadAffiliateCodeUsage();
      final eligible = !affiliateCodeValidatedNotifier.value;
      if (!eligible) return;

      if (_rouletteDialogOpen) return;
      if (!mounted) return;

      _rouletteChecked = true;

      _rouletteDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (dialogContext) =>
            PopScope(canPop: false, child: const _RouletteDialog()),
      );
    } finally {
      if (!_rouletteDialogOpen) {
        _rouletteChecked = true;
      }
      _rouletteDialogOpen = false;
    }
  }

  Future<bool?> _getCurrentUserIsFirstLoginSafely() async {
    try {
      return await PlayerService().getCurrentUserIsFirstLogin();
    } catch (_) {
      return null;
    }
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
    rouletteTriggerAfterTutorialNotifier.removeListener(
      _onRouletteTriggerChanged,
    );
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

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo abrir Play Store.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
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
          fit: BoxFit.cover,
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
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(ad, index),
            if (ad.description != null && ad.description!.trim().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 52),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Text(
                    ad.description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
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
    final isWeb = kIsWeb;

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Inicio',
          subtitle: 'Los ultimos anuncios de tus casinos afiliados',
          icon: Icons.campaign,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final homeBody = isWeb
                  ? (() {
                      final isNarrowWeb = constraints.maxWidth < 900;
                      if (isNarrowWeb) {
                        return _buildWebNarrowHomeLayout(
                          primaryGreen: primaryGreen,
                          textColor: textColor,
                        );
                      }

                      return _buildWebDesktopHomeLayout(
                        primaryGreen: primaryGreen,
                        textColor: textColor,
                      );
                    })()
                  : _buildCarouselPanel(
                      primaryGreen: primaryGreen,
                      textColor: textColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    );

              if (isWeb) {
                return SizedBox(height: constraints.maxHeight, child: homeBody);
              }

              return RefreshIndicator(
                onRefresh: _fetchAds,
                color: primaryGreen,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: constraints.maxHeight, child: homeBody),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebDesktopHomeLayout({
    required Color primaryGreen,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          _buildWebStoreStrip(primaryGreen: primaryGreen, textColor: textColor),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildCarouselPanel(
                  primaryGreen: primaryGreen,
                  textColor: textColor,
                  margin: EdgeInsets.zero,
                  maxPanelWidth: 600,
                  maxAdWidth: 420,
                  adAspectRatio: 9 / 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebNarrowHomeLayout({
    required Color primaryGreen,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Column(
        children: [
          _buildWebStoreStrip(primaryGreen: primaryGreen, textColor: textColor),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildCarouselPanel(
                  primaryGreen: primaryGreen,
                  textColor: textColor,
                  margin: EdgeInsets.zero,
                  maxPanelWidth: 480,
                  maxAdWidth: 340,
                  adAspectRatio: 9 / 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStoreStrip({
    required Color primaryGreen,
    required Color textColor,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryGreen.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Descargá la app:',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),
            _buildPlayStoreLogoButton(compact: true, stripMode: true),
            const SizedBox(width: 8),
            _buildAppStoreComingSoonButton(compact: true, textColor: textColor, stripMode: true),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDownloadCard({
    required Color primaryGreen,
    required Color textColor,
    bool compact = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // — Radial glow accent (centered top) —
            Positioned(
              top: -40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 160,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryGreen.withValues(alpha: 0.13),
                        primaryGreen.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // — Contenido principal centrado —
            Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
                  : const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Todas las funciones en tu móvil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.38),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: compact ? 10 : 12),
                  // Store buttons centrados
                  _buildStoreButtonsRow(compact: compact, textColor: textColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreButtonsRow({
    required bool compact,
    required Color textColor,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: compact ? 14 : 20,
      runSpacing: 12,
      children: [
        _buildPlayStoreLogoButton(compact: compact),
        _buildAppStoreComingSoonButton(compact: compact, textColor: textColor),
      ],
    );
  }

  Widget _buildPlayStoreLogoButton({required bool compact, bool stripMode = false}) {
    final height = stripMode ? 28.0 : (compact ? 40.0 : 52.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPlayStore,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: stripMode ? 2 : (compact ? 4 : 6),
            vertical: stripMode ? 2 : (compact ? 4 : 6),
          ),
          child: SvgPicture.asset(
            'assets/images/playstore_logo.svg',
            height: height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAppStoreComingSoonButton({
    required bool compact,
    required Color textColor,
    bool stripMode = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = stripMode ? 28.0 : (compact ? 40.0 : 52.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Logo más visible: mayor opacidad, menor blur
        Opacity(
          opacity: 0.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
              child: SvgPicture.asset(
                'assets/images/appstore_logo.svg',
                height: height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Badge "Proximamente" — más compacto y sutil
        IgnorePointer(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: stripMode ? 5 : (compact ? 8 : 10),
              vertical: stripMode ? 2 : (compact ? 3.5 : 4.5),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.black.withValues(alpha: isDark ? 0.58 : 0.55),
              border: Border.all(
                color: textColor.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              'Próximamente',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.90),
                fontSize: stripMode ? 7.5 : (compact ? 9.5 : 10.5),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
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
    double? maxPanelWidth,
    double? maxAdWidth,
    double adAspectRatio = _adAspectRatio,
  }) {
    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxAdWidth ?? double.infinity,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: adAspectRatio,
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
                          return _buildAdCard(
                            ad,
                            index,
                            primaryGreen,
                            textColor,
                          );
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
                      Positioned(
                        bottom: 14,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _ads.isNotEmpty ? _ads.length : 1,
                            (index) => GestureDetector(
                              onTap: () {
                                if (_carouselController.hasClients &&
                                    _ads.isNotEmpty) {
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
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width:
                                      _currentCarouselPage == index ? 24 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: _currentCarouselPage == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    boxShadow: _currentCarouselPage == index
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
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
    const bg = Color(0xFF0A0A0A);
    final panelBorder = primaryGreen.withValues(alpha: 0.18);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactWeb = kIsWeb && constraints.maxWidth < 520;

        final width = constraints.maxWidth;
        final t = (((520 - width) / 160).clamp(0.0, 1.0));
        final tileScale = kIsWeb ? (1.0 + 0.30 * t) : 1.0;

        final squareSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final panelWidth = isCompactWeb ? constraints.maxWidth : squareSide;
        final compactHeight = (constraints.maxWidth * 0.86)
            .clamp(320.0, 420.0)
            .toDouble();
        final panelHeight = isCompactWeb
            ? (constraints.maxHeight.isFinite
                  ? math.min(compactHeight, constraints.maxHeight)
                  : compactHeight)
            : squareSide;
        const gridSpacing = 8.0;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen.withValues(alpha: 0.14),
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
                                  uiScale: tileScale,
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
                                  uiScale: tileScale,
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
                                  uiScale: tileScale,
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
                                  uiScale: tileScale,
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
                                  uiScale: tileScale,
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
                                  uiScale: tileScale,
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
    this.uiScale = 1.0,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double uiScale;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white;
    final fgSoft = Colors.white.withValues(alpha: 0.88);
    final surfaceVariant = Colors.white.withValues(alpha: 0.08);
    final borderColor = accent.withValues(alpha: 0.22);

    final s = uiScale;

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
                accent.withValues(alpha: 0.22),
                accent.withValues(alpha: 0.08),
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
                    size: 74 * s,
                    color: Colors.white.withValues(alpha: 0.14),
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
                        Icon(icon, size: 17 * s, color: fg),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5 * s,
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
                          fontSize: 11.5 * s,
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

class _RouletteDialog extends StatefulWidget {
  const _RouletteDialog();

  @override
  State<_RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<_RouletteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinning = false;
  bool _spinCompleted = false;
  bool _showResult = false;
  // TOGGLE: set to true to auto-close after spin, false to keep it open.
  static const bool _autoCloseAfterSpin = false;
  static const List<String> _baseLabels = [
    'Afiliacion\nsin cargo',
    'Bono de\nbienvenida',
    'Carga inicial\nde 35.000',
    'Acceso a\nbeneficios\npor un mes',
  ];
  static const String _targetLabel = 'Acceso a\nbeneficios\npor un mes';
  List<String> _segments = const [];
  int _targetIndex = 0;
  late final List<_RouletteConfetti> _confetti;
  bool _confirmingPrize = false;

  @override
  void initState() {
    super.initState();
    _confetti = _buildConfetti();
    _segments = _buildSegments();
    _targetIndex = _pickTargetIndex(_segments);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _rotation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _spinning = false;
          _spinCompleted = true;
          _showResult = true;
        });
        if (_autoCloseAfterSpin) {
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning || _spinCompleted) return;
    const extraTurns = 6;
    final sweep = (2 * math.pi) / _segments.length;
    // Forzar resultado al segmento target debajo del indicador superior.
    final end = (2 * math.pi * extraTurns) - (sweep * (_targetIndex + 0.5));

    setState(() {
      _spinning = true;
      _rotation = Tween<double>(begin: 0, end: end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
    });

    _controller
      ..reset()
      ..forward();
  }

  Future<void> _confirmPrizeAndClose() async {
    if (_confirmingPrize) return;
    setState(() => _confirmingPrize = true);

    try {
      await PlayerService().setFirstLoginFalse();
    } catch (_) {
      // Ignorar para no bloquear el cierre del flujo.
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelSize = kIsWeb
        ? (screenWidth * 0.36).clamp(300.0, 420.0)
        : (screenWidth - 48).clamp(260.0, 360.0);

    final dialogChild = Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¡TE GANASTE UN PREMIO!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              // const SizedBox(height: 6),
              // Text(
              //   'Y ganate un buen premio inicial!',
              //   textAlign: TextAlign.center,
              //   style: TextStyle(
              //     color: textColor.withValues(alpha: 0.7),
              //     fontSize: 13,
              //   ),
              // ),
              const SizedBox(height: 14),
              SizedBox(
                width: wheelSize,
                height: wheelSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: wheelSize,
                      height: wheelSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _rotation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotation.value,
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        size: Size(wheelSize, wheelSize),
                        painter: _RoulettePainter(
                          primaryColor: primary,
                          labels: _segments,
                          textColor: textColor,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 32,
                        color: primary,
                      ),
                    ),
                    Container(
                      width: wheelSize * 0.2,
                      height: wheelSize * 0.2,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: 0.95),
                            primary.withValues(alpha: 0.6),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _spinning ? null : _spin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: AppConstants.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_spinning ? 'Girando...' : 'Girar'),
                ),
              ),
            ],
          ),
        ),
        if (_showResult)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildConfettiLayer()),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryGreen.withValues(alpha: 0.25),
                              AppConstants.primaryGreen.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppConstants.primaryGreen.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.primaryGreen.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppConstants.primaryGreen,
                              size: 42,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'GANASTE',
                              style: TextStyle(
                                color: AppConstants.primaryGreen,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Acceso gratuito a beneficios\n durante un mes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _confirmingPrize
                                    ? null
                                    : _confirmPrizeAndClose,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.primaryGreen,
                                  foregroundColor: AppConstants.textLight,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('OK!'),
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
      ],
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Colors.transparent,
      child: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: dialogChild,
              ),
            )
          : dialogChild,
    );
  }

  List<_RouletteConfetti> _buildConfetti() {
    final rng = math.Random();
    return List.generate(18, (index) {
      return _RouletteConfetti(
        dx: rng.nextDouble(),
        dy: rng.nextDouble(),
        size: 6 + rng.nextDouble() * 8,
        delay: rng.nextDouble() * 0.4,
        opacity: 0.5 + rng.nextDouble() * 0.5,
      );
    });
  }

  Widget _buildConfettiLayer() {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showResult ? 1 : 0,
        child: Stack(
          children: _confetti.map((c) {
            return Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  final y = (c.dy - 0.6) + value * 1.0;
                  return Transform.translate(
                    offset: Offset((c.dx - 0.5) * 260, y * 260),
                    child: Opacity(
                      opacity: (1 - value) * c.opacity,
                      child: child,
                    ),
                  );
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.rotate(
                    angle: c.dx * math.pi,
                    child: Container(
                      width: c.size,
                      height: c.size * 0.6,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryGreen.withValues(
                          alpha: c.opacity,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<String> _buildSegments() {
    return [..._baseLabels, ..._baseLabels];
  }

  int _pickTargetIndex(List<String> items) {
    for (var i = 0; i < items.length; i++) {
      if (items[i] == _targetLabel) return i;
    }
    return 0;
  }
}

class _RouletteConfetti {
  const _RouletteConfetti({
    required this.dx,
    required this.dy,
    required this.size,
    required this.delay,
    required this.opacity,
  });

  final double dx;
  final double dy;
  final double size;
  final double delay;
  final double opacity;
}

class _RoulettePainter extends CustomPainter {
  _RoulettePainter({
    required this.primaryColor,
    required this.labels,
    required this.textColor,
  });

  final Color primaryColor;
  final List<String> labels;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segments = labels.length;
    final sweep = (2 * math.pi) / segments;
    final innerRadius = radius * 0.13;

    final gradient = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.22),
        primaryColor.withValues(alpha: 0.6),
      ],
    );

    for (int i = 0; i < segments; i++) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..color = i.isEven
            ? primaryColor.withValues(alpha: 0.25)
            : primaryColor.withValues(alpha: 0.5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (sweep * i) - (math.pi / 2),
        sweep,
        true,
        paint,
      );

      final label = labels[i];
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.98),
            fontSize: 11.2,
            fontWeight: FontWeight.w900,
            height: 1.12,
            letterSpacing: 0.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 8,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: radius * 0.7);

      final angle = (sweep * i) + (sweep / 2) - (math.pi / 2);
      final textRadius = radius * 0.54;
      final offset = Offset(
        center.dx + textRadius * math.cos(angle),
        center.dy + textRadius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(angle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    final divider = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.18);
    for (int i = 0; i < segments; i++) {
      final angle = (sweep * i) - (math.pi / 2);
      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, divider);
    }

    final inner = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawCircle(center, innerRadius, inner);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = primaryColor.withValues(alpha: 0.7);
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
