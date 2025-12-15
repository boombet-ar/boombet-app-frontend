import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/edit_profile_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/unaffiliate_result_page.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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
      final token = await TokenService.getToken();

      debugPrint("🧪 TOKEN RAW: '$token'");

      if (token == null || token.isEmpty || token == "null") {
        throw Exception("Token vacío o inválido");
      }

      // Decodificar
      late final Map<String, dynamic> decoded;
      try {
        decoded = JwtDecoder.decode(token);
        debugPrint("🧩 DECODED: $decoded");
      } catch (decodeError) {
        throw Exception("Error decodificando token: $decodeError");
      }

      final idJugador = decoded["idJugador"];
      if (idJugador == null) throw Exception("Token sin idJugador");

      final player = await PlayerService().getPlayerData(idJugador.toString());

      setState(() {
        _playerData = player;
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
        child: ResponsiveWrapper(
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
                      await TokenService.deleteToken();
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
                foregroundColor: Colors.black,
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
              color: isDark ? const Color(0xFF202020) : Colors.white,
            ),
            child: Icon(Icons.person, size: 70, color: primaryGreen),
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
          Icon(Icons.verified_user, size: 16, color: primaryGreen),
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
          color: isDark ? Colors.white10 : Colors.black12,
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Editar Información",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // 🚀 BOTÓN PARA DESAFILIARSE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _showUnaffiliateDialog(primaryGreen, textColor, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Desafiliarse de Boombet",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg;
    final subtitleColor = isDark ? Colors.white70 : AppConstants.lightHintText;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(dialogRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono de advertencia
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(dialogRadius),
                      topRight: Radius.circular(dialogRadius),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 48,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Desafiliarse de Boombet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Esto es importante:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Puntos de información
                      _buildUnaffiliateInfoCard(
                        icon: Icons.delete_outline,
                        title: 'Tu cuenta será eliminada',
                        subtitle:
                            'Toda tu información personal y datos de juego serán borrados permanentemente',
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildUnaffiliateInfoCard(
                        icon: Icons.logout_rounded,
                        title: 'Te desafiliamos de Boombet',
                        subtitle:
                            'Perderás acceso a nuestra plataforma y sus beneficios',
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildUnaffiliateInfoCard(
                        icon: Icons.casino,
                        title: 'Afiliación a casinos asociados',
                        subtitle:
                            'Permanecerás afiliado a los casinos asociados según tus acuerdos individuales',
                        isDark: isDark,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),

                      const SizedBox(height: 24),

                      // Pregunta de confirmación
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.orange.shade900.withValues(alpha: 0.2)
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '¿Estás completamente seguro de esta decisión? Esta acción no se puede deshacer.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.orange.shade200
                                : Colors.orange.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botones
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.grey.shade800
                                : AppConstants.lightInputBg,
                            foregroundColor: primaryGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: primaryGreen.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'No, continuar',
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUnaffiliating
                              ? null
                              : () => _handleUnaffiliateConfirm(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUnaffiliating
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sí, desafiliarme',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
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
    );
  }

  Widget _buildUnaffiliatePoint(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8)),
      ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.3)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.red.shade600),
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
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                    height: 1.4,
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
          style: TextStyle(color: Colors.white),
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
            style: const TextStyle(color: Colors.white),
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
            color: isDark ? Colors.white10 : Colors.black12,
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
