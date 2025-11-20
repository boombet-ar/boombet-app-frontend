import 'package:boombet_app/data/mock_data.dart';
import 'package:boombet_app/data/player_data.dart';
// TODO: Descomentar cuando el backend esté listo
// import 'package:boombet_app/services/auth_service.dart';
// import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/views/pages/confirm_data_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/register-page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
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

  // TODO: Descomentar cuando el backend esté listo
  // final AuthService _authService = AuthService();
  // final PlayerService _playerService = PlayerService();

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
      // ====== MODO TESTING: USANDO MOCK DATA ======
      // TODO: Descomentar cuando el backend esté listo
      /*
      final result = await _authService.login(
        _userController.text.trim(),
        _passwordController.text,
      );
      */

      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Validar credenciales mock
      final username = _userController.text.trim();
      final password = _passwordController.text;

      if (username == MockData.testUsername &&
          password == MockData.testPassword) {
        // Login exitoso - Usar datos mock
        try {
          final playerData = PlayerData.fromJson(MockData.playerDataJson);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPlayerDataPage(
                datosJugador: playerData,
                onConfirm: (datosConfirmados) async {
                  // ====== MODO TESTING: SIMULANDO GUARDADO ======
                  // TODO: Descomentar cuando el backend esté listo
                  /*
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final result = await _playerService.updatePlayerData(
                    datosConfirmados,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (result['success'] == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  } else {
                    showDialog(...); // error dialog
                  }
                  */

                  // Simular guardado exitoso y navegar a HomePage
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ),
          );
        } catch (e) {
          // Error al parsear datos del jugador
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Error al cargar datos',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              content: Text(
                'No se pudieron cargar los datos del usuario: $e',
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
      } else {
        // Error en el login - Mostrar mensaje específico
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
              'Usuario o contraseña incorrectos\n\n'
              'Credenciales de prueba:\n'
              'Usuario: ${MockData.testUsername}\n'
              'Contraseña: ${MockData.testPassword}',
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
      body: Container(
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
                              color: _passwordError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _passwordError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _passwordError ? Colors.red : primaryGreen,
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
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _isLoading ? null : _validateAndLogin,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: isDark ? Colors.black : Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.black : Colors.white,
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
                              borderRadius: BorderRadius.circular(borderRadius),
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
    );
  }
}
