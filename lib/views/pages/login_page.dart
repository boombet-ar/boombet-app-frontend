import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/forget_password_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/register_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _identifierController;
  late TextEditingController _passwordController;

  bool _identifierError = false;
  bool _passwordError = false;
  bool _isLoading = false;
  bool _rememberMe =
      false; // Por defecto desactivado - usuario debe activarlo manualmente
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Pre-rellenar campos para testing
    _identifierController = TextEditingController(text: 'test');
    _passwordController = TextEditingController(text: 'Test124!');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndLogin() async {
    final identifier = _identifierController.text.trim();

    // Validar campos vacíos
    setState(() {
      _identifierError = identifier.isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
    });

    if (_identifierError || _passwordError) {
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

    // Validar formato de email si contiene @
    if (identifier.contains('@')) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(identifier)) {
        setState(() {
          _identifierError = true;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Email inválido',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
            content: const Text(
              'Por favor, ingresa un email válido.',
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
    }

    // Mostrar overlay de carga
    LoadingOverlay.show(context, message: 'Iniciando sesión...');

    try {
      // Llamar al servicio de autenticación real
      final result = await _authService.login(
        _identifierController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (result['success'] == true) {
        // Login exitoso - El token ya fue guardado por AuthService
        print('DEBUG Login - Token guardado correctamente');

        // Verificar que el token esté guardado
        final token = await TokenService.getToken();
        print(
          'DEBUG Login - Token verificado: ${token != null ? "existe" : "null"}',
        );

        // Navegar directamente a HomePage
        // Los usuarios que hacen login ya pasaron por el proceso de confirmación de datos
        Navigator.pushReplacement(context, ScaleRoute(page: const HomePage()));
      } else {
        // Error en el login
        setState(() {
          _identifierError = true;
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
              result['message'] ?? 'Usuario/Email o contraseña incorrectos',
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

      LoadingOverlay.hide(context);

      // Detectar error de CORS o ClientException
      String errorTitle = 'Error de conexión';
      String errorMessage = 'No se pudo conectar con el servidor';

      if (e.toString().contains('ClientException') ||
          e.toString().contains('Failed to fetch')) {
        errorTitle = 'Error de conexión desde navegador';
        errorMessage =
            'El servidor no permite conexiones desde navegadores web por seguridad (CORS).\n\n'
            '✅ Solución: Usa la aplicación desde Android o iOS.\n\n'
            'Si necesitas usar el navegador, contacta al administrador para configurar CORS en el backend.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            errorTitle,
            style: const TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: Text(
            errorMessage,
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
    final textColor = theme.colorScheme.onSurface;
    final accentColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE8E8E8);
    final borderColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFD0D0D0);
    const borderRadius = 12.0;

    return Scaffold(
      appBar: const MainAppBar(showSettings: false, showProfileButton: false),
      body: GestureDetector(
        onTap: () {
          // Quitar el foco de los campos al tocar fuera
          FocusScope.of(context).unfocus();
        },
        child: ResponsiveWrapper(
          maxWidth: 600,
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
                      child: Hero(
                        tag: 'boombet_logo',
                        child: Image.asset(
                          'assets/images/boombetlogo.png',
                          width: 200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título de bienvenida
                  Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos y botones
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Usuario o Email
                      Semantics(
                        label: 'Campo de usuario o email',
                        hint:
                            'Ingresa tu nombre de usuario o dirección de correo electrónico',
                        child: TextField(
                          controller: _identifierController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          enableInteractiveSelection: true,
                          style: TextStyle(color: textColor),
                          onChanged: (value) {
                            if (_identifierError && value.isNotEmpty) {
                              setState(() => _identifierError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Usuario o Email',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF6C6C6C),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _identifierError
                                  ? Colors.red
                                  : primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _identifierError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _identifierError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _identifierError
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
                      ),
                      const SizedBox(height: 20),

                      // TextField Contraseña
                      Semantics(
                        label: 'Campo de contraseña',
                        hint: 'Ingresa tu contraseña',
                        obscured: true,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          enableInteractiveSelection: true,
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: textColor.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
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
                      ),
                      const SizedBox(height: 24),

                      // CheckboxListTile Recordar sesión
                      Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(
                            color: borderColor.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          activeColor: primaryGreen,
                          checkColor: isDark ? Colors.black : Colors.white,
                          title: Text(
                            'Mantener sesión iniciada',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'No cerrar sesión al salir de la app',
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botón Iniciar Sesión (principal)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            elevation: 3,
                            shadowColor: primaryGreen.withOpacity(0.4),
                          ),
                          onPressed: _isLoading ? null : _validateAndLogin,
                          child: _isLoading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: isDark ? Colors.black : Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Divider con texto
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: textColor.withOpacity(0.2),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: textColor.withOpacity(0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Botón Registrarse (secundario)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: primaryGreen.withOpacity(0.7),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              SlideRightRoute(page: const RegisterPage()),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 20,
                                color: primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Crear cuenta nueva',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Link para restaurar contraseña
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadeRoute(page: const ForgetPasswordPage()),
                          );
                        },
                        icon: Icon(
                          Icons.help_outline,
                          size: 18,
                          color: primaryGreen,
                        ),
                        label: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Espacio disponible abajo para futuros elementos
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
