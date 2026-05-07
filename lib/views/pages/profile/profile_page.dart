import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:go_router/go_router.dart';
import 'package:boombet_app/views/pages/other/unaffiliate_result_page.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/views/pages/profile/widgets/username_badge.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'widgets/avatar_image.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  PlayerData? _playerData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUnaffiliating = false;

  Widget _buildActionGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color accentColor,
  }) {
    final enabled = onPressed != null;
    const labelColor = Colors.black;
    final effectiveBg = enabled
        ? accentColor
        : accentColor.withValues(alpha: 0.45);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              color: enabled ? null : effectiveBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.38),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: enabled
                        ? labelColor
                        : labelColor.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: enabled
                          ? labelColor
                          : labelColor.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  bool _isFetching = false;

  Future<void> _loadUserData() async {
    if (_isFetching) return; // 🔥 evita doble llamada
    _isFetching = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await PlayerService().getCurrentUserSnapshot();

      final mergedPlayer = snapshot.avatarUrl.isNotEmpty
          ? snapshot.playerData.copyWith(avatarUrl: snapshot.avatarUrl)
          : snapshot.playerData;

      setState(() {
        _playerData = mergedPlayer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error obteniendo datos del jugador: $e";
      });
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _refreshProfile() async {
    HttpClient.clearCache(urlPattern: '/users/me');
    _isFetching = false;
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: bgColor,
      body: isWeb
          ? (_isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorView(textColor, primaryGreen)
                : _buildWebProfileContent(textColor, isDark, primaryGreen))
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: ResponsiveWrapper(
                      maxWidth: 900,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                          ? _buildErrorView(textColor, primaryGreen)
                          : RefreshIndicator(
                              onRefresh: _refreshProfile,
                              child: _buildProfileContent(
                                textColor,
                                isDark,
                                primaryGreen,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ----------------- ERROR VIEW -----------------

  Widget _buildErrorView(Color textColor, Color primaryGreen) {
    final isTokenError = _errorMessage?.contains("Invalid token") ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (isTokenError)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Necesitas iniciar sesión nuevamente',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isTokenError
                  ? () async {
                      await AuthService().logout();
                      if (mounted) {
                        context.go('/');
                      }
                    }
                  : _loadUserData,
              icon: Icon(isTokenError ? Icons.login : Icons.refresh),
              label: Text(isTokenError ? 'Ir a Login' : 'Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: AppConstants.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- MAIN CONTENT -----------------

  Widget _buildProfileContent(
    Color textColor,
    bool isDark,
    Color primaryGreen,
  ) {
    return Column(
      children: [
        _buildHeader(textColor, isDark, primaryGreen),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _buildInfoCard(isDark, textColor, primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildWebProfileContent(
    Color textColor,
    bool isDark,
    Color primaryGreen,
  ) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowWeb = constraints.maxWidth < 900;

        if (isNarrowWeb) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        _buildHeader(textColor, isDark, primaryGreen),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildInfoCard(
                            isDark,
                            textColor,
                            primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1600),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryGreen.withValues(alpha: 0.25),
                                  primaryGreen.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : AppConstants.borderLight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: AppConstants.mediumDelay,
                                  curve: Curves.easeOutBack,
                                  width: 210,
                                  height: 210,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryGreen,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryGreen.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 22,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                    color: isDark
                                        ? const Color(0xFF202020)
                                        : theme.colorScheme.surface,
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(
                                      primaryGreen,
                                      isDark,
                                      size: 210,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  "${_playerData?.nombre ?? ''} ${_playerData?.apellido ?? ''}"
                                      .trim(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildVerifiedBadge(
                                  primaryGreen,
                                  _playerData?.username ?? '',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 900),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 20),
                                    _buildInfoCard(
                                      isDark,
                                      textColor,
                                      primaryGreen,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------- HEADER (ANIMATED) -----------------

  Widget _buildHeader(Color textColor, bool isDark, Color primaryGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0D0D0D), const Color(0xFF131313)]
              : [
                  primaryGreen.withValues(alpha: 0.08),
                  primaryGreen.withValues(alpha: 0.02),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: primaryGreen.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppConstants.mediumDelay,
            curve: Curves.easeOutBack,
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 4),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 6,
                ),
              ],
              color: isDark
                  ? const Color(0xFF202020)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: ClipOval(
              child: _buildAvatarImage(primaryGreen, isDark, size: 110),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${_playerData?.nombre ?? ''} ${_playerData?.apellido ?? ''}"
                .trim(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerifiedBadge(primaryGreen, _playerData?.username ?? ''),
        ],
      ),
    );
  }

  //AVATAR

  Widget _buildAvatarImage(
    Color primaryGreen,
    bool isDark, {
    double size = 130,
  }) {
    return AvatarImage(
      imageUrl: _playerData?.avatarUrl,
      primaryColor: primaryGreen,
      size: size,
    );
  }

  //USERNAME BADGE

  Widget _buildVerifiedBadge(Color primaryGreen, String username) {
    if (username.isEmpty) return const SizedBox.shrink();
    return UsernameBadge(primaryGreen: primaryGreen, username: username);
  }

  // ----------------- INFO SECTION -----------------

  Widget _buildInfoCard(bool isDark, Color textColor, Color primaryGreen) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernInfoRow(
            icon: Icons.email_outlined,
            label: "Email",
            value: _playerData?.correoElectronico ?? "",
            isDark: isDark,
            textColor: textColor,
            primaryGreen: primaryGreen,
          ),
          _buildModernInfoRow(
            icon: Icons.phone_outlined,
            label: "Teléfono",
            value: _playerData?.telefono ?? "",
            isDark: isDark,
            textColor: textColor,
            primaryGreen: primaryGreen,
          ),
          _buildModernInfoRow(
            icon: Icons.wc_outlined,
            label: "Género",
            value: _playerData?.sexo ?? "",
            isDark: isDark,
            textColor: textColor,
            primaryGreen: primaryGreen,
          ),
          _buildModernInfoRow(
            icon: Icons.cake_outlined,
            label: "Fecha de Nacimiento",
            value: _playerData?.fechaNacimiento ?? "",
            isDark: isDark,
            textColor: textColor,
            primaryGreen: primaryGreen,
          ),

          const SizedBox(height: 16),

          // 🚀 BOTÓN PARA EDITAR PERFIL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: _buildActionGradientButton(
              label: 'Editar Información',
              icon: Icons.edit_note_rounded,
              onPressed: () async {
                final updated = await context.push<PlayerData>(
                  HomePageKeys.profileEdit,
                  extra: _playerData,
                );
                if (updated != null && mounted) {
                  setState(() => _playerData = updated);
                }
              },
              accentColor: primaryGreen,
            ),
          ),

          // 🚀 BOTÓN PARA DESAFILIARSE
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: _buildActionGradientButton(
              label: 'Desafiliarse de Boombet',
              icon: Icons.person_off_rounded,
              onPressed: () =>
                  _showUnaffiliateDialog(primaryGreen, textColor, isDark),
              accentColor: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  // --------------- UNAFFILIATE DIALOG ---------------

  void _showUnaffiliateDialog(
    Color primaryGreen,
    Color textColor,
    bool isDark,
  ) {
    const dialogRadius = 20.0;
    const redDark = Color(0xFFE53935);
    const redDeep = Color(0xFFB71C1C);
    const bgColor = Color(0xFF111111);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxDialogWidth = kIsWeb ? 480.0 : 400.0;
        final effectiveWidth = (screenWidth * (kIsWeb ? 0.48 : 0.90))
            .clamp(280.0, maxDialogWidth)
            .toDouble();

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 20 : 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogRadius),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            child: SizedBox(
              width: effectiveWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(dialogRadius),
                  border: Border.all(
                    color: redDark.withValues(alpha: 0.22),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: redDark.withValues(alpha: 0.18),
                      blurRadius: 32,
                      spreadRadius: 0,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(dialogRadius),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header compacto ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                        decoration: BoxDecoration(
                          color: redDark.withValues(alpha: 0.07),
                          border: Border(
                            bottom: BorderSide(
                              color: redDark.withValues(alpha: 0.14),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: redDark.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: redDark.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: redDark.withValues(alpha: 0.22),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_off_rounded,
                                size: 21,
                                color: redDark,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Desafiliarse de Boombet',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Acción permanente e irreversible',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.38,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Items de advertencia ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          children: [
                            _buildCompactUnaffiliateItem(
                              icon: Icons.delete_forever_rounded,
                              title: 'Tu cuenta será eliminada',
                              subtitle:
                                  'Toda tu información y datos de juego serán borrados permanentemente.',
                              textColor: textColor,
                              redDark: redDark,
                            ),
                            const SizedBox(height: 10),
                            _buildCompactUnaffiliateItem(
                              icon: Icons.block_rounded,
                              title: 'Perdés acceso a Boombet',
                              subtitle:
                                  'No podrás ingresar ni disfrutar de sus beneficios.',
                              textColor: textColor,
                              redDark: redDark,
                            ),
                            const SizedBox(height: 10),
                            _buildCompactUnaffiliateItem(
                              icon: Icons.casino_outlined,
                              title: 'Casinos asociados',
                              subtitle:
                                  'Permanecerás afiliado según tus acuerdos individuales.',
                              textColor: textColor,
                              redDark: redDark,
                            ),
                          ],
                        ),
                      ),

                      // ── Advertencia ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: redDark.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: redDark.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 15,
                                color: redDark.withValues(alpha: 0.80),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '¿Estás seguro? Esta acción no se puede deshacer.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade300,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Botones (lado a lado) ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        child: Row(
                          children: [
                            // Cancelar
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF1A1A1A),
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.38,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => Navigator.pop(context),
                                        splashColor: primaryGreen.withValues(
                                          alpha: 0.08,
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.arrow_back_rounded,
                                                size: 16,
                                                color: primaryGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryGreen,
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Confirmar
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _isUnaffiliating
                                          ? [
                                              redDark.withValues(alpha: 0.45),
                                              redDeep.withValues(alpha: 0.45),
                                            ]
                                          : const [redDark, redDeep],
                                    ),
                                    boxShadow: _isUnaffiliating
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: redDark.withValues(
                                                alpha: 0.38,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isUnaffiliating
                                            ? null
                                            : () => _handleUnaffiliateConfirm(
                                                context,
                                              ),
                                        splashColor: Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                        child: Center(
                                          child: _isUnaffiliating
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.person_off_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Confirmar',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactUnaffiliateItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color redDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: redDark.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: redDark.withValues(alpha: 0.24),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 16, color: redDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: textColor.withValues(alpha: 0.48),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleUnaffiliateConfirm(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    if (_isUnaffiliating) return;

    setState(() => _isUnaffiliating = true);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Solicitud procesada. Desafiliación en progreso...',
          style: TextStyle(color: AppConstants.textLight),
        ),
        backgroundColor: Colors.orange.shade700,
        duration: AppConstants.longSnackbarDuration,
      ),
    );

    try {
      await PlayerService().unaffiliateCurrentUser();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UnaffiliateResultPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No pudimos procesar la desafiliación: $e',
            style: const TextStyle(color: AppConstants.textLight),
          ),
          backgroundColor: Colors.red.shade700,
          duration: AppConstants.longSnackbarDuration,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUnaffiliating = false);
      }
    }
  }

  // ----------------- MODERN INFO ROW -----------------

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color primaryGreen,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: primaryGreen, size: 21),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "—" : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
