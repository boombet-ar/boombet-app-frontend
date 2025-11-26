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
          nombre: 'Usuario',
          apellido: 'Demo',
          cuil: '20-12345678-9',
          dni: '12345678',
          sexo: 'Masculino',
          estadoCivil: 'Soltero',
          telefono: '11 1234-5678',
          correoElectronico: 'usuario@boombet.com',
          direccionCompleta: 'Calle Ejemplo 123',
          calle: 'Calle Ejemplo',
          numCalle: '123',
          localidad: 'Buenos Aires',
          provincia: 'Buenos Aires',
          fechaNacimiento: '01-01-1990',
          anioNacimiento: '1990',
          cp: 1234,
          edad: 34,
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
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [primaryGreen.withOpacity(0.2), bgColor],
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            // Avatar placeholder
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFE8E8E8),
                                border: Border.all(
                                  color: primaryGreen,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 64,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Nombre completo
                            Text(
                              '${_playerData?.nombre ?? ''} ${_playerData?.apellido ?? ''}'
                                  .trim(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email
                            if (_playerData?.correoElectronico != null &&
                                _playerData!.correoElectronico.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _playerData!.correoElectronico,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),

                      // Datos personales
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // DNI
                            _buildInfoCard(
                              icon: Icons.badge_outlined,
                              label: 'DNI',
                              value: _playerData?.dni ?? 'No disponible',
                              isDark: isDark,
                              textColor: textColor,
                            ),

                            // CUIL
                            if (_playerData?.cuil != null &&
                                _playerData!.cuil.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.credit_card,
                                label: 'CUIL',
                                value: _playerData!.cuil,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Fecha de Nacimiento
                            if (_playerData?.fechaNacimiento != null &&
                                _playerData!.fechaNacimiento.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.cake_outlined,
                                label: 'Fecha de Nacimiento',
                                value: _playerData!.fechaNacimiento,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Edad
                            if (_playerData?.edad != null)
                              _buildInfoCard(
                                icon: Icons.calendar_today_outlined,
                                label: 'Edad',
                                value: '${_playerData!.edad} años',
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Sexo
                            if (_playerData?.sexo != null &&
                                _playerData!.sexo.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.person_outline,
                                label: 'Sexo',
                                value: _playerData!.sexo,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Estado Civil
                            if (_playerData?.estadoCivil != null &&
                                _playerData!.estadoCivil.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.people_outline,
                                label: 'Estado Civil',
                                value: _playerData!.estadoCivil,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            const SizedBox(height: 24),

                            // Contacto
                            Text(
                              'Contacto',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Teléfono
                            if (_playerData?.telefono != null &&
                                _playerData!.telefono.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.phone_outlined,
                                label: 'Teléfono',
                                value: _playerData!.telefono,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            const SizedBox(height: 24),

                            // Dirección
                            Text(
                              'Dirección',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dirección completa
                            if (_playerData?.direccionCompleta != null &&
                                _playerData!.direccionCompleta.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.home_outlined,
                                label: 'Dirección',
                                value: _playerData!.direccionCompleta,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Localidad
                            if (_playerData?.localidad != null &&
                                _playerData!.localidad.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.location_city_outlined,
                                label: 'Localidad',
                                value: _playerData!.localidad,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Provincia
                            if (_playerData?.provincia != null &&
                                _playerData!.provincia.isNotEmpty)
                              _buildInfoCard(
                                icon: Icons.map_outlined,
                                label: 'Provincia',
                                value: _playerData!.provincia,
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            // Código Postal
                            if (_playerData?.cp != null)
                              _buildInfoCard(
                                icon: Icons.markunread_mailbox_outlined,
                                label: 'Código Postal',
                                value: _playerData!.cp.toString(),
                                isDark: isDark,
                                textColor: textColor,
                              ),

                            const SizedBox(height: 24),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 41, 255, 94).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color.fromARGB(255, 41, 255, 94),
            ),
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
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
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
