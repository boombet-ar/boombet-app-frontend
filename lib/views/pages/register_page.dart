import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/password_generator_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/confirm_player_data_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late TextEditingController _emailController;
  late TextEditingController _dniController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _emailError = false;
  bool _dniError = false;
  bool _phoneError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;
  bool _isLoading = false;
  String? _selectedGender;
  bool _genderError = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _dniController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    if (!email.contains('@')) return false;
    if (email.indexOf('@') == 0) return false;
    final parts = email.split('@');
    if (parts.length != 2 || parts[1].isEmpty) return false;
    if (!parts[1].contains('.')) return false;
    final domainParts = parts[1].split('.');
    if (domainParts.any((part) => part.isEmpty)) return false;
    return true;
  }

  void _validateAndRegister() async {
    setState(() {
      _emailError = _emailController.text.trim().isEmpty;
      _dniError = _dniController.text.trim().isEmpty;
      _phoneError = _phoneController.text.trim().isEmpty;
      _passwordError = _passwordController.text.trim().isEmpty;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty;
      _genderError = _selectedGender == null;
    });

    if (_emailError ||
        _dniError ||
        _phoneError ||
        _passwordError ||
        _confirmPasswordError ||
        _genderError) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Campos incompletos',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'Por favor, completa todos los campos obligatorios.',
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

    // Validar formato de email
    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailError = true;
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
            'Por favor, ingresa un email válido (ejemplo: usuario@ejemplo.com).',
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

    // Validar fortaleza de contraseña
    String? passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      setState(() {
        _passwordError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Contraseña inválida',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: Text(
            passwordError,
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
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Error en contraseña',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'Las contraseñas no coinciden.',
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
      // Llamar al servicio de registro
      final result = await _authService.register(
        _emailController.text.trim(),
        _dniController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text,
        _selectedGender!,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Registro exitoso - parsear datos del jugador
        final fullResponse = result['data'];

        // Extraer el token
        final token = fullResponse['token'] as String?;

        // Guardar el token
        if (token != null) {
          await TokenService.saveToken(token);
        }

        // Parsear PlayerData desde la respuesta
        final playerService = PlayerService();
        final playerData = playerService.parsePlayerDataFromRegisterResponse(
          fullResponse,
        );

        if (playerData != null) {
          // Agregar email y teléfono que no vienen en listaExistenciaFisica
          final updatedPlayerData = playerData.copyWith(
            correoElectronico: _emailController.text.trim(),
            telefono: _phoneController.text.trim(),
          );

          // Navegar a la pantalla de confirmación
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPlayerDataPage(
                playerData: updatedPlayerData,
                token: token,
              ),
            ),
          );
        } else {
          // Error al parsear los datos
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Error',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              content: const Text(
                'Error al procesar los datos del registro. Por favor, contacta con soporte.',
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
        }
      } else {
        // Error en el registro
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Error en el registro',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
            content: Text(
              result['message'] ?? 'No se pudo completar el registro',
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
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos y botón
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

                      // TextField Teléfono
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          if (_phoneError && value.isNotEmpty) {
                            setState(() => _phoneError = false);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Número de teléfono',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF808080)
                                : const Color(0xFF6C6C6C),
                          ),
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: _phoneError ? Colors.red : primaryGreen,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _phoneError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _phoneError ? Colors.red : borderColor,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            borderSide: BorderSide(
                              color: _phoneError ? Colors.red : primaryGreen,
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
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
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
                      const SizedBox(height: 16),

                      // TextField Repetir Contraseña
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
                          hintText: 'Repetir contraseña',
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
                      const SizedBox(height: 16),

                      // Selector de Género
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _genderError ? Colors.red : borderColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(borderRadius),
                          color: accentColor,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Icon(
                                Icons.wc,
                                color: _genderError ? Colors.red : primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: Text(
                                        'Masculino',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      value: 'M',
                                      groupValue: _selectedGender,
                                      activeColor: primaryGreen,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value;
                                          _genderError = false;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: Text(
                                        'Femenino',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      value: 'F',
                                      groupValue: _selectedGender,
                                      activeColor: primaryGreen,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value;
                                          _genderError = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botón Registrarse
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
                          onPressed: _isLoading ? null : _validateAndRegister,
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
                                    const Icon(Icons.person_add, size: 22),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Crear cuenta',
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

//http://localhost:8080/api/auth/register
