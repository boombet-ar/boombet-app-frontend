import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/views/pages/limited_home_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
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

  final AffiliationService _affiliationService = AffiliationService();
  bool _isLoading = false;

  String _normalizarGenero(String genero) {
    if (genero == 'M') return 'Masculino';
    if (genero == 'F') return 'Femenino';
    return genero;
  }

  String _generateWebSocketUrl() {
    final baseUrl = ApiConfig.baseUrl;
    final wsUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    return '$wsUrl/affiliation/$uniqueId';
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
    _affiliationService.dispose();
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

    setState(() {
      _isLoading = true;
    });

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

      print('PASO 1: Generando WebSocket URL...');

      // Generar URL del WebSocket
      final wsUrl = _generateWebSocketUrl();
      print('WebSocket URL: $wsUrl');

      print('PASO 2: Preparando payload...');

      // Preparar payload con campos en nivel raíz + playerData anidado
      final payload = {
        // Campos requeridos en nivel raíz
        'email': widget.email,
        'telefono': widget.telefono,
        'genero': widget.genero, // Usar el valor original M/F
        'dni': widget.dni,
        'username': widget.username,
        'password': widget.password,
        // playerData con todos los campos
        'playerData': {
          'nombre': updatedData.nombre,
          'apellido': updatedData.apellido,
          'email': widget.email,
          'telefono': widget.telefono,
          'genero': _normalizarGenero(widget.genero),
          'fecha_nacimiento': updatedData.fechaNacimiento,
          'dni': widget.dni,
          'cuit': updatedData.cuil,
          'est_civil': updatedData.estadoCivil,
          'calle': updatedData.calle,
          'numCalle': updatedData.numCalle,
          'provincia': updatedData.provincia,
          'ciudad': updatedData.localidad,
          'cp': updatedData.cp?.toString() ?? '',
          'user': widget.username,
          'password': widget.password,
        },
        'websocketLink': wsUrl,
      };

      print('PASO 3: Enviando POST a /api/users/auth/register');
      print('Payload: ${jsonEncode(payload)}');

      // Enviar POST al endpoint de registro
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/register');
      print('URL: $url');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('Request timeout', 408),
          );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final affiliationResult =
          response.statusCode == 200 || response.statusCode == 201
          ? {'success': true, 'message': 'Registro exitoso'}
          : {
              'success': false,
              'message': 'Error ${response.statusCode}: ${response.body}',
            };

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (affiliationResult['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Iniciando afiliación...'),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 2),
          ),
        );

        // Navegar a LimitedHomePage pasando el servicio de afiliación
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LimitedHomePage(affiliationService: _affiliationService),
          ),
        );
      } else {
        if (!mounted) return;

        // Error al iniciar afiliación (pero la cuenta ya está creada)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              affiliationResult['message']?.toString() ??
                  'Error al iniciar afiliación',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('ERROR CRÍTICO en _onConfirmarDatos: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

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
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Scaffold(
      backgroundColor: Colors.black87,
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
            const Text(
              'Confirmá tus datos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Verificá que todos tus datos sean correctos',
              style: TextStyle(fontSize: 14, color: Colors.white70),
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

            _buildReadOnlyField('DNI', data.dni),
            _buildReadOnlyField('CUIL', data.cuil),
            _buildReadOnlyField('Fecha de Nacimiento', data.fechaNacimiento),
            _buildReadOnlyField('Año de Nacimiento', data.anioNacimiento),
            if (data.edad != null)
              _buildReadOnlyField('Edad', data.edad.toString()),

            const SizedBox(height: 16),

            _buildEditableField('Nombre', _nombreController),
            _buildEditableField('Apellido', _apellidoController),
            _buildEditableField('Sexo', _sexoController),
            _buildEditableField('Estado Civil', _estadoCivilController),

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
              'Correo Electrónico',
              _correoController,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildEditableField(
              'Teléfono',
              _telefonoController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),

            // --------- DIRECCIÓN ---------
            const Text(
              'Dirección',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 16),

            _buildReadOnlyField('Calle', data.calle),
            _buildReadOnlyField('Número', data.numCalle),
            _buildReadOnlyField('Localidad', data.localidad),
            _buildReadOnlyField('Provincia', data.provincia),
            if (data.cp != null)
              _buildReadOnlyField('Código Postal', data.cp.toString()),

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

  Widget _buildReadOnlyField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        readOnly: true,
        enabled: false,
        controller: TextEditingController(text: value),
        style: const TextStyle(color: Colors.white60),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        label: 'Campo de $label',
        hint: 'Puedes editar este campo',
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
