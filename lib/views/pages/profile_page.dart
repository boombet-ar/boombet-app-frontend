import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Por ahora, usar datos mock como placeholder
      // TODO: Implementar endpoint para obtener datos del usuario autenticado
      // usando solo el token sin necesidad de DNI

      // Simulación de datos para desarrollo
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _playerData = PlayerData(
          nombre: 'SANTIAGO MARTIN',
          apellido: 'RODRIGUEZ',
          cuil: '', // No mostrar
          dni: '', // No mostrar
          sexo: 'Masculino',
          estadoCivil: '', // No mostrar
          telefono: '1145678923',
          correoElectronico: 'santiago.rodriguez@gmail.com',
          direccionCompleta: '', // No mostrar
          calle: '',
          numCalle: '',
          localidad: '', // No mostrar
          provincia: '', // No mostrar
          fechaNacimiento: '15-03-1992',
          anioNacimiento: '1992',
          cp: null, // No mostrar
          edad: null, // No mostrar
        );
        _isLoading = false;
      });

      // Código original comentado hasta que el backend tenga el endpoint correcto
      /*
      // Obtener DNI del token o de la respuesta de login
      final tokenData = await TokenService.getTokenData();
      print('DEBUG Profile - Token data: $tokenData');
      
      // Intentar obtener DNI de diferentes lugares
      final dni = tokenData?['dni']?.toString() ?? 
                tokenData?['sub']?.toString() ?? 
                tokenData?['user_id']?.toString() ?? '';

      if (dni.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo obtener la información del usuario';
        });
        return;
      }

      // Obtener datos del jugador
      final playerService = PlayerService();
      final result = await playerService.getPlayerData(dni);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _playerData = PlayerData.fromJson(result['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Error al cargar los datos';
        });
      }
      */
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error de conexión: $e';
      });
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
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade400,
                      ),
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
              )
            : RepaintBoundary(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header con avatar y nombre
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryGreen.withOpacity(0.15),
                              primaryGreen.withOpacity(0.05),
                              bgColor,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            // Avatar con sombra mejorada
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.white,
                                  border: Border.all(
                                    color: primaryGreen,
                                    width: 4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 70,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Nombre completo
                            Text(
                              '${_playerData?.nombre ?? ''} ${_playerData?.apellido ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Username con badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: primaryGreen.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.alternate_email,
                                    size: 16,
                                    color: primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SantiR92',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryGreen,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),

                      // Tarjeta de información
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: primaryGreen,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Información Personal',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Tarjeta con todos los datos
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Email
                                  _buildModernInfoRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: _playerData?.correoElectronico ?? '',
                                    isDark: isDark,
                                    textColor: textColor,
                                    primaryGreen: primaryGreen,
                                    isFirst: true,
                                  ),

                                  // Teléfono
                                  _buildModernInfoRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Teléfono',
                                    value: _playerData?.telefono ?? '',
                                    isDark: isDark,
                                    textColor: textColor,
                                    primaryGreen: primaryGreen,
                                  ),

                                  // Género
                                  _buildModernInfoRow(
                                    icon: Icons.wc_outlined,
                                    label: 'Género',
                                    value: _playerData?.sexo ?? '',
                                    isDark: isDark,
                                    textColor: textColor,
                                    primaryGreen: primaryGreen,
                                  ),

                                  // Fecha de Nacimiento
                                  _buildModernInfoRow(
                                    icon: Icons.cake_outlined,
                                    label: 'Fecha de Nacimiento',
                                    value: _playerData?.fechaNacimiento ?? '',
                                    isDark: isDark,
                                    textColor: textColor,
                                    primaryGreen: primaryGreen,
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
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

  Widget _buildModernInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
    required Color primaryGreen,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          // Icono con fondo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: primaryGreen),
          ),
          const SizedBox(width: 16),
          // Label y valor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
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
