import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/casino_response.dart';
import 'package:boombet_app/views/pages/home/home_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// ─── Constantes visuales ─────────────────────────────────────────────────────
const _scaffoldBg = Color(0xFF0E0E0E);
const _cardBg = Color(0xFF111111);
const _tileBg = Color(0xFF141414);
const _green = AppConstants.primaryGreen;

/// Página que muestra los resultados de la afiliación
class AffiliationResultsPage extends StatelessWidget {
  final AffiliationResult? result;
  final bool preview;

  const AffiliationResultsPage({super.key, this.result, this.preview = false});

  @override
  Widget build(BuildContext context) {
    if (result == null) return _buildErrorView(context);

    final visibleEntries = result!.responses.entries
        .where((e) => e.value.isSuccess || e.value.isWarning)
        .toList();

    final successCount =
        visibleEntries.where((e) => e.value.isSuccess).length;
    final alreadyAffiliatedCount =
        visibleEntries.where((e) => e.value.isWarning).length;
    final totalCount = visibleEntries.length;
    final isWeb = kIsWeb;

    final dni = _resolveCredential(
      result!.playerData,
      keys: const ['dni', 'documento', 'doc'],
      fallback: affiliationDniNotifier.value,
    );
    final username = _resolveCredential(
      result!.playerData,
      keys: const ['user', 'username', 'usuario'],
      fallback: affiliationUsernameNotifier.value,
    );

    return Scaffold(
      backgroundColor: _scaffoldBg,
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
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 900;
                  if (isNarrow) {
                    return _buildNarrowLayout(
                      context,
                      maxWidth: constraints.maxWidth,
                      visibleEntries: visibleEntries,
                      totalCount: totalCount,
                      successCount: successCount,
                      alreadyAffiliatedCount: alreadyAffiliatedCount,
                      dni: dni,
                      username: username,
                    );
                  }
                  return _buildWebLayout(
                    context,
                    visibleEntries: visibleEntries,
                    totalCount: totalCount,
                    successCount: successCount,
                    alreadyAffiliatedCount: alreadyAffiliatedCount,
                    dni: dni,
                    username: username,
                  );
                },
              )
            : _buildMobileLayout(
                context,
                visibleEntries: visibleEntries,
                totalCount: totalCount,
                successCount: successCount,
                alreadyAffiliatedCount: alreadyAffiliatedCount,
                dni: dni,
                username: username,
              ),
      ),
    );
  }

  // ─── Mobile layout ──────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context, {
    required List<MapEntry<String, CasinoResponse>> visibleEntries,
    required int totalCount,
    required int successCount,
    required int alreadyAffiliatedCount,
    required String dni,
    required String username,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header compacto
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _green.withValues(alpha: 0.10),
              border: Border.all(
                color: _green.withValues(alpha: 0.22),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 38,
              color: _green,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¡Proceso Completado!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _green,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Tu cuenta fue creada y el proceso de afiliación finalizó.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          _buildEmailNotice(),
          const SizedBox(height: 14),

          // Resumen + Detalle en un card unificado
          _buildUnifiedSummaryCard(
            visibleEntries: visibleEntries,
            totalCount: totalCount,
            successCount: successCount,
            alreadyAffiliatedCount: alreadyAffiliatedCount,
          ),
          const SizedBox(height: 14),

          _buildCredentialsCard(dni: dni, username: username),
          const SizedBox(height: 10),
          if (AppConstants.affiliationPlayerDataDebugEnabled)
            _buildDebugPlayerDataCard(result!.playerData),
          const SizedBox(height: 18),

          AppButton(
            label: 'Ir a la Aplicación',
            onPressed: preview
                ? () {}
                : () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    ),
            disabled: preview,
            icon: Icons.arrow_forward_rounded,
            borderRadius: AppConstants.borderRadius,
          ),
        ],
      ),
    );
  }

  // ─── Web layout (ancho) ─────────────────────────────────────────────────────

  Widget _buildWebLayout(
    BuildContext context, {
    required List<MapEntry<String, CasinoResponse>> visibleEntries,
    required int totalCount,
    required int successCount,
    required int alreadyAffiliatedCount,
    required String dni,
    required String username,
  }) {
    final size = MediaQuery.sizeOf(context);
    final gridHeight = (size.height - 280).clamp(520.0, 760.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildEmailNotice(),
          const SizedBox(height: 18),
          SizedBox(
            height: gridHeight,
            child: Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _green.withValues(alpha: 0.14)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lado izquierdo — Header
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _green.withValues(alpha: 0.10),
                              border: Border.all(
                                color: _green.withValues(alpha: 0.22),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 52,
                              color: _green,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '¡Proceso Completado!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _green,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu cuenta fue creada y el proceso de afiliación finalizó.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.50),
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: _green.withValues(alpha: 0.10),
                  ),
                  // Lado derecho — Resumen + Detalle
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // Resumen stats
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _tileBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _green.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Resumen de Afiliaciones',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildSummaryRow(
                                  icon: Icons.casino_outlined,
                                  label: 'Total de casinos',
                                  value: totalCount.toString(),
                                  color: _green,
                                ),
                                if (successCount > 0) ...[
                                  const SizedBox(height: 10),
                                  _buildSummaryRow(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: 'Afiliaciones exitosas',
                                    value: successCount.toString(),
                                    color: Colors.greenAccent,
                                  ),
                                ],
                                if (alreadyAffiliatedCount > 0) ...[
                                  const SizedBox(height: 10),
                                  _buildSummaryRow(
                                    icon: Icons.info_outline_rounded,
                                    label: 'Ya estabas afiliado',
                                    value: alreadyAffiliatedCount.toString(),
                                    color: Colors.orange,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Detalle por casino
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _tileBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _green.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detalle por Casino',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: visibleEntries
                                              .map(
                                                (e) => _buildCasinoDetail(
                                                  casinoName:
                                                      _formatCasinoName(e.key),
                                                  response: e.value,
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
          const SizedBox(height: 20),
          _buildCredentialsCard(
            dni: dni,
            username: username,
            compact: true,
          ),
          const SizedBox(height: 12),
          if (AppConstants.affiliationPlayerDataDebugEnabled)
            _buildDebugPlayerDataCard(result!.playerData),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: AppButton(
                label: 'Ir a la Aplicación',
                onPressed: preview
                    ? () {}
                    : () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        ),
                disabled: preview,
                icon: Icons.arrow_forward_rounded,
                borderRadius: AppConstants.borderRadius,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── Web narrow layout ──────────────────────────────────────────────────────

  Widget _buildNarrowLayout(
    BuildContext context, {
    required double maxWidth,
    required List<MapEntry<String, CasinoResponse>> visibleEntries,
    required int totalCount,
    required int successCount,
    required int alreadyAffiliatedCount,
    required String dni,
    required String username,
  }) {
    final s = (maxWidth / 420).clamp(0.78, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14 * s, 16 * s, 14 * s, 24 * s),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmailNotice(),
              SizedBox(height: 14 * s),
              // Header card
              Container(
                padding: EdgeInsets.all(18 * s),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _green.withValues(alpha: 0.14)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16 * s),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green.withValues(alpha: 0.10),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.22),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 36 * s,
                        color: _green,
                      ),
                    ),
                    SizedBox(height: 12 * s),
                    Text(
                      '¡Proceso Completado!',
                      style: TextStyle(
                        fontSize: 20 * s,
                        fontWeight: FontWeight.bold,
                        color: _green,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6 * s),
                    Text(
                      'Tu cuenta fue creada y el proceso de afiliación finalizó.',
                      style: TextStyle(
                        fontSize: 12.5 * s,
                        color: Colors.white.withValues(alpha: 0.50),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12 * s),
              _buildUnifiedSummaryCard(
                visibleEntries: visibleEntries,
                totalCount: totalCount,
                successCount: successCount,
                alreadyAffiliatedCount: alreadyAffiliatedCount,
                scale: s,
              ),
              SizedBox(height: 12 * s),
              _buildCredentialsCard(
                dni: dni,
                username: username,
                compact: true,
                scale: s,
              ),
              SizedBox(height: 10 * s),
              if (AppConstants.affiliationPlayerDataDebugEnabled)
            _buildDebugPlayerDataCard(result!.playerData),
              SizedBox(height: 16 * s),
              AppButton(
                label: 'Ir a la Aplicación',
                onPressed: preview
                    ? () {}
                    : () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        ),
                disabled: preview,
                icon: Icons.arrow_forward_rounded,
                borderRadius: AppConstants.borderRadius,
                height: 48 * s,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Error view ─────────────────────────────────────────────────────────────

  Widget _buildErrorView(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 36,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No pudimos obtener los resultados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tu cuenta fue creada correctamente, pero no pudimos verificar el estado de las afiliaciones.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Continuar',
                onPressed: preview
                    ? () {}
                    : () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                        ),
                disabled: preview,
                icon: Icons.arrow_forward_rounded,
                borderRadius: AppConstants.borderRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Email notice ────────────────────────────────────────────────────────────

  Widget _buildEmailNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mail_outline_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Revisá el correo de cada casino afiliado para activar tu cuenta mediante el enlace de verificación.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Unified summary + casino detail card ────────────────────────────────────

  Widget _buildUnifiedSummaryCard({
    required List<MapEntry<String, CasinoResponse>> visibleEntries,
    required int totalCount,
    required int successCount,
    required int alreadyAffiliatedCount,
    double scale = 1.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row compacto
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _buildStatChip(
                  icon: Icons.casino_outlined,
                  label: 'Total',
                  value: totalCount.toString(),
                  color: _green,
                ),
                if (successCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Exitosas',
                    value: successCount.toString(),
                    color: Colors.greenAccent,
                  ),
                ],
                if (alreadyAffiliatedCount > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.info_outline_rounded,
                    label: 'Ya afiliado',
                    value: alreadyAffiliatedCount.toString(),
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: _green.withValues(alpha: 0.10),
          ),
          // Detalle por casino
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text(
              'Detalle por Casino',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...visibleEntries.map(
            (e) => _buildCasinoDetail(
              casinoName: _formatCasinoName(e.key),
              response: e.value,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary row (solo para web layout ancho) ────────────────────────────────

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double iconSize = 20,
    double labelFontSize = 14,
    double valueFontSize = 18,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.white.withValues(alpha: 0.80),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Credentials card ────────────────────────────────────────────────────────

  Widget _buildCredentialsCard({
    required String dni,
    required String username,
    bool compact = false,
    double scale = 1.0,
  }) {
    Widget credRow({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Container(
        margin: EdgeInsets.only(bottom: 8 * scale),
        padding: EdgeInsets.symmetric(
          horizontal: 11 * scale,
          vertical: 9 * scale,
        ),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _green.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: _green, size: 14 * scale),
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * scale,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: value.isEmpty ? 'No disponible' : value,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all((compact ? 14 : 16) * scale),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.22)),
                ),
                child: const Icon(Icons.vpn_key_outlined, color: _green, size: 15),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tus credenciales BoomBet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Usá las mismas credenciales para ingresar a cada casino.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12 * scale),
          credRow(icon: Icons.badge_outlined, label: 'DNI', value: dni),
          credRow(
            icon: Icons.person_outline_rounded,
            label: 'Usuario',
            value: username,
          ),
          Container(
            margin: EdgeInsets.only(bottom: 8 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 11 * scale,
              vertical: 9 * scale,
            ),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.lock_outline_rounded, color: _green, size: 14 * scale),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    'Tu contraseña es la misma que usaste para afiliarte a Boombet',
                    style: TextStyle(
                      fontSize: 13 * scale,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Casino detail row ───────────────────────────────────────────────────────

  Widget _buildCasinoDetail({
    required String casinoName,
    required CasinoResponse response,
  }) {
    final color = response.isSuccess ? Colors.greenAccent : Colors.orange;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Text(response.statusIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  casinoName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  response.statusMessage,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: color.withValues(alpha: 0.85),
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

  // ─── Debug playerData card ───────────────────────────────────────────────────

  Widget _buildDebugPlayerDataCard(Map<String, dynamic> playerData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A00),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: Colors.orange, size: 14),
              const SizedBox(width: 6),
              const Text(
                'DEBUG — playerData del backend',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (playerData.isEmpty)
            Text(
              '(vacío)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...playerData.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, height: 1.3),
                    children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: e.value?.toString() ?? 'null',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _resolveCredential(
    Map<String, dynamic> playerData, {
    required List<String> keys,
    required String fallback,
  }) {
    for (final key in keys) {
      final value = playerData[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback.trim();
  }

  String _formatCasinoName(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return 'Casino';

    final words = cleaned
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();

    return words.isEmpty ? cleaned : words.first;
  }
}
