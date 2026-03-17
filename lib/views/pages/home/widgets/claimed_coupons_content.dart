import 'dart:async';
import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/utils/coupon_error_parser.dart';
import 'package:boombet_app/views/pages/home/widgets/loading_badge.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boombet_app/services/token_service.dart';

class ClaimedCouponsContent extends StatefulWidget {
  const ClaimedCouponsContent({
    super.key,
    this.hideHeader = false,
    this.enablePullToRefresh = true,
  });

  final bool hideHeader;
  final bool enablePullToRefresh;

  @override
  State<ClaimedCouponsContent> createState() => ClaimedCouponsContentState();
}

class ClaimedCouponsContentState extends State<ClaimedCouponsContent> {
  List<Cupon> _claimedCupones = [];
  int _claimedPage = 1;
  final int _claimedPageSize = 25;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _claimedHasMore = false;
  bool _claimedCacheApplied = false;
  DateTime? _claimedCacheTimestamp;
  static const String _claimedCacheKey = 'cached_claimed_cupones_bonda';
  static const String _claimedCacheTsKey = 'cached_claimed_cupones_ts_bonda';
  static const String _claimedCachePageKey = 'cached_claimed_cupones_page';
  static const String _claimedCacheHasMoreKey =
      'cached_claimed_cupones_has_more';
  static const Duration _claimedCacheTtl = Duration(hours: 6);

  static const List<String> _claimedLegacyKeys = [
    _claimedCacheKey,
    _claimedCacheTsKey,
    _claimedCachePageKey,
    _claimedCacheHasMoreKey,
  ];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadClaimedCache();

