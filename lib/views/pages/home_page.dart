import 'dart:async';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/forum_page.dart';
import 'package:boombet_app/views/pages/points_category_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
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
          body: Center(
            child: Container(
              constraints: kIsWeb ? const BoxConstraints(maxWidth: 1200) : null,
              child: IndexedStack(
                index: selectedPage,
                children: const [
                  HomeContent(),
                  PointsContent(),
                  DiscountsContent(),
                  RafflesPage(),
                  ForumPage(),
                ],
              ),
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

class PointsContent extends StatelessWidget {
  const PointsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    final categories = [
      {'name': 'Compras', 'icon': Icons.shopping_cart},
      {'name': 'Gastronomía', 'icon': Icons.restaurant},
      {'name': 'Indumentaria, calzado y moda', 'icon': Icons.shopping_bag},
      {'name': 'Educación', 'icon': Icons.school},
      {'name': 'Servicios', 'icon': Icons.home_repair_service},
      {'name': 'Turismo', 'icon': Icons.flight},
      {'name': 'Gimnasio y Deportes', 'icon': Icons.fitness_center},
      {'name': 'Belleza y Salud', 'icon': Icons.spa},
      {'name': 'Entretenimiento', 'icon': Icons.theater_comedy},
      {'name': 'Motos', 'icon': Icons.two_wheeler},
      {'name': 'Autos', 'icon': Icons.directions_car},
      {'name': 'Cines', 'icon': Icons.local_movies},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Seleccione la categoría:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kIsWeb ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: primaryGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PointsCategoryPage(
                          categoryName: category['name'] as String,
                          categoryIcon: category['icon'] as IconData,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 48,
                        color: primaryGreen,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          category['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class DiscountsContent extends StatefulWidget {
  const DiscountsContent({super.key});

  @override
  State<DiscountsContent> createState() => _DiscountsContentState();
}

class _DiscountsContentState extends State<DiscountsContent> {
  String _selectedFilter = 'Todos';

  // Mock data de descuentos
  final List<Map<String, dynamic>> _discounts = [
    {
      'id': 1,
      'title': '50% OFF en Pizzas',
      'merchant': 'Pizza Express',
      'category': 'Gastronomía',
      'discount': '50%',
      'description':
          'Llevá 2 pizzas familiares y pagá solo 1. Válido de lunes a jueves.',
      'validUntil': '31/12/2025',
      'terms':
          'No acumulable con otras promociones. Válido para consumo en el local.',
      'image': Icons.local_pizza,
    },
    {
      'id': 2,
      'title': '30% OFF en Ropa Deportiva',
      'merchant': 'SportLife',
      'category': 'Indumentaria',
      'discount': '30%',
      'description':
          'Descuento en toda la línea de ropa deportiva. Incluye zapatillas.',
      'validUntil': '15/01/2026',
      'terms': 'Válido en compras mayores a \$50.000',
      'image': Icons.sports,
    },
    {
      'id': 3,
      'title': '2x1 en Entradas de Cine',
      'merchant': 'CineMax',
      'category': 'Entretenimiento',
      'discount': '2x1',
      'description': 'Comprá 1 entrada y llevá 2. Válido de lunes a miércoles.',
      'validUntil': '28/12/2025',
      'terms': 'No válido para estrenos. Sujeto a disponibilidad.',
      'image': Icons.movie,
    },
    {
      'id': 4,
      'title': '40% OFF en Mecánica',
      'merchant': 'AutoService Pro',
      'category': 'Autos',
      'discount': '40%',
      'description':
          'Service completo con descuento. Incluye cambio de aceite y filtros.',
      'validUntil': '31/01/2026',
      'terms': 'Válido para autos hasta 2020',
      'image': Icons.build,
    },
    {
      'id': 5,
      'title': '25% OFF en Spa',
      'merchant': 'Relax Beauty',
      'category': 'Belleza',
      'discount': '25%',
      'description':
          'Masajes, tratamientos faciales y corporales con descuento.',
      'validUntil': '20/12/2025',
      'terms': 'Requiere reserva previa. Cupos limitados.',
      'image': Icons.spa,
    },
    {
      'id': 6,
      'title': '15% OFF en Supermercado',
      'merchant': 'MercadoMax',
      'category': 'Compras',
      'discount': '15%',
      'description':
          'Descuento en compras mayores a \$30.000. Todos los productos.',
      'validUntil': '31/12/2025',
      'terms': 'No incluye productos en oferta',
      'image': Icons.shopping_cart,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Obtener categorías únicas
    final categories = <String>{'Todos'};
    for (var discount in _discounts) {
      categories.add(discount['category'] as String);
    }

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
            ],
          ),
        ),

        // Lista de descuentos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _getFilteredDiscounts().length,
            itemBuilder: (context, index) {
              final discount = _getFilteredDiscounts()[index];
              return _buildDiscountCard(
                context,
                discount,
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

  List<Map<String, dynamic>> _getFilteredDiscounts() {
    if (_selectedFilter == 'Todos') {
      return _discounts;
    }
    return _discounts.where((d) => d['category'] == _selectedFilter).toList();
  }

  Widget _buildFilterChip(String label, Color primaryGreen, bool isDark) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : primaryGreen.withValues(alpha: 0.5),
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

  Widget _buildDiscountCard(
    BuildContext context,
    Map<String, dynamic> discount,
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
          _showDiscountDetails(context, discount, primaryGreen, textColor);
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryGreen.withValues(alpha: 0.7),
                    primaryGreen.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      discount['image'],
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
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
                        discount['discount'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        discount['category'],
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                    discount['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 16,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        discount['merchant'],
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    discount['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                        'Válido hasta: ${discount['validUntil']}',
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
                      onPressed: () {
                        _showDiscountDetails(
                          context,
                          discount,
                          primaryGreen,
                          textColor,
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Ver Detalles'),
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

  void _showDiscountDetails(
    BuildContext context,
    Map<String, dynamic> discount,
    Color primaryGreen,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                            discount['discount'],
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
                        discount['title'],
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.store, color: primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            discount['merchant'],
                            style: TextStyle(
                              fontSize: 18,
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
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
                          discount['category'],
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discount['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.5,
                        ),
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
                      const SizedBox(height: 8),
                      Text(
                        discount['terms'],
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
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
                            discount['validUntil'],
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '¡Descuento activado! Mostrá este código en ${discount['merchant']}',
                                ),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'OK',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Activar Descuento'),
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
