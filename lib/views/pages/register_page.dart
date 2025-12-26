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

  // Terms and conditions acceptance flags
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _dataAccepted = false;

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
    // Check if all legal documents have been acknowledged
    if (!_termsAccepted || !_privacyAccepted || !_dataAccepted) {
      _showTermsDialog();
      return;
    }

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

      final body = {
        'dni': _dniController.text.trim(),
        'genero': _selectedGender!,
        'telefono': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      debugPrint('📡 POST → $url');
      debugPrint('📦 Body: $body');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      LoadingOverlay.hide(context);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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

  void _showTermsDialog() {
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
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: dialogBg,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con título
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.borderRadius),
                      topRight: Radius.circular(AppConstants.borderRadius),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppConstants.primaryGreen.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Documentos Legales',
                    style: TextStyle(
                      color: AppConstants.primaryGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Por favor, revisa y acepta los siguientes documentos:',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildLegalDocumentItem(
                            context,
                            title: 'Términos y Condiciones',
                            isAccepted: _termsAccepted,
                            onTap: () {
                              _openLegalDocument('Términos y Condiciones');
                              setDialogState(() {});
                            },
                            setDialogState: setDialogState,
                          ),
                          const SizedBox(height: 12),
                          _buildLegalDocumentItem(
                            context,
                            title: 'Políticas de Privacidad',
                            isAccepted: _privacyAccepted,
                            onTap: () {
                              _openLegalDocument('Políticas de Privacidad');
                              setDialogState(() {});
                            },
                            setDialogState: setDialogState,
                          ),
                          const SizedBox(height: 12),
                          _buildLegalDocumentItem(
                            context,
                            title: 'Uso de Datos Personales',
                            isAccepted: _dataAccepted,
                            onTap: () {
                              _openLegalDocument('Uso de Datos Personales');
                              setDialogState(() {});
                            },
                            setDialogState: setDialogState,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed:
                            (_termsAccepted &&
                                _privacyAccepted &&
                                _dataAccepted)
                            ? () {
                                Navigator.pop(context);
                                _proceedWithRegistration();
                              }
                            : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          backgroundColor:
                              (_termsAccepted &&
                                  _privacyAccepted &&
                                  _dataAccepted)
                              ? AppConstants.primaryGreen.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color:
                                (_termsAccepted &&
                                    _privacyAccepted &&
                                    _dataAccepted)
                                ? AppConstants.primaryGreen
                                : Colors.grey[400],
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalDocumentItem(
    BuildContext context, {
    required String title,
    required bool isAccepted,
    required VoidCallback onTap,
    required StateSetter setDialogState,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isAccepted
                ? AppConstants.primaryGreen
                : Colors.grey.withValues(alpha: 0.25),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          color: isAccepted
              ? AppConstants.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.circle_outlined,
              color: isAccepted ? AppConstants.primaryGreen : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAccepted ? '✓ Leído y aceptado' : '👁️ Tap para leer',
                    style: TextStyle(
                      color: isAccepted
                          ? AppConstants.primaryGreen
                          : Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLegalDocument(String documentType) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    // Map document types to their content (placeholder for now)
    final content = _getLegalDocumentContent(documentType);

    showDialog(
      context: context,
      builder: (context) => _LegalDocumentDialog(
        documentType: documentType,
        content: content,
        dialogBg: dialogBg,
        textColor: textColor,
        onAcknowledged: () {
          Navigator.pop(context);
          // Marcar el documento como leído
          setState(() {
            if (documentType == 'Términos y Condiciones') {
              _termsAccepted = true;
            } else if (documentType == 'Políticas de Privacidad') {
              _privacyAccepted = true;
            } else if (documentType == 'Uso de Datos Personales') {
              _dataAccepted = true;
            }
          });
        },
      ),
    );
  }

  String _getLegalDocumentContent(String documentType) {
    switch (documentType) {
      case 'Términos y Condiciones':
        return '''TÉRMINOS Y CONDICIONES

1. Objeto
El presente documento regula los términos bajo los cuales los usuarios (“Jugadores”) se afilian voluntariamente a la comunidad BoomBet (www.boombet-ar.com), administrada por WEST DIGITAL ALLIANCE SRL, en adelante “BoomBet”. BoomBet actúa como portal de afiliación e intermediario autorizado para registrar a sus miembros en casinos online y casas de apuestas legales que operen dentro de la República Argentina bajo licencias otorgadas por las autoridades competentes.

2. Afiliación y autorización
Al completar y enviar el formulario de registro, el Jugador:
  - Declara que los datos ingresados son reales, completos y verificables.
  - Acepta afiliarse a la comunidad BoomBet, participar en sus programas, beneficios, sorteos y promociones.
  - Autoriza expresamente a BoomBet a efectuar, en su nombre, en la actualidad y a futuro, los registros o afiliaciones en todos los casinos online y casas de apuestas legales con los que BoomBet mantenga convenios vigentes, incluyendo pero no limitándose a Bplay, Sportsbet y otros operadores licenciados.
  - Reconoce y acepta que dicha autorización implica también la aceptación, en su nombre, de los Términos y Condiciones, Políticas de Privacidad y normas de cada operador, conforme a su jurisdicción.
  - Reconoce y acepta que dicha autorización implica también la aceptación, en su nombre, de los Términos y Condiciones, Políticas de Privacidad y normas de cada operador, conforme a su jurisdicción.

3. Alcance de la representación
BoomBet realiza la gestión administrativa del registro de los Jugadores, sin intervenir en la operación, el juego ni la administración de fondos.
El Jugador entiende y acepta que:
  - Cada casino u operador es único responsable del manejo de cuentas, depósitos, retiros, promociones, límites de juego y cumplimiento normativo.
  - BoomBet no presta servicios de apuestas ni gestiona fondos, sino que actúa únicamente como intermediario de registro y beneficios.
  - Las condiciones de cada casino podrán variar y están sujetas a las políticas propias de cada operador y a la normativa provincial correspondiente.

4. Protección de datos personales
El Jugador autoriza a BoomBet a recopilar, almacenar, usar y transferir sus datos personales exclusivamente para:
  - Gestionar el proceso de afiliación a casinos y operadores asociados.
  - Ofrecer beneficios, sorteos y promociones vinculadas a la comunidad.
Los datos serán tratados conforme a la Ley 25.326 de Protección de Datos Personales y las políticas de privacidad publicadas en www.boombet-ar.com/form .

5. Gratuito y sin obligación
La afiliación a BoomBet es gratuita, legal y sin obligación de compra ni permanencia. El Jugador podrá solicitar su baja de la comunidad BoomBet en cualquier momento escribiendo a info@boombet-ar.com.

6. Bajas y cancelaciones
El Jugador entiende y acepta que:
  - BoomBet solo puede gestionar la baja de la comunidad BoomBet, lo que implica dejar de recibir beneficios, promociones o comunicaciones.
  - La baja de los casinos u operadores afiliados debe ser realizada directamente por el Jugador ante cada entidad, siguiendo los procedimientos establecidos por dichas plataformas.
  - BoomBet no tiene acceso ni autoridad para eliminar, suspender o modificar cuentas dentro de los casinos, ya que cada uno opera bajo su propia licencia y autonomía administrativa.

7. Responsabilidad limitada
BoomBet no asume responsabilidad por:
  - Interrupciones, suspensiones, bloqueos o decisiones tomadas por los casinos u operadores.
  - Errores, demoras o inconvenientes en las acreditaciones, retiros o promociones gestionadas por terceros.
  - Cualquier acción u omisión del Jugador dentro de las plataformas de apuestas.
BoomBet garantiza únicamente la correcta tramitación de las afiliaciones y la gestión de beneficios dentro de su propia comunidad.

8. Comunicaciones y promociones
El Jugador acepta recibir información y comunicaciones relacionadas con beneficios, eventos, novedades o sorteos de la comunidad BoomBet a través de correo electrónico, WhatsApp, Instagram u otros medios digitales. Podrá darse de baja de dichas comunicaciones en cualquier momento mediante los canales habilitados.

9. Modificaciones
BoomBet podrá modificar estos Términos y Condiciones cuando sea necesario.
Las actualizaciones serán publicadas en www.boombet-ar.com/form y entrarán en vigencia a partir de su publicación, considerándose aceptadas si el Jugador continúa participando en la comunidad.

10. Legislación aplicable
Estos Términos y Condiciones se rigen por las leyes de la República Argentina. Para cualquier controversia, las partes se someten a los tribunales ordinarios con jurisdicción en la Ciudad Autónoma de Buenos Aires.
''';
      case 'Políticas de Privacidad':
        return '''POLÍTICAS DE PRIVACIDAD

1. Alcance general
La presente Política de Privacidad complementa los Términos y Condiciones de Afiliación y establece cómo boombet protege la información personal de los usuarios de su comunidad. El solo hecho de registrarse o mantenerse afiliado implica la aceptación de esta política en su totalidad.

2. Finalidad del tratamiento
Los datos personales brindados por los Jugadores son utilizados exclusivamente para:
  - Gestionar su afiliación y registro en casinos online y casas de apuestas legales asociadas.
  - Brindar beneficios, promociones y sorteos dentro de la comunidad BoomBet.
  - Comunicarse con los Jugadores respecto de novedades, cambios y eventos.
  - Cumplir con obligaciones legales o requerimientos regulatorios.
BoomBet no realiza ningún otro tratamiento ajeno a estos fines ni comparte información con terceros fuera de los convenios operativos estrictamente necesarios.

3. Cesión a operadores asociados
El Jugador autoriza a BoomBet a transferir sus datos únicamente a casinos y operadores licenciados con los cuales mantenga acuerdos vigentes, a los fines de procesar su registro y habilitar su cuenta. Cada operador será responsable del uso que haga de dicha información conforme a sus propias políticas, las cuales el Jugador acepta al ser afiliado.

4. Seguridad de la información
BoomBet adopta medidas técnicas y administrativas razonables para preservar la confidencialidad e integridad de la información almacenada. No obstante, los usuarios reconocen que ningún sistema es infalible y liberan a BoomBet de toda responsabilidad por incidentes de seguridad que excedan su control razonable o dependan de terceros operadores.

5. Derechos del usuario
Los Jugadores podrán, en cualquier momento:
  - Acceder a los datos que BoomBet conserva sobre ellos.
  - Solicitar su actualización o corrección.
  - Pedir su eliminación o baja de la comunidad.
  - Revocar el consentimiento para el envío de comunicaciones promocionales.
Dichas solicitudes podrán realizarse mediante correo a info@boombet-ar.com, conforme a los plazos establecidos por la Ley 25.326.

6. Vigencia y modificaciones
BoomBet podrá actualizar esta Política de Privacidad para adaptarla a cambios normativos o tecnológicos. La versión vigente estará siempre disponible en esta misma página, reemplazando automáticamente a las anteriores.
''';
      case 'Uso de Datos Personales':
        return '''USO DE DATOS PERSONALES

1. Principios generales
BoomBet respeta los principios de licitud, finalidad, proporcionalidad, veracidad, seguridad y confidencialidad establecidos por la Ley 25.326 y las buenas prácticas internacionales (RGPD). El tratamiento de datos personales se realiza de manera transparente y con consentimiento informado.

2. Naturaleza de los datos tratados
BoomBet únicamente recopila los datos estrictamente necesarios para cumplir los fines detallados en los Términos y Condiciones y en la Política de Privacidad. Esto incluye información de identificación básica y, eventualmente, datos técnicos mínimos derivados del uso del sitio.

3. Almacenamiento y conservación
Los datos se almacenan en bases seguras administradas por BoomBet y/o proveedores tecnológicos que mantienen acuerdos de confidencialidad. Serán conservados durante el tiempo que dure la relación del usuario con BoomBet o mientras sea necesario para cumplir obligaciones legales o contractuales.

4. Cesión y confidencialidad
BoomBet no vende ni comercializa los datos personales de sus usuarios. Las únicas cesiones permitidas son las necesarias para ejecutar el proceso de afiliación o cumplir requerimientos legales o judiciales. Todo acceso o tratamiento por parte de terceros se rige por acuerdos de confidencialidad y uso limitado a la finalidad específica.

5. Ejercicio de derechos ARCO
Los usuarios pueden ejercer los derechos de Acceso, Rectificación, Cancelación y Oposición (ARCO) en cualquier momento enviando una solicitud formal a info@boombet-ar.com. BoomBet responderá dentro del plazo legal previsto por la normativa argentina.

6. Autoridad de control
El titular de los datos puede, en caso de disconformidad, dirigirse a la Agencia de Acceso a la Información Pública (www.argentina.gob.ar/aaip), organismo responsable del cumplimiento de la Ley 25.326 en la República Argentina.
''';
      default:
        return 'Contenido no disponible';
    }
  }

  void _proceedWithRegistration() async {
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

      final body = {
        'dni': _dniController.text.trim(),
        'genero': _selectedGender!,
        'telefono': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      debugPrint('📡 POST → $url');
      debugPrint('📦 Body: $body');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      LoadingOverlay.hide(context);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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

    // Detectar secuencias numéricas ascendentes/descendentes (dos o más: 78, 87, 123, 321, etc.)
    for (int i = 0; i < password.length - 1; i++) {
      final a = password[i];
      final b = password[i + 1];
      if (RegExp(r'[0-9]').hasMatch(a) && RegExp(r'[0-9]').hasMatch(b)) {
        final n1 = int.parse(a);
        final n2 = int.parse(b);
        if ((n2 - n1 == 1) || (n1 - n2 == 1)) {
          return 'La contraseña no debe tener secuencias numéricas';
        }
      }
    }

    // Detectar secuencias alfabéticas ascendentes/descendentes solo si son 3+ seguidas (abc, cba)
    for (int i = 0; i < password.length - 2; i++) {
      final a = password[i];
      final b = password[i + 1];
      final c = password[i + 2];
      if (RegExp(r'[a-zA-Z]').hasMatch(a) &&
          RegExp(r'[a-zA-Z]').hasMatch(b) &&
          RegExp(r'[a-zA-Z]').hasMatch(c)) {
        final c1 = a.toLowerCase().codeUnitAt(0);
        final c2 = b.toLowerCase().codeUnitAt(0);
        final c3 = c.toLowerCase().codeUnitAt(0);
        final bool asc = (c2 - c1 == 1) && (c3 - c2 == 1);
        final bool desc = (c1 - c2 == 1) && (c2 - c3 == 1);
        if (asc || desc) {
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

/// Widget de diálogo para documentos legales con detección de scroll
class _LegalDocumentDialog extends StatefulWidget {
  final String documentType;
  final String content;
  final Color dialogBg;
  final Color textColor;
  final VoidCallback onAcknowledged;

  const _LegalDocumentDialog({
    required this.documentType,
    required this.content,
    required this.dialogBg,
    required this.textColor,
    required this.onAcknowledged,
  });

  @override
  State<_LegalDocumentDialog> createState() => _LegalDocumentDialogState();
}

class _LegalDocumentDialogState extends State<_LegalDocumentDialog> {
  late ScrollController _scrollController;
  bool _isScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Evaluar inmediatamente por si el contenido ya cabe en pantalla (maxScrollExtent == 0)
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrolledFlag());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateScrolledFlag();
  }

  void _updateScrolledFlag() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;

    // Si el contenido ya entra en pantalla, consideramos como leído.
    final isAtBottom = maxExtent <= 0 || offset >= maxExtent - 50;

    if (isAtBottom != _isScrolledToBottom) {
      setState(() {
        _isScrolledToBottom = isAtBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: widget.dialogBg,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con título
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius),
                  topRight: Radius.circular(AppConstants.borderRadius),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                widget.documentType,
                style: TextStyle(
                  color: AppConstants.primaryGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Content con scroll controller
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    widget.content,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 15,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            // Indicador de scroll
            if (!_isScrolledToBottom)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: AppConstants.primaryGreen.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Desliza para continuar',
                      style: TextStyle(
                        color: AppConstants.primaryGreen.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: TextButton(
                onPressed: _isScrolledToBottom ? widget.onAcknowledged : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Entendido',
                  style: TextStyle(
                    color: _isScrolledToBottom
                        ? AppConstants.primaryGreen
                        : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