      // Siempre refrescar desde backend en background para evitar mostrar
      // datos stale entre sesiones de usuarios en el mismo dispositivo.
      unawaited(_loadClaimedCupones(pageOverride: _claimedPage));
    });
  }

  Future<void> refreshClaimedCupones() async {
    await _loadClaimedCupones(forceRefresh: true);
  }

  Future<void> _clearClaimedCachePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await _removeClaimedCacheKeys(prefs);
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

  Future<void> _removeClaimedCacheKeys(
    SharedPreferences prefs, {
    String? scope,
  }) async {
    for (final legacyKey in _claimedLegacyKeys) {
      await prefs.remove(legacyKey);
    }

    final keys = prefs.getKeys();
    for (final key in keys) {
      final isScopedClaimedCache = _claimedLegacyKeys.any(
        (baseKey) => key.startsWith('${baseKey}_'),
      );
      if (!isScopedClaimedCache) continue;

      if (scope == null) {
        await prefs.remove(key);
        continue;
      }

      final matchesScope = _claimedLegacyKeys.any(
        (baseKey) => key == _scopedKey(baseKey, scope),
      );
      if (matchesScope) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _loadClaimedCache() async {
    try {
      final token = await TokenService.getToken();
      if (token == null ||
          token.isEmpty ||
          TokenService.isJwtExpiredSafe(token)) {
        await _clearClaimedCachePrefs();
        return;
      }

      final scope = await _currentCacheScope();
      if (scope == null) {
        await _clearClaimedCachePrefs();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await _removeClaimedCacheKeys(prefs, scope: scope);

      final cacheKey = _scopedKey(_claimedCacheKey, scope);
      final cacheTsKey = _scopedKey(_claimedCacheTsKey, scope);
      final cachePageKey = _scopedKey(_claimedCachePageKey, scope);
      final cacheHasMoreKey = _scopedKey(_claimedCacheHasMoreKey, scope);

      final cached = prefs.getString(cacheKey);
      if (cached == null || cached.isEmpty) return;

      final cachedTs = prefs.getString(cacheTsKey);
      if (cachedTs != null) {
        _claimedCacheTimestamp = DateTime.tryParse(cachedTs);
      }

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
        _claimedCupones = cachedCupones;
        _claimedPage = prefs.getInt(cachePageKey) ?? _claimedPage;
        _claimedHasMore = prefs.getBool(cacheHasMoreKey) ?? _claimedHasMore;
        _claimedCacheApplied = true;
      });

      final isStale =
          _claimedCacheTimestamp != null &&
          DateTime.now().difference(_claimedCacheTimestamp!) > _claimedCacheTtl;
      if (isStale) {
        debugPrint(
          'INFO: Cache de cupones reclamados vencido, usando cache igualmente.',
        );
      }
    } catch (e) {
      debugPrint('WARN: No se pudo cargar cache de cupones reclamados: $e');
    }
  }

  Future<void> _persistClaimedCache() async {
    try {
      final scope = await _currentCacheScope();
      if (scope == null) return;

      final prefs = await SharedPreferences.getInstance();
      await _removeClaimedCacheKeys(prefs, scope: scope);

      final cacheKey = _scopedKey(_claimedCacheKey, scope);
      final cacheTsKey = _scopedKey(_claimedCacheTsKey, scope);
      final cachePageKey = _scopedKey(_claimedCachePageKey, scope);
      final cacheHasMoreKey = _scopedKey(_claimedCacheHasMoreKey, scope);

      final data = _claimedCupones.map((c) => c.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(data));
      await prefs.setString(cacheTsKey, DateTime.now().toIso8601String());
      await prefs.setInt(cachePageKey, _claimedPage);
      await prefs.setBool(cacheHasMoreKey, _claimedHasMore);
    } catch (e) {
      debugPrint('WARN: No se pudo guardar cache de cupones reclamados: $e');
    }
  }

  Future<void> _loadClaimedCupones({
    int? pageOverride,
    bool forceRefresh = false,
  }) async {
    if (!mounted) return;
    final targetPage = pageOverride ?? _claimedPage;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result =
          await CuponesService.getCuponesRecibidos(
            page: targetPage,
            pageSize: _claimedPageSize,
            forceRefresh: forceRefresh,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('ERROR: Timeout loading claimed cupones');
              throw TimeoutException('Timeout cargando cupones reclamados');
            },
          );

      if (!mounted) return;

      setState(() {
        _claimedCupones = result['cupones'] ?? [];
        _claimedHasMore = result['has_more'] as bool? ?? false;
        _claimedPage = targetPage;
        _isLoading = false;
        _claimedCacheApplied = true;
      });

      unawaited(_persistClaimedCache());
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = parseCouponErrorMessage(e, claimedCoupons: true);
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
    final pagedCupones = _claimedCupones;
    final canGoPrevious = _claimedPage > 1;
    final canGoNext = _claimedHasMore;

    final content = Column(
      children: [
        if (!widget.hideHeader)
          SectionHeaderWidget(
            title: 'Mis Cupones Reclamados',
            subtitle: '${_claimedCupones.length} códigos disponibles',
            icon: Icons.check_circle,
            onRefresh: _loadClaimedCupones,
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
                        child: const Icon(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: AppConstants.textLight,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reintentar'),
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
                        child: const Icon(
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
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final useDesktopWebLayout =
                                  kIsWeb && width >= 900;

                              if (useDesktopWebLayout) {
                                final double maxCrossAxisExtent = width >= 1700
                                    ? 420
                                    : width >= 1400
                                    ? 400
                                    : width >= 1100
                                    ? 380
                                    : 360;
                                // Reducimos altura para evitar espacio vacío en reclamados.
                                final double mainAxisExtent = width >= 1700
                                    ? 368
                                    : width >= 1400
                                    ? 356
                                    : width >= 1100
                                    ? 346
                                    : 336;

                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: pagedCupones.length,
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: maxCrossAxisExtent,
                                        mainAxisExtent: mainAxisExtent,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                      ),
                                  itemBuilder: (context, index) {
                                    final cupon = pagedCupones[index];
                                    return _buildClaimedCuponCard(
                                      context,
                                      cupon,
                                      primaryGreen,
                                      textColor,
                                      isDark,
                                    );
                                  },
                                );
                              }

                              final isTwoColumnCompact = width >= 360;
                              if (isTwoColumnCompact) {
                                final compactAspectRatio = kIsWeb ? 0.72 : 0.70;
                                return GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    12,
                                    20,
                                  ),
                                  itemCount: pagedCupones.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: compactAspectRatio,
                                      ),
                                  itemBuilder: (context, index) {
                                    final cupon = pagedCupones[index];
                                    return _buildClaimedCuponCard(
                                      context,
                                      cupon,
                                      primaryGreen,
                                      textColor,
                                      isDark,
                                      compactMobile: true,
                                      forceMobileStyle: kIsWeb,
                                    );
                                  },
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: pagedCupones.length,
                                itemBuilder: (context, index) {
                                  final cupon = pagedCupones[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: Duration(
                                      milliseconds: 300 + (index * 50),
                                    ),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 30 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _buildClaimedCuponCard(
                                        context,
                                        cupon,
                                        primaryGreen,
                                        textColor,
                                        isDark,
                                        forceMobileStyle: kIsWeb,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          if (_isLoading && _claimedCupones.isNotEmpty)
                            Positioned(
                              top: 12,
                              right: 16,
                              child: LoadingBadge(
                                color: primaryGreen,
                                size: 36,
                                spinnerSize: 18,
                                backgroundColor: Colors.black.withOpacity(0.75),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: PaginationBar(
                          currentPage: _claimedPage,
                          canGoPrevious: canGoPrevious,
                          canGoNext: canGoNext,
                          onPrev: () {
                            final prevPage = (_claimedPage - 1).clamp(
                              1,
                              1 << 30,
                            );
                            _loadClaimedCupones(pageOverride: prevPage);
                          },
                          onNext: () {
                            final nextPage = _claimedPage + 1;
                            _loadClaimedCupones(pageOverride: nextPage);
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
    );

    if (!widget.enablePullToRefresh) {
      return content;
    }

    return RefreshIndicator(
      onRefresh: () async =>
          _loadClaimedCupones(pageOverride: 1, forceRefresh: true),
      child: content,
    );
  }

  Widget _buildClaimedCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark, {
    bool compactMobile = false,
    bool forceMobileStyle = false,
  }) {
    final isWeb = kIsWeb && !forceMobileStyle;
    final double heroHeight = isWeb ? 118 : (compactMobile ? 104 : 136);
    final EdgeInsets contentPadding = isWeb
        ? const EdgeInsets.fromLTRB(14, 12, 14, 0)
        : (compactMobile
              ? const EdgeInsets.fromLTRB(12, 10, 12, 0)
              : const EdgeInsets.fromLTRB(16, 12, 16, 0));
    final double gapSm = isWeb ? 8 : (compactMobile ? 6 : 10);
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
                color: primaryGreen.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                                Colors.black.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                              colors: [
                                primaryGreen,
                                primaryGreen.withValues(alpha: 0.75),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            cupon.descuento,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
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
                                color: primaryGreen.withValues(alpha: 0.45),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.black,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Reclamado',
                                style: TextStyle(
                                  color: Colors.black,
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
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryGreen.withValues(alpha: 0.10),
                                    primaryGreen.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen.withValues(alpha: 0.28),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.08),
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: primaryGreen,
                                            fontFamily: 'monospace',
                                            letterSpacing: 1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Código copiado: ${cupon.displayCode}',
                                          ),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: primaryGreen,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryGreen.withValues(
                                            alpha: 0.25,
                                          ),
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
                            SizedBox(height: gapSm),
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
                            SizedBox(height: gapSm),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
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
                          SizedBox(height: compactMobile ? 8 : 12),
                          Container(
                            padding: EdgeInsets.all(compactMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryGreen.withValues(alpha: 0.10),
                                  primaryGreen.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.28),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGreen.withValues(alpha: 0.08),
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
                                    children: [
                                      Text(
                                        'Tu Código',
                                        style: TextStyle(
                                          fontSize: compactMobile ? 10 : 11,
                                          color: textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: compactMobile ? 2 : 6),
                                      Text(
                                        cupon.displayCode,
                                        style: TextStyle(
                                          fontSize: compactMobile ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                          fontFamily: 'monospace',
                                          letterSpacing: 1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: compactMobile ? 8 : 12),
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
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        compactMobile ? 10 : 12,
                                      ),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.25,
                                        ),
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
                          SizedBox(height: compactMobile ? 6 : 10),
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
                                    fontSize: compactMobile ? 10 : 11,
                                    color: textColor.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compactMobile ? 8 : 12),
                        ],
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

  void _showClaimedCuponDetails(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
  ) {
    const dialogSurface = Color(0xFF0A1A1A);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                                    color: primaryGreen.withValues(alpha: 0.55),
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
                          // Logo bottom-left
                          if (cupon.logoUrl.isNotEmpty)
                            Positioned(
                              bottom: 14,
                              left: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: primaryGreen.withValues(alpha: 0.30),
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
                                              color: const Color(0xFF1A1A1A),
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
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
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
                                  color: Colors.white.withValues(alpha: 0.08),
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
                            // Código reclamado
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
                                  color: primaryGreen.withValues(alpha: 0.2),
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
                                          cupon.displayCode,
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
                                      await Clipboard.setData(
                                        ClipboardData(text: cupon.displayCode),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Código copiado: ${cupon.displayCode}',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            backgroundColor: primaryGreen,
                                          ),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(height: 18),
                            _buildHtmlSection(
                              'Instrucciones',
                              Icons.info_outline,
                              primaryGreen,
                              cupon.instrucciones,
                              textColor,
                            ),
                            if (cupon.legales.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _buildHtmlSection(
                                'Términos y Condiciones',
                                Icons.gavel,
                                primaryGreen,
                                cupon.legales,
                                textColor.withValues(alpha: 0.8),
                              ),
                            ],
                            const SizedBox(height: 18),
                            // Fecha reclamado
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0D0D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: primaryGreen.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today,
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
                                          'Reclamado el',
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
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: AppConstants.textLight,
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
                                child: const Text(
                                  'CERRAR',
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
  }

  Widget _buildHtmlSection(
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
            data: content.isNotEmpty ? content : 'Sin información disponible.',
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
              'a': Style(
                color: primaryGreen,
                textDecoration: TextDecoration.underline,
              ),
            },
          ),
        ),
      ],
    );
  }
}
