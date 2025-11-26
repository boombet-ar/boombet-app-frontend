import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';

class PointsCategoryPage extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;

  const PointsCategoryPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  State<PointsCategoryPage> createState() => _PointsCategoryPageState();
}

class _PointsCategoryPageState extends State<PointsCategoryPage> {
  final bool _isLoading = false;
  final Map<String, bool> _selectedSubcategories = {'Todas': true};
  bool _isFilterExpanded = false;

  // Subcategorías de ejemplo (puedes cambiarlas según la categoría)
  final List<String> _subcategories = [
    'Todas',
    'Subcategoría 1',
    'Subcategoría 2',
    'Subcategoría 3',
    'Subcategoría 4',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar todas las subcategorías como seleccionadas excepto "Todas"
    for (var subcategory in _subcategories) {
      if (subcategory != 'Todas') {
        _selectedSubcategories[subcategory] = true;
      }
    }
  }

  void _toggleSubcategory(String subcategory) {
    setState(() {
      if (subcategory == 'Todas') {
        // Si se selecciona "Todas", activar todas las demás
        final allSelected = !_selectedSubcategories['Todas']!;
        for (var key in _selectedSubcategories.keys) {
          _selectedSubcategories[key] = allSelected;
        }
      } else {
        // Toggle individual
        _selectedSubcategories[subcategory] =
            !_selectedSubcategories[subcategory]!;

        // Si todas las subcategorías individuales están seleccionadas, activar "Todas"
        bool allOthersSelected = _subcategories
            .where((s) => s != 'Todas')
            .every((s) => _selectedSubcategories[s] == true);
        _selectedSubcategories['Todas'] = allOthersSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header de categoría
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryGreen, width: 2),
                            ),
                            child: Icon(
                              widget.categoryIcon,
                              size: 64,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.categoryName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filtro de subcategorías
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isFilterExpanded = !_isFilterExpanded;
                              });
                            },
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: primaryGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Filtrar por subcategoría',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_subcategories.where((s) => s != "Todas" && _selectedSubcategories[s] == true).length} de ${_subcategories.length - 1} activas',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _isFilterExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: textColor.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isFilterExpanded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      children: _subcategories.map((
                                        subcategory,
                                      ) {
                                        return CheckboxListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            subcategory,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: subcategory == 'Todas'
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          value:
                                              _selectedSubcategories[subcategory],
                                          activeColor: primaryGreen,
                                          onChanged: (bool? value) {
                                            _toggleSubcategory(subcategory);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sección de puntos disponibles
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryGreen.withOpacity(0.2),
                              primaryGreen.withOpacity(0.05),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.stars, size: 48, color: primaryGreen),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tus Puntos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '0 pts',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título de comercios
                    Text(
                      'Comercios Afiliados',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lista de comercios (placeholder)
                    _buildMerchantPlaceholder(
                      context,
                      'Comercio Ejemplo 1',
                      '10% de descuento',
                      isDark,
                      primaryGreen,
                      textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMerchantPlaceholder(
                      context,
                      'Comercio Ejemplo 2',
                      'Acumula 5 puntos por cada \$100',
                      isDark,
                      primaryGreen,
                      textColor,
                    ),
                    const SizedBox(height: 12),
                    _buildMerchantPlaceholder(
                      context,
                      'Comercio Ejemplo 3',
                      '2x1 en productos seleccionados',
                      isDark,
                      primaryGreen,
                      textColor,
                    ),
                    const SizedBox(height: 24),

                    // Mensaje informativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Próximamente encontrarás más comercios y ofertas exclusivas en esta categoría.',
                              style: TextStyle(color: textColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMerchantPlaceholder(
    BuildContext context,
    String name,
    String offer,
    bool isDark,
    Color primaryGreen,
    Color textColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comercio: $name'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.store, color: primaryGreen, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_offer, size: 16, color: primaryGreen),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            offer,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: textColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
