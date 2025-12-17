import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:boombet_app/services/cupones_service.dart';
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

  final Map<String, Categoria> _categoriaByName = {};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCupones();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCupones({int? pageOverride, bool reset = false}) async {
    if (_isLoading) return;
    final targetPage = pageOverride ?? _apiPage;

    setState(() {
      _isLoading = true;
      if (reset) {
        _cupones.clear();
        _filteredCupones.clear();
        _apiPage = 1;
        _currentPage = 1;
        _categoriaByName.clear();
      }
    });

    try {
      final result = await CuponesService.getCupones(
        page: targetPage,
        pageSize: _pageSize,
        apiKey: ApiConfig.apiKey,
        micrositioId: ApiConfig.micrositioId.toString(),
        codigoAfiliado: ApiConfig.codigoAfiliado,
      );

      final newCupones = result['cupones'] as List<Cupon>? ?? [];

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
    final nextPage = _apiPage + 1;
    _currentPage = nextPage;
    _loadCupones(pageOverride: nextPage);
  }

  void _showHowToEarnPoints(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cupon.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descuento: ${cupon.descuento}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (cupon.descripcionMicrositio.isNotEmpty) ...[
                    const Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(data: cupon.descripcionMicrositio),
                    const SizedBox(height: 16),
                  ],
                  if (cupon.legales.isNotEmpty) ...[
                    const Text(
                      'Términos y Condiciones:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(data: cupon.legales),
                  ],
                ],
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
    final primaryGreen = const Color(0xFF00D084);

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: true,
        showLogo: true,
        showProfileButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título "Descuentos Activos"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Descuentos Activos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

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
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _categoriaByName.length,
                        itemBuilder: (context, index) {
                          final categoryName = _categoriaByName.keys.elementAt(
                            index,
                          );
                          final isSelected = _selectedCategory == categoryName;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(categoryName),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _onCategoryToggle(categoryName),
                            ),
                          );
                        },
                      ),
                    ),

                  // Widget de Puntos - AQUÍ, después de los filtros
                  Container(
                    margin: const EdgeInsets.all(16),
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
                          child: Icon(
                            Icons.star,
                            color: primaryGreen,
                            size: 28,
                          ),
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
    final primaryGreen = const Color(0xFF00D084);

    return GestureDetector(
      onTap: () => _showCuponDetails(cupon),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de fondo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
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
                          color: primaryGreen.withValues(alpha: 0.2),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: primaryGreen,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      height: 150,
                      color: primaryGreen.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(
                          Icons.discount,
                          color: primaryGreen,
                          size: 40,
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
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cupon.descuento,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                        CircleAvatar(
                          backgroundImage: NetworkImage(cupon.logoUrl),
                          radius: 20,
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cupon.empresa.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                cupon.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Categorías
                  if (cupon.categorias.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: cupon.categorias
                          .take(3)
                          .map(
                            (cat) => Chip(
                              label: Text(
                                cat.nombre,
                                style: const TextStyle(fontSize: 10),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
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
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
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
