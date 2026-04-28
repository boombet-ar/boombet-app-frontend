import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:flutter/material.dart';

class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedFilter,
    required this.isDark,
    required this.primaryGreen,
    required this.remoteCategories,
    required this.categoriaByName,
    required this.onCategorySelected,
  });

  final Iterable<String> categories;
  final String selectedFilter;
  final bool isDark;
  final Color primaryGreen;
  final List<Categoria> remoteCategories;
  final Map<String, Categoria> categoriaByName;
  final void Function(String categoryName, String? categoryId) onCategorySelected;

  void _handleTap(String category) {
    if (category == 'Todos') {
      onCategorySelected('Todos', null);
      return;
    }
    final cat = remoteCategories.firstWhere(
      (c) => c.nombre == category,
      orElse: () =>
          categoriaByName[category] ??
          Categoria(id: category, nombre: category),
    );
    final id = cat.id?.toString() ?? cat.finalId?.toString();
    onCategorySelected(category, id);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedFilter == category;
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
                    color: (isSelected ? primaryGreen : Colors.black)
                        .withValues(alpha: 0.12),
                    blurRadius: isSelected ? 10 : 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleTap(category),
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
                              ? (isDark ? Colors.white : AppConstants.textLight)
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
    );
  }
}
