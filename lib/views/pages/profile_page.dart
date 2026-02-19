import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/edit_profile_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/unaffiliate_result_page.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    required List<Color> gradientColors,
    Color? glowColor,
  }) {
    final enabled = onPressed != null;
    final glow = (glowColor ?? gradientColors.first).withValues(
      alpha: enabled ? 0.35 : 0.15,
    );

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? gradientColors
                : gradientColors
                      .map((c) => c.withValues(alpha: 0.45))
                      .toList(growable: false),
          ),
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: 18,
              spreadRadius: 0.5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              splashColor: Colors.white.withValues(alpha: 0.10),
              highlightColor: Colors.white.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: Colors.white.withValues(alpha: 0.98),
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
    // Limpiar el estado y recargar
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
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: isWeb
            ? (_isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorView(textColor, primaryGreen)
                  : _buildWebProfileContent(textColor, isDark, primaryGreen))
            : ResponsiveWrapper(
                maxWidth: 900,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorView(textColor, primaryGreen)
                    : _buildProfileContent(textColor, isDark, primaryGreen),
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
                        Navigator.of(context).pushAndRemoveUntil(
                          FadeRoute(page: const LoginPage()),
                          (route) => false,
                        );
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
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(textColor, isDark, primaryGreen),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildSectionTitle(primaryGreen, textColor),
                const SizedBox(height: 20),
                _buildInfoCard(isDark, textColor, primaryGreen),
              ],
            ),
          ),
        ],
      ),
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
                          child: Column(
                            children: [
                              _buildSectionTitle(primaryGreen, textColor),
                              const SizedBox(height: 16),
                              _buildInfoCard(isDark, textColor, primaryGreen),
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
                                    _buildSectionTitle(primaryGreen, textColor),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withValues(alpha: 0.25),
            primaryGreen.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppConstants.mediumDelay,
            curve: Curves.easeOutBack,
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen, width: 4),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              color: isDark
                  ? const Color(0xFF202020)
                  : Theme.of(context).colorScheme.surface,
            ),
            child: ClipOval(child: _buildAvatarImage(primaryGreen, isDark)),
          ),
          const SizedBox(height: 20),
          Text(
            "${_playerData?.nombre ?? ''} ${_playerData?.apellido ?? ''}"
                .trim(),
            style: TextStyle(
              fontSize: 27,
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

  Widget _buildAvatarImage(
    Color primaryGreen,
    bool isDark, {
    double size = 130,
  }) {
    final url = _playerData?.avatarUrl ?? '';

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        key: ValueKey(
          url,
        ), // fuerza rebuild cuando cambia la URL (cache-buster)
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => Icon(
          Icons.person,
          size: (size * 0.55).clamp(48.0, 96.0).toDouble(),
          color: primaryGreen,
        ),
      );
    }

    return Icon(
      Icons.person,
      size: (size * 0.55).clamp(48.0, 96.0).toDouble(),
      color: primaryGreen,
    );
  }

  Widget _buildVerifiedBadge(Color primaryGreen, String username) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 16, color: primaryGreen),
          const SizedBox(width: 6),
          Text(
            username,
            style: TextStyle(
              color: primaryGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- INFO SECTION -----------------

  Widget _buildSectionTitle(Color primaryGreen, Color textColor) {
    return Row(
      children: [
        Icon(Icons.person_outline_rounded, color: primaryGreen, size: 28),
        const SizedBox(width: 12),
        Text(
          "Información Personal",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, Color textColor, Color primaryGreen) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppConstants.borderLight,
          width: 1,
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

          const SizedBox(height: 10),

          // 🚀 BOTÓN PARA EDITAR PERFIL
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildActionGradientButton(
              label: 'Editar Información',
              icon: Icons.edit_note_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(player: _playerData!),
                  ),
                ).then((updatedPlayer) {
                  if (updatedPlayer != null && updatedPlayer is PlayerData) {
                    setState(() {
                      _playerData = updatedPlayer;
                    });
                  }
                });
              },
              gradientColors: [
                primaryGreen.withValues(alpha: 0.98),
                primaryGreen.withValues(alpha: 0.78),
              ],
              glowColor: primaryGreen,
            ),
          ),

          // 🚀 BOTÓN PARA DESAFILIARSE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildActionGradientButton(
              label: 'Desafiliarse de Boombet',
              icon: Icons.person_off_rounded,
              onPressed: () =>
                  _showUnaffiliateDialog(primaryGreen, textColor, isDark),
              gradientColors: [
                const Color(0xFFE53935),
                const Color(0xFFB71C1C),
              ],
              glowColor: Colors.red,
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
    const dialogRadius = 24.0;
    const redDark = Color(0xFFE53935);
    const redDeep = Color(0xFFB71C1C);
    final bgColor = isDark ? const Color(0xFF141414) : AppConstants.lightCardBg;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6);
    final cardBorder = isDark ? Colors.white10 : AppConstants.borderLight;
    final subtitleColor = textColor.withValues(alpha: 0.6);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final maxDialogWidth = kIsWeb ? 580.0 : 480.0;
        final effectiveWidth = (screenWidth * (kIsWeb ? 0.55 : 0.92))
            .clamp(300.0, maxDialogWidth)
            .toDouble();

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 20 : 16,
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
                    color: redDark.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: redDark.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.40),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(dialogRadius),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header con gradiente rojo ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF3A0A0A), Color(0xFF2A0808)],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Icono con glow
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [redDark, redDeep],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: redDark.withValues(alpha: 0.45),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_off_rounded,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Desafiliarse de Boombet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Esta acción es permanente e irreversible',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Contenido ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Esto es importante:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textColor.withValues(alpha: 0.5),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildUnaffiliateInfoCard(
                                icon: Icons.delete_forever_rounded,
                                title: 'Tu cuenta será eliminada',
                                subtitle:
                                    'Toda tu información personal y datos de juego serán borrados permanentemente.',
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 10),
                              _buildUnaffiliateInfoCard(
                                icon: Icons.block_rounded,
                                title: 'Perdés acceso a Boombet',
                                subtitle:
                                    'No podrás ingresar a la plataforma ni disfrutar de sus beneficios.',
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                              const SizedBox(height: 10),
                              _buildUnaffiliateInfoCard(
                                icon: Icons.casino_outlined,
                                title: 'Casinos asociados',
                                subtitle:
                                    'Permanecerás afiliado a los casinos asociados según tus acuerdos individuales.',
                                isDark: isDark,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),

                              const SizedBox(height: 18),

                              // Advertencia final
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: redDark.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: redDark.withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: redDark.withValues(alpha: 0.85),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '¿Estás completamente seguro? Esta acción no se puede deshacer.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.red.shade300
                                              : Colors.red.shade700,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Botones ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          child: Column(
                            children: [
                              // Botón cancelar (outline estilo app)
                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: cardBg,
                                    border: Border.all(
                                      color: primaryGreen.withValues(
                                        alpha: 0.35,
                                      ),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => Navigator.pop(context),
                                        splashColor: primaryGreen.withValues(
                                          alpha: 0.08,
                                        ),
                                        highlightColor: primaryGreen.withValues(
                                          alpha: 0.04,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.arrow_back_rounded,
                                                size: 18,
                                                color: primaryGreen,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'No, continuar usando la app',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryGreen,
                                                  letterSpacing: 0.2,
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

                              const SizedBox(height: 10),

                              // Botón confirmar (gradiente rojo)
                              SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
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
                                              blurRadius: 18,
                                              spreadRadius: 0.5,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: _isUnaffiliating ? 0.06 : 0.14,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
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
                                        highlightColor: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          child: _isUnaffiliating
                                              ? const Center(
                                                  child: SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.person_off_rounded,
                                                      size: 18,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Sí, desafiliarme',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.2,
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
                            ],
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

  Widget _buildUnaffiliatePoint(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: TextStyle(fontSize: 13, color: textColor)),
    );
  }

  Widget _buildUnaffiliateInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    const redDark = Color(0xFFE53935);
    const redDeep = Color(0xFFB71C1C);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F3F3);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppConstants.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono con gradiente rojo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [redDark, redDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: redDark.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : AppConstants.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "—" : value,
                  style: TextStyle(
                    fontSize: 17,
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
