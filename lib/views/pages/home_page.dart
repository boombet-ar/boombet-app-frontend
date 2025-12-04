import 'dart:async';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
import 'package:boombet_app/views/pages/forum_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:boombet_app/widgets/search_bar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

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
                ),
                ClaimedCouponsContent(key: _claimedKey),
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
  int _currentCarouselPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // Auto-scroll del carrusel cada 30 segundos
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _carouselController.hasClients) {
        final nextPage = (_currentCarouselPage + 1) % 5;
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
    _autoScrollTimer?.cancel();
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    debugPrint('Buscando: $query');
    // Aquí puedes agregar la lógica de búsqueda
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  onSearch: _handleSearch,
                  placeholder: '¿Qué estás buscando?',
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'HOME',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 2,
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
        // Carrusel de promociones
        RepaintBoundary(
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _carouselController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCarouselPage = index;
                      });
                    },
                    itemCount: 5,
                    itemBuilder: (context, index) {
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              // Contenido del placeholder
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getPromoIcon(index),
                                      size: 48,
                                      color: primaryGreen,
                                    ),
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
                              // Badge de número
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
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
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Indicadores de página
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentCarouselPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentCarouselPage == index
                            ? primaryGreen
                            : primaryGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
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

  const DiscountsContent({super.key, this.onCuponClaimed});

  @override
  State<DiscountsContent> createState() => _DiscountsContentState();
}

class _DiscountsContentState extends State<DiscountsContent> {
  String _selectedFilter = 'Todos';
  late PageController _pageController;
  int _currentPage = 1;
  final int _pageSize = 10;

  List<Cupon> _cupones = [];
  List<Cupon> _filteredCupones = [];
  List<String> _claimedCuponIds = []; // IDs de cupones ya reclamados
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMore = false;
  Map<String, List<String>> _categoriasByName = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCupones();
    _loadClaimedCuponIds();
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

