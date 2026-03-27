import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/services/reset_password_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class ResetPasswordPage extends StatefulWidget {
  final String token; // Token del email de recuperación
  final bool preview;

  const ResetPasswordPage({
    super.key,
    required this.token,
    this.preview = false,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  StreamSubscription<DeepLinkPayload>? _deepLinkSubscription;
  late String _currentToken;

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
      _currentToken = widget.token;
      _passwordController = TextEditingController();
      _confirmPasswordController = TextEditingController();
      _passwordController.addListener(_validatePasswordLive);

      if (!widget.preview) {
        // Escuchar deep links por si se actualiza el token
        _deepLinkSubscription = DeepLinkService.instance.stream.listen((
          payload,
        ) {
          if (payload.isPasswordReset &&
              payload.token != null &&
              payload.token!.isNotEmpty) {
            setState(() {
              _currentToken = payload.token!;
            });
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Verificar si hay un pending payload del deep link
          final pendingPayload = DeepLinkService.instance.lastPayload;
          if (pendingPayload != null && pendingPayload.isPasswordReset) {
            if (pendingPayload.token != null &&
                pendingPayload.token!.isNotEmpty) {
              setState(() {
                _currentToken = pendingPayload.token!;
              });
            }
          }
        });
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    try {
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      _deepLinkSubscription?.cancel();
    } catch (e) {}
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
    if (widget.preview) {
      _showSnackbar(
        'Preview: reset deshabilitado (solo visual).',
        isError: false,
      );
      return;
    }

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
        token: _currentToken,
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

        await TokenService.clearTokens();

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

      _showSnackbar('❌ Error al resetear contraseña: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFB00020)
            : AppConstants.primaryGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Si el token está vacío, mostrar error
      if (_currentToken.isEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFF0E0E0E),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.link_off_rounded,
                      size: 42,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Token inválido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El link de recuperación no es válido o ha expirado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Volver al Login',
                    onPressed: () => context.go('/'),
                    icon: Icons.arrow_back_rounded,
                    borderRadius: AppConstants.borderRadius,
                  ),
              ],
            ),
          ),
        ));
      }

      const scaffoldBg = Color(0xFF0E0E0E);
      const green = AppConstants.primaryGreen;
      const borderRadius = AppConstants.borderRadius;
      final isWeb = kIsWeb;

      Widget buildLogo({required double width}) {
        return Center(
          child: Hero(
            tag: 'boombet_logo',
            child: Image.asset('assets/images/boombetlogo.png', width: width),
          ),
        );
      }

      final header = Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: green.withValues(alpha: 0.22),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.lock_reset_rounded, color: green, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Restablecer Contraseña',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: green,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tu nueva contraseña',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
        ],
      );

      Widget buildForm() {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: green,
              onChanged: (value) {
                if (_passwordError && value.isNotEmpty) {
                  setState(() => _passwordError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _passwordError
                      ? Colors.redAccent
                      : green.withValues(alpha: 0.7),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _passwordError
                        ? Colors.redAccent
                        : green.withValues(alpha: 0.14),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _passwordError
                        ? Colors.redAccent
                        : green.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _passwordError ? Colors.redAccent : green,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_passwordController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: green.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _passwordRules.entries.map((e) {
                    final isValid = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.check_circle_outline_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isValid
                                ? green
                                : Colors.white.withValues(alpha: 0.25),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isValid
                                  ? green
                                  : Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                              fontWeight: isValid
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              enableInteractiveSelection: false,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: green,
              onChanged: (value) {
                if (_confirmPasswordError && value.isNotEmpty) {
                  setState(() => _confirmPasswordError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'Confirma tu contraseña',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: _confirmPasswordError
                      ? Colors.redAccent
                      : green.withValues(alpha: 0.7),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _confirmPasswordError
                        ? Colors.redAccent
                        : green.withValues(alpha: 0.14),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _confirmPasswordError
                        ? Colors.redAccent
                        : green.withValues(alpha: 0.14),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  borderSide: BorderSide(
                    color: _confirmPasswordError ? Colors.redAccent : green,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Restablecer Contraseña',
              onPressed: _validateAndResetPassword,
              isLoading: _isLoading,
              icon: Icons.lock_reset,
              borderRadius: borderRadius,
            ),
          ],
        );
      }

      final mobileBody = ResponsiveWrapper(
        maxWidth: 600,
        child: Container(
          color: scaffoldBg,
          height: double.infinity,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: buildLogo(width: 200),
                ),
                const SizedBox(height: 28),
                header,
                buildForm(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );

      final webBody = LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowWeb = constraints.maxWidth < 900;

          if (isNarrowWeb) {
            // Web angosto (mobile browser): layout vertical tipo mobile
            // para evitar que la columna del formulario quede demasiado estrecha.
            return ResponsiveWrapper(
              maxWidth: 600,
              constrainOnWeb: true,
              child: Container(
                color: scaffoldBg,
                width: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      buildLogo(width: 180),
                      const SizedBox(height: 28),
                      header,
                      buildForm(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }

          // Desktop web: mantener 2 columnas.
          return Container(
            color: scaffoldBg,
            height: double.infinity,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double logoWidth = (constraints.maxWidth * 0.8)
                            .clamp(260.0, 520.0)
                            .toDouble();
                        return Center(child: buildLogo(width: logoWidth));
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [header, buildForm()],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      return Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: const Color(0xFF0E0E0E)),
            ),
            isWeb ? webBody : mobileBody,
          ],
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.30),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Error al cargar la página',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detalles: $e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Volver',
                  onPressed: () => context.go('/'),
                  icon: Icons.arrow_back_rounded,
                  borderRadius: AppConstants.borderRadius,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
