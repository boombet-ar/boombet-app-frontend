import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/models/publicidad_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/services/publicidad_service.dart';
import 'package:boombet_app/views/pages/forum_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:boombet_app/widgets/search_bar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // GlobalKeys para controlar las vistas de Descuentos y Reclamados
  late GlobalKey<_DiscountsContentState> _discountsKey;
  late GlobalKey<_ClaimedCouponsContentState> _claimedKey;

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<_DiscountsContentState>();
    _claimedKey = GlobalKey<_ClaimedCouponsContentState>();
    // Resetear a la página de Home cuando se carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedPageNotifier.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          appBar: const MainAppBar(
            showSettings: true,
            showLogo: true,
            showProfileButton: true,
            showLogoutButton: true,
            showExitButton: false,
          ),
          body: ResponsiveWrapper(
            maxWidth: 1200,
            child: IndexedStack(
              index: selectedPage,
              children: [
                const HomeContent(),
                DiscountsContent(
                  key: _discountsKey,
                  onCuponClaimed: () {
                    _claimedKey.currentState?.refreshClaimedCupones();
                    _discountsKey.currentState?.refreshClaimedIds();
                  },
                  claimedKey: _claimedKey,
                ),
                const RafflesPage(),
                const ForumPage(),
              ],
            ),
          ),
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
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

  void _handleSearch(String query) {
    debugPrint('Buscando: $query');
    // Aquí puedes agregar la lógica de búsqueda
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
    _autoScrollTimer?.cancel(); // don't count time while video readies
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
      // Reemplazar espacios con %20 directamente para URLs de Azure
      return raw.replaceAll(' ', '%20');
    }
    final base = ApiConfig.baseUrl;
    // Remove trailing '/api' to serve static files if needed.
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
          // Ensure playback starts even if init finished after page became visible.
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getPromoIcon(index), size: 48, color: primaryGreen),
                const SizedBox(height: 8),
                Text(
                  _getPromoTitle(index),
                  style: TextStyle(
                    fontSize: 18,
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
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${index + 1}/5',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SearchBarWidget(
            controller: _searchController,
            onSearch: _handleSearch,
            placeholder: '¿Qué estás buscando?',
          ),
        ),
        // Carrusel de promociones - ocupa casi toda la pantalla
        Expanded(
          child: RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                children: [
                  // Header con información de la publicidad actual
                  if (_ads.isNotEmpty && !_adsLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Texto/Descripción
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

                        // Placeholder cuando no hay publicidades
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
                  // Indicadores de página
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

class DiscountsContent extends StatefulWidget {
  final VoidCallback? onCuponClaimed;
  final GlobalKey<_ClaimedCouponsContentState>? claimedKey;

  const DiscountsContent({super.key, this.onCuponClaimed, this.claimedKey});

  @override
  State<DiscountsContent> createState() => _DiscountsContentState();
}

class _DiscountsContentState extends State<DiscountsContent> {
  String _selectedFilter = 'Todos';
  late PageController _pageController;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _showClaimed = false; // Switch entre descuentos y reclamados

  List<Cupon> _cupones = [];
  List<Cupon> _filteredCupones = [];
  List<String> _claimedCuponIds = []; // IDs de cupones ya reclamados
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = false;
  Map<String, List<String>> _categoriasByName = {};
  bool _affiliationCompleted = false;
  bool _affiliationLoading = false;
  String? _affiliationError;
  String? _affiliationMessage;
  static const String _affiliationAcceptedKey =
      'affiliation_accepted_bonda';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Cargar datos de forma asíncrona sin bloquear
    // Se pedirá consentimiento antes de cargar beneficios
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAffiliationAcceptance();
    });
  }

  Future<void> _loadAffiliationAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_affiliationAcceptedKey) ?? false;
    if (!mounted || !accepted) return;

    setState(() {
      _affiliationCompleted = true;
    });

    await _runPostAffiliationLoadsWithRetry();
  }

  Future<void> refreshClaimedIds() async {
    await _loadClaimedCuponIds();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCupones() async {
    if (_isLoading) return;
    if (!_affiliationCompleted) return;

    setState(() => _isLoading = true);
    try {
      final result =
          await CuponesService.getCupones(
            page: _currentPage,
            pageSize: _pageSize,
            apiKey: ApiConfig.apiKey,
            micrositioId: ApiConfig.micrositioId.toString(),
            codigoAfiliado: ApiConfig.codigoAfiliado,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('ERROR: Timeout loading cupones');
              throw TimeoutException('Timeout cargando cupones');
            },
          );

      final newCupones = result['cupones'] as List<Cupon>? ?? [];

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _cupones = newCupones;
          } else {
            _cupones.addAll(newCupones);
          }

          _hasMore = result['has_more'] as bool? ?? false;
          _hasError = false;
          _isLoading = false;

          // Actualizar categorías
          _updateCategorias();
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Error: ${e.toString()}\n\nIntenta revisar la consola de logs para más detalles.';
          _isLoading = false;
        });
      }
    }
  }

  void _updateCategorias() {
    _categoriasByName.clear();
    for (var cupon in _cupones) {
      for (var cat in cupon.categorias) {
        _categoriasByName.putIfAbsent(cat.nombre, () => []).add(cupon.id);
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'Todos') {
      _filteredCupones = _cupones
          .where((c) => !_claimedCuponIds.contains(c.id))
          .toList();
    } else {
      final ids = _categoriasByName[_selectedFilter] ?? [];
      _filteredCupones = _cupones
          .where((c) => ids.contains(c.id) && !_claimedCuponIds.contains(c.id))
          .toList();
    }
  }

  Future<void> _loadClaimedCuponIds() async {
    if (!_affiliationCompleted) return;
    try {
      final result =
          await CuponesService.getCuponesRecibidos(
            apiKey: ApiConfig.apiKey,
            micrositioId: ApiConfig.micrositioId.toString(),
            codigoAfiliado: ApiConfig.codigoAfiliado,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('ERROR: Timeout loading claimed cupones');
              throw TimeoutException('Timeout cargando cupones reclamados');
            },
          );
      final claimedCupones = result['cupones'] as List<Cupon>? ?? [];

      if (mounted) {
        setState(() {
          _claimedCuponIds = claimedCupones.map((c) => c.id).toList();
          _applyFilter();
        });
      }
    } catch (e) {
      // Silenciosamente ignorar errores al cargar IDs reclamados
      debugPrint('Error loading claimed coupon IDs: $e');
    }
  }

  String _cleanHtml(String html) {
    // Remover tags HTML simples
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Future<void> _startAffiliation() async {
    if (_affiliationLoading) return;

    setState(() {
      _affiliationLoading = true;
      _affiliationError = null;
      _affiliationMessage = null;
    });

    try {
      _currentPage = 1;
      final result = await CuponesService.afiliarAfiliado(
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
        codigoAfiliado: ApiConfig.codigoAfiliado,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('ERROR: Timeout affiliating to Bonda');
          throw TimeoutException('Timeout al afiliar a Bonda');
        },
      );

      if (!mounted) return;
      setState(() {
        _affiliationCompleted = true;
        _affiliationMessage =
            (result['data'] as Map<String, dynamic>?)?['message'] as String?;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_affiliationAcceptedKey, true);
      await _runPostAffiliationLoadsWithRetry();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _affiliationError =
            'No pudimos activar tus beneficios en este momento. ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _affiliationLoading = false;
        });
      }
    }
  }

  Future<void> _runPostAffiliationLoadsWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _loadClaimedCuponIds();
        await _loadCupones();
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final categories = <String>{'Todos'};
    categories.addAll(_categoriasByName.keys);

    if (!_affiliationCompleted) {
      return RefreshIndicator(
        onRefresh: _startAffiliation,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [_buildAffiliationCard(primaryGreen, textColor, isDark)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCupones,
      child: Column(
        children: [
          // Header con switch entre Descuentos y Reclamados
          if (_showClaimed)
            buildSectionHeaderWithSwitch(
              'Mis Cupones Reclamados',
              'Ver cupones que ya reclamaste',
              Icons.check_circle,
              primaryGreen,
              isDark,
              isShowingClaimed: true,
              onSwitchPressed: () {
                setState(() {
                  _showClaimed = false;
                });
              },
            )
          else
            buildSectionHeaderWithSwitch(
              'Descuentos Exclusivos',
              '${_filteredCupones.length} ofertas disponibles',
              Icons.local_offer,
              primaryGreen,
              isDark,
              isShowingClaimed: false,
              onSwitchPressed: () {
                setState(() {
                  _showClaimed = true;
                });
              },
            ),

          // Mostrar vista de reclamados si _showClaimed es true
          if (_showClaimed)
            Expanded(
              child: ClaimedCouponsContent(
                key: widget.claimedKey,
                hideHeader: true,
              ),
            )
          else
            // Filtros mejorados (solo para descuentos)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final isSelected = _selectedFilter == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    primaryGreen,
                                    primaryGreen.withValues(alpha: 0.8),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? Colors.grey[800] : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: primaryGreen.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = category;
                                _applyFilter();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : primaryGreen,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          if (!_showClaimed)
            // Lista de cupones con animaciones (solo para descuentos)
            Expanded(
              child: _isLoading && _cupones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: primaryGreen,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Cargando ofertas...',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _currentPage = 1;
                              _loadCupones();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredCupones.isEmpty
                  ? Center(
                      child: Text(
                        'No hay cupones disponibles',
                        style: TextStyle(color: textColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _filteredCupones.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredCupones.length) {
                          // Load more button
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _currentPage++;
                                  _loadCupones();
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Cargar más'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ),
                          );
                        }

                        final cupon = _filteredCupones[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCuponCard(
                            context,
                            cupon,
                            primaryGreen,
                            textColor,
                            isDark,
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildAffiliationCard(
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? Colors.grey[850]! : Colors.white,
                  isDark ? Colors.grey[900]! : Colors.grey[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ícono principal animado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryGreen.withValues(alpha: 0.15),
                          primaryGreen.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: primaryGreen,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Título principal
                  Text(
                    '¿Querés recibir beneficios?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Descripción principal
                  Text(
                    'Al aceptar te afiliamos a Bonda para habilitar cupones, códigos y beneficios exclusivos en comercios asociados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: primaryGreen,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Proceso único. Puede demorar unos segundos en completarse.',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _affiliationLoading ? null : _startAffiliation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: primaryGreen.withValues(
                          alpha: 0.6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryGreen.withValues(alpha: 0.3),
                      ),
                      child: _affiliationLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Procesando afiliación...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Sí, recibir beneficios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  // Error message
                  if (_affiliationError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _affiliationError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Success message
                  if (_affiliationMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: primaryGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _affiliationMessage!,
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Footer text
                  Text(
                    'Al continuar aceptás que gestionemos tu afiliación a Bonda para liberar beneficios.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showCuponDetails(context, cupon, primaryGreen, textColor);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
              child: Container(
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen con overlay mejorado
                    Stack(
                      children: [
                        // Imagen
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: primaryGreen.withValues(alpha: 0.1),
                          child: cupon.fotoUrl.isNotEmpty
                              ? Image.network(
                                  cupon.fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 64,
                                        color: primaryGreen.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.local_offer,
                                    size: 64,
                                    color: primaryGreen.withValues(alpha: 0.3),
                                  ),
                                ),
                        ),
                        // Overlay gradiente
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Badge de descuento
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade600, Colors.red],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              cupon.descuento,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: cupon.logoUrl.isNotEmpty
                                  ? Image.network(
                                      cupon.logoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 56,
                                              height: 56,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Text(
                                                  cupon.empresa.nombre
                                                      .substring(
                                                        0,
                                                        (cupon
                                                                .empresa
                                                                .nombre
                                                                .length)
                                                            .clamp(0, 2),
                                                      )
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryGreen,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Text(
                                          cupon.empresa.nombre
                                              .substring(
                                                0,
                                                (cupon.empresa.nombre.length)
                                                    .clamp(0, 2),
                                              )
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contenido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            cupon.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Empresa
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 14,
                                color: primaryGreen.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cupon.empresa.nombre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Descripción
                          Text(
                            _cleanHtml(cupon.descripcionBreve),
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          // Categorías
                          if (cupon.categorias.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: cupon.categorias.take(2).map((cat) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    cat.nombre,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 10),

                          // Fecha
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: textColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Válido hasta: ${cupon.fechaVencimientoFormatted}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Footer con branding y botón
                          Row(
                            children: [
                              // Branding Bonda
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Beneficio provisto por',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: 28,
                                    width: 80,
                                    child: Image.asset(
                                      'assets/images/logo_bonda.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // Botón Reclamar
                              Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    LoadingOverlay.show(
                                      context,
                                      message: 'Reclamando cupón...',
                                    );

                                    try {
                                      await CuponesService.claimCupon(
                                        cuponId: cupon.id,
                                      );

                                      LoadingOverlay.hide(context);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            '¡Cupón reclamado exitosamente!',
                                          ),
                                          duration: const Duration(seconds: 3),
                                          backgroundColor: primaryGreen,
                                          action: SnackBarAction(
                                            label: 'OK',
                                            onPressed: () {},
                                          ),
                                        ),
                                      );

                                      widget.onCuponClaimed?.call();
                                    } catch (e) {
                                      LoadingOverlay.hide(context);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                          duration: const Duration(seconds: 3),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Reclamar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryGreen, Color textColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: primaryGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),
    );
  }

  Widget _buildContentBox(
    String htmlContent,
    Color textColor,
    Color primaryGreen,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withValues(alpha: 0.5)
            : Colors.grey[100]!.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Html(
        data: htmlContent,
        style: {
          'body': Style(
            color: textColor,
            fontSize: FontSize(14),
            lineHeight: LineHeight.number(1.6),
            margin: Margins.all(0),
            padding: HtmlPaddings.all(0),
          ),
          'p': Style(margin: Margins.symmetric(vertical: 6), color: textColor),
          'a': Style(
            color: primaryGreen,
            textDecoration: TextDecoration.underline,
          ),
          'b': Style(fontWeight: FontWeight.bold, color: primaryGreen),
          'u': Style(textDecoration: TextDecoration.underline),
        },
      ),
    );
  }

  void _showCuponDetails(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Gradient Header con descuento
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryGreen.withValues(alpha: 0.1),
                            Colors.red.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Badge de descuento
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.shade500,
                                  Colors.red.shade600,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              cupon.descuento,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            cupon.nombre,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                color: primaryGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cupon.empresa.nombre,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: cupon.categorias.map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  cat.nombre,
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Beneficio provisto por Bonda
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Beneficio provisto por ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                SizedBox(
                                  height: 18,
                                  width: 70,
                                  child: Image.asset(
                                    'assets/images/logo_bonda.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cómo usar
                          _buildSectionTitle(
                            'Cómo usar',
                            primaryGreen,
                            textColor,
                          ),
                          const SizedBox(height: 12),
                          _buildContentBox(
                            cupon.descripcionMicrositio,
                            textColor,
                            primaryGreen,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          // Términos y Condiciones
                          _buildSectionTitle(
                            'Términos y Condiciones',
                            primaryGreen,
                            textColor,
                          ),
                          const SizedBox(height: 12),
                          _buildContentBox(
                            cupon.legales,
                            textColor.withValues(alpha: 0.8),
                            primaryGreen,
                            isDark,
                          ),
                          const SizedBox(height: 20),
                          // Vencimiento
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.orange.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Válido hasta',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cupon.fechaVencimientoFormatted,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Botón cerrar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cerrar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
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
        ),
      ),
    );
  }
}

/// Página de Cupones Reclamados
class ClaimedCouponsContent extends StatefulWidget {
  final bool hideHeader;
  final bool enablePullToRefresh;

  const ClaimedCouponsContent({
    super.key,
    this.hideHeader = false,
    this.enablePullToRefresh = true,
  });

  @override
  State<ClaimedCouponsContent> createState() => _ClaimedCouponsContentState();
}

class _ClaimedCouponsContentState extends State<ClaimedCouponsContent> {
  List<Cupon> _claimedCupones = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Cargar datos de forma asíncrona sin bloquear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClaimedCupones();
    });
  }

  Future<void> refreshClaimedCupones() async {
    await _loadClaimedCupones();
  }

  Future<void> _loadClaimedCupones() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result =
          await CuponesService.getCuponesRecibidos(
            apiKey: ApiConfig.apiKey,
            micrositioId: ApiConfig.micrositioId.toString(),
            codigoAfiliado: ApiConfig.codigoAfiliado,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('ERROR: Timeout loading claimed cupones');
              throw TimeoutException('Timeout cargando cupones reclamados');
            },
          );

      setState(() {
        _claimedCupones = result['cupones'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Error: ${e.toString()}\n\nIntenta revisar la consola de logs para más detalles.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      children: [
        if (!widget.hideHeader)
          buildSectionHeader(
            'Mis Cupones Reclamados',
            '${_claimedCupones.length} códigos disponibles',
            Icons.check_circle,
            primaryGreen,
            isDark,
          ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Cargando cupones reclamados...',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Oops, hubo un error',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadClaimedCupones,
                        child: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _claimedCupones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sin cupones reclamados',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¡Reclama un cupón para verlo aquí!',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _claimedCupones.length,
                  itemBuilder: (context, index) {
                    final cupon = _claimedCupones[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildClaimedCuponCard(
                          context,
                          cupon,
                          primaryGreen,
                          textColor,
                          isDark,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.enablePullToRefresh) {
      return RefreshIndicator(onRefresh: _loadClaimedCupones, child: content);
    }

    return content;
  }

  Widget _buildClaimedCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showClaimedCuponDetails(context, cupon, primaryGreen, textColor);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
              child: Container(
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen con overlay
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.green.withValues(alpha: 0.1),
                          child: cupon.fotoUrl.isNotEmpty
                              ? Image.network(
                                  cupon.fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.local_offer,
                                        size: 64,
                                        color: Colors.green.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.local_offer,
                                    size: 64,
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                        ),
                        // Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Badge de descuento
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade600, Colors.green],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              cupon.descuento,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Badge "Reclamado"
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reclamado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contenido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            cupon.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Empresa
                          Row(
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 14,
                                color: Colors.green.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cupon.empresa.nombre,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Código promocional mejorado
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withValues(alpha: 0.08),
                                  Colors.green.withValues(alpha: 0.04),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tu Código',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cupon.displayCode,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontFamily: 'monospace',
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: cupon.displayCode),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Código copiado: ${cupon.displayCode}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.content_copy,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Fecha de vencimiento
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: textColor.withValues(alpha: 0.4),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Reclamado el: ${cupon.fechaVencimientoFormatted}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Footer con branding y código
                          Row(
                            children: [
                              // Branding Bonda
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Beneficio provisto por',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SizedBox(
                                    height: 28,
                                    width: 80,
                                    child: Image.asset(
                                      'assets/images/logo_bonda.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClaimedCuponDetails(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header compacto con info del cupón
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo más pequeño
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[200],
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    cupon.empresa.logo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.store,
                                        color: primaryGreen,
                                        size: 28,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cupon.nombre,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      cupon.empresa.nombre,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: primaryGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Badge descuento
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade500,
                                      Colors.red.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  cupon.descuento,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Estado - Cupón Reclamado
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withValues(alpha: 0.15),
                                  Colors.green.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cupón Reclamado',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Usá este código en ${cupon.empresa.nombre}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Código de Descuento
                          Text(
                            'Código de Descuento',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                                  : Colors.grey[100]!.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cupon.displayCode,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: cupon.displayCode),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Código copiado: ${cupon.displayCode}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.content_copy,
                                      color: primaryGreen,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Instrucciones
                          Text(
                            'Instrucciones',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                                  : Colors.grey[100]!.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Html(
                              data: cupon.instrucciones.isEmpty
                                  ? '<ol style="margin: 0; padding-left: 20px;"><li style="margin: 4px 0; color: inherit;">Ingresá en ${cupon.empresa.nombre}</li><li style="margin: 4px 0; color: inherit;">Seleccioná los productos que deseas comprar</li><li style="margin: 4px 0; color: inherit;">Ingresá tu código de descuento</li><li style="margin: 4px 0; color: inherit;">Completá tu compra</li></ol>'
                                  : cupon.instrucciones,
                              style: {
                                'body': Style(
                                  color: textColor,
                                  fontSize: FontSize(13),
                                  lineHeight: LineHeight.number(1.5),
                                  margin: Margins.all(0),
                                  padding: HtmlPaddings.all(0),
                                ),
                                'p': Style(
                                  margin: Margins.symmetric(vertical: 4),
                                  color: textColor,
                                ),
                                'li': Style(
                                  margin: Margins.symmetric(vertical: 4),
                                  color: textColor,
                                ),
                                'b': Style(
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              },
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Vencimiento
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.orange.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reclamado el',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        cupon.fechaVencimientoFormatted,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Beneficio provisto por Bonda
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Beneficio provisto por ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                SizedBox(
                                  height: 18,
                                  width: 70,
                                  child: Image.asset(
                                    'assets/images/logo_bonda.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botón cerrar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Cerrar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
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
        ),
      ),
    );
  }
}

/// Widget de header normalizado para todas las secciones
Widget buildSectionHeader(
  String title,
  String subtitle,
  IconData icon,
  Color primaryGreen,
  bool isDark,
) {
  final headerBg = isDark ? Colors.grey[800] : Colors.grey[300];

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: headerBg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Widget de header con switch para alternar entre vistas
Widget buildSectionHeaderWithSwitch(
  String title,
  String subtitle,
  IconData icon,
  Color primaryGreen,
  bool isDark, {
  required bool isShowingClaimed,
  required VoidCallback onSwitchPressed,
}) {
  final headerBg = isDark ? Colors.grey[800] : Colors.grey[300];

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: headerBg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        // Botón toggle para cambiar de vista
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSwitchPressed,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isShowingClaimed
                    ? Icons.local_offer_outlined
                    : Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
