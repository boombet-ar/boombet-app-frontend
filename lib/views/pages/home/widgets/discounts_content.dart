import 'dart:async';
import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/coupon_error_parser.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/loading_badge.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/rewards/not_enabled_page.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:boombet_app/widgets/search_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountsContent extends StatefulWidget {
  const DiscountsContent({
    super.key,
    this.onCuponClaimed,
    this.claimedKey,
    this.firstCouponTutorialTargetKey,
    this.claimedSwitchTutorialTargetKey,
  });

  final VoidCallback? onCuponClaimed;
  final GlobalKey<ClaimedCouponsContentState>? claimedKey;
  final GlobalKey? firstCouponTutorialTargetKey;
  final GlobalKey? claimedSwitchTutorialTargetKey;

  @override
  State<DiscountsContent> createState() => DiscountsContentState();
}

class DiscountsContentState extends State<DiscountsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Todos';
  String? _selectedCategoryId;
  late PageController _pageController;
  late final ScrollController _listScrollController;
  int _currentPage = 1;
  int _apiPage = 1;
  final int _pageSize = 15;
  final Map<int, List<Cupon>> _pageCache = {};
  List<Cupon> _categoryFilteredUniverse = [];
  String? _categoryUniverseKey;
  int _categoryBackendPage = 0;
  bool _categoryBackendHasMore = false;
  List<Categoria> _remoteCategories = [];
  bool _showClaimed = false;

  List<Cupon> _cupones = [];
  List<Cupon> _filteredCupones = [];
  List<String> _claimedCuponIds = [];
  final Map<String, String> _claimedCuponCodes = {};
  final Set<String> _claimingCuponIds = <String>{};
  bool _isLoading = false;
  bool _isBootstrapLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = false;
  final Map<String, Categoria> _categoriaByName = {};
  bool _isCouponActivationReady = false;
  DateTime? _accountCreatedAtUtc;
  Timer? _couponActivationTimer;
  static const Duration _couponActivationDelay = Duration(minutes: 30);
  static const String _cachedCuponesKey = 'cached_cupones_bonda';
  static const String _cachedCuponesTsKey = 'cached_cupones_ts_bonda';
  static const String _cachedPageKey = 'cached_cupones_page';
  static const String _cachedHasMoreKey = 'cached_cupones_has_more';
  static const List<String> _legacyCuponCacheKeys = [
    _cachedCuponesKey,
    _cachedCuponesTsKey,
    _cachedPageKey,
    _cachedHasMoreKey,
  ];
  bool _cacheApplied = false;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(hours: 6);
  static const Duration _searchDebounce = Duration(milliseconds: 600);
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  bool _authGuardTriggered = false;
  bool _authBlocked = false;
  bool _authCheckInProgress = false;
  DateTime? _lastAuthCheckAt;
  bool? _bondaEnabled;

  void openClaimedFromTutorial() {
    setState(() {
      _showClaimed = true;
    });
    _resetDiscountsState(triggerLoad: false);
  }

  Widget _buildScrollableCouponCode(
    String code,
    Color primaryGreen, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 1,
  }) {
    if (code.isEmpty) {
      return Text(
        'Codigo no disponible',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryGreen.withValues(alpha: 0.8),
        ),
      );
    }

    return SizedBox(
      height: fontSize + 6,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Text(
          code,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: primaryGreen,
            fontFamily: 'monospace',
            letterSpacing: letterSpacing,
          ),
          softWrap: false,
        ),
      ),
    );
  }

  Future<void> _clearCuponCachePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await _removeCuponCacheKeys(prefs);
  }

  Future<String?> _currentCacheScope() async {
    final tokenData = await TokenService.getTokenData();
    if (tokenData == null) return null;

    final raw =
        tokenData['sub'] ??
        tokenData['userId'] ??
        tokenData['user_id'] ??
        tokenData['id'] ??
        tokenData['uid'];
    if (raw == null) return null;

    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _scopedKey(String baseKey, String scope) => '${baseKey}_$scope';

  Future<void> _removeCuponCacheKeys(
    SharedPreferences prefs, {
    String? scope,
  }) async {
    for (final legacyKey in _legacyCuponCacheKeys) {
      await prefs.remove(legacyKey);
    }

    final keys = prefs.getKeys();
    for (final key in keys) {
      final isScopedCuponCache = _legacyCuponCacheKeys.any(
        (baseKey) => key.startsWith('${baseKey}_'),
      );
      if (!isScopedCuponCache) continue;

      if (scope == null) {
        await prefs.remove(key);
        continue;
      }

      final matchesScope = _legacyCuponCacheKeys.any(
        (baseKey) => key == _scopedKey(baseKey, scope),
      );
      if (matchesScope) {
        await prefs.remove(key);
      }
    }
  }

  void _triggerSessionExpiredOnce() {
    if (_authGuardTriggered) return;
    _authGuardTriggered = true;
    HttpClient.onSessionExpired?.call();
  }

  Future<void> _recheckAuthAndMaybeBlock({bool force = false}) async {
    if (_authCheckInProgress) return;

    final now = DateTime.now();
    final last = _lastAuthCheckAt;
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(seconds: 2)) {
      return;
    }

    _authCheckInProgress = true;
    _lastAuthCheckAt = now;

    try {
      final access = await TokenService.getToken();
      final refresh = await TokenService.getRefreshToken();

      final hasAccess =
          access != null &&
          access.isNotEmpty &&
          !TokenService.isJwtExpiredSafe(access);

      if (hasAccess) {
        if (mounted && _authBlocked) {
          setState(() {
            _authBlocked = false;
          });
        }
        return;
      }

      final hasRefresh = refresh != null && refresh.isNotEmpty;
      final refreshExpired =
          hasRefresh &&
          TokenService.isLikelyJwt(refresh!) &&
          TokenService.isJwtExpiredSafe(refresh);

      // No hay forma de recuperar sesión: bloquear UI y disparar popup.
      if (!hasRefresh || refreshExpired) {
        await _clearCuponCachePrefs();
        if (!mounted) return;

        setState(() {
          _authBlocked = true;
          _cupones.clear();
          _filteredCupones.clear();
          _pageCache.clear();
          _cacheApplied = false;
          _hasError = true;
          _errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
          _hasMore = false;
          _isLoading = false;
        });

        _triggerSessionExpiredOnce();
        return;
      }

      // Hay refreshToken: intentar validar/renovar haciendo una llamada auth.
      // Si el refresh falla, HttpClient dispara onSessionExpired.
      try {
        await PlayerService().getCurrentUser();
      } catch (_) {
        // ignore
      }

      final accessAfter = await TokenService.getToken();
      final nowHasAccess =
          accessAfter != null &&
          accessAfter.isNotEmpty &&
          !TokenService.isJwtExpiredSafe(accessAfter);

      if (!mounted) return;

      setState(() {
        _authBlocked = !nowHasAccess;
        if (!nowHasAccess) {
          _cupones.clear();
          _filteredCupones.clear();
          _pageCache.clear();
          _cacheApplied = false;
          _hasMore = false;
          _hasError = true;
          _errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
        }
      });
    } finally {
      _authCheckInProgress = false;
    }
  }

  Future<bool> _guardAuthOrRedirect() async {
    await _recheckAuthAndMaybeBlock(force: true);
    return !_authBlocked;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _listScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await _guardAuthOrRedirect();
      if (!ok) {
        if (mounted) {
          setState(() {
            _isBootstrapLoading = false;
          });
        }
        return;
      }
      await _loadCuponCache();
      await _initializeCouponActivationGate();
    });
  }

  Future<void> _loadCuponCache() async {
    try {
      final token = await TokenService.getToken();
      if (token == null ||
          token.isEmpty ||
          TokenService.isJwtExpiredSafe(token)) {
        // Sin sesión: no aplicar cache (evita ver cupones “de movida”).
        await _clearCuponCachePrefs();
        return;
      }

      final scope = await _currentCacheScope();
      if (scope == null) {
        await _clearCuponCachePrefs();
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      final cacheKey = _scopedKey(_cachedCuponesKey, scope);
      final cacheTsKey = _scopedKey(_cachedCuponesTsKey, scope);
      final cachePageKey = _scopedKey(_cachedPageKey, scope);
      final cacheHasMoreKey = _scopedKey(_cachedHasMoreKey, scope);

      final cached = prefs.getString(cacheKey);
      if (cached == null || cached.isEmpty) return;
      final cachedTs = prefs.getString(cacheTsKey);
      if (cachedTs != null) {
        _cacheTimestamp = DateTime.tryParse(cachedTs);
      }
      final isStale =
          _cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) > _cacheTtl;
      final decoded = jsonDecode(cached);
      if (decoded is! List) return;
      final cachedCupones = decoded
          .map((item) {
            try {
              return Cupon.fromJson(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Cupon>()
          .toList();
      if (cachedCupones.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _cupones = cachedCupones;
        _updateCategorias();
        _applyFilter();
        _cacheApplied = true;
        _apiPage = prefs.getInt(cachePageKey) ?? _apiPage;
        _currentPage = _apiPage;
        _hasMore = prefs.getBool(cacheHasMoreKey) ?? _hasMore;
        _pageCache[_apiPage] = cachedCupones;
      });

      if (isStale) {
        debugPrint('INFO: Cache de cupones vencido, usando cache igualmente.');
      }
    } catch (e) {
      debugPrint('WARN: No se pudo cargar cache de cupones: $e');
    }
  }

  Future<void> _persistCuponCache() async {
    try {
      final scope = await _currentCacheScope();
      if (scope == null) return;

      final prefs = await SharedPreferences.getInstance();
      await _removeCuponCacheKeys(prefs, scope: scope);

      final cacheKey = _scopedKey(_cachedCuponesKey, scope);
      final cacheTsKey = _scopedKey(_cachedCuponesTsKey, scope);
      final cachePageKey = _scopedKey(_cachedPageKey, scope);
      final cacheHasMoreKey = _scopedKey(_cachedHasMoreKey, scope);

      final data = _cupones.map((c) => c.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(cacheTsKey, DateTime.now().toIso8601String());
      await prefs.setInt(cachePageKey, _apiPage);
      await prefs.setBool(cacheHasMoreKey, _hasMore);
    } catch (e) {
      debugPrint('WARN: No se pudo guardar cache de cupones: $e');
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await CuponesService.getCategorias();
      if (!mounted) return;
      setState(() {
        _remoteCategories = cats;
        for (final cat in cats) {
          if (cat.nombre.isNotEmpty) {
            _categoriaByName.putIfAbsent(cat.nombre, () => cat);
          }
        }
      });
    } catch (e) {
      debugPrint('WARN: No se pudieron cargar categorías: $e');
    }
  }

  DateTime? _tryParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final parsed = DateTime.tryParse(value.trim());
      return parsed?.toUtc();
    }
    if (value is int) {
      // Soporta timestamps en segundos o milisegundos.
      final millis = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    return null;
  }

  DateTime? _extractCreatedAt(Map<String, dynamic> userData) {
    final direct = _tryParseDateTime(
      userData['created_at'] ?? userData['createdAt'],
    );
    if (direct != null) return direct;

    final data = userData['data'];
    if (data is Map<String, dynamic>) {
      final fromData = _tryParseDateTime(
        data['created_at'] ?? data['createdAt'],
      );
      if (fromData != null) return fromData;

      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        final fromNested = _tryParseDateTime(
          nestedUser['created_at'] ?? nestedUser['createdAt'],
        );
        if (fromNested != null) return fromNested;
      }
    }

    final user = userData['user'];
    if (user is Map<String, dynamic>) {
      return _tryParseDateTime(user['created_at'] ?? user['createdAt']);
    }

    return null;
  }

  bool _extractBondaEnabled(Map<String, dynamic> userData) {
    final direct = userData['bonda_enabled'];
    if (direct is bool) return direct;

    final data = userData['data'];
    if (data is Map<String, dynamic>) {
      final fromData = data['bonda_enabled'];
      if (fromData is bool) return fromData;

      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        final fromNested = nestedUser['bonda_enabled'];
        if (fromNested is bool) return fromNested;
      }
    }

    final user = userData['user'];
    if (user is Map<String, dynamic>) {
      final fromUser = user['bonda_enabled'];
      if (fromUser is bool) return fromUser;
    }

    return true; // fallback: permitir acceso si el campo no está presente
  }

  Duration _couponActivationRemaining() {
    final createdAt = _accountCreatedAtUtc;
    if (createdAt == null) return Duration.zero;
    final unlockAt = createdAt.add(_couponActivationDelay);
    final remaining = unlockAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool _canUseCouponsNow() {
    final createdAt = _accountCreatedAtUtc;
    if (createdAt == null) return true;
    return _couponActivationRemaining() == Duration.zero;
  }

  Future<void> _enableCouponsAndLoad() async {
    if (!mounted) return;
    if (!_canUseCouponsNow()) return;

    if (mounted) {
      setState(() {
        _isCouponActivationReady = true;
      });
    }

    await _runInitialCouponLoadsWithRetry();

    if (mounted) {
      setState(() {
        _isBootstrapLoading = false;
      });
    }
  }

  void _scheduleCouponActivationTimer() {
    _couponActivationTimer?.cancel();
    final remaining = _couponActivationRemaining();
    if (remaining == Duration.zero) {
      unawaited(_enableCouponsAndLoad());
      return;
    }

    _couponActivationTimer = Timer(remaining, () {
      unawaited(_enableCouponsAndLoad());
    });
  }

  Future<void> _initializeCouponActivationGate() async {
    try {
      final userData = await PlayerService().getCurrentUser();
      _accountCreatedAtUtc = _extractCreatedAt(userData);
      final bondaEnabled = _extractBondaEnabled(userData);

      if (!mounted) return;

      setState(() {
        _bondaEnabled = bondaEnabled;
      });

      // Si bonda_enabled es false, no cargar cupones para evitar errores
      // que puedan disparar el cierre de sesión.
      if (!bondaEnabled) return;

      final canUseCoupons = _canUseCouponsNow();

      if (!mounted) return;

      setState(() {
        _isCouponActivationReady = canUseCoupons;
      });

      if (canUseCoupons) {
        await _runInitialCouponLoadsWithRetry();
      } else {
        _scheduleCouponActivationTimer();
      }
    } catch (e) {
      debugPrint('ERROR validando created_at para cupones: $e');
      if (!mounted) return;
      setState(() {
        // Fallback: no bloquear cupones si users/me falla.
        _isCouponActivationReady = true;
        _bondaEnabled = true;
      });
      await _runInitialCouponLoadsWithRetry();
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapLoading = false;
        });
      }
    }
  }

  Future<void> refreshClaimedIds() async {
    await _loadClaimedCuponIds();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _couponActivationTimer?.cancel();
    _pageController.dispose();
    _listScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListToTop() {
    if (!_listScrollController.hasClients) return;
    _listScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _normalizeCategoryLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  Set<String> _buildSelectedCategoryCandidates({
    String? selectedCategoryId,
    String? selectedCategoryName,
  }) {
    final candidates = <String>{};
    final normalizedId = selectedCategoryId?.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      candidates.add(normalizedId);
    }

    final normalizedName = selectedCategoryName == null
        ? null
        : _normalizeCategoryLabel(selectedCategoryName);
    if (normalizedName == null || normalizedName.isEmpty) {
      return candidates;
    }

    for (final cat in _remoteCategories) {
      if (_normalizeCategoryLabel(cat.nombre) == normalizedName) {
        final id = cat.id?.toString().trim();
        final finalId = cat.finalId?.toString().trim();
        if (id != null && id.isNotEmpty) candidates.add(id);
        if (finalId != null && finalId.isNotEmpty) candidates.add(finalId);
      }
    }

    final mapped = _categoriaByName[selectedCategoryName];
    if (mapped != null) {
      final id = mapped.id?.toString().trim();
      final finalId = mapped.finalId?.toString().trim();
      if (id != null && id.isNotEmpty) candidates.add(id);
      if (finalId != null && finalId.isNotEmpty) candidates.add(finalId);
    }

    return candidates;
  }

  List<Cupon> _filterCuponesList(
    List<Cupon> source, {
    String? selectedCategoryId,
    String? selectedCategoryName,
    required String query,
  }) {
    final selectedName = selectedCategoryName == null
        ? null
        : _normalizeCategoryLabel(selectedCategoryName);
    final selectedCandidates = _buildSelectedCategoryCandidates(
      selectedCategoryId: selectedCategoryId,
      selectedCategoryName: selectedCategoryName,
    );
    final queryLower = query.trim().toLowerCase();

    return source.where((c) {
      final hasSelectedId = selectedCandidates.isNotEmpty;
      final hasSelectedName = selectedName != null && selectedName.isNotEmpty;

      if (hasSelectedId || hasSelectedName) {
        final matchesId = hasSelectedId
            ? c.categorias.any((cat) {
                final catId = cat.id?.toString().trim();
                final catFinalId = cat.finalId?.toString().trim();
                final catParentId = cat.parentId?.toString().trim();
                return (catId != null && selectedCandidates.contains(catId)) ||
                    (catFinalId != null &&
                        selectedCandidates.contains(catFinalId)) ||
                    (catParentId != null &&
                        selectedCandidates.contains(catParentId));
              })
            : false;

        final matchesName = hasSelectedName
            ? c.categorias.any(
                (cat) => _normalizeCategoryLabel(cat.nombre) == selectedName,
              )
            : false;

        // Si tenemos id y nombre, aceptamos por cualquiera de los dos.
        // Esto evita vaciar categorías válidas cuando algún id viene distinto
        // entre endpoints (id vs final_id).
        if (!(matchesId || matchesName)) return false;
      }

      if (queryLower.isEmpty) return true;

      final nameMatch = c.nombre.toLowerCase().contains(queryLower);
      final companyMatch = c.empresa.nombre.toLowerCase().contains(queryLower);
      final categoryMatch = c.categorias.any(
        (cat) => cat.nombre.toLowerCase().contains(queryLower),
      );

      return nameMatch || companyMatch || categoryMatch;
    }).toList();
  }

  String _buildCategoryUniverseKey({
    String? categoryId,
    String? categoryName,
    required String query,
  }) {
    final idPart = categoryId?.trim() ?? '';
    final namePart = categoryName?.trim().toLowerCase() ?? '';
    final queryPart = query.trim().toLowerCase();
    return '$idPart|$namePart|$queryPart';
  }

  void _applyCategoryUniversePage(int requestedPage) {
    final total = _categoryFilteredUniverse.length;
    final maxPage = total == 0 ? 1 : ((total - 1) ~/ _pageSize) + 1;
    final safePage = requestedPage.clamp(1, maxPage);
    final start = (safePage - 1) * _pageSize;
    final pageSlice = _categoryFilteredUniverse
        .skip(start)
        .take(_pageSize)
        .toList();

    _currentPage = safePage;
    _filteredCupones = pageSlice;
    _hasMore = (safePage < maxPage) || _categoryBackendHasMore;
  }

  Future<void> _loadCupones({
    int? pageOverride,
    bool reset = false,
    String? searchQuery,
    String? categoryId,
    String? categoryName,
    bool ignoreCategory = false,
    bool forceRefresh = false,
  }) async {
    if (!_isCouponActivationReady) return;
    if (_isLoading) return;

    final normalizedSearch = (searchQuery ?? _searchQuery).trim();
    final normalizedCategoryId = ignoreCategory
        ? null
        : categoryId ??
              _selectedCategoryId ??
              _categoriaByName[_selectedFilter]?.id?.toString() ??
              _categoriaByName[_selectedFilter]?.finalId?.toString();
    final normalizedCategoryName = ignoreCategory
        ? null
        : categoryName ?? (_selectedFilter == 'Todos' ? null : _selectedFilter);
    final hasSearchQuery = normalizedSearch.isNotEmpty;
    final targetPage = (pageOverride ?? _currentPage).clamp(1, 1 << 30);
    final hasCategoryFilter =
        (normalizedCategoryId != null && normalizedCategoryId.isNotEmpty) ||
        (normalizedCategoryName != null && normalizedCategoryName.isNotEmpty);

    setState(() {
      _isLoading = true;
      if (reset) {
        _cupones.clear();
        _filteredCupones.clear();
        _categoryFilteredUniverse.clear();
        _categoryUniverseKey = null;
        _categoryBackendPage = 0;
        _categoryBackendHasMore = false;
        _apiPage = hasSearchQuery ? 0 : 1;
        if (!hasSearchQuery) {
          _currentPage = 1;
        }
        _pageCache.clear();
        _hasMore = false;
        _hasError = false;
      }
    });

    if (!hasCategoryFilter &&
        !hasSearchQuery &&
        !reset &&
        !forceRefresh &&
        _pageCache.containsKey(targetPage)) {
      if (mounted) {
        setState(() {
          _cupones = List<Cupon>.from(_pageCache[targetPage]!);
          _apiPage = targetPage;
          _currentPage = targetPage;
          _hasError = false;
          _hasMore = _hasMore;
          _updateCategorias();
          _applyFilter();
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final requestPage = hasSearchQuery ? null : targetPage;
      final requestPageSize = hasSearchQuery ? null : _pageSize;

      final result =
          await CuponesService.getCupones(
            page: requestPage,
            pageSize: requestPageSize,
            categoryId: normalizedCategoryId,
            categoryName: normalizedCategoryName,
            searchQuery: normalizedSearch.isEmpty ? null : normalizedSearch,
            orderBy: 'relevant',
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              debugPrint('ERROR: Timeout loading cupones');
              throw TimeoutException('Timeout cargando cupones');
            },
          );

      final fetchedCupones = result['cupones'] as List<Cupon>? ?? [];

      if (hasSearchQuery) {
        final universeKey = _buildCategoryUniverseKey(
          categoryId: normalizedCategoryId,
          categoryName: normalizedCategoryName,
          query: normalizedSearch,
        );

        _categoryFilteredUniverse = _filterCuponesList(
          fetchedCupones,
          selectedCategoryId: normalizedCategoryId,
          selectedCategoryName: normalizedCategoryName,
          query: normalizedSearch,
        );
        _categoryUniverseKey = universeKey;
        _categoryBackendPage = 1;
        _categoryBackendHasMore = false;

        if (mounted) {
          setState(() {
            _applyCategoryUniversePage(targetPage);
            _cupones = List<Cupon>.from(_filteredCupones);
            _apiPage = 1;
            _hasError = false;
            _updateCategorias();
            _isLoading = false;
            unawaited(_persistCuponCache());
          });
        }
        return;
      }

      _categoryFilteredUniverse.clear();
      _categoryUniverseKey = null;
      _categoryBackendPage = 0;
      _categoryBackendHasMore = false;

      final filteredFetched = _filterCuponesList(
        fetchedCupones,
        selectedCategoryId: normalizedCategoryId,
        selectedCategoryName: normalizedCategoryName,
        query: normalizedSearch,
      );

      if (targetPage > 1 && filteredFetched.isEmpty) {
        if (mounted) {
          setState(() {
            _apiPage = targetPage - 1;
            _currentPage = targetPage - 1;
            _hasMore = false;
            _hasError = false;
            _filteredCupones = filteredFetched;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _cupones = List<Cupon>.from(filteredFetched);
          _filteredCupones = filteredFetched;
          _apiPage = targetPage;
          _currentPage = targetPage;
          final hasMoreResponse = result['has_more'] as bool? ?? false;
          _hasMore = hasMoreResponse;
          _hasError = false;
          if (!hasCategoryFilter) {
            _pageCache[targetPage] = List<Cupon>.from(filteredFetched);
          }
          _updateCategorias();
          _isLoading = false;
          unawaited(_persistCuponCache());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = parseCouponErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  void _resetDiscountsState({required bool triggerLoad}) {
    setState(() {
      _selectedFilter = 'Todos';
      _selectedCategoryId = null;
      _searchQuery = '';
      _searchController.clear();
      _pageCache.clear();
      _categoryFilteredUniverse.clear();
      _categoryUniverseKey = null;
      _categoryBackendPage = 0;
      _categoryBackendHasMore = false;
      _cupones.clear();
      _filteredCupones.clear();
      _apiPage = 1;
      _currentPage = 1;
      _hasMore = false;
      _hasError = false;
    });

    if (triggerLoad) {
      unawaited(
        _loadCupones(
          reset: true,
          pageOverride: 1,
          categoryId: null,
          categoryName: null,
          searchQuery: '',
          ignoreCategory: false,
        ),
      );
    }
  }

  void _updateCategorias() {
    for (var cupon in _cupones) {
      for (var cat in cupon.categorias) {
        if (cat.nombre.isNotEmpty) {
          _categoriaByName.putIfAbsent(cat.nombre, () => cat);
        }
      }
    }
  }

  void _applyFilter() {
    final selectedName = _selectedFilter == 'Todos' ? null : _selectedFilter;
    final selectedId = selectedName != null
        ? (_categoriaByName[selectedName]?.id?.toString() ??
              _categoriaByName[selectedName]?.finalId?.toString())
        : null;
    _filteredCupones = _filterCuponesList(
      _cupones,
      selectedCategoryId: selectedId,
      selectedCategoryName: selectedName,
      query: _searchQuery,
    );
  }

  void _executeSearch(String query) {
    final normalized = query.trim();
    if (normalized == _searchQuery && !_hasError) {
      return;
    }

    setState(() {
      _searchQuery = normalized;
    });
    unawaited(_loadCupones(reset: true, searchQuery: normalized));
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      _executeSearch(query);
    });
  }

  void _onSearchSubmitted(String query) {
    _searchDebounceTimer?.cancel();
    _executeSearch(query);
  }

  Future<void> _loadClaimedCuponIds({bool forceRefresh = false}) async {
    try {
      final result =
          await CuponesService.getCuponesRecibidos(
            forceRefresh: forceRefresh,
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
          final mergedIds = <String>{
            ..._claimedCuponIds,
            ...claimedCupones.map((c) => c.id),
          };
          _claimedCuponIds = mergedIds.toList();

          final mergedCodes = <String, String>{..._claimedCuponCodes};
          for (final cupon in claimedCupones) {
            final resolvedCode = cupon.codigo.trim();
            if (resolvedCode.isNotEmpty) {
              mergedCodes[cupon.id] = resolvedCode;
            }
          }
          _claimedCuponCodes
            ..clear()
            ..addAll(mergedCodes);

          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('Error loading claimed coupon IDs: $e');
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  String _safeImageUrl(String url) {
    if (url.isEmpty) return url;
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    final scheme = uri.scheme.isEmpty
        ? 'https'
        : (uri.scheme == 'http' ? 'https' : uri.scheme);
    return uri.replace(scheme: scheme).toString();
  }

  String _imageUrlForPlatform(String url) {
    final safe = _safeImageUrl(url);
    if (!kIsWeb || safe.isEmpty) return safe;
    final proxyBase = ApiConfig.imageProxyBase;
    if (proxyBase.isEmpty) return safe;
    final encoded = Uri.encodeComponent(safe);
    return '$proxyBase$encoded';
  }

  Future<void> _runInitialCouponLoadsWithRetry() async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await Future.wait([_loadCategorias(), _loadClaimedCuponIds()]);
        await _loadCupones(
          reset: !_cacheApplied,
          forceRefresh: !_cacheApplied,
          pageOverride: _cacheApplied ? _currentPage : 1,
        );

        if (_cacheApplied) {
          unawaited(
            _loadCupones(
              reset: false,
              forceRefresh: true,
              pageOverride: _currentPage,
            ),
          );
        }

        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  Widget _buildCouponActivationPendingCard(
    Color primaryGreen,
    Color textColor,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.14),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.07),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Stack(
                  children: [
                    // Radial glow — top center
                    Positioned(
                      top: -60,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 240,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                primaryGreen.withValues(alpha: 0.14),
                                primaryGreen.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Radial glow — bottom right (sutil)
                    Positioned(
                      bottom: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryGreen.withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon-box con glow
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.22),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.card_giftcard,
                              color: primaryGreen,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Pill "EN PROCESO"
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.18),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'EN PROCESO',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Título
                          Text(
                            'Activando cupones',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pronto tendrás tus beneficios disponibles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.40),
                              fontSize: 13,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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

  Widget _buildCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark, {
    bool compactMobile = false,
    bool forceMobileStyle = false,
  }) {
    final isClaimed = _claimedCuponIds.contains(cupon.id);
    final displayCode = (_claimedCuponCodes[cupon.id] ?? cupon.codigo).trim();
    final isWeb = kIsWeb && !forceMobileStyle;
    final double heroHeight = isWeb ? 140 : (compactMobile ? 112 : 160);
    final double logoSize = compactMobile ? 40 : 56;
    final EdgeInsets contentPadding = isWeb
        ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
        : (compactMobile
              ? const EdgeInsets.fromLTRB(14, 12, 14, 0)
              : const EdgeInsets.fromLTRB(16, 14, 16, 0));
    final double gapSm = isWeb ? 8 : (compactMobile ? 6 : 10);
    final double gapMd = isWeb ? 10 : (compactMobile ? 8 : 14);
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
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: const Color(0xFF111111),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: heroHeight,
                        width: double.infinity,
                        color: const Color(0xFF1A1A1A),
                        child: cupon.fotoUrl.isNotEmpty
                            ? Image.network(
                                _imageUrlForPlatform(cupon.fotoUrl),
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
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: isClaimed
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryGreen.withValues(alpha: 0.9),
                                      primaryGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: isDark
                                          ? Colors.white
                                          : AppConstants.textLight,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reclamado',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppConstants.textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Positioned(
                        top: compactMobile ? 8 : 12,
                        right: compactMobile ? 8 : 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactMobile ? 9 : 12,
                            vertical: compactMobile ? 4 : 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryGreen,
                                primaryGreen.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              compactMobile ? 18 : 24,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            cupon.descuento,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: compactMobile ? 12 : 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: compactMobile ? 8 : 12,
                        left: compactMobile ? 8 : 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(
                              compactMobile ? 10 : 12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.30),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: cupon.logoUrl.isNotEmpty
                                ? Image.network(
                                    _imageUrlForPlatform(cupon.logoUrl),
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: logoSize,
                                        height: logoSize,
                                        color: const Color(0xFF1A1A1A),
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
                                      );
                                    },
                                  )
                                : Container(
                                    width: logoSize,
                                    height: logoSize,
                                    color: const Color(0xFF1A1A1A),
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
                  if (isWeb)
                    Expanded(
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            SizedBox(height: gapSm),
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
                            SizedBox(height: gapSm),
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
                                      color: primaryGreen.withValues(
                                        alpha: 0.12,
                                      ),
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
                            SizedBox(height: gapSm),
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
                                    isClaimed
                                        ? 'Reclamado el: ${cupon.fechaVencimientoFormatted}'
                                        : 'Válido hasta: ${cupon.fechaVencimientoFormatted}',
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
                            SizedBox(
                              height: compactMobile
                                  ? 4
                                  : (isWeb ? gapSm : gapMd),
                            ),

                            // En web, fijamos el bloque inferior (código o botón)
                            // al fondo para mantener todas las cards simétricas.
                            if (isWeb) const Spacer(),
                            if (isClaimed) ...[
                              Container(
                                padding: EdgeInsets.all(
                                  isWeb ? 10 : (compactMobile ? 8 : 12),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryGreen.withValues(alpha: 0.12),
                                      primaryGreen.withValues(alpha: 0.06),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            compactMobile
                                                ? 'Código:'
                                                : 'Tu Código',
                                            style: TextStyle(
                                              fontSize: compactMobile ? 10 : 11,
                                              color: textColor.withValues(
                                                alpha: 0.6,
                                              ),
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          SizedBox(
                                            height: compactMobile ? 2 : 6,
                                          ),
                                          if (compactMobile)
                                            SizedBox(
                                              height: 16,
                                              width: double.infinity,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    displayCode,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: primaryGreen,
                                                      fontFamily: 'monospace',
                                                      letterSpacing: 0.9,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            _buildScrollableCouponCode(
                                              displayCode,
                                              primaryGreen,
                                              fontSize: isWeb ? 16 : 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: compactMobile ? 8 : 12),
                                    InkWell(
                                      onTap: () async {
                                        if (displayCode.isEmpty) return;
                                        await Clipboard.setData(
                                          ClipboardData(text: displayCode),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Código copiado: $displayCode',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            backgroundColor: primaryGreen,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(
                                        compactMobile ? 10 : 12,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          compactMobile ? 6 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            compactMobile ? 10 : 12,
                                          ),
                                          border: Border.all(
                                            color: primaryGreen.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.content_copy,
                                          color: primaryGreen,
                                          size: compactMobile ? 16 : 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              if (isWeb)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildClaimButton(
                                    context: context,
                                    cupon: cupon,
                                    primaryGreen: primaryGreen,
                                  ),
                                )
                              else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildClaimButton(
                                    context: context,
                                    cupon: cupon,
                                    primaryGreen: primaryGreen,
                                    compact: true,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cupon.nombre,
                              style: TextStyle(
                                fontSize: compactMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.2,
                              ),
                              maxLines: compactMobile ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
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
                            SizedBox(height: gapSm),
                            if (!compactMobile) ...[
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
                              SizedBox(height: gapSm),
                            ],
                            if (cupon.categorias.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: cupon.categorias
                                    .take(compactMobile ? 1 : 2)
                                    .map((cat) {
                                      final rawCategoryName = cat.nombre.trim();
                                      final compactCategoryName =
                                          rawCategoryName.contains(',')
                                          ? rawCategoryName
                                                .split(',')
                                                .first
                                                .trim()
                                          : rawCategoryName;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: primaryGreen.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          compactMobile
                                              ? compactCategoryName
                                              : rawCategoryName,
                                          style: TextStyle(
                                            fontSize: compactMobile ? 10 : 11,
                                            color: primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            SizedBox(height: gapSm),
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
                                    isClaimed
                                        ? 'Reclamado el: ${cupon.fechaVencimientoFormatted}'
                                        : 'Válido hasta: ${cupon.fechaVencimientoFormatted}',
                                    style: TextStyle(
                                      fontSize: compactMobile ? 10 : 11,
                                      color: textColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compactMobile ? 4 : gapMd),
                            if (isClaimed) ...[
                              Container(
                                padding: EdgeInsets.all(
                                  isWeb ? 10 : (compactMobile ? 8 : 12),
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryGreen.withValues(alpha: 0.12),
                                      primaryGreen.withValues(alpha: 0.06),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.3),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: compactMobile
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Código:',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: textColor.withValues(
                                                      alpha: 0.6,
                                                    ),
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                SizedBox(
                                                  height: 16,
                                                  width: double.infinity,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                        displayCode,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: primaryGreen,
                                                          fontFamily:
                                                              'monospace',
                                                          letterSpacing: 0.9,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          InkWell(
                                            onTap: () async {
                                              if (displayCode.isEmpty) return;
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: displayCode,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Código copiado: $displayCode',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  backgroundColor: primaryGreen,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: primaryGreen.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: primaryGreen
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.content_copy,
                                                color: primaryGreen,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
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
                                                      alpha: 0.6,
                                                    ),
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                _buildScrollableCouponCode(
                                                  displayCode,
                                                  primaryGreen,
                                                  fontSize: isWeb ? 16 : 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          InkWell(
                                            onTap: () async {
                                              if (displayCode.isEmpty) return;
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: displayCode,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Código copiado: $displayCode',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  backgroundColor: primaryGreen,
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: primaryGreen.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: primaryGreen
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.content_copy,
                                                color: primaryGreen,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ] else ...[
                              Align(
                                alignment: compactMobile
                                    ? Alignment.center
                                    : Alignment.centerRight,
                                child: _buildClaimButton(
                                  context: context,
                                  cupon: cupon,
                                  primaryGreen: primaryGreen,
                                  compact: true,
                                ),
                              ),
                            ],
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
  }

  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 380;
  }

  Widget _buildClaimButton({
    required BuildContext context,
    required Cupon cupon,
    required Color primaryGreen,
    bool compact = false,
  }) {
    final isSmallScreen = _isSmallScreen(context);
    final showIcon = !isSmallScreen;
    final isClaimed = _claimedCuponIds.contains(cupon.id);
    final isClaiming = _claimingCuponIds.contains(cupon.id);
    final isDisabled = isClaimed || isClaiming;

    return ElevatedButton(
      onPressed: isDisabled
          ? null
          : () => _claimCupon(context, cupon, primaryGreen),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: AppConstants.textLight,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 7 : (compact ? 9 : 11),
          horizontal: isSmallScreen ? 12 : (compact ? 14 : 16),
        ),
        minimumSize: Size(isSmallScreen ? 88 : 0, isSmallScreen ? 36 : 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        shadowColor: primaryGreen.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              isClaimed ? Icons.check_circle_outline : Icons.check_circle,
              size: 17,
            ),
            const SizedBox(width: 7),
          ],
          Text(
            isClaimed
                ? 'Reclamado'
                : (isClaiming ? 'Reclamando...' : 'Reclamar'),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _claimCupon(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
  ) async {
    if (_claimedCuponIds.contains(cupon.id) ||
        _claimingCuponIds.contains(cupon.id)) {
      return false;
    }

    if (mounted) {
      setState(() {
        _claimingCuponIds.add(cupon.id);
      });
    }

    LoadingOverlay.show(context, message: 'Reclamando cupón...');

    try {
      final claimResponse = await CuponesService.claimCupon(cuponId: cupon.id);
      final claimedCode = _extractClaimCodeFromResponse(
        claimResponse,
        cupon.id,
      );

      LoadingOverlay.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Cupón reclamado exitosamente!'),
          duration: const Duration(seconds: 3),
          backgroundColor: primaryGreen,
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );

      if (!mounted) return false;
      setState(() {
        if (!_claimedCuponIds.contains(cupon.id)) {
          _claimedCuponIds.add(cupon.id);
        }
        _claimingCuponIds.remove(cupon.id);
        if (claimedCode.isNotEmpty) {
          _claimedCuponCodes[cupon.id] = claimedCode;
        } else {
          final modelCode = cupon.codigo.trim();
          if (modelCode.isNotEmpty) {
            _claimedCuponCodes[cupon.id] = modelCode;
          }
        }
        _applyFilter();
      });
      unawaited(_loadClaimedCuponIds(forceRefresh: true));
      widget.onCuponClaimed?.call();
      return true;
    } catch (e) {
      LoadingOverlay.hide(context);

      if (mounted) {
        setState(() {
          _claimingCuponIds.remove(cupon.id);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  String _extractClaimCodeFromResponse(
    Map<String, dynamic> response,
    String cuponId,
  ) {
    final candidates = <String>[];

    void addCandidate(dynamic value) {
      if (value == null) return;
      final normalized = value.toString().trim();
      if (normalized.isEmpty) return;
      if (normalized == cuponId) return;
      candidates.add(normalized);
    }

    void collectFromMap(Map<dynamic, dynamic> source) {
      addCandidate(source['codigo']);
      addCandidate(source['code']);
      addCandidate(source['coupon_code']);
      addCandidate(source['couponCode']);
      addCandidate(source['codigo_afiliado']);
      addCandidate(source['affiliate_code']);

      final nestedData = source['data'];
      if (nestedData is Map) {
        collectFromMap(nestedData);
      }

      final nestedSuccess = source['success'];
      if (nestedSuccess is Map) {
        collectFromMap(nestedSuccess);
      }
    }

    collectFromMap(response);
    return candidates.isNotEmpty ? candidates.first : '';
  }

  void _showCuponDetails(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
  ) {
    const dialogSurface = Color(0xFF0A1A1A);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        var isClaimed = _claimedCuponIds.contains(cupon.id);
        var isClaiming = _claimingCuponIds.contains(cupon.id);
        var displayCode = (_claimedCuponCodes[cupon.id] ?? cupon.codigo).trim();

        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              decoration: BoxDecoration(
                color: dialogSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hero header con imagen
                          Stack(
                            children: [
                              Container(
                                height: 200,
                                width: double.infinity,
                                color: const Color(0xFF0A0A0A),
                                child: cupon.fotoUrl.isNotEmpty
                                    ? Image.network(
                                        cupon.fotoUrl,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox.shrink(),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.local_offer_rounded,
                                          size: 72,
                                          color: primaryGreen.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                              ),
                              // Gradient overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.12),
                                        Colors.black.withValues(alpha: 0.70),
                                        const Color(0xFF0A1A1A),
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Discount badge — top right
                              Positioned(
                                top: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryGreen,
                                        primaryGreen.withValues(alpha: 0.75),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.55,
                                        ),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    cupon.descuento,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              // Logo bottom-left (if available)
                              if (cupon.logoUrl.isNotEmpty)
                                Positioned(
                                  bottom: 14,
                                  left: 16,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.30,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryGreen.withValues(
                                            alpha: 0.20,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        cupon.logoUrl,
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 46,
                                                  height: 46,
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Title + company overlay at bottom
                              Positioned(
                                bottom: 14,
                                left: cupon.logoUrl.isNotEmpty ? 78 : 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cupon.nombre,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                        height: 1.15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.storefront_rounded,
                                          color: primaryGreen,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            cupon.empresa.nombre,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: primaryGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Categories + logo bonda
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                            child: Column(
                              children: [
                                if (cupon.categorias.isNotEmpty) ...[
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: cupon.categorias.map((cat) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryGreen.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: primaryGreen.withValues(
                                                alpha: 0.35,
                                              ),
                                              width: 0.8,
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
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Beneficio provisto por ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
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
                                _buildSection(
                                  'Cómo usar',
                                  Icons.info_outline,
                                  primaryGreen,
                                  cupon.descripcionMicrositio,
                                  textColor,
                                ),
                                const SizedBox(height: 18),
                                _buildSection(
                                  'Términos y Condiciones',
                                  Icons.gavel,
                                  primaryGreen,
                                  cupon.legales,
                                  textColor.withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: 18),
                                // Fecha vencimiento
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D0D0D),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: primaryGreen.withValues(
                                              alpha: 0.25,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.schedule_rounded,
                                          color: primaryGreen,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Válido hasta',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: textColor.withValues(
                                                  alpha: 0.45,
                                                ),
                                                letterSpacing: 0.4,
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
                                if (isClaimed) ...[
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryGreen.withValues(alpha: 0.08),
                                          primaryGreen.withValues(alpha: 0.04),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.2,
                                        ),
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
                                              _buildScrollableCouponCode(
                                                displayCode,
                                                primaryGreen,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () async {
                                            if (displayCode.isEmpty) return;
                                            await Clipboard.setData(
                                              ClipboardData(text: displayCode),
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Código copiado: $displayCode',
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                                backgroundColor: primaryGreen,
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: primaryGreen.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.content_copy,
                                              color: primaryGreen,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                // Botón reclamar (mismo flujo que el botón de card)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: (isClaimed || isClaiming)
                                        ? null
                                        : () async {
                                            setDialogState(() {
                                              isClaiming = true;
                                            });
                                            final claimed = await _claimCupon(
                                              context,
                                              cupon,
                                              primaryGreen,
                                            );
                                            if (!context.mounted) return;
                                            setDialogState(() {
                                              isClaiming = false;
                                              if (claimed) {
                                                isClaimed = true;
                                                displayCode =
                                                    (_claimedCuponCodes[cupon
                                                                .id] ??
                                                            cupon.codigo)
                                                        .trim();
                                              }
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: AppConstants.textLight,
                                      disabledBackgroundColor:
                                          Colors.grey.shade800,
                                      disabledForegroundColor: textColor
                                          .withValues(alpha: 0.55),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 8,
                                      shadowColor: primaryGreen.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      isClaimed
                                          ? 'CUPÓN YA RECLAMADO'
                                          : (isClaiming
                                                ? 'RECLAMANDO...'
                                                : 'RECLAMAR'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón cerrar en esquina
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.3),
                        ),
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

  Widget _buildSection(
    String title,
    IconData icon,
    Color primaryGreen,
    String content,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryGreen,
                        primaryGreen.withValues(alpha: 0.50),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.40),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: primaryGreen.withValues(alpha: 0.07),
                    child: Row(
                      children: [
                        Icon(icon, color: primaryGreen, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                            letterSpacing: 0.5,
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
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
          ),
          child: Html(
            data: content,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(13),
                color: textColor,
                lineHeight: const LineHeight(1.5),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'ul': Style(margin: Margins.only(left: 16, bottom: 8)),
              'li': Style(margin: Margins.only(bottom: 4)),
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recheckAuthAndMaybeBlock();
    });

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final pagedFilteredCupones = _filteredCupones;
    final canGoPrevious = _currentPage > 1;
    final canGoNext = _hasMore;

    final categories = <String>{'Todos'};
    categories.addAll(_remoteCategories.map((c) => c.nombre));
    categories.addAll(_categoriaByName.keys);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCupones(
          pageOverride: _currentPage,
          reset: false,
          categoryId: _selectedCategoryId,
          categoryName: _selectedFilter == 'Todos' ? null : _selectedFilter,
          ignoreCategory: false,
          forceRefresh: true,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showClaimed)
            SectionHeaderWidget(
              title: 'Cupones Reclamados',
              subtitle: 'Mira y usa los cupones que ya reclamaste',
              icon: Icons.check_circle,
              onSwitch: () {
                _showClaimed = false;
                _resetDiscountsState(triggerLoad: true);
              },
              switchIcon: Icons.local_offer_outlined,
            )
          else
            SectionHeaderWidget(
              title: 'Descuentos',
              subtitle: 'Descuentos exclusivos para vos.',
              icon: Icons.local_offer,
              switchButtonKey: widget.claimedSwitchTutorialTargetKey,
              onSwitch: () {
                setState(() {
                  _showClaimed = true;
                });
                _resetDiscountsState(triggerLoad: false);
              },
              switchIcon: Icons.check_circle_outline,
            ),
          if (_bondaEnabled == false)
            const Expanded(child: NotEnabledContent())
          else if (_showClaimed)
            Expanded(
              child: ClaimedCouponsContent(
                key: widget.claimedKey,
                hideHeader: true,
              ),
            )
          else if (_isCouponActivationReady)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF0E0E0E),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.14),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    onSearch: _onSearchSubmitted,
                    onChanged: _onSearchChanged,
                    placeholder:
                        'Buscar por nombre de cupón, empresa o categoría',
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected = _selectedFilter == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        primaryGreen,
                                        primaryGreen.withValues(alpha: 0.75),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : primaryGreen.withValues(alpha: 0.22),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isSelected ? primaryGreen : Colors.black)
                                          .withValues(alpha: 0.12),
                                  blurRadius: isSelected ? 10 : 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final selectedCat = category == 'Todos'
                                      ? null
                                      : (_remoteCategories.firstWhere(
                                          (c) => c.nombre == category,
                                          orElse: () =>
                                              _categoriaByName[category] ??
                                              Categoria(
                                                id: category,
                                                nombre: category,
                                              ),
                                        ));
                                  final selectedId = selectedCat == null
                                      ? null
                                      : (selectedCat.id?.toString() ??
                                            selectedCat.finalId?.toString());
                                  setState(() {
                                    _selectedFilter = category;
                                    _selectedCategoryId = selectedId;
                                    _currentPage = 1;
                                    _apiPage = 1;
                                  });
                                  _scrollListToTop();
                                  unawaited(
                                    _loadCupones(
                                      pageOverride: 1,
                                      reset: true,
                                      categoryId: selectedId,
                                      categoryName: selectedCat?.nombre,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.local_offer_outlined,
                                        size: 16,
                                        color: isSelected
                                            ? (isDark
                                                  ? Colors.white
                                                  : AppConstants.textLight)
                                            : primaryGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? (isDark
                                                    ? Colors.white
                                                    : AppConstants.textLight)
                                              : primaryGreen,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          if (!_showClaimed && _bondaEnabled != false && !_isCouponActivationReady)
            Expanded(
              child: (_isBootstrapLoading || _isLoading)
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
                  : _buildCouponActivationPendingCard(primaryGreen, textColor),
            ),
          if (!_showClaimed && _bondaEnabled != false && _isCouponActivationReady)
            Expanded(
              child: (_isLoading || _isBootstrapLoading) && _cupones.isEmpty
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
                          const Icon(
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
                              () async {
                                final ok = await _guardAuthOrRedirect();
                                if (!ok) return;

                                _currentPage = 1;
                                _loadCupones(
                                  pageOverride: 1,
                                  reset: true,
                                  categoryId: _selectedCategoryId,
                                  categoryName: _selectedFilter == 'Todos'
                                      ? null
                                      : _selectedFilter,
                                  ignoreCategory: false,
                                  forceRefresh: true,
                                );
                              }();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: AppConstants.textLight,
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
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  // >= 600px: tablet o desktop (web o nativo)
                                  final useWideLayout = width >= 600;

                                  if (useWideLayout) {
                                    // Tablet y desktop: grid adaptativo con MaxCrossAxisExtent
                                    final double maxExtent;
                                    if (width >= 1800) {
                                      maxExtent = 420;
                                    } else if (width >= 1400) {
                                      maxExtent = 460;
                                    } else if (width >= 900) {
                                      maxExtent = 520;
                                    } else {
                                      // Tablet 600-900px: 2 columnas cómodas
                                      maxExtent = 400;
                                    }

                                    return GridView.builder(
                                      controller: _listScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        24,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: maxExtent,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            mainAxisExtent: 430,
                                          ),
                                      itemCount: pagedFilteredCupones.length,
                                      itemBuilder: (context, index) {
                                        final cupon =
                                            pagedFilteredCupones[index];
                                        final card = _buildCuponCard(
                                          context,
                                          cupon,
                                          primaryGreen,
                                          textColor,
                                          isDark,
                                        );
                                        if (index == 0 &&
                                            widget.firstCouponTutorialTargetKey !=
                                                null) {
                                          return KeyedSubtree(
                                            key: widget
                                                .firstCouponTutorialTargetKey,
                                            child: card,
                                          );
                                        }
                                        return card;
                                      },
                                    );
                                  }

                                  // Solo phones < 600px llegan aquí
                                  final isTwoColumnPhone = width >= 360;
                                  final hasClaimedInPage = pagedFilteredCupones
                                      .any(
                                        (cupon) =>
                                            _claimedCuponIds.contains(cupon.id),
                                      );

                                  if (isTwoColumnPhone) {
                                    return GridView.builder(
                                      controller: _listScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        20,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            // Cuando hay cupones reclamados en la grilla,
                                            // el bloque de código necesita algunos px extra.
                                            childAspectRatio: hasClaimedInPage
                                                ? 0.62
                                                : 0.66,
                                          ),
                                      itemCount: pagedFilteredCupones.length,
                                      itemBuilder: (context, index) {
                                        final cupon =
                                            pagedFilteredCupones[index];
                                        final card = _buildCuponCard(
                                          context,
                                          cupon,
                                          primaryGreen,
                                          textColor,
                                          isDark,
                                          compactMobile: true,
                                          forceMobileStyle: kIsWeb,
                                        );
                                        if (index == 0 &&
                                            widget.firstCouponTutorialTargetKey !=
                                                null) {
                                          return KeyedSubtree(
                                            key: widget
                                                .firstCouponTutorialTargetKey,
                                            child: card,
                                          );
                                        }
                                        return card;
                                      },
                                    );
                                  }

                                  return ListView.builder(
                                    controller: _listScrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      24,
                                    ),
                                    itemCount: pagedFilteredCupones.length,
                                    itemBuilder: (context, index) {
                                      final cupon = pagedFilteredCupones[index];
                                      final item = Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 520,
                                            ),
                                            child: _buildCuponCard(
                                              context,
                                              cupon,
                                              primaryGreen,
                                              textColor,
                                              isDark,
                                              forceMobileStyle: kIsWeb,
                                            ),
                                          ),
                                        ),
                                      );
                                      if (index == 0 &&
                                          widget.firstCouponTutorialTargetKey !=
                                              null) {
                                        return KeyedSubtree(
                                          key: widget
                                              .firstCouponTutorialTargetKey,
                                          child: item,
                                        );
                                      }
                                      return item;
                                    },
                                  );
                                },
                              ),
                              if (_isLoading && _filteredCupones.isNotEmpty)
                                Positioned(
                                  top: 12,
                                  right: 16,
                                  child: LoadingBadge(
                                    color: primaryGreen,
                                    size: 36,
                                    spinnerSize: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: PaginationBar(
                              currentPage: _currentPage,
                              canGoPrevious: canGoPrevious,
                              canGoNext: canGoNext,
                              onPrev: () {
                                _scrollListToTop();
                                final prevPage = (_currentPage - 1).clamp(
                                  1,
                                  1 << 30,
                                );
                                unawaited(_loadCupones(pageOverride: prevPage));
                              },
                              onNext: () {
                                _scrollListToTop();
                                final nextPage = _currentPage + 1;
                                unawaited(_loadCupones(pageOverride: nextPage));
                              },
                              primaryColor: primaryGreen,
                              textColor: textColor,
                            ),
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