    setState(() => _isLoading = true);
    try {
      final result = await CuponesService.getCupones(
        page: _currentPage,
        pageSize: _pageSize,
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
        codigoAfiliado: ApiConfig.codigoAfiliado,
      );

      final newCupones = result['cupones'] as List<Cupon>? ?? [];

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
    try {
      final result = await CuponesService.getCuponesRecibidos(
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
        codigoAfiliado: ApiConfig.codigoAfiliado,
      );
      final claimedCupones = result['cupones'] as List<Cupon>? ?? [];
      setState(() {
        _claimedCuponIds = claimedCupones.map((c) => c.id).toList();
        _applyFilter();
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final categories = <String>{'Todos'};
    categories.addAll(_categoriasByName.keys);

    return Column(
      children: [
        // Header con filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, color: primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Descuentos Activos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(category, primaryGreen, isDark),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Widget de Puntos
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withValues(alpha: 0.9),
                      primaryGreen.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(Icons.star, color: primaryGreen, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tus Puntos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '0 pts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de descuentos
        Expanded(
          child: _isLoading && _cupones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryGreen),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando cupones...',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                )
              : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                  padding: const EdgeInsets.all(16),
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
                    return _buildCuponCard(
                      context,
                      cupon,
                      primaryGreen,
                      textColor,
                      isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, Color primaryGreen, bool isDark) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilter();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryGreen
                : primaryGreen.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 14,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showCuponDetails(context, cupon, primaryGreen, textColor);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen y badge de descuento
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  // Imagen de fondo
                  if (cupon.fotoUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        cupon.fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: primaryGreen.withValues(alpha: 0.2),
                            child: Center(
                              child: Icon(
                                Icons.local_offer,
                                size: 60,
                                color: primaryGreen.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        },
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
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.4),
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
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        cupon.descuento,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Logo de empresa
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: cupon.logoUrl.isNotEmpty
                            ? Image.network(
                                cupon.logoUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
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
                                          fontSize: 12,
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
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Text(
                                    cupon.empresa.nombre
                                        .substring(
                                          0,
                                          (cupon.empresa.nombre.length).clamp(
                                            0,
                                            2,
                                          ),
                                        )
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
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
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cupon.nombre,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cupon.empresa.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cleanHtml(cupon.descripcionBreve),
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  if (cupon.categorias.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: cupon.categorias.take(2).map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            cat.nombre,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Válido hasta: ${cupon.fechaVencimiento.split(' ').first}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Mostrar loading
                        LoadingOverlay.show(
                          context,
                          message: 'Reclamando cupón...',
                        );

                        try {
                          await CuponesService.claimCupon(cuponId: cupon.id);

                          // Ocultar loading
                          LoadingOverlay.hide(context);

                          // Mostrar success
                          ScaffoldMessenger.of(context).showSnackBar(
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

                          // Recargar ambas listas (Descuentos y Reclamados)
                          widget.onCuponClaimed?.call();
                        } catch (e) {
                          // Ocultar loading
                          LoadingOverlay.hide(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Reclamar Cupón'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    );
  }

  void _showCuponDetails(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de descuento grande
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            cupon.descuento,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        cupon.nombre,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.business, color: primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cupon.empresa.nombre,
                              style: TextStyle(
                                fontSize: 18,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: cupon.categorias.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              cat.nombre,
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cómo usar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Html(
                        data: cupon.descripcionMicrositio,
                        style: {
                          'body': Style(
                            color: textColor,
                            fontSize: FontSize(14),
                            lineHeight: LineHeight.number(1.6),
                            margin: Margins.all(0),
                            padding: HtmlPaddings.all(0),
                          ),
                          'p': Style(
                            margin: Margins.symmetric(vertical: 8),
                            color: textColor,
                          ),
                          'a': Style(
                            color: primaryGreen,
                            textDecoration: TextDecoration.underline,
                          ),
                          'b': Style(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          'u': Style(textDecoration: TextDecoration.underline),
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Html(
                        data: cupon.legales,
                        style: {
                          'body': Style(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: FontSize(14),
                            lineHeight: LineHeight.number(1.5),
                            margin: Margins.all(0),
                            padding: HtmlPaddings.all(0),
                          ),
                          'p': Style(margin: Margins.symmetric(vertical: 8)),
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: textColor.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Válido hasta: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            cupon.fechaVencimiento,
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }
}

/// Página de Cupones Reclamados
class ClaimedCouponsContent extends StatefulWidget {
  const ClaimedCouponsContent({super.key});

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
    _loadClaimedCupones();
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
      final result = await CuponesService.getCuponesRecibidos(
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
        codigoAfiliado: ApiConfig.codigoAfiliado,
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

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Cupones Reclamados',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de cupones reclamados
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryGreen),
                      const SizedBox(height: 16),
                      Text(
                        'Cargando cupones reclamados...',
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                )
              : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadClaimedCupones,
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
              : _claimedCupones.isEmpty
              ? Center(
                  child: Text(
                    'No hay cupones reclamados aún',
                    style: TextStyle(color: textColor),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _claimedCupones.length,
                  itemBuilder: (context, index) {
                    final cupon = _claimedCupones[index];
                    return _buildClaimedCuponCard(
                      context,
                      cupon,
                      primaryGreen,
                      textColor,
                      isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildClaimedCuponCard(
    BuildContext context,
    Cupon cupon,
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _showClaimedCuponDetails(context, cupon, primaryGreen, textColor);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con imagen y badge de estado
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  // Imagen de fondo
                  if (cupon.fotoUrl.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        cupon.fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: primaryGreen.withValues(alpha: 0.2),
                            child: Center(
                              child: Icon(
                                Icons.local_offer,
                                size: 60,
                                color: primaryGreen.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      color: primaryGreen.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(
                          Icons.local_offer,
                          size: 60,
                          color: primaryGreen.withValues(alpha: 0.5),
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
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        cupon.descuento,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Badge de "Reclamado"
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Reclamado',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body del card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo y nombre de empresa
                  Row(
                    children: [
                      if (cupon.empresa.logo.isNotEmpty)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: Image.network(
                            cupon.empresa.logo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.store,
                                  size: 24,
                                  color: primaryGreen,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 4),
                            Text(
                              cupon.empresa.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Código del cupón
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cupon.id,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: primaryGreen.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Código copiado: ${cupon.id}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.content_copy,
                            color: primaryGreen,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Vencimiento
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: textColor.withValues(alpha: 0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Válido hasta: ${cupon.fechaVencimiento}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: Image.network(
                      cupon.empresa.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.store, color: primaryGreen);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cupon.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cupon.empresa.nombre,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cupon.descuento,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Estado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cupón Reclamado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usá este código en ${cupon.empresa.nombre}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Código
              Text(
                'Código de Descuento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryGreen),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cupon.id,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Código copiado: ${cupon.id}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Icon(
                        Icons.content_copy,
                        color: primaryGreen,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instrucciones
              Text(
                'Instrucciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Html(
                  data: cupon.instrucciones.isEmpty
                      ? '<p>No hay instrucciones especiales</p>'
                      : cupon.instrucciones,
                  style: {
                    'body': Style(
                      color: textColor,
                      fontSize: FontSize(14),
                      lineHeight: LineHeight.number(1.5),
                      margin: Margins.all(0),
                      padding: HtmlPaddings.all(0),
                    ),
                    'p': Style(margin: Margins.symmetric(vertical: 8)),
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Vencimiento
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: textColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Válido hasta: ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      cupon.fechaVencimiento.isNotEmpty
                          ? cupon.fechaVencimiento.split(' ').first
                          : 'Fecha no disponible',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
