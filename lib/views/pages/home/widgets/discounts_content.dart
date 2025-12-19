import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/loading_badge.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/home/widgets/section_headers.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/search_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscountsContent extends StatefulWidget {
  const DiscountsContent({super.key, this.onCuponClaimed, this.claimedKey});

  final VoidCallback? onCuponClaimed;
  final GlobalKey<ClaimedCouponsContentState>? claimedKey;

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
  List<Categoria> _remoteCategories = [];
  bool _showClaimed = false;

  List<Cupon> _cupones = [];
  List<Cupon> _filteredCupones = [];
  List<String> _claimedCuponIds = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = false;
  final Map<String, Categoria> _categoriaByName = {};
  bool _affiliationCompleted = false;
  bool _affiliationLoading = false;
  String? _affiliationError;
  String? _affiliationMessage;
  static const String _affiliationAcceptedKey = 'affiliation_accepted_bonda';
  static const String _cachedCuponesKey = 'cached_cupones_bonda';
  static const String _cachedCuponesTsKey = 'cached_cupones_ts_bonda';
  static const String _cachedPageKey = 'cached_cupones_page';
  static const String _cachedHasMoreKey = 'cached_cupones_has_more';
  bool _cacheApplied = false;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTtl = Duration(hours: 6);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _listScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCuponCache();
      await _loadAffiliationAcceptance();
    });
  }

  Future<void> _loadCuponCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cachedCuponesKey);
      if (cached == null || cached.isEmpty) return;
      final cachedTs = prefs.getString(_cachedCuponesTsKey);
      if (cachedTs != null) {
        _cacheTimestamp = DateTime.tryParse(cachedTs);
      }
      if (_cacheTimestamp != null &&
          DateTime.now().difference(_cacheTimestamp!) > _cacheTtl) {
        return;
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
        _cupones = cachedCupones;
        _updateCategorias();
        _applyFilter();
        _cacheApplied = true;
        _apiPage = prefs.getInt(_cachedPageKey) ?? _apiPage;
        _currentPage = _apiPage;
        _hasMore = prefs.getBool(_cachedHasMoreKey) ?? _hasMore;
        _pageCache[_apiPage] = cachedCupones;
      });
    } catch (e) {
      debugPrint('WARN: No se pudo cargar cache de cupones: $e');
    }
  }

  Future<void> _persistCuponCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _cupones.map((c) => c.toJson()).toList();
      await prefs.setString(_cachedCuponesKey, jsonEncode(data));
      await prefs.setString(
        _cachedCuponesTsKey,
        DateTime.now().toIso8601String(),
      );
      await prefs.setInt(_cachedPageKey, _apiPage);
      await prefs.setBool(_cachedHasMoreKey, _hasMore);
    } catch (e) {
      debugPrint('WARN: No se pudo guardar cache de cupones: $e');
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await CuponesService.getCategorias(
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
      );
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

  void _jumpPages(int delta) {
    if (_isLoading) return;
    final target = (_currentPage + delta).clamp(1, 1 << 30);
    if (target == _currentPage) return;
    _scrollListToTop();
    unawaited(_loadCupones(pageOverride: target));
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
    if (_isLoading) return;
    if (!_affiliationCompleted) return;

    final normalizedSearch = (searchQuery ?? _searchQuery).trim();
    final normalizedCategoryId = ignoreCategory
        ? null
        : categoryId ??
              _selectedCategoryId ??
              _categoriaByName[_selectedFilter]?.id?.toString();
    final normalizedCategoryName = ignoreCategory
        ? null
        : categoryName ?? (_selectedFilter == 'Todos' ? null : _selectedFilter);
    final targetPage = (pageOverride ?? _currentPage).clamp(1, 1 << 30);

    setState(() {
      _isLoading = true;
      if (reset) {
        _cupones.clear();
        _filteredCupones.clear();
        _apiPage = 1;
        _currentPage = 1;
        _pageCache.clear();
        _hasMore = false;
        _hasError = false;
      }
    });

    if (!reset && !forceRefresh && _pageCache.containsKey(targetPage)) {
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
      final result =
          await CuponesService.getCupones(
            page: targetPage,
            pageSize: _pageSize,
            apiKey: ApiConfig.apiKey,
            micrositioId: ApiConfig.micrositioId.toString(),
            codigoAfiliado: ApiConfig.codigoAfiliado,
            searchQuery: normalizedSearch.isEmpty ? null : normalizedSearch,
            categoryId: normalizedCategoryId,
            categoryName: normalizedCategoryName,
            orderBy: 'relevant',
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
          _cupones = newCupones;
          _apiPage = targetPage;
          _currentPage = targetPage;
          final hasMoreResponse = result['has_more'] as bool? ?? false;
          _hasMore = hasMoreResponse;
          _hasError = false;
          _pageCache[targetPage] = List<Cupon>.from(newCupones);
          _updateCategorias();
          _applyFilter();
          unawaited(_persistCuponCache());
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
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

  void _resetDiscountsState({required bool triggerLoad}) {
    setState(() {
      _selectedFilter = 'Todos';
      _selectedCategoryId = null;
      _searchQuery = '';
      _searchController.clear();
      _pageCache.clear();
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
        ? (_categoriaByName[selectedName]?.finalId?.toString() ??
              _categoriaByName[selectedName]?.id?.toString())
        : null;
    final query = _searchQuery.trim().toLowerCase();

    _filteredCupones = _cupones.where((c) {
      if (_claimedCuponIds.contains(c.id)) return false;

      if (selectedId != null &&
          !c.categorias.any((cat) {
            final catId = cat.id?.toString();
            final catFinalId = cat.finalId?.toString();
            return catId == selectedId || catFinalId == selectedId;
          })) {
        return false;
      }

      if (query.isEmpty) return true;

      final nameMatch = c.nombre.toLowerCase().contains(query);
      final companyMatch = c.empresa.nombre.toLowerCase().contains(query);
      final categoryMatch = c.categorias.any(
        (cat) => (cat.nombre).toLowerCase().contains(query),
      );

      return nameMatch || companyMatch || categoryMatch;
    }).toList();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    unawaited(_loadCupones(pageOverride: 1, reset: true, searchQuery: query));
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
    final encoded = Uri.encodeComponent(safe);
    return 'https://images.weserv.nl/?url=$encoded';
  }

  Future<void> _startAffiliation() async {
    if (_affiliationLoading) return;

    setState(() {
      _affiliationLoading = true;
      _affiliationError = null;
      _affiliationMessage = null;
    });

    try {
      final result =
          await CuponesService.afiliarAfiliado(
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
        await _loadCategorias();
        await _loadClaimedCuponIds();
        if (!_cacheApplied) {
          await _loadCupones(reset: true);
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
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
                          const Icon(
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
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          width: double.infinity,
                          color: primaryGreen.withValues(alpha: 0.1),
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
                                      _imageUrlForPlatform(cupon.logoUrl),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                          const SizedBox(height: 10),
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
                          Row(
                            children: [
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

                                      setState(() {
                                        _claimedCuponIds.add(cupon.id);
                                        _applyFilter();
                                      });
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
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final pagedFilteredCupones = _filteredCupones;
    final canGoPrevious = _currentPage > 1;
    final canGoNext = _hasMore || pagedFilteredCupones.length == _pageSize;
    final canJumpBack5 = _currentPage > 5;
    final canJumpBack10 = _currentPage > 10;
    final canJumpForward = canGoNext;

    final categories = <String>{'Todos'};
    categories.addAll(_remoteCategories.map((c) => c.nombre));

    if (!_affiliationCompleted) {
      return RefreshIndicator(
        onRefresh: () async {
          _apiPage = 1;
          _currentPage = 1;
          await _startAffiliation();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [_buildAffiliationCard(primaryGreen, textColor, isDark)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCupones(
          pageOverride: _currentPage,
          reset: false,
          categoryId: null,
          categoryName: null,
          ignoreCategory: true,
          forceRefresh: true,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showClaimed)
            buildSectionHeaderWithSwitch(
              'Mis Cupones Reclamados',
              'Ver cupones que ya reclamaste',
              Icons.check_circle,
              primaryGreen,
              isDark,
              isShowingClaimed: true,
              onSwitchPressed: () {
                _showClaimed = false;
                _resetDiscountsState(triggerLoad: true);
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
                _resetDiscountsState(triggerLoad: false);
              },
            ),
          if (_showClaimed)
            Expanded(
              child: ClaimedCouponsContent(
                key: widget.claimedKey,
                hideHeader: true,
              ),
            )
          else
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBarWidget(
                    controller: _searchController,
                    onSearch: _onSearch,
                    onChanged: _onSearch,
                    placeholder:
                        'Buscar por nombre de cupón, empresa o categoría',
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
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
                                      color: primaryGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1.5,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
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
                                      : (selectedCat.finalId?.toString() ??
                                            selectedCat.id?.toString());
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
                ],
              ),
            ),
          if (!_showClaimed)
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
                              _currentPage = 1;
                              _loadCupones(
                                pageOverride: 1,
                                reset: true,
                                categoryId: _selectedCategoryId,
                                categoryName: _selectedFilter == 'Todos'
                                    ? null
                                    : _selectedFilter,
                                ignoreCategory: true,
                                forceRefresh: true,
                              );
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
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              if (kIsWeb)
                                GridView.builder(
                                  controller: _listScrollController,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    24,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 520,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: 0.78,
                                      ),
                                  itemCount: pagedFilteredCupones.length,
                                  itemBuilder: (context, index) {
                                    final cupon = pagedFilteredCupones[index];
                                    return _buildCuponCard(
                                      context,
                                      cupon,
                                      primaryGreen,
                                      textColor,
                                      isDark,
                                    );
                                  },
                                )
                              else
                                ListView.builder(
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
                                    return Padding(
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
                                          ),
                                        ),
                                      ),
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
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: PaginationBar(
                              currentPage: _currentPage,
                              canGoPrevious: canGoPrevious,
                              canGoNext: canGoNext,
                              canJumpBack5: canJumpBack5,
                              canJumpBack10: canJumpBack10,
                              canJumpForward: canJumpForward,
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
                              onJumpBack5: () => _jumpPages(-5),
                              onJumpBack10: () => _jumpPages(-10),
                              onJumpForward5: () => _jumpPages(5),
                              onJumpForward10: () => _jumpPages(10),
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
