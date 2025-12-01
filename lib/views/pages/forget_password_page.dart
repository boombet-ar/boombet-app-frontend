import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/password_generator_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
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
      _emailError = _emailController.text.trim().isEmpty;
      _dniError = _dniController.text.trim().isEmpty;
      _newPasswordError = _newPasswordController.text.trim().isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
    });

    if (_emailError ||
        _dniError ||
        _newPasswordError ||
        _confirmPasswordError) {
      _showDialog(
        'Campos incompletos',
        'Por favor, completa todos los campos.',
      );
      return;
    }

    // Validar formato de email usando PasswordValidationService
    final email = _emailController.text.trim();
    if (!PasswordValidationService.isEmailValid(email)) {
      setState(() {
        _emailError = true;
      });
      _showDialog(
        'Email inválido',
        PasswordValidationService.getEmailValidationMessage(email),
      );
      return;
    }

    // Validar formato de DNI usando PasswordValidationService
    final dni = _dniController.text.trim();
    if (!PasswordValidationService.isDniValid(dni)) {
      setState(() {
        _dniError = true;
      });
      _showDialog(
        'DNI inválido',
        PasswordValidationService.getDniValidationMessage(dni),
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
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final dialogBg = isDark
          ? AppConstants.darkAccent
          : AppConstants.lightDialogBg;
      final textColor = isDark
          ? AppConstants.textDark
          : AppConstants.lightLabelText;

      // Mostrar mensaje de éxito y redirigir al login
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            'Contraseña actualizada',
            style: TextStyle(color: textColor),
          ),
          content: Text(
            'Tu contraseña ha sido actualizada exitosamente. Ahora puedes iniciar sesión con tu nueva contraseña.',
            style: TextStyle(color: textColor),
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
                style: TextStyle(color: AppConstants.primaryGreen),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(title, style: TextStyle(color: textColor)),
        content: Text(message, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryGreen = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
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
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campos y botones
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Email
                      AppTextFormField(
                        label: 'Correo Electrónico',
                        hint: 'tu@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hasError: _emailError,
                        errorText: _emailError ? 'Email no válido' : null,
                        onChanged: (value) {
                          if (_emailError && value.isNotEmpty) {
                            setState(() => _emailError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // TextField DNI
                      AppTextFormField(
                        label: 'DNI',
                        hint: '12345678',
                        controller: _dniController,
                        keyboardType: TextInputType.number,
                        hasError: _dniError,
                        errorText: _dniError ? 'DNI requerido' : null,
                        onChanged: (value) {
                          if (_dniError && value.isNotEmpty) {
                            setState(() => _dniError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // TextField Nueva Contraseña
                      AppPasswordField(
                        label: 'Nueva Contraseña',
                        hint: 'Ingresa tu nueva contraseña',
                        controller: _newPasswordController,
                        hasError: _newPasswordError,
                        errorText: _newPasswordError
                            ? 'Contraseña inválida'
                            : null,
                        onChanged: (value) {
                          if (_newPasswordError && value.isNotEmpty) {
                            setState(() => _newPasswordError = false);
                          }
                        },
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
                              color: primaryGreen.withValues(alpha: 0.5),
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
                      AppPasswordField(
                        label: 'Confirmar Contraseña',
                        hint: 'Repite tu nueva contraseña',
                        controller: _confirmPasswordController,
                        hasError: _confirmPasswordError,
                        errorText: _confirmPasswordError
                            ? 'Las contraseñas no coinciden'
                            : null,
                        onChanged: (value) {
                          if (_confirmPasswordError && value.isNotEmpty) {
                            setState(() => _confirmPasswordError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón Restablecer Contraseña (principal)
                      AppButton(
                        label: 'Restablecer contraseña',
                        onPressed: _validateAndResetPassword,
                        isLoading: _isLoading,
                        icon: Icons.lock_reset,
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
