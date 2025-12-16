import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/casino_response.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

/// Página que muestra los resultados de la afiliación
class AffiliationResultsPage extends StatelessWidget {
  final AffiliationResult? result;

  const AffiliationResultsPage({super.key, this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final bgColor = theme.scaffoldBackgroundColor;

    // Si no hay resultado, mostrar error genérico
    if (result == null) {
      return _buildErrorView(context, theme);
    }

    final statusCount = result!.statusCount;
    final successCount = statusCount['success'] ?? 0;
    final alreadyAffiliatedCount = statusCount['alreadyAffiliated'] ?? 0;
    final errorCount = statusCount['error'] ?? 0;
    final totalCount = statusCount['total'] ?? 0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: false,
        showProfileButton: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icono de éxito
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryGreen.withValues(alpha: 0.1),
                  border: Border.all(color: primaryGreen, width: 3),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: primaryGreen,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                '¡Proceso Completado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtítulo
              Text(
                'Tu cuenta ha sido creada y el proceso de afiliación ha finalizado',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Aviso de verificación por correo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mail_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Para activar completamente cada una de tus cuentas, debés ingresar al correo electrónico que te ha enviado cada casino al que fuiste afiliado. Dentro de ese email, encontrarás un enlace de verificación o confirmación necesario para finalizar el registro.',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Resumen de afiliaciones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : AppConstants.lightCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppConstants.lightDivider,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Resumen de Afiliaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total de casinos
                    _buildSummaryRow(
                      icon: Icons.casino_outlined,
                      label: 'Total de casinos',
                      value: totalCount.toString(),
                      color: primaryGreen,
                      textColor: textColor,
                    ),

                    const SizedBox(height: 16),

                    // Afiliaciones exitosas
                    if (successCount > 0) ...[
                      _buildSummaryRow(
                        icon: Icons.check_circle,
                        label: 'Afiliaciones exitosas',
                        value: successCount.toString(),
                        color: Colors.green,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Ya afiliado
                    if (alreadyAffiliatedCount > 0) ...[
                      _buildSummaryRow(
                        icon: Icons.info,
                        label: 'Ya estabas afiliado',
                        value: alreadyAffiliatedCount.toString(),
                        color: Colors.orange,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Errores
                    if (errorCount > 0)
                      _buildSummaryRow(
                        icon: Icons.error,
                        label: 'Errores',
                        value: errorCount.toString(),
                        color: Colors.red,
                        textColor: textColor,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Detalle de cada casino
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : AppConstants.lightCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : AppConstants.lightDivider,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle por Casino',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...result!.responses.entries.map(
                      (entry) => _buildCasinoDetail(
                        casinoName: _formatCasinoName(entry.key),
                        response: entry.value,
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botón para continuar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Ir a la Aplicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'No pudimos obtener los resultados',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Tu cuenta fue creada correctamente, pero no pudimos verificar el estado de las afiliaciones.',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCasinoDetail({
    required String casinoName,
    required CasinoResponse response,
    required bool isDark,
    required Color textColor,
  }) {
    Color statusColor;
    if (response.isSuccess) {
      statusColor = Colors.green;
    } else if (response.isWarning) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Text(response.statusIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  casinoName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  response.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (response.error != null && response.isError) ...[
                  const SizedBox(height: 4),
                  Text(
                    response.error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCasinoName(String key) {
    // Convertir camelCase a título
    // Ej: "sportsbetPba" → "Sportsbet Pba"
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
