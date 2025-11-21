import 'package:boombet_app/core/constants/mock_data.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/confirm_data_page.dart';
import 'package:boombet_app/views/pages/forget_password_page.dart';
import 'package:boombet_app/views/pages/pending_afiliacion.dart';
import 'package:boombet_app/views/pages/register_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _userController;
  late TextEditingController _passwordController;

  bool _userError = false;
  bool _passwordError = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndLogin() async {
    // Validar campos vacíos
    setState(() {
      _userError = _userController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (_userError || _passwordError) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'Por favor, completa todos los campos.',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Color.fromARGB(255, 41, 255, 94)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al servicio de autenticación real
      final result = await _authService.login(
        _userController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Login exitoso - El token ya fue guardado por AuthService
        print('DEBUG Login - Token guardado correctamente');

        // Verificar que el token esté guardado
        final token = await TokenService.getToken();
        print(
          'DEBUG Login - Token verificado: ${token != null ? "existe" : "null"}',
        );

        // Obtener datos del jugador del backend
        final playerService = PlayerService();

        // Obtener DNI del usuario logueado (del resultado del login o del token)
        final tokenData = await TokenService.getTokenData();
        final userDni = result['data']?['dni'] ?? tokenData?['dni'] ?? '';

        print('DEBUG Login - DNI del usuario: $userDni');

        final playerResult = await playerService.getPlayerData(userDni);

        if (playerResult['success'] == true && playerResult['data'] != null) {
          final playerData = PlayerData.fromJson(playerResult['data']);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPlayerDataPage(
                datosJugador: playerData,
                onConfirm: (datosConfirmados) async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final updateResult = await playerService.updatePlayerData(
                    datosConfirmados,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (updateResult['success'] == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingAfiliacionPage(),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1A),
                        title: const Text(
                          'Error al actualizar datos',
                          style: TextStyle(color: Color(0xFFE0E0E0)),
                        ),
                        content: Text(
                          updateResult['message'] ?? 'Error desconocido',
                          style: const TextStyle(color: Color(0xFFE0E0E0)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Entendido',
                              style: TextStyle(
                                color: Color.fromARGB(255, 41, 255, 94),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          );
        } else {
          // Si no se pueden obtener datos del jugador, usar mock data como fallback
          print('DEBUG Login - Usando datos mock como fallback');
          final playerData = PlayerData.fromJson(MockData.playerDataJson);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPlayerDataPage(
                datosJugador: playerData,
                onConfirm: (datosConfirmados) async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingAfiliacionPage(),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        // Error en el login
        setState(() {
          _userError = true;
          _passwordError = true;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Error de autenticación',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
            content: Text(
              result['message'] ?? 'Usuario o contraseña incorrectos',
              style: const TextStyle(color: Color(0xFFE0E0E0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: Color.fromARGB(255, 41, 255, 94)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Error inesperado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Error de conexión',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: Text(
            'No se pudo conectar con el servidor: $e',
            style: const TextStyle(color: Color(0xFFE0E0E0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Color.fromARGB(255, 41, 255, 94)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGreen = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onBackground;
    final accentColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE8E8E8);
    final borderColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFD0D0D0);
    const borderRadius = 12.0;

    return Scaffold(
      appBar: const MainAppBar(showSettings: false, showProfileButton: false),
      body: ResponsiveWrapper(
        child: Container(
          color: bgColor,
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Logo en la parte superior
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: Image.asset(
                      'assets/images/boombetlogo.png',
                      width: 200,
                    ),
                  ),
                ), // Campos y botones
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TextField Usuario
                        TextField(
                          controller: _userController,
                          style: TextStyle(color: textColor),
                          onChanged: (value) {
                            if (_userError && value.isNotEmpty) {
                              setState(() => _userError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Correo electrónico o usuario',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF6C6C6C),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _userError ? Colors.red : primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _userError ? Colors.red : borderColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _userError ? Colors.red : borderColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _userError ? Colors.red : primaryGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: accentColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // TextField Contraseña
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          onChanged: (value) {
                            if (_passwordError && value.isNotEmpty) {
                              setState(() => _passwordError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Contraseña',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF6C6C6C),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: _passwordError ? Colors.red : primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _passwordError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _passwordError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _passwordError
                                    ? Colors.red
                                    : primaryGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: accentColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Botón Iniciar Sesión (principal)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isLoading ? null : _validateAndLogin,
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Botón Registrarse (secundario)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryGreen, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return const RegisterPage();
                                  },
                                ),
                              );
                            },
                            child: Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Link para restaurar contraseña
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgetPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña? Restaurala',
                            style: TextStyle(
                              color: primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Espacio disponible abajo para futuros elementos
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
