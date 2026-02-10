import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
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
  static const String _claimedCachePageKey =
      'cached_claimed_cupones_page';
  static const String _claimedCacheHasMoreKey =
      'cached_claimed_cupones_has_more';
  static const Duration _claimedCacheTtl = Duration(hours: 6);

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
      if (!_claimedCacheApplied) {
        await _loadClaimedCupones();
      }
    });
  }

  Future<void> refreshClaimedCupones() async {
    await _loadClaimedCupones();
  }

  Future<void> _clearClaimedCachePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claimedCacheKey);
    await prefs.remove(_claimedCacheTsKey);
    await prefs.remove(_claimedCachePageKey);
    await prefs.remove(_claimedCacheHasMoreKey);
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

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_claimedCacheKey);
      if (cached == null || cached.isEmpty) return;

      final cachedTs = prefs.getString(_claimedCacheTsKey);
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
        _claimedPage = prefs.getInt(_claimedCachePageKey) ?? _claimedPage;
        _claimedHasMore =
            prefs.getBool(_claimedCacheHasMoreKey) ?? _claimedHasMore;
        _claimedCacheApplied = true;
      });

      final isStale = _claimedCacheTimestamp != null &&
          DateTime.now().difference(_claimedCacheTimestamp!) >
              _claimedCacheTtl;
      if (isStale) {
        debugPrint('INFO: Cache de cupones reclamados vencido, usando cache igualmente.');
      }
    } catch (e) {
      debugPrint('WARN: No se pudo cargar cache de cupones reclamados: $e');
    }
  }

  Future<void> _persistClaimedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _claimedCupones.map((c) => c.toJson()).toList();
      await prefs.setString(_claimedCacheKey, jsonEncode(data));
      await prefs.setString(
        _claimedCacheTsKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt(_claimedCachePageKey, _claimedPage);
      await prefs.setBool(_claimedCacheHasMoreKey, _claimedHasMore);
    } catch (e) {
      debugPrint('WARN: No se pudo guardar cache de cupones reclamados: $e');
    }
  }

  Future<void> _loadClaimedCupones({int? pageOverride}) async {
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
    final pagedCupones = _claimedCupones;
    final canGoPrevious = _claimedPage > 1;
    final canGoNext = _claimedHasMore;
    final claimedCanJumpBack5 = _claimedPage > 1;
    final claimedCanJumpBack10 = _claimedPage > 1;
    final claimedCanJumpForward = canGoNext;
    final isWeb = kIsWeb;

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
                          if (isWeb)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;

                                // Similar lógica que “Descuentos” (SOLO WEB):
                                // grid responsive por ancho, con cards compactas.
                                final double maxCrossAxisExtent = width >= 1700
                                    ? 420
                                    : width >= 1400
                                    ? 400
                                    : width >= 1100
                                    ? 380
                                    : 360;
                                // Las cards reclamadas tienen más contenido (código + fecha),
                                // así que en web fijamos un alto para evitar overflows.
                                final double mainAxisExtent = width >= 1700
                                    ? 380
                                    : width >= 1400
                                    ? 370
                                    : width >= 1100
                                    ? 360
                                    : 350;

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
                              },
                            )
                          else
                            ListView.builder(
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
                          canJumpBack5: claimedCanJumpBack5,
                          canJumpBack10: claimedCanJumpBack10,
                          canJumpForward: claimedCanJumpForward,
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
                          onJumpBack5: () {
                            final prevPage = (_claimedPage - 5).clamp(
                              1,
                              1 << 30,
                            );
                            _loadClaimedCupones(pageOverride: prevPage);
                          },
                          onJumpBack10: () {
                            final prevPage = (_claimedPage - 10).clamp(
                              1,
                              1 << 30,
                            );
                            _loadClaimedCupones(pageOverride: prevPage);
                          },
                          onJumpForward5: () {
                            final nextPage = _claimedPage + 5;
                            _loadClaimedCupones(pageOverride: nextPage);
                          },
                          onJumpForward10: () {
                            final nextPage = _claimedPage + 10;
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
      onRefresh: () async => _loadClaimedCupones(pageOverride: 1),
      child: content,
    );
  }

  Widget _buildClaimedCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    final isWeb = kIsWeb;
    final double heroHeight = isWeb ? 130 : 160;
    final EdgeInsets contentPadding = isWeb
        ? const EdgeInsets.fromLTRB(14, 12, 14, 0)
        : const EdgeInsets.fromLTRB(16, 14, 16, 0);
    final double gapSm = isWeb ? 8 : 12;
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
                color: isDark ? Colors.grey[900] : AppConstants.lightCardBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: heroHeight,
                          width: double.infinity,
                          color: Colors.green.withValues(alpha: 0.1),
                          child: cupon.fotoUrl.isNotEmpty
                              ? Image.network(
                                  _imageUrlForPlatform(cupon.fotoUrl),
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
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppConstants.textLight,
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
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: isDark
                                      ? Colors.white
                                      : AppConstants.textLight,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Reclamado',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppConstants.textLight,
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
                              SizedBox(height: gapSm),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(10),
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
                                            style: const TextStyle(
                                              fontSize: 16,
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
                                          ClipboardData(
                                            text: cupon.displayCode,
                                          ),
                                        );
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.content_copy,
                                          color: Colors.green,
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                      child: const Icon(
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
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 3),
                                    SizedBox(height: 0, width: 120),
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

    final dialogSurface = isDark
        ? const Color(0xFF0A1A1A)
        : AppConstants.lightCardBg;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.5),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryGreen.withValues(alpha: 0.15),
                              Colors.red.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
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
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                cupon.descuento,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppConstants.textLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              cupon.nombre,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppConstants.textLight,
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 14),
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
                                      color: primaryGreen.withValues(
                                        alpha: 0.4,
                                      ),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppConstants.lightSurfaceVariant,
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
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppConstants.textLight,
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
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
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
                                          style: const TextStyle(
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
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
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
                                      child: const Icon(
                                        Icons.content_copy,
                                        color: Colors.green,
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
                              isDark,
                            ),
                            if (cupon.legales.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _buildHtmlSection(
                                'Términos y Condiciones',
                                Icons.gavel,
                                primaryGreen,
                                cupon.legales,
                                textColor.withValues(alpha: 0.8),
                                isDark,
                              ),
                            ],
                            const SizedBox(height: 18),
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
                                          'Reclamado el',
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
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppConstants.textLight,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : AppConstants.lightSurfaceVariant,
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
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primaryGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : AppConstants.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
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
