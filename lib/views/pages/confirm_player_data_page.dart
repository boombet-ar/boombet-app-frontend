import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/limited_home_page.dart';
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

  final AffiliationService _affiliationService = AffiliationService();
  bool _isLoading = false;

  String _normalizarGenero(String genero) {
    if (genero == 'M') return 'Masculino';
    if (genero == 'F') return 'Femenino';
    return genero;
  }

  String _generateWebSocketUrl() {
    // 🔌 Generar URL del WebSocket apuntando al servidor del FRONTEND (ngrok)
    // Esta es la URL donde el backend enviará los mensajes de afiliación

    // Convertir http/https a ws/wss para WebSocket
    final baseUrl = ApiConfig.baseUrl;
    var wsBaseUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    if (wsBaseUrl.endsWith('/api')) {
      wsBaseUrl = wsBaseUrl.substring(0, wsBaseUrl.length - 4);
    }

    // Generar ID único basado en timestamp
    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // Retornar URL completa del WebSocket
    return '$wsBaseUrl/affiliation/$uniqueId';
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
    //_affiliationService.dispose();
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

    LoadingOverlay.show(context, message: 'Creando cuenta y afiliando...');

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

      // Preparar payload con estructura exacta requerida por el backend
      final payload = {
        'websocketLink': wsUrl,
        'playerData': {
          'nombre': updatedData.nombre,
          'apellido': updatedData.apellido,
          'email': email, // Email editado
          'telefono': telefono, // Teléfono editado
          'genero': _normalizarGenero(widget.genero), // Masculino/Femenino
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

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ REGISTRO EXITOSO - Extraer y guardar token
        String? savedToken;
        try {
          final responseData = jsonDecode(response.body);
          final token = responseData['token'] as String?;

          if (token != null && token.isNotEmpty) {
            // Guardar token PERSISTENTE (usuario mantiene sesión al cerrar app)
            await TokenService.saveToken(token);
            savedToken = token;
            print('✅ Token persistente guardado exitosamente');
          } else {
            print('⚠️ ADVERTENCIA: No se recibió token en la respuesta');
          }
        } catch (e) {
          print('⚠️ Error al parsear token: $e');
        }

        // 🔌 CONECTAR WEBSOCKET usando la MISMA URL que se envió al backend
        // El frontend genera el wsUrl y lo usa directamente para la conexión
        print(
          '🔌 Conectando WebSocket con URL generada por el frontend: $wsUrl',
        );
        _affiliationService
            .connectToWebSocket(wsUrl: wsUrl, token: savedToken ?? '')
            .then((_) {
              print('✅ WebSocket conectado exitosamente');
            })
            .catchError((e) {
              print('⚠️ Error al conectar WebSocket: $e');
              // No hacemos nada crítico, la navegación continúa igual
            });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Iniciando afiliación...'),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 2),
          ),
        );

        // Pequeño delay para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navegar a LimitedHomePage con servicio de afiliación
        // El usuario esperará 30 segundos (o hasta que se complete la afiliación)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LimitedHomePage(affiliationService: _affiliationService),
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
      print('ERROR CRÍTICO en _onConfirmarDatos: $e');

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
