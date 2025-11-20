import 'package:boombet_app/views/pages/home_page.dart';
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

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    const darkBg = Color(0xFF000000);
    const textColor = Color(0xFFE0E0E0);
    const accentGray = Color(0xFF1A1A1A);
    const borderRadius = 12.0;

    return Scaffold(
      appBar: const MainAppBar(showSettings: false, showProfileButton: false),
      body: Container(
        color: darkBg,
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
              ),
              // Campos y botones
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Usuario
                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico o usuario',
                          hintStyle: const TextStyle(color: Color(0xFF808080)),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: accentGray,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: accentGray,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: primaryGreen,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: accentGray,
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
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          hintStyle: const TextStyle(color: Color(0xFF808080)),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: accentGray,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: accentGray,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: const BorderSide(
                              color: primaryGreen,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: accentGray,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
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
                            side: const BorderSide(
                              color: primaryGreen,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                          ),
                          onPressed: () {
                            // Navegar a página de registro
                          },
                          child: const Text(
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
