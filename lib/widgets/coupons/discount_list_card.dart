import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/cupon_model.dart';
import 'package:flutter/material.dart';

class DiscountListCard extends StatelessWidget {
  const DiscountListCard({
    super.key,
    required this.cupon,
    required this.primaryGreen,
    required this.isDark,
    required this.textColor,
    required this.onTap,
  });

  final Cupon cupon;
  final Color primaryGreen;
  final bool isDark;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                                        color: primaryGreen.withValues(alpha: 0.4),
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
                                          color: primaryGreen.withValues(alpha: 0.35),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryGreen.withValues(alpha: 0.18),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: NetworkImage(cupon.logoUrl),
                                        radius: 20,
                                        onBackgroundImageError: (_, __) {},
                                      ),
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
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.50)
                                                  : AppConstants.textLight.withValues(alpha: 0.55),
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
                              // Categorías
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
                                            color: primaryGreen.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: primaryGreen.withValues(alpha: 0.22),
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
                                    color: textColor.withValues(alpha: 0.50),
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
