import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/limited_home_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailConfirmationPage extends StatefulWidget {
  final PlayerData? playerData;
  final String? email;
  final String? username;
  final String? password;
  final String? dni;
  final String? telefono;
  final String? genero;
  final String verificacionToken;
  final bool isFromDeepLink;

  const EmailConfirmationPage({
    super.key,
    this.playerData,
    this.email,
    this.username,
    this.password,
    this.dni,
    this.telefono,
    this.genero,
    required this.verificacionToken,
    this.isFromDeepLink = false,
  });

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  final AffiliationService _affiliationService = AffiliationService();
  bool _isProcessing = false;
  bool _emailConfirmed = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controllers
    if (widget.playerData != null) {
      final data = widget.playerData!;
      _nombreController = TextEditingController(text: data.nombre);
      _apellidoController = TextEditingController(text: data.apellido);
    } else {
      _nombreController = TextEditingController();
      _apellidoController = TextEditingController();
    }

    // Si viene de deep link y el token no está vacío, confirmar automáticamente
    if (widget.isFromDeepLink && widget.verificacionToken.isNotEmpty) {
      _confirmEmailWithToken();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  Future<void> _confirmEmailWithToken() async {
    debugPrint(
      '🔗 Deep Link - Confirmando email con token: ${widget.verificacionToken}',
    );
    debugPrint('🔗 Context mounted: $mounted');
    debugPrint(
      '🔗 Verificacion token vacío: ${widget.verificacionToken.isEmpty}',
    );

    try {
      debugPrint('🔗 [1] Intentando mostrar LoadingOverlay...');
      LoadingOverlay.show(context, message: 'Confirmando tu email...');
      debugPrint('🔗 [2] LoadingOverlay mostrado');

      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/verify');
      debugPrint('📡 [3] URL de verificación: $url');
      debugPrint(
        '📦 [4] Payload: ${jsonEncode({'token': widget.verificacionToken})}',
      );

      debugPrint('📡 [5] Enviando POST...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': widget.verificacionToken}),
          )
          .timeout(
            AppConstants.apiTimeout,
            onTimeout: () => http.Response('Request timeout', 408),
          );

      debugPrint('✉️ [6] Response recibido');
      debugPrint('✉️ Response Status: ${response.statusCode}');
      debugPrint('✉️ Response Body: "${response.body}"');
      debugPrint('✉️ Response Headers: ${response.headers}');

      debugPrint('🔗 [7] Verificando si mounted...');
      if (!mounted) {
        debugPrint('❌ [8] Widget no está mounted, retornando');
        return;
      }

      debugPrint('🔗 [9] Ocultando LoadingOverlay...');
      LoadingOverlay.hide(context);
      debugPrint('🔗 [10] LoadingOverlay ocultado');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ EMAIL CONFIRMADO EXITOSAMENTE
        debugPrint('✅ [11] Email confirmado exitosamente');

        if (!mounted) {
          debugPrint('❌ [12] Widget no está mounted, retornando');
          return;
        }

        debugPrint('🔗 [13] Mostrando SnackBar de éxito...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Email confirmado exitosamente!'),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('🔗 [14] SnackBar mostrado');

        debugPrint('🔗 [15] Esperando 2 segundos...');
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) {
          debugPrint('❌ [16] Widget no está mounted, retornando');
          return;
        }

        debugPrint('🔗 [17] Navegando a /...');
        Navigator.pushReplacementNamed(context, '/');
        debugPrint('🔗 [18] Navegación completada');
      } else {
        debugPrint('❌ [19] Error confirmando email: ${response.statusCode}');
        debugPrint('❌ Response body completo: ${response.body}');

        if (!mounted) {
          debugPrint('❌ [20] Widget no está mounted, retornando');
          return;
        }

        // Mostrar el error exacto del servidor
        String errorMessage = 'Error ${response.statusCode}: ${response.body}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint('⚠️ No se pudo parsear el error: $e');
        }

        debugPrint('🔗 [21] Mostrando SnackBar de error: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
        debugPrint('🔗 [22] SnackBar de error mostrado');
      }
    } catch (e) {
      debugPrint('❌ Error crítico en confirmación: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');

      if (!mounted) {
        debugPrint('❌ Widget no está mounted después del error');
        return;
      }

      debugPrint('🔗 [23] Ocultando LoadingOverlay después de error...');
      LoadingOverlay.hide(context);
      debugPrint('🔗 [24] LoadingOverlay ocultado');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  String _normalizarGenero(String genero) {
    if (genero == 'M') return 'Masculino';
    if (genero == 'F') return 'Femenino';
    return genero;
  }

  String _generateWebSocketUrl() {
    return WebSocketUrlService.generateAffiliationUrl();
  }

  Future<void> _processAfiliation() async {
    if (_isProcessing) return;

    // Validar que tenemos los datos necesarios
    if (widget.playerData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Datos de jugador no disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    LoadingOverlay.show(context, message: 'Completando tu afiliación...');

    try {
      // Generar WebSocket URL
      final wsUrl = _generateWebSocketUrl();
      debugPrint('WebSocket URL generada: $wsUrl');

      // Preparar payload con estructura exacta requerida por el backend
      final payload = {
        'websocketLink': wsUrl,
        'playerData': {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'email': widget.email ?? '',
          'telefono': widget.telefono ?? '',
          'genero': _normalizarGenero(widget.genero ?? ''),
          'dni': widget.dni ?? '',
          'cuit': widget.playerData!.cuil,
          'calle': widget.playerData!.calle,
          'numCalle': widget.playerData!.numCalle,
          'provincia': widget.playerData!.provincia,
          'ciudad': widget.playerData!.localidad,
          'cp': widget.playerData!.cp?.toString() ?? '',
          'user': widget.username ?? '',
          'password': widget.password ?? '',
          'fecha_nacimiento': widget.playerData!.fechaNacimiento,
          'est_civil': widget.playerData!.estadoCivil,
        },
      };

      debugPrint('Enviando POST a /api/users/auth/affiliate');
      debugPrint('Payload: ${jsonEncode(payload)}');

      // Enviar POST al endpoint de afiliación
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/affiliate');

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
        // ✅ AFILIACIÓN EXITOSA
        debugPrint('✅ Afiliación exitosa');

        // 🔌 CONECTAR WEBSOCKET
        debugPrint(
          '🔌 Conectando WebSocket con URL generada por el frontend: $wsUrl',
        );
        _affiliationService
            .connectToWebSocket(wsUrl: wsUrl, token: '')
            .then((_) {
              debugPrint('✅ WebSocket conectado exitosamente');
            })
            .catchError((e) {
              debugPrint('⚠️ Error al conectar WebSocket: $e');
            });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Afiliación completada exitosamente!'),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navegar a LimitedHomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LimitedHomePage(affiliationService: _affiliationService),
          ),
        );
      } else {
        // ❌ ERROR EN LA AFILIACIÓN
        String errorMessage = 'Error al completar la afiliación';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR CRÍTICO en _processAfiliation: $e');

      if (!mounted) return;

      LoadingOverlay.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );

      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _confirmEmail() {
    setState(() {
      _emailConfirmed = true;
    });
    debugPrint('✅ Email confirmado por el usuario');
  }

  @override
  Widget build(BuildContext context) {
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
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono de email
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryGreen.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        _emailConfirmed
                            ? Icons.check_circle
                            : Icons.mail_outline,
                        size: 60,
                        color: _emailConfirmed
                            ? primaryGreen
                            : primaryGreen.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      _emailConfirmed
                          ? '¡Email confirmado!'
                          : 'Confirmá tu email',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtítulo
                    Text(
                      _emailConfirmed
                          ? 'Tu email ha sido verificado exitosamente'
                          : 'Te enviamos un enlace de confirmación a:',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white70
                            : AppConstants.lightHintText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Email (solo mostrar si no es deep link)
                    if (widget.email != null && widget.email!.isNotEmpty)
                      Text(
                        widget.email!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),

                    // Mensaje principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _emailConfirmed
                            ? 'Ya podés completar tu afiliación haciendo click en el botón de abajo.'
                            : 'Haz click en el enlace que recibiste para verificar tu email y poder continuar con tu afiliación.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white70
                              : AppConstants.lightHintText,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón de afiliación (solo si NO es deep link y email confirmado)
                    if (!widget.isFromDeepLink)
                      if (_isProcessing)
                        Column(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Procesando tu afiliación...',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppConstants.lightHintText,
                              ),
                            ),
                          ],
                        )
                      else if (!_emailConfirmed)
                        Column(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Esperando confirmación...',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppConstants.lightHintText,
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _processAfiliation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 24),
                                SizedBox(width: 12),
                                Text(
                                  'Completar afiliación',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            // Botón invisible para simular confirmación de email (para testing)
            if (!_emailConfirmed && !_isProcessing && !widget.isFromDeepLink)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onLongPress: _confirmEmail,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check, color: Colors.transparent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
