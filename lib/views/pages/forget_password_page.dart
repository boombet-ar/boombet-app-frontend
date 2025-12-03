import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/forgot_password_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:flutter/material.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  late TextEditingController _emailController;

  bool _emailError = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateAndSendEmail() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
    });

    if (_emailError) {
      _showDialog('Campo vacío', 'Por favor, ingresa tu correo electrónico.');
      return;
    }

    // Validar formato de email
    final email = _emailController.text.trim();
    debugPrint('📧 [ForgetPasswordPage] Email ingresado: "$email"');
    debugPrint('📧 [ForgetPasswordPage] Email length: ${email.length}');

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

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al backend para enviar email
      debugPrint(
        '📧 [ForgetPasswordPage] Llamando a ForgotPasswordService.sendPasswordResetEmail()',
      );
      final result = await ForgotPasswordService.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('📧 [ForgetPasswordPage] Respuesta del servicio: $result');

      if (result['success'] == true) {
        // ✅ EMAIL ENVIADO EXITOSAMENTE
        _showDialog(
          '¡Email enviado!',
          result['message'] ??
              'Se ha enviado un correo de recuperación a $email con las instrucciones para restaurar tu contraseña.',
          isSuccess: true,
        );
      } else {
        // ❌ ERROR AL ENVIAR EMAIL
        setState(() {
          if (result['statusCode'] == 404) {
            _emailError = true;
          }
        });
        _showDialog(
          'Error',
          result['message'] ??
              'No se pudo enviar el correo. Por favor intenta más tarde.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error en _validateAndSendEmail: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showDialog('Error', 'Ocurrió un error inesperado: $e');
    }
  }

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFE8E8E8),
        title: Text(
          title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pop(context); // Volver a login
              }
            },
            child: Text('Entendido', style: TextStyle(color: primaryGreen)),
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
    final textColor = theme.colorScheme.onBackground;
    final accentColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);
    final borderColor = isDark
        ? const Color(0xFF404040)
        : const Color(0xFFB0B0B0);
    const double borderRadius = 12;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: isDark ? Colors.black38 : const Color(0xFFE8E8E8),
          leading: null,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryGreen),
                tooltip: 'Volver',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLightMode, child) {
                    return Icon(
                      isLightMode ? Icons.dark_mode : Icons.light_mode,
                      color: primaryGreen,
                    );
                  },
                ),
                tooltip: 'Cambiar tema',
                onPressed: () {
                  isLightModeNotifier.value = !isLightModeNotifier.value;
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset('assets/images/boombetlogo.png', height: 80),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título
                Text(
                  'Recuperar Contraseña',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu correo electrónico',
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // Input Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_emailError && value.isNotEmpty) {
                            setState(() => _emailError = false);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: TextStyle(
                            color: _emailError
                                ? Colors.red
                                : textColor.withOpacity(0.7),
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: _emailError ? Colors.red : primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
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
                      const SizedBox(height: 24),

                      // Botón Enviar Email
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
                          onPressed: _isLoading ? null : _validateAndSendEmail,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enviar Correo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
