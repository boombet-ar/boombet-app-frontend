import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/notification_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;

class ConfirmPlayerDataPage extends StatefulWidget {
  final PlayerData playerData;
  final String email;
  final String username;
  final String password;
  final String dni;
  final String telefono;
  final String genero;
  final bool preview;

  const ConfirmPlayerDataPage({
    super.key,
    required this.playerData,
    required this.email,
    required this.username,
    required this.password,
    required this.dni,
    required this.telefono,
    required this.genero,
    this.preview = false,
  });

  @override
  State<ConfirmPlayerDataPage> createState() => _ConfirmPlayerDataPageState();
}

class _ConfirmPlayerDataPageState extends State<ConfirmPlayerDataPage> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _estadoCivilController;

  bool _isLoading = false;
  String? _selectedGenero;
  final List<String> _generOptions = ['Masculino', 'Femenino'];

  String _normalizarGenero(String genero) {
    if (genero == 'M') return 'Masculino';
    if (genero == 'F') return 'Femenino';
    return genero;
  }

  @override
  void initState() {
    super.initState();
    final data = widget.playerData;

    _nombreController = TextEditingController(text: data.nombre);
    _apellidoController = TextEditingController(text: data.apellido);
    _correoController = TextEditingController(text: data.correoElectronico);
    _telefonoController = TextEditingController(text: data.telefono);
    _estadoCivilController = TextEditingController(text: data.estadoCivil);
    final generoNormalizado = _normalizarGenero(data.sexo);
    if (_generOptions.contains(generoNormalizado)) {
      _selectedGenero = generoNormalizado;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _estadoCivilController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmarDatos() async {
    if (widget.preview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview: acción deshabilitada (solo visual).'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isLoading) return; // Prevenir doble tap

    // Validar Nombre
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu nombre.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (nombre.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 2 caracteres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar Apellido
    final apellido = _apellidoController.text.trim();
    if (apellido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu apellido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (apellido.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El apellido debe tener al menos 2 caracteres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar Género
    if (_selectedGenero == null || _selectedGenero!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona tu género.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar Estado Civil
    final estadoCivil = _estadoCivilController.text.trim();
    if (estadoCivil.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa tu estado civil.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar formato de email
    final email = _correoController.text.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un email válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar formato de teléfono
    final telefono = _telefonoController.text.trim();
    if (!RegExp(r'^\d{10,15}$').hasMatch(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El teléfono debe contener solo números (10-15 dígitos).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    LoadingOverlay.show(context, message: 'Creando cuenta...');

    try {
      // Crear PlayerData actualizado (solo campos editables)
      final updatedData = widget.playerData.copyWith(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correoElectronico: email,
        telefono: telefono,
        estadoCivil: _estadoCivilController.text.trim(),
        sexo: _selectedGenero ?? '',
      );

      debugPrint('PASO 1: Preparando payload para /register...');

      // Preparar payload con estructura exacta requerida por el backend
      final payload = {
        'websocketLink': WebSocketUrlService.generateAffiliationUrl(),
        'playerData': {
          'nombre': updatedData.nombre,
          'apellido': updatedData.apellido,
          'email': email,
          'telefono': telefono,
          'genero': _selectedGenero ?? 'Masculino',
          'dni': widget.dni,
          'cuit': updatedData.cuil,
          'calle': updatedData.calle,
          'numCalle': updatedData.numCalle,
          'provincia': updatedData.provincia,
          'ciudad': updatedData.localidad,
          'cp': updatedData.cp?.toString() ?? '',
          'user': widget.username,
          'password': widget.password,
          'fecha_nacimiento': updatedData.fechaNacimiento,
          'est_civil': updatedData.estadoCivil,
        },
      };

      debugPrint('PASO 2: Enviando POST a /api/users/auth/register');
      debugPrint('Payload: ${jsonEncode(payload)}');

      // Enviar POST al endpoint de registro
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/register');
      debugPrint('URL: $url');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            AppConstants.apiTimeout,
            onTimeout: () => http.Response('Request timeout', 408),
          );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ REGISTRO EXITOSO - El token se envía por mail
        debugPrint('✅ Registro exitoso. Token enviado por email.');
        debugPrint('Response: ${response.body}');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Verifica tu email para continuar...'),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 2),
          ),
        );

        // Pequeño delay para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Extraer los datos que devuelve el backend (estos son los datos confirmados)
        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
          debugPrint('📦 [REG-1] Datos extraídos de la respuesta del backend');
          debugPrint('📦 [REG-2] responseData: $responseData');
        } catch (e) {
          debugPrint('⚠️ [REG-3] No se pudo parsear respuesta: $e');
        }

        // Intentar guardar el JWT que devuelva el backend (si existe)
        String? tokenFromResponse;
        try {
          final maybeToken = responseData['token'] ?? responseData['jwt'];
          if (maybeToken is String && maybeToken.isNotEmpty) {
            tokenFromResponse = maybeToken;
            await TokenService.saveToken(maybeToken);
            debugPrint('🔐 [REG-TOKEN] JWT guardado tras registro');
          }
        } catch (e) {
          debugPrint('⚠️ [REG-TOKEN] No se pudo guardar token: $e');
        }

        // Enviar el FCM token al backend para habilitar push desde el inicio
        try {
          final existingToken = await TokenService.getToken();
          final hasAuth =
              (tokenFromResponse != null && tokenFromResponse.isNotEmpty) ||
              (existingToken != null && existingToken.isNotEmpty);

          if (hasAuth) {
            final sent = await const NotificationService()
                .saveFcmTokenToBackend();
            debugPrint('🔔 [REG-FCM] FCM token enviado al backend: $sent');
          } else {
            debugPrint(
              '⚠️ [REG-FCM] No hay JWT disponible para enviar FCM token',
            );
          }
        } catch (e) {
          debugPrint('⚠️ [REG-FCM] Error enviando FCM token: $e');
        }

        // Guardar datos en notifiers para acceso posterior en EmailConfirmationPage
        // Usar los datos devueltos por el backend si están disponibles, si no usar updatedData
        final playerDataFromResponse = responseData['playerData'];

        if (playerDataFromResponse != null) {
          debugPrint(
            '✅ [REG-4] Guardando datos devueltos por el backend en notifiers',
          );
          await saveAffiliationData(
            playerData: updatedData,
            email: playerDataFromResponse['email'] ?? email,
            username: playerDataFromResponse['user'] ?? widget.username,
            password: playerDataFromResponse['password'] ?? widget.password,
            dni: playerDataFromResponse['dni'] ?? widget.dni,
            telefono: playerDataFromResponse['telefono'] ?? telefono,
            genero: playerDataFromResponse['genero'] ?? widget.genero,
          );
        } else {
          debugPrint(
            '⚠️ [REG-5] Backend no devolvió playerData, usando datos del formulario',
          );
          await saveAffiliationData(
            playerData: updatedData,
            email: email,
            username: widget.username,
            password: widget.password,
            dni: widget.dni,
            telefono: telefono,
            genero: widget.genero,
          );
        }

        debugPrint(
          '✅ [REG-6] Datos guardados en notifiers Y SharedPreferences para afiliación',
        );
        debugPrint(
          '📋 [REG-7] affiliationPlayerDataNotifier: ${affiliationPlayerDataNotifier.value}',
        );
        debugPrint(
          '📋 [REG-8] affiliationEmailNotifier: ${affiliationEmailNotifier.value}',
        );
        debugPrint(
          '📋 [REG-9] affiliationUsernameNotifier: ${affiliationUsernameNotifier.value}',
        );

        // Navegar a EmailConfirmationPage sin token (se obtendrá del link del mail)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailConfirmationPage(
              playerData: updatedData,
              email: email,
              username: widget.username,
              password: widget.password,
              dni: widget.dni,
              telefono: telefono,
              genero: widget.genero,
              verificacionToken: '', // Sin token aún, lo tendrá del mail
            ),
          ),
        );
      } else if (response.statusCode == 409) {
        // ❌ ERROR 409 - Usuario/Email ya existe
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El usuario o email ya están registrados. Por favor, intenta con otros datos.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // ❌ OTROS ERRORES
        if (!mounted) return;

        String errorMessage = 'Error al crear la cuenta';
        try {
          final errorData = jsonDecode(response.body);
          final backendMsg = (errorData['message'] as String?) ?? '';

          // Mapear errores conocidos a mensajes claros
          if (backendMsg.toLowerCase().contains('duplicate key') ||
              backendMsg.contains('jugadores_dni_key')) {
            errorMessage =
                'El DNI ya está registrado. Usá un DNI diferente o recuperá acceso.';
          } else {
            errorMessage = backendMsg.isNotEmpty ? backendMsg : errorMessage;
          }
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR CRÍTICO en _onConfirmarDatos: $e');

      if (!mounted) return;

      LoadingOverlay.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error crítico: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.playerData;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black87 : AppConstants.lightBg;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    final header = Column(
      children: [
        Text(
          'Confirmá tus datos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Verificá que todos tus datos sean correctos',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : AppConstants.lightHintText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: ResponsiveWrapper(
        maxWidth: kIsWeb ? 1200 : 800,
        child: kIsWeb
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    header,
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 920 ? 2 : 1;
                        final cardPadding = EdgeInsets.all(
                          columns == 2 ? 18.0 : 16.0,
                        );

                        return MasonryGridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Datos editables',
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildEditableField(
                                        context,
                                        'Nombre',
                                        _nombreController,
                                      ),
                                      _buildEditableField(
                                        context,
                                        'Apellido',
                                        _apellidoController,
                                      ),
                                      _buildGeneroDropdown(context),
                                      _buildEditableField(
                                        context,
                                        'Estado Civil',
                                        _estadoCivilController,
                                      ),
                                    ],
                                  ),
                                );
                              case 1:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Contacto',
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildEditableField(
                                        context,
                                        'Correo Electrónico',
                                        _correoController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      _buildEditableField(
                                        context,
                                        'Teléfono',
                                        _telefonoController,
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ),
                                );
                              case 2:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Datos personales',
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildReadOnlyField(
                                        context,
                                        'DNI',
                                        data.dni,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'CUIL',
                                        data.cuil,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Fecha de Nacimiento',
                                        data.fechaNacimiento,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Año de Nacimiento',
                                        data.anioNacimiento,
                                      ),
                                      if (data.edad != null)
                                        _buildReadOnlyField(
                                          context,
                                          'Edad',
                                          data.edad.toString(),
                                        ),
                                    ],
                                  ),
                                );
                              case 3:
                              default:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Dirección',
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildReadOnlyField(
                                        context,
                                        'Calle',
                                        data.calle,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Número',
                                        data.numCalle,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Localidad',
                                        data.localidad,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Provincia',
                                        data.provincia,
                                      ),
                                      if (data.cp != null)
                                        _buildReadOnlyField(
                                          context,
                                          'Código Postal',
                                          data.cp.toString(),
                                        ),
                                    ],
                                  ),
                                );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onConfirmarDatos,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Confirmar datos',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  header,
                  const SizedBox(height: 32),

                  // --------- DATOS PERSONALES ---------
                  const Text(
                    'Datos Personales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildReadOnlyField(context, 'DNI', data.dni),
                  _buildReadOnlyField(context, 'CUIL', data.cuil),
                  _buildReadOnlyField(
                    context,
                    'Fecha de Nacimiento',
                    data.fechaNacimiento,
                  ),
                  _buildReadOnlyField(
                    context,
                    'Año de Nacimiento',
                    data.anioNacimiento,
                  ),
                  if (data.edad != null)
                    _buildReadOnlyField(context, 'Edad', data.edad.toString()),
                  const SizedBox(height: 16),

                  _buildEditableField(context, 'Nombre', _nombreController),
                  _buildEditableField(context, 'Apellido', _apellidoController),
                  _buildGeneroDropdown(context),
                  _buildEditableField(
                    context,
                    'Estado Civil',
                    _estadoCivilController,
                  ),

                  const SizedBox(height: 24),

                  // --------- CONTACTO ---------
                  const Text(
                    'Contacto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    context,
                    'Correo Electrónico',
                    _correoController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildEditableField(
                    context,
                    'Teléfono',
                    _telefonoController,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),

                  // --------- DIRECCIÓN ---------
                  Text(
                    'Dirección',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildReadOnlyField(context, 'Calle', data.calle),
                  _buildReadOnlyField(context, 'Número', data.numCalle),
                  _buildReadOnlyField(context, 'Localidad', data.localidad),
                  _buildReadOnlyField(context, 'Provincia', data.provincia),
                  if (data.cp != null)
                    _buildReadOnlyField(
                      context,
                      'Código Postal',
                      data.cp.toString(),
                    ),

                  const SizedBox(height: 32),

                  // --------- BOTÓN CONFIRMAR ---------
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onConfirmarDatos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Confirmar datos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _buildWebSectionCard({
    required BuildContext context,
    required String title,
    required EdgeInsets padding,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    final borderColor = primaryGreen.withValues(alpha: 0.35);
    final cardBg = isDark ? const Color(0xFF111111) : Colors.white;
    final titleColor = primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white60 : AppConstants.lightLabelText;
    final labelColor = isDark ? Colors.white54 : AppConstants.lightHintText;
    final fillColor = isDark
        ? const Color(0xFF2A2A2A)
        : AppConstants.lightInputBg;
    final borderColor = isDark ? Colors.white24 : AppConstants.lightInputBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        readOnly: true,
        enabled: false,
        controller: TextEditingController(text: value),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    final fillColor = isDark
        ? const Color(0xFF1A1A1A)
        : AppConstants.lightInputBg;
    final textColor = isDark ? Colors.white : AppConstants.lightLabelText;
    final labelColor = isDark ? Colors.white70 : AppConstants.lightLabelText;
    final borderColor = isDark ? primaryGreen : AppConstants.lightInputBorder;
    final focusedBorderColor = isDark
        ? primaryGreen
        : AppConstants.lightInputBorderFocus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        label: 'Campo de $label',
        hint: 'Puedes editar este campo',
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: labelColor),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusedBorderColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  // Construir dropdown de género
  Widget _buildGeneroDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    final fillColor = isDark
        ? const Color(0xFF1A1A1A)
        : AppConstants.lightInputBg;
    final textColor = isDark ? Colors.white : AppConstants.lightLabelText;
    final labelColor = isDark ? Colors.white70 : AppConstants.lightLabelText;
    final borderColor = isDark ? primaryGreen : AppConstants.lightInputBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        label: 'Campo de Sexo',
        hint: 'Puedes seleccionar tu sexo',
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Sexo',
            labelStyle: TextStyle(color: labelColor),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
          ),
          child: DropdownButton<String>(
            value: _selectedGenero,
            hint: Text(
              'Selecciona tu sexo',
              style: TextStyle(color: labelColor),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: fillColor,
            style: TextStyle(color: textColor, fontSize: 16),
            items: _generOptions.map((String genero) {
              return DropdownMenuItem<String>(
                value: genero,
                child: Text(genero),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGenero = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
