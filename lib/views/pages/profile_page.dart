import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/edit_profile_page.dart';
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
      final decoded = JwtDecoder.decode(token);
      debugPrint("🧩 DECODED: $decoded");

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
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView(textColor, primaryGreen)
            : _buildProfileContent(textColor, isDark, primaryGreen),
      ),
    );
  }

  // ----------------- ERROR VIEW -----------------

  Widget _buildErrorView(Color textColor, Color primaryGreen) {
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
          _buildVerifiedBadge(primaryGreen),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(Color primaryGreen) {
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
            "Usuario Verificado",
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
        ],
      ),
    );
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
