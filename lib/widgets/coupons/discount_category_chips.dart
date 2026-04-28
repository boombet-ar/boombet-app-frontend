import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class DiscountCategoryChips extends StatelessWidget {
  const DiscountCategoryChips({
    super.key,
    required this.categoryNames,
    required this.selectedCategory,
    required this.isDark,
    required this.primaryGreen,
    required this.onCategoryToggle,
  });

  final List<String> categoryNames;
  final String? selectedCategory;
  final bool isDark;
  final Color primaryGreen;
  final void Function(String categoryName) onCategoryToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categoryNames.length,
        itemBuilder: (context, index) {
          final categoryName = categoryNames[index];
          final isSelected = selectedCategory == categoryName;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onCategoryToggle(categoryName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGreen.withValues(alpha: 0.14)
                      : (isDark
                            ? const Color(0xFF1A1A1A)
                            : AppConstants.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primaryGreen.withValues(alpha: 0.55)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.20),
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? primaryGreen
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.65)
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
  }
}
