import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/password_generator_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/confirm_player_data_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    // 🧪 DATOS DE TEST PRE-CARGADOS (comentar para producción)
    _usernameController = TextEditingController(text: 'test');
    _emailController = TextEditingController(text: 'test@gmail.com');
    _dniController = TextEditingController(text: '45614451');
    _phoneController = TextEditingController(text: '1121895575');
    _passwordController = TextEditingController(text: 'Test124!');
    _confirmPasswordController = TextEditingController(text: 'Test124!');
    _selectedGender = 'M'; // Masculino
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
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
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

    // Validar formato de teléfono (solo números, 10-15 dígitos)
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^\d{10,15}$').hasMatch(phone)) {
      setState(() {
        _phoneError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Teléfono inválido',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'El teléfono debe contener solo números y tener entre 10 y 15 dígitos.',
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

    // Validar formato de DNI (solo números, 7-8 dígitos)
    final dni = _dniController.text.trim();
    if (!RegExp(r'^\d{7,8}$').hasMatch(dni)) {
      setState(() {
        _dniError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'DNI inválido',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'El DNI debe contener solo números y tener 7 u 8 dígitos.',
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

    // Validar formato de username (mínimo 4 caracteres, alfanumérico, sin espacios)
    final username = _usernameController.text.trim();
    if (username.length < 4 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _usernameError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Usuario inválido',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
          content: const Text(
            'El usuario debe tener mínimo 4 caracteres, solo letras, números y guión bajo (_).',
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

        print('DEBUG - Response recibida: $fullResponse');

        // Extraer el primer elemento de listaExistenciaFisica
        final lista = fullResponse['listaExistenciaFisica'] as List?;
        if (lista == null || lista.isEmpty) {
          LoadingOverlay.hide(context);

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Error',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              content: const Text(
                'No se encontraron datos para el DNI ingresado.',
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

        final playerDataJson = lista[0] as Map<String, dynamic>;
        print('DEBUG - Primer elemento: $playerDataJson');

        // Parsear PlayerData desde la respuesta
        PlayerData? playerData;
        try {
          playerData = PlayerData.fromRegisterResponse(playerDataJson);
          print('DEBUG - PlayerData parseado: OK');
        } catch (e, stackTrace) {
          print('DEBUG - ERROR AL PARSEAR: $e');
          print('DEBUG - STACK: $stackTrace');
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Error',
                style: TextStyle(color: Color(0xFFE0E0E0)),
              ),
              content: const Text(
                'Error al procesar los datos. Por favor, contacta con soporte.',
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
        // Error en la validación
        print('DEBUG - Error status: ${response.statusCode}');
        print('DEBUG - Error body: ${response.body}');

        final errorData = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Error de validación',
              style: TextStyle(color: Color(0xFFE0E0E0)),
            ),
            content: Text(
              errorData['message'] ?? 'No se pudieron validar los datos',
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

  void _validatePasswordLive() {
    final pw = _passwordController.text;

    setState(() {
      _passwordRules["8+ caracteres"] = pw.length >= 8;
      _passwordRules["1 mayúscula"] = pw.contains(RegExp(r"[A-Z]"));
      _passwordRules["1 número"] = pw.contains(RegExp(r"[0-9]"));
      _passwordRules["1 símbolo"] = pw.contains(
        RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]'),
      );
      _passwordRules["Sin repetidos"] = !RegExp(r"(.)\1{2,}").hasMatch(pw);

      // Secuencias tipo 123, abc
      bool hasSeq = false;
      for (int i = 0; i < pw.length - 2; i++) {
        if (pw.codeUnitAt(i + 1) == pw.codeUnitAt(i) + 1 &&
            pw.codeUnitAt(i + 2) == pw.codeUnitAt(i) + 2) {
          hasSeq = true;
        }
      }

      _passwordRules["Sin secuencias"] = !hasSeq;
    });
  }

  Widget _genderOption(String value, IconData icon) {
    final selected = _selectedGender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = value;
            _genderError = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.greenAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.black : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                value == "M" ? "Masculino" : "Femenino",
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos y botón
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TextField Nombre de Usuario
                      Semantics(
                        label: 'Campo de nombre de usuario',
                        hint: 'Ingresa tu nombre de usuario',
                        child: TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          enableInteractiveSelection: true,
                          style: TextStyle(color: textColor),
                          onChanged: (value) {
                            if (_usernameError && value.isNotEmpty) {
                              setState(() => _usernameError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Nombre de usuario',
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF808080)
                                  : const Color(0xFF6C6C6C),
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _usernameError ? Colors.red : primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _usernameError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _usernameError
                                    ? Colors.red
                                    : borderColor,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                              borderSide: BorderSide(
                                color: _usernameError
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
                      const SizedBox(height: 16),

                      // TextField Email
                      Semantics(
                        label: 'Campo de correo electrónico',
                        hint: 'Ingresa tu dirección de email',
                        child: TextField(
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
                      ),
                      const SizedBox(height: 16),

                      // TextField DNI
                      Semantics(
                        label: 'Campo de DNI',
                        hint: 'Ingresa tu número de documento',
                        child: TextField(
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
                      ),
                      const SizedBox(height: 16),

                      // TextField Teléfono
                      Semantics(
                        label: 'Campo de teléfono',
                        hint: 'Ingresa tu número de teléfono',
                        child: TextField(
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
                      ),
                      const SizedBox(height: 16),

                      // TextField Contraseña
                      Semantics(
                        label: 'Campo de contraseña',
                        hint: 'Ingresa tu contraseña',
                        obscured: true,
                        child: TextField(
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
                      Semantics(
                        label: 'Campo de confirmación de contraseña',
                        hint: 'Vuelve a ingresar tu contraseña',
                        obscured: true,
                        child: TextField(
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
                      ),
                      const SizedBox(height: 16),

                      // Selector de Género
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _genderError
                                ? Colors.red
                                : primaryGreen.withOpacity(0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: accentColor,
                        ),
                        child: Row(
                          children: [
                            _genderOption("M", Icons.male),
                            _genderOption("F", Icons.female),
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
//http://localhost:8080/api/auth/startaffiliate
//Para el websocket: devolver un json con la siguiente estructura:
//{
// "playerData" : { ... },
// "websocketlink" : ""
//Terminar de configurar conexion del websocket en el frontend y backend
//Revisar api de startaffiliate
