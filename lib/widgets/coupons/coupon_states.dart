import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class CouponLoadingState extends StatelessWidget {
  const CouponLoadingState({
    super.key,
    required this.primaryGreen,
    required this.textColor,
    this.message = 'Cargando ofertas...',
  });

  final Color primaryGreen;
  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryGreen, strokeWidth: 3),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CouponEmptyState extends StatelessWidget {
  const CouponEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [AppConstants.primaryGreen, Color(0xFF00E5FF)],
              ).createShader(r),
              child: const Icon(
                Icons.discount_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIN CUPONES DISPONIBLES',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'ThaleahFat',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No hay cupones disponibles en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class CouponErrorState extends StatelessWidget {
  const CouponErrorState({
    super.key,
    required this.errorMessage,
    required this.primaryGreen,
    required this.textColor,
    required this.onRetry,
  });

  final String errorMessage;
  final Color primaryGreen;
  final Color textColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: AppConstants.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
