import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/services/reset_password_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token; // Token del email de recuperación

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _passwordError = false;
  bool _confirmPasswordError = false;
  bool _isLoading = false;

  Map<String, bool> _passwordRules = {
    "8+ caracteres": false,
    "1 mayúscula": false,
    "1 número": false,
    "1 símbolo": false,
    "Sin repetidos": false,
    "Sin secuencias": false,
  };

  @override
  void initState() {
    super.initState();
    try {
      debugPrint('📝 [ResetPasswordPage] initState - token: ${widget.token}');
      _passwordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
      _passwordController.addListener(_validatePasswordLive);
    } catch (e) {
      debugPrint('❌ [ResetPasswordPage] Error en initState: $e');
    }
  }

  @override
  void dispose() {
    try {
      _passwordController.dispose();
      _confirmPasswordController.dispose();
    } catch (e) {
      debugPrint('❌ [ResetPasswordPage] Error en dispose: $e');
    }
    super.dispose();
  }

  // Validar que las contraseñas cumplan con los requisitos
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return null;
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe tener al menos una mayúscula';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe tener al menos un número';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'))) {
      return 'La contraseña debe tener al menos un símbolo';
    }

    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return 'La contraseña no debe tener caracteres repetidos consecutivos';
    }

    for (int i = 0; i < password.length - 2; i++) {
      if (RegExp(r'[0-9]').hasMatch(password[i]) &&
          RegExp(r'[0-9]').hasMatch(password[i + 1]) &&
          RegExp(r'[0-9]').hasMatch(password[i + 2])) {
        int n1 = int.parse(password[i]);
        int n2 = int.parse(password[i + 1]);
        int n3 = int.parse(password[i + 2]);
        if ((n2 == n1 + 1 && n3 == n2 + 1) || (n2 == n1 - 1 && n3 == n2 - 1)) {
          return 'La contraseña no debe tener secuencias numéricas';
        }
      }
    }

    for (int i = 0; i < password.length - 2; i++) {
      if (RegExp(r'[a-zA-Z]').hasMatch(password[i]) &&
          RegExp(r'[a-zA-Z]').hasMatch(password[i + 1]) &&
          RegExp(r'[a-zA-Z]').hasMatch(password[i + 2])) {
        int c1 = password[i].toLowerCase().codeUnitAt(0);
        int c2 = password[i + 1].toLowerCase().codeUnitAt(0);
        int c3 = password[i + 2].toLowerCase().codeUnitAt(0);
        if ((c2 == c1 + 1 && c3 == c2 + 1) || (c2 == c1 - 1 && c3 == c2 - 1)) {
          return 'La contraseña no debe tener secuencias de letras';
        }
      }
    }

    return null;
  }

  void _validatePasswordLive() {
    final pw = _passwordController.text;
    final status = PasswordValidationService.getValidationStatus(pw);

    setState(() {
      _passwordRules["8+ caracteres"] = status['minimum_length']!;
      _passwordRules["1 mayúscula"] = status['uppercase']!;
      _passwordRules["1 número"] = status['number']!;
      _passwordRules["1 símbolo"] = status['symbol']!;
      _passwordRules["Sin repetidos"] = status['no_repetition']!;
      _passwordRules["Sin secuencias"] = status['no_sequence']!;
    });
  }

  void _validateAndResetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _passwordError = password.isEmpty;
      _confirmPasswordError = confirmPassword.isEmpty;
    });

    if (_passwordError || _confirmPasswordError) {
      _showSnackbar('Por favor completa todos los campos', isError: true);
      return;
    }

    // Validar que la contraseña cumpla con los requisitos
    String? passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() {
        _passwordError = true;
      });
      _showSnackbar(passwordError, isError: true);
      return;
    }

    // Validar que las contraseñas coincidan
    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = true;
      });
      _showSnackbar('Las contraseñas no coinciden', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al servicio para resetear la contraseña
      final result = await ResetPasswordService.resetPassword(
        token: widget.token,
        newPassword: password,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // ✅ CONTRASEÑA RESETEADA EXITOSAMENTE
        // Si éxito (200):
        // ✅ Mostrar snackbar de éxito
        // → Esperar 2 segundos
        // → Navegar a login

        _showSnackbar(
          '✅ ${result['message'] ?? 'Contraseña actualizada exitosamente'}',
          isError: false,
        );

        // Navegar a login después de 2 segundos
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/');
        }
      } else {
        // ❌ ERROR AL RESETEAR CONTRASEÑA
        _showSnackbar(
          '❌ ${result['message'] ?? 'No se pudo resetear la contraseña'}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('❌ Error en _validateAndResetPassword: $e');
      _showSnackbar('❌ Error al resetear contraseña: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      debugPrint('📝 [ResetPasswordPage] build - token: ${widget.token}');
      debugPrint(
        '📝 [ResetPasswordPage] token isEmpty: ${widget.token.isEmpty}',
      );

      // Si el token está vacío, mostrar error
      if (widget.token.isEmpty) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error: Token inválido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El link de recuperación no es válido o ha expirado.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Volver al Login'),
                ),
              ],
            ),
          ),
        );
      }

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final primaryGreen = theme.colorScheme.primary;
      final textColor = theme.colorScheme.onSurface;
      final accentColor = isDark
          ? AppConstants.borderDark
          : AppConstants.lightAccent;
      final borderColor = isDark
          ? AppConstants.borderDark
          : const Color(0xFFB0B0B0);
      final borderRadius = AppConstants.borderRadius;

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
            maxWidth: 600,
            child: Container(
              color: theme.scaffoldBackgroundColor,
              height: double.infinity,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Logo con Hero Animation
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

                    // Título
                    Text(
                      'Restablecer Contraseña',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Ingresa tu nueva contraseña',
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campos y botones
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            hintText: 'Nueva contraseña',
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
                        const SizedBox(height: 16),

                        // Validación de reglas de contraseña
                        if (_passwordController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(borderRadius),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _passwordRules.entries.map((e) {
                                final isValid = e.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isValid
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: isValid
                                            ? AppConstants.primaryGreen
                                            : Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        e.key,
                                        style: TextStyle(
                                          color: isValid
                                              ? AppConstants.primaryGreen
                                              : textColor.withValues(
                                                  alpha: 0.6,
                                                ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // TextField Confirmar Contraseña
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          onChanged: (value) {
                            if (_confirmPasswordError && value.isNotEmpty) {
                              setState(() => _confirmPasswordError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Confirma tu contraseña',
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
                        const SizedBox(height: 24),

                        // Botón Restablecer
                        AppButton(
                          label: 'Restablecer Contraseña',
                          onPressed: _validateAndResetPassword,
                          isLoading: _isLoading,
                          icon: Icons.lock_reset,
                          borderRadius: borderRadius,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ [ResetPasswordPage] Error en build: $e');
      debugPrint('❌ [ResetPasswordPage] Stack trace: ${StackTrace.current}');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error: No se pudo cargar la página',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Detalles: $e', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
