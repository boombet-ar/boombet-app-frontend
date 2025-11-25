import 'package:boombet_app/services/password_generator_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  late TextEditingController _emailController;
  late TextEditingController _dniController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _emailError = false;
  bool _dniError = false;
  bool _newPasswordError = false;
  bool _confirmPasswordError = false;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _dniController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dniController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndResetPassword() async {
    // Validar campos vacíos
    setState(() {
      _newPasswordError = _newPasswordController.text.trim().isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
    });

    if (_newPasswordError || _confirmPasswordError) {
      _showDialog(
        'Campos incompletos',
        'Por favor, completa todos los campos.',
      );
      return;
    }

    // Validar que las contraseñas coincidan
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _newPasswordError = true;
        _confirmPasswordError = true;
      });
      _showDialog(
        'Las contraseñas no coinciden',
        'Por favor, asegúrate de que ambas contraseñas sean iguales.',
      );
      return;
    }

    // Validar longitud mínima de contraseña
    if (_newPasswordController.text.length < 6) {
      setState(() {
        _newPasswordError = true;
        _confirmPasswordError = true;
      });
      _showDialog(
        'Contraseña muy corta',
        'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Mostrar mensaje de éxito y redirigir al login
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Contraseña actualizada',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'Ir al inicio de sesión',
                style: TextStyle(color: Color.fromARGB(255, 41, 255, 94)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showDialog('Error', 'No se pudo restablecer la contraseña: $e');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Color(0xFFE0E0E0))),
        content: Text(
          message,
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
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ResponsiveWrapper(
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
                  ),
                  const SizedBox(height: 24),

                  // Título de bienvenida
                  Text(
                    'Recuperar contraseña',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa tu nueva contraseña',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campos y botones
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_emailError && value.isNotEmpty) {
                            setState(() => _emailError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF808080)
                                : const Color(0xFF6C6C6C),
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: _emailError ? Colors.red : primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _emailError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _emailError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _emailError ? Colors.red : primaryGreen,
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

                      // TextField DNI
                      TextField(
                        controller: _dniController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_dniError && value.isNotEmpty) {
                            setState(() => _dniError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'DNI',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF808080)
                                : const Color(0xFF6C6C6C),
                          ),
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                            color: _dniError ? Colors.red : primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _dniError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _dniError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _dniError ? Colors.red : primaryGreen,
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

                      // TextField Nueva Contraseña
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_newPasswordError && value.isNotEmpty) {
                            setState(() => _newPasswordError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Nueva contraseña',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF808080)
                                : const Color(0xFF6C6C6C),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: _newPasswordError
                                ? Colors.red
                                : primaryGreen,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textColor.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _newPasswordError
                                  ? Colors.red
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _newPasswordError
                                  ? Colors.red
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _newPasswordError
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
                      const SizedBox(height: 12),

                      // Botón para generar contraseña sugerida
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final email = _emailController.text.trim();
                            final dni = _dniController.text.trim();

                            if (email.isEmpty || dni.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Completa Email y DNI primero'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            // Usar la parte local del email antes del @ como nombre
                            final emailParts = email.split('@');
                            final localPart = emailParts.isNotEmpty
                                ? emailParts[0]
                                : email;
                            final primerNombre = localPart.length >= 2
                                ? localPart
                                : email;
                            // Usar el dominio o parte del email como apellido
                            final apellido = emailParts.length > 1
                                ? emailParts[1].split('.')[0]
                                : localPart;

                            final password =
                                PasswordGeneratorService.generatePassword(
                                  primerNombre,
                                  apellido,
                                  dni,
                                );

                            setState(() {
                              _newPasswordController.text = password;
                              _confirmPasswordController.text = password;
                              _newPasswordError = false;
                              _confirmPasswordError = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '¡Contraseña generada y aplicada!',
                                ),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: primaryGreen,
                          ),
                          label: Text(
                            'Generar contraseña sugerida',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: primaryGreen.withOpacity(0.5),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TextField Confirmar Contraseña
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_confirmPasswordError && value.isNotEmpty) {
                            setState(() => _confirmPasswordError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirmar contraseña',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF808080)
                                : const Color(0xFF6C6C6C),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: _confirmPasswordError
                                ? Colors.red
                                : primaryGreen,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textColor.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _confirmPasswordError
                                  ? Colors.red
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _confirmPasswordError
                                  ? Colors.red
                                  : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _confirmPasswordError
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
                      const SizedBox(height: 32),

                      // Botón Restablecer Contraseña (principal)
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
                          onPressed: _isLoading
                              ? null
                              : _validateAndResetPassword,
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
                                    const Icon(Icons.lock_reset, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Restablecer contraseña',
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
                    ],
                  ),
                  // Espacio disponible abajo
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
