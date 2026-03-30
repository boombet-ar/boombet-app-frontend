import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/category_order.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({super.key});

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  late PageController _pageController;
  List<Cupon> _cupones = [];
  List<Cupon> _filteredCupones = [];
  bool _isLoading = false;
  bool _hasMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _apiPage = 1;
  bool _isPrefetching = false;
  static const int _pageSize = 15;
  List<Cupon> _categoryFilteredUniverse = [];
  String? _categoryUniverseKey;

  final Map<String, Categoria> _categoriaByName = {};
  String? _selectedCategory;

  bool _authGuardTriggered = false;
  bool _authCheckInProgress = false;
  DateTime? _lastAuthCheckAt;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Resetear para no mostrar resultados previos si el widget queda vivo.
    _cupones = [];
    _filteredCupones = [];
    _loadCupones(reset: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recheckAuthAndMaybeTriggerPopup();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _hasAnyAuthToken() async {
    final access = await TokenService.getToken();
    final refresh = await TokenService.getRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }

  void _triggerSessionExpiredOnce() {
    if (_authGuardTriggered) return;
    _authGuardTriggered = true;
    HttpClient.onSessionExpired?.call();
  }

  Future<void> _recheckAuthAndMaybeTriggerPopup() async {
    if (_authCheckInProgress) return;

    final now = DateTime.now();
    final last = _lastAuthCheckAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }

    _authCheckInProgress = true;
    _lastAuthCheckAt = now;
    try {
      final access = await TokenService.getToken();
      final refresh = await TokenService.getRefreshToken();

      final accessExpired =
          access == null ||
          access.isEmpty ||
          TokenService.isJwtExpiredSafe(access);

      if (!accessExpired) return;

      final hasRefresh = refresh != null && refresh.isNotEmpty;
      final refreshExpired =
          hasRefresh &&
          TokenService.isLikelyJwt(refresh!) &&
          TokenService.isJwtExpiredSafe(refresh);

      if (!hasRefresh || refreshExpired) {
        if (!mounted) return;
        setState(() {
          _cupones.clear();
          _filteredCupones.clear();
          _hasMore = false;
          _hasError = false;
          _errorMessage = '';
          _isLoading = false;
          _categoriaByName.clear();
          _selectedCategory = null;
          _apiPage = 1;
          _currentPage = 1;
        });
        _triggerSessionExpiredOnce();
      }
    } finally {
      _authCheckInProgress = false;
    }
  }

  Future<void> _loadCupones({int? pageOverride, bool reset = false}) async {
    if (_isLoading) return;

    // Si no hay ningún token (access/refresh), no permitir ver cupones.
    final hasAuth = await _hasAnyAuthToken();
    if (!hasAuth) {
      if (!mounted) return;
      setState(() {
        _cupones.clear();
        _filteredCupones.clear();
        _hasMore = false;
        _hasError = false;
        _errorMessage = '';
        _isLoading = false;
        _categoriaByName.clear();
        _selectedCategory = null;
        _apiPage = 1;
        _currentPage = 1;
      });
      _triggerSessionExpiredOnce();
      return;
    }

    final targetPage = pageOverride ?? _apiPage;
    final selectedName = _selectedCategory;
    final selectedId = selectedName != null
        ? _categoriaByName[selectedName]?.id?.toString()
        : null;
    final hasCategoryFilter =
        selectedName != null && selectedName.trim().isNotEmpty;
    final universeKey = '${selectedId ?? ''}|${selectedName ?? ''}';

    setState(() {
      _isLoading = true;
      if (reset) {
        _cupones.clear();
        _filteredCupones.clear();
        _categoryFilteredUniverse.clear();
        _categoryUniverseKey = null;
        _apiPage = 1;
        _currentPage = 1;
        _categoriaByName.clear();
      }
    });

    try {
      if (hasCategoryFilter) {
        if (_categoryUniverseKey != universeKey ||
            _categoryFilteredUniverse.isEmpty ||
            reset) {
          final allFetched = <Cupon>[];
          final seenIds = <String>{};
          var backendPage = 1;
          var backendHasMore = true;
          var lastBackendPage = 0;
          var safetyIterations = 0;

          while (backendHasMore && safetyIterations < 200) {
            safetyIterations++;
            final result = await CuponesService.getCupones(
              page: backendPage,
              pageSize: _pageSize,
            );

            final batch = result['cupones'] as List<Cupon>? ?? [];
            for (final cupon in batch) {
              if (seenIds.add(cupon.id)) {
                allFetched.add(cupon);
              }
            }

            backendHasMore =
                (result['has_more'] as bool? ?? false) ||
                batch.length >= _pageSize;
            lastBackendPage = backendPage;
            backendPage++;

            if (batch.isEmpty) {
              backendHasMore = false;
            }
          }

          _cupones = allFetched;
          _updateCategorias();
          _applyFilter();
          _categoryFilteredUniverse = List<Cupon>.from(_filteredCupones);
          _categoryUniverseKey = universeKey;
          _apiPage = lastBackendPage;
        }

        final maxVisible = targetPage * _pageSize;
        final visible = _categoryFilteredUniverse.take(maxVisible).toList();

        setState(() {
          _currentPage = targetPage;
          _filteredCupones = visible;
          _hasMore = visible.length < _categoryFilteredUniverse.length;
          _hasError = false;
          _isLoading = false;
        });
      } else {
        _categoryFilteredUniverse.clear();
        _categoryUniverseKey = null;

        final result = await CuponesService.getCupones(
          page: targetPage,
          pageSize: _pageSize,
        );

        final newCupones = result['cupones'] as List<Cupon>? ?? [];

        if (targetPage > 1 && newCupones.isEmpty) {
          setState(() {
            _apiPage = targetPage - 1;
            _currentPage = targetPage - 1;
            _hasMore = false;
            _hasError = false;
            _isLoading = false;
            _applyFilter();
          });
          return;
        }

        setState(() {
          if (reset || targetPage == 1) {
            _cupones = newCupones;
            _apiPage = 1;
            _currentPage = 1;
          } else {
            _cupones.addAll(newCupones);
            _apiPage = targetPage;
          }

          _hasMore =
              (result['has_more'] as bool? ?? false) ||
              newCupones.length >= _pageSize;
          _hasError = false;
          _isLoading = false;

          _updateCategorias();
          _applyFilter();
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'Error: ${e.toString()}\n\nIntenta revisar la consola de logs para más detalles.';
        _isLoading = false;
      });
    }
  }

  void _updateCategorias() {
    for (var cupon in _cupones) {
      for (var categoria in cupon.categorias) {
        if (categoria.nombre.isNotEmpty) {
          _categoriaByName.putIfAbsent(categoria.nombre, () => categoria);
        }
      }
    }
  }

  void _applyFilter() {
    final selectedName = _selectedCategory;
    final selectedId = selectedName != null
        ? _categoriaByName[selectedName]?.id?.toString()
        : null;

    _filteredCupones = _cupones.where((c) {
      if (selectedId == null) return true;
      return c.categorias.any((cat) => cat.id?.toString() == selectedId);
    }).toList();
  }

  void _onCategoryToggle(String categoryName) {
    setState(() {
      _selectedCategory = (_selectedCategory == categoryName)
          ? null
          : categoryName;
      _currentPage = 1;
      _apiPage = 1;
    });
    _loadCupones(pageOverride: 1, reset: true);
  }

  void _loadMore() {
    if (_isLoading) return;
    final nextPage = _currentPage + 1;
    _currentPage = nextPage;
    _loadCupones(pageOverride: nextPage);
  }

  void _showHowToEarnPoints(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? theme.dialogBackgroundColor
            : AppConstants.lightCardBg,
        title: const Text(
          '¿Cómo ganar puntos?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Text(
                'Gana puntos de las siguientes formas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              _PointRow(
                icon: Icons.shopping_bag,
                title: 'Compras',
                description: 'Obtén puntos por cada compra realizada.',
              ),
              _PointRow(
                icon: Icons.credit_card,
                title: 'Transacciones',
                description: 'Gana puntos con pagos y transferencias.',
              ),
              _PointRow(
                icon: Icons.card_giftcard,
                title: 'Promociones',
                description: 'Participa en promociones especiales.',
              ),
              _PointRow(
                icon: Icons.people,
                title: 'Referidos',
                description: 'Invita amigos y gana puntos bonus.',
              ),
              SizedBox(height: 16),
              Text(
                '💡 Tip: Cuantos más puntos tengas, más descuentos podrás disfrutar.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showCuponDetails(Cupon cupon) {
    final primaryGreen = const Color(0xFF00D084);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogSurface = isDark
        ? const Color(0xFF0A1A1A)
        : AppConstants.lightCardBg;
    final dialogOnSurface = isDark ? Colors.white : AppConstants.textLight;
    final htmlBodyColor = isDark
        ? Colors.white70
        : AppConstants.textLight.withValues(alpha: 0.75);
    final contentSurface = isDark
        ? Colors.white.withOpacity(0.05)
        : AppConstants.lightSurfaceVariant;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: isDark ? 0.8 : 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: dialogSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryGreen.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: primaryGreen.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con imagen y close button
              Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGreen.withOpacity(0.3),
                          primaryGreen.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_offer_rounded,
                        size: 80,
                        color: primaryGreen.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.6)
                            : AppConstants.lightSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: dialogOnSurface),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),

              // Content scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        cupon.nombre,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: dialogOnSurface,
                          fontFamily: 'ThaleahFat',
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Descuento badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryGreen,
                              primaryGreen.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.percent,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cupon.descuento,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'ThaleahFat',
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (cupon.descripcionMicrositio.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          'Instrucciones',
                          Icons.info_outline,
                          primaryGreen,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: contentSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Html(
                            data: cupon.descripcionMicrositio,
                            style: {
                              "body": Style(
                                color: htmlBodyColor,
                                fontSize: FontSize(14),
                                margin: Margins.zero,
                              ),
                            },
                          ),
                        ),
                      ],

                      if (cupon.legales.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSection(
                          'Términos y Condiciones',
                          Icons.description_outlined,
                          primaryGreen,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: contentSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Html(
                            data: cupon.legales,
                            style: {
                              "body": Style(
                                color: htmlBodyColor.withValues(alpha: 0.85),
                                fontSize: FontSize(12),
                                margin: Margins.zero,
                              ),
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: primaryGreen.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ThaleahFat',
                              letterSpacing: 1,
                            ),
                          ),
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
    );
  }

  Widget _buildSection(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'ThaleahFat',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryGreen = const Color(0xFF00D084);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg : AppConstants.lightBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Contenido principal
            if (_isLoading && _cupones.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: primaryGreen),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando cupones...',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
              )
            else if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _currentPage = 1;
                          _cupones.clear();
                          _loadCupones();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_cupones.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.discount,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No hay cupones disponibles',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Filtros de categorías
                  if (_categoriaByName.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final sortedCategoryNames =
                            CategoryOrder.sortCategoryNames(
                              _categoriaByName.keys,
                            );

                        return SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: sortedCategoryNames.length,
                            itemBuilder: (context, index) {
                              final categoryName = sortedCategoryNames[index];
                              final isSelected =
                                  _selectedCategory == categoryName;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () => _onCategoryToggle(categoryName),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryGreen.withValues(alpha: 0.14)
                                          : (isDark
                                                ? const Color(0xFF1A1A1A)
                                                : AppConstants
                                                      .lightSurfaceVariant),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryGreen.withValues(alpha: 0.55)
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : Colors.black12),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: primaryGreen.withValues(
                                                  alpha: 0.20,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? primaryGreen
                                            : (isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.65,
                                                    )
                                                  : AppConstants.textLight),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                  // Widget de Puntos - AQUÍ, después de los filtros
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111111)
                          : AppConstants.lightCardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryGreen.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.40),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withValues(alpha: 0.22),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: primaryGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tus Puntos',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.50)
                                    : AppConstants.textLight.withValues(
                                        alpha: 0.60,
                                      ),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '0 pts',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: primaryGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Lista de cupones
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredCupones.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredCupones.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: _loadMore,
                            child: const Text('Cargar más'),
                          ),
                        );
                      }
                      final cupon = _filteredCupones[index];
                      return _buildCuponCard(cupon);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: const NavbarWidget(),
    );
  }

  Widget _buildCuponCard(Cupon cupon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF00D084);

    return GestureDetector(
      onTap: () => _showCuponDetails(cupon),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Neon left strip
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryGreen,
                        primaryGreen.withValues(alpha: 0.45),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.45),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Card content
                Expanded(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF111111)
                        : AppConstants.lightCardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen de fondo
                        Stack(
                          children: [
                            if (cupon.fotoUrl.isNotEmpty)
                              Image.network(
                                cupon.fotoUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    color: const Color(0xFF1A1A1A),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: primaryGreen.withValues(
                                          alpha: 0.4,
                                        ),
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                height: 150,
                                color: const Color(0xFF1A1A1A),
                                child: Center(
                                  child: Icon(
                                    Icons.discount,
                                    color: primaryGreen.withValues(alpha: 0.4),
                                    size: 40,
                                  ),
                                ),
                              ),
                            // Badge de descuento — neon green
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
                                  borderRadius: BorderRadius.circular(20),
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
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Contenido de la tarjeta
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo y nombre empresa
                              if (cupon.logoUrl.isNotEmpty)
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: primaryGreen.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryGreen.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(cupon.logoUrl),
                                        radius: 20,
                                        onBackgroundImageError: (_, __) {},
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cupon.empresa.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.50,
                                                    )
                                                  : AppConstants.textLight
                                                        .withValues(alpha: 0.55),
                                            ),
                                          ),
                                          Text(
                                            cupon.nombre,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  cupon.nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Categorías — custom neon chips
                              if (cupon.categorias.isNotEmpty)
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: cupon.categorias
                                      .take(3)
                                      .map(
                                        (cat) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryGreen.withValues(
                                              alpha: 0.10,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: primaryGreen.withValues(
                                                alpha: 0.22,
                                              ),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            cat.nombre,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: primaryGreen,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              const SizedBox(height: 8),
                              // Descripción breve
                              if (cupon.descripcionBreve.isNotEmpty)
                                Text(
                                  cupon.descripcionBreve,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.50),
                                  ),
                                ),
                            ],
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
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PointRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF00D084)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
