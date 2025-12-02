import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConfirmPlayerDataPage extends StatefulWidget {
  final PlayerData playerData;
  final String email;
  final String username;
  final String password;
  final String dni;
  final String telefono;
  final String genero;

  const ConfirmPlayerDataPage({
    super.key,
    required this.playerData,
    required this.email,
    required this.username,
    required this.password,
    required this.dni,
    required this.telefono,
    required this.genero,
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
  late TextEditingController _sexoController;

  bool _isLoading = false;

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
    _sexoController = TextEditingController(text: data.sexo);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _estadoCivilController.dispose();
    _sexoController.dispose();
    super.dispose();
  }

  Future<void> _onConfirmarDatos() async {
    if (_isLoading) return; // Prevenir doble tap

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
        sexo: _sexoController.text.trim(),
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
          'genero': _normalizarGenero(widget.genero),
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
          errorMessage = errorData['message'] ?? errorMessage;
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: ResponsiveWrapper(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
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
            _buildEditableField(context, 'Sexo', _sexoController),
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
              _buildReadOnlyField(context, 'Código Postal', data.cp.toString()),

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
}
