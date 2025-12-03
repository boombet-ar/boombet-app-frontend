import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/password_generator_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/confirm_player_data_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _dniController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _usernameError = false;
  bool _emailError = false;
  bool _dniError = false;
  bool _phoneError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;
  bool _isLoading = false;
  String? _selectedGender;
  bool _genderError = false;

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
    // Inicializar controllers con datos hardcodeados para testing
    _usernameController = TextEditingController(text: 'test');
    _emailController = TextEditingController(text: 'santinooliveto1@gmail.com');
    _dniController = TextEditingController(text: '45614451');
    _phoneController = TextEditingController(text: '1121895575');
    _passwordController = TextEditingController(text: 'Test135!');
    _confirmPasswordController = TextEditingController(text: 'Test135!');
    _selectedGender = 'Masculino';
    _passwordController.addListener(_validatePasswordLive);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndRegister() async {
    setState(() {
      _usernameError = _usernameController.text.trim().isEmpty;
      _emailError = _emailController.text.trim().isEmpty;
      _dniError = _dniController.text.trim().isEmpty;
      _phoneError = _phoneController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
      _genderError = _selectedGender == null;
    });

    if (_usernameError ||
        _emailError ||
        _dniError ||
        _phoneError ||
        _passwordError ||
        _confirmPasswordError ||
        _genderError) {
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
          title: Text('Campos incompletos', style: TextStyle(color: textColor)),
          content: Text(
            'Por favor, completa todos los campos obligatorios.',
            style: TextStyle(color: textColor),
          ),
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
      return;
    }

    // Validar formato de email usando PasswordValidationService
    final email = _emailController.text.trim();
    if (!PasswordValidationService.isEmailValid(email)) {
      setState(() {
        _emailError = true;
      });
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
          title: Text('Email inválido', style: TextStyle(color: textColor)),
          content: Text(
            PasswordValidationService.getEmailValidationMessage(email),
            style: TextStyle(color: textColor),
          ),
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
      return;
    }

    // Validar formato de teléfono usando PasswordValidationService
    final phone = _phoneController.text.trim();
    if (!PasswordValidationService.isPhoneValid(phone)) {
      setState(() {
        _phoneError = true;
      });
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
          title: Text('Teléfono inválido', style: TextStyle(color: textColor)),
          content: Text(
            PasswordValidationService.getPhoneValidationMessage(phone),
            style: TextStyle(color: textColor),
          ),
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
      return;
    }

    // Validar formato de DNI usando PasswordValidationService
    final dni = _dniController.text.trim();
    if (!PasswordValidationService.isDniValid(dni)) {
      setState(() {
        _dniError = true;
      });
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
          title: Text('DNI inválido', style: TextStyle(color: textColor)),
          content: Text(
            PasswordValidationService.getDniValidationMessage(dni),
            style: TextStyle(color: textColor),
          ),
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
      return;
    }

    // Validar formato de username (mínimo 4 caracteres, alfanumérico, sin espacios)
    final username = _usernameController.text.trim();
    if (username.length < 4 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _usernameError = true;
      });
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
          title: Text('Usuario inválido', style: TextStyle(color: textColor)),
          content: Text(
            'El usuario debe tener mínimo 4 caracteres, solo letras, números y guión bajo (_).',
            style: TextStyle(color: textColor),
          ),
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
      return;
    }

    // Validar fortaleza de contraseña
    String? passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() {
        _passwordError = true;
      });
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
          title: Text(
            'Contraseña inválida',
            style: TextStyle(color: textColor),
          ),
          content: Text(passwordError, style: TextStyle(color: textColor)),
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
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = true;
      });
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
          title: Text(
            'Error en contraseña',
            style: TextStyle(color: textColor),
          ),
          content: const Text(
            'Las contraseñas no coinciden.',
            style: TextStyle(color: AppConstants.textDark),
          ),
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
      return;
    }

    // Mostrar overlay de carga
    LoadingOverlay.show(context, message: 'Validando datos...');

    try {
      // Validar datos con el backend (sin crear cuenta todavía)
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/userData');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dni': _dniController.text.trim(),
          'genero': _selectedGender!,
          'telefono': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // DNI válido - parsear datos del jugador
        final fullResponse = jsonDecode(response.body);

        debugPrint('DEBUG - Response recibida: $fullResponse');

        // Extraer el primer elemento de listaExistenciaFisica
        final lista = fullResponse['listaExistenciaFisica'] as List?;
        if (lista == null || lista.isEmpty) {
          LoadingOverlay.hide(context);
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
              title: Text('Error', style: TextStyle(color: textColor)),
              content: const Text(
                'No se encontraron datos para el DNI ingresado.',
                style: TextStyle(color: AppConstants.textDark),
              ),
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
          return;
        }

        final playerDataJson = lista[0] as Map<String, dynamic>;
        debugPrint('DEBUG - Primer elemento: $playerDataJson');

        // Parsear PlayerData desde la respuesta
        PlayerData? playerData;
        try {
          playerData = PlayerData.fromRegisterResponse(playerDataJson);
          debugPrint('DEBUG - PlayerData parseado: OK');
        } catch (e, stackTrace) {
          debugPrint('DEBUG - ERROR AL PARSEAR: $e');
          debugPrint('DEBUG - STACK: $stackTrace');
          playerData = null;
        }

        if (playerData != null) {
          // Agregar email y teléfono que no vienen en listaExistenciaFisica
          final updatedPlayerData = playerData.copyWith(
            correoElectronico: _emailController.text.trim(),
            telefono: _phoneController.text.trim(),
          );

          // Navegar a la pantalla de confirmación CON LOS DATOS DE REGISTRO
          Navigator.pushReplacement(
            context,
            SlideFadeRoute(
              page: ConfirmPlayerDataPage(
                playerData: updatedPlayerData,
                email: _emailController.text.trim(),
                username: _usernameController.text.trim(),
                password: _passwordController.text,
                dni: _dniController.text.trim(),
                telefono: _phoneController.text.trim(),
                genero: _selectedGender!,
              ),
            ),
          );
        } else {
          // Error al parsear los datos
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
              title: Text('Error', style: TextStyle(color: textColor)),
              content: const Text(
                'Error al procesar los datos. Por favor, contacta con soporte.',
                style: TextStyle(color: AppConstants.textDark),
              ),
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
      } else {
        // Error en la validación
        debugPrint('DEBUG - Error status: ${response.statusCode}');
        debugPrint('DEBUG - Error body: ${response.body}');
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final dialogBg = isDark
            ? AppConstants.darkAccent
            : AppConstants.lightDialogBg;
        final textColor = isDark
            ? AppConstants.textDark
            : AppConstants.lightLabelText;

        final errorData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: dialogBg,
            title: Text(
              'Error de validación',
              style: TextStyle(color: textColor),
            ),
            content: Text(
              errorData['message'] ?? 'No se pudieron validar los datos',
              style: TextStyle(color: textColor),
            ),
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
    } catch (e) {
      if (!mounted) return;

      LoadingOverlay.hide(context);
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final dialogBg = isDark
          ? AppConstants.darkAccent
          : AppConstants.lightDialogBg;
      final textColor = isDark
          ? AppConstants.textDark
          : AppConstants.lightLabelText;

      // Error inesperado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Error de conexión', style: TextStyle(color: textColor)),
          content: Text(
            'No se pudo conectar con el servidor: $e',
            style: TextStyle(color: textColor),
          ),
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
  }

  String? _validatePassword(String password) {
    // Al menos 8 caracteres
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Al menos una mayúscula
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe tener al menos una mayúscula';
    }

    // Al menos un número
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe tener al menos un número';
    }

    // Al menos un símbolo
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]'))) {
      return 'La contraseña debe tener al menos un símbolo';
    }

    // Detectar secuencias de caracteres repetidos (3 o más seguidos)
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return 'La contraseña no debe tener caracteres repetidos consecutivos';
    }

    // Detectar secuencias numéricas ascendentes/descendentes (123, 321, etc.)
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

    // Detectar secuencias alfabéticas (abc, xyz, cba, zyx, etc.)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGreen = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.colorScheme.onSurface;
    final accentColor = isDark
        ? AppConstants.borderDark
        : AppConstants.lightAccent;
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
          maxWidth: 700,
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
                    'Crear cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completa los datos para registrarte',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos y botón
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Nombre de Usuario
                      AppTextFormField(
                        label: 'Nombre de Usuario',
                        hint: 'Ingresa tu nombre de usuario',
                        controller: _usernameController,
                        hasError: _usernameError,
                        errorText: _usernameError
                            ? 'Nombre de usuario requerido'
                            : null,
                        onChanged: (value) {
                          if (_usernameError && value.isNotEmpty) {
                            setState(() => _usernameError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

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

                      // TextField Teléfono
                      AppTextFormField(
                        label: 'Teléfono',
                        hint: '1234567890',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hasError: _phoneError,
                        errorText: _phoneError ? 'Teléfono requerido' : null,
                        onChanged: (value) {
                          if (_phoneError && value.isNotEmpty) {
                            setState(() => _phoneError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // TextField Contraseña
                      AppPasswordField(
                        label: 'Contraseña',
                        hint: 'Crea tu contraseña',
                        controller: _passwordController,
                        hasError: _passwordError,
                        errorText: _passwordError
                            ? 'Contraseña inválida'
                            : null,
                        onChanged: (value) {
                          if (_passwordError && value.isNotEmpty) {
                            setState(() => _passwordError = false);
                          }
                          _validatePasswordLive();
                        },
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _passwordRules.entries.map((e) {
                          final ok = e.value;
                          return Row(
                            children: [
                              Icon(
                                ok ? Icons.check_circle : Icons.cancel,
                                size: 18,
                                color: ok
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: ok
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Botón para generar contraseña sugerida
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final email = _emailController.text.trim();
                            final dni = _dniController.text.trim();

                            if (email.isEmpty || dni.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Completa Email y DNI primero',
                                  ),
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
                              _passwordController.text = password;
                              _confirmPasswordController.text = password;
                              _passwordError = false;
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
                      const SizedBox(height: 16),

                      // TextField Repetir Contraseña
                      AppPasswordField(
                        label: 'Confirmar Contraseña',
                        hint: 'Repite tu contraseña',
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
                      const SizedBox(height: 16),

                      // Selector de Género
                      GenderSelector(
                        selectedGender: _selectedGender ?? 'M',
                        onGenderChanged: (gender) {
                          setState(() {
                            _selectedGender = gender;
                            _genderError = false;
                          });
                        },
                        primaryColor: primaryGreen,
                        backgroundColor: accentColor,
                      ),

                      const SizedBox(height: 28),

                      // Botón Registrarse
                      AppButton(
                        label: 'Crear cuenta',
                        onPressed: _validateAndRegister,
                        isLoading: _isLoading,
                        icon: Icons.person_add,
                      ),
                      const SizedBox(height: 20),

                      // Texto centrado debajo del botón
                      Center(
                        child: Text(
                          "LA CONTRASEÑA NO DEBE POSEER SECUENCIAS DE TEXTO NI NÚMEROS O CARACTERES REPETIDOS Y DEBE TENER AL MENOS 8 CARACTERES, UNA MAYUSCULA, UN NUMERO Y UN SIMBOLO",
                          style: TextStyle(color: textColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
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
  }
}
