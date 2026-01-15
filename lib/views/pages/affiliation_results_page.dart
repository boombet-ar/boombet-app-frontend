import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/casino_response.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    final visibleEntries = result!.responses.entries
        .where((entry) => entry.value.isSuccess || entry.value.isWarning)
        .toList();

    final successCount = visibleEntries
        .where((entry) => entry.value.isSuccess)
        .length;
    final alreadyAffiliatedCount = visibleEntries
        .where((entry) => entry.value.isWarning)
        .length;
    final totalCount = visibleEntries.length;
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: false,
        showProfileButton: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: isWeb ? 980 : 800,
        constrainOnWeb: isWeb,
        child: isWeb
            ? _buildWebLayout(
                context,
                isDark: isDark,
                primaryGreen: primaryGreen,
                textColor: textColor,
                visibleEntries: visibleEntries,
                totalCount: totalCount,
                successCount: successCount,
                alreadyAffiliatedCount: alreadyAffiliatedCount,
              )
            : SingleChildScrollView(
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

                    _buildEmailNotice(textColor),

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
                          ...visibleEntries.map(
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
                          foregroundColor: isDark
                              ? Colors.black
                              : AppConstants.textLight,
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
                                color: isDark
                                    ? Colors.black
                                    : AppConstants.textLight,
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

  Widget _buildEmailNotice(Color textColor) {
    return Container(
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
    );
  }

  Widget _buildWebLayout(
    BuildContext context, {
    required bool isDark,
    required Color primaryGreen,
    required Color textColor,
    required List<MapEntry<String, CasinoResponse>> visibleEntries,
    required int totalCount,
    required int successCount,
    required int alreadyAffiliatedCount,
  }) {
    final size = MediaQuery.sizeOf(context);
    final gridHeight = (size.height - 280).clamp(520.0, 760.0);

    final cardBg = isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg;
    final borderColor = isDark
        ? const Color(0xFF2A2A2A)
        : AppConstants.lightDivider;
    final dividerColor = borderColor.withValues(alpha: 0.9);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildEmailNotice(textColor),
          const SizedBox(height: 18),
          SizedBox(
            height: gridHeight,
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryGreen.withValues(alpha: 0.1),
                              border: Border.all(color: primaryGreen, width: 3),
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 86,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            '¡Proceso Completado!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tu cuenta ha sido creada y el proceso de afiliación ha finalizado',
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor.withValues(alpha: 0.7),
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, color: dividerColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.95),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Resumen de Afiliaciones',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSummaryRow(
                                    icon: Icons.casino_outlined,
                                    label: 'Total de casinos',
                                    value: totalCount.toString(),
                                    color: primaryGreen,
                                    textColor: textColor,
                                  ),
                                  const SizedBox(height: 14),
                                  if (successCount > 0) ...[
                                    _buildSummaryRow(
                                      icon: Icons.check_circle,
                                      label: 'Afiliaciones exitosas',
                                      value: successCount.toString(),
                                      color: Colors.green,
                                      textColor: textColor,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  if (alreadyAffiliatedCount > 0) ...[
                                    _buildSummaryRow(
                                      icon: Icons.info,
                                      label: 'Ya estabas afiliado',
                                      value: alreadyAffiliatedCount.toString(),
                                      color: Colors.orange,
                                      textColor: textColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.95),
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
                                  const SizedBox(height: 14),
                                  Expanded(
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: visibleEntries
                                              .map(
                                                (entry) => _buildCasinoDetail(
                                                  casinoName: _formatCasinoName(
                                                    entry.key,
                                                  ),
                                                  response: entry.value,
                                                  isDark: isDark,
                                                  textColor: textColor,
                                                ),
                                              )
                                              .toList(),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                height: 56,
                width: double.infinity,
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
                    foregroundColor: isDark
                        ? Colors.black
                        : AppConstants.textLight,
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
                          color: isDark ? Colors.black : AppConstants.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
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
    } else {
      statusColor = Colors.orange;
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCasinoName(String key) {
    // Convertir camelCase a título y quedarse solo con la primera palabra
    final cleaned = key.trim();
    if (cleaned.isEmpty) return 'Casino';

    final words = cleaned
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .toList();

    if (words.isEmpty) return cleaned;

    return words.first;
  }
}
