import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/edit_profile_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Desafiliarse de Boombet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Al desafiliarte de Boombet:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildUnaffiliatePoint('• Tu cuenta será eliminada', textColor),
            _buildUnaffiliatePoint('• Te desafiliamos de Boombet', textColor),
            _buildUnaffiliatePoint(
              '• Permanecerás afiliado a los casinos asociados',
              textColor,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de esta decisión?',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back_outlined, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'No, continuar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _handleUnaffiliateConfirm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_outline, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Sí, desafiliarme',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  void _handleUnaffiliateConfirm(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Solicitud procesada. Desafiliación en progreso...',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade700,
        duration: AppConstants.longSnackbarDuration,
      ),
    );
    // TODO: Llamar a servicio para desafiliarse cuando esté la lógica lista
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
