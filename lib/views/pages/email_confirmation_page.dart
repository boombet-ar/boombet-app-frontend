import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
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
    debugPrint('📱 EmailConfirmationPage initState');
    debugPrint('📱 isFromDeepLink: ${widget.isFromDeepLink}');
    debugPrint('📱 verificacionToken: ${widget.verificacionToken}');
    debugPrint(
      '📱 verificacionToken.isEmpty: ${widget.verificacionToken.isEmpty}',
    );

    // Cargar datos de SharedPreferences
    _loadAffiliationData();

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
      debugPrint(
        '🔗 Detectado deep link, ejecutando confirmación después del frame',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint(
            '🔗 Post frame callback ejecutado, llamando _confirmEmailWithToken',
          );
          _confirmEmailWithToken();
        }
      });
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

      // Cambiar a GET con el token como query parameter
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/users/auth/verify?token=${widget.verificacionToken}',
      );
      debugPrint('📡 [3] URL de verificación: $url');

      debugPrint('📡 [5] Enviando GET...');
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
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
      if (mounted) {
        LoadingOverlay.hide(context);
        debugPrint('🔗 [10] LoadingOverlay ocultado');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ EMAIL CONFIRMADO EXITOSAMENTE
        debugPrint('✅ [11] Email confirmado exitosamente');

        if (!mounted) {
          debugPrint('❌ [12] Widget no está mounted, retornando');
          return;
        }

        debugPrint('🔗 [13] Email verificado, actualizando UI...');
        setState(() {
          _emailConfirmed = true;
        });
        debugPrint('🔗 [14] Estado actualizado, _emailConfirmed = true');

        debugPrint('🔗 [15] Mostrando SnackBar de éxito...');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Email confirmado exitosamente! Iniciando tu afiliación...',
            ),
            backgroundColor: Color.fromARGB(255, 41, 255, 94),
            duration: Duration(seconds: 3),
          ),
        );
        debugPrint('🔗 [16] SnackBar mostrado');

        debugPrint(
          '🔗 [17] Esperando 2 segundos antes de iniciar afiliación...',
        );
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) {
          debugPrint('❌ [18] Widget no está mounted, retornando');
          return;
        }

        debugPrint('🔗 [19] Iniciando proceso de afiliación...');
        await _startAffiliation();
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

  Future<void> _startAffiliation() async {
    debugPrint('🔗 [AF-1] Iniciando proceso de afiliación');

    // DEBUG: Verificar qué hay en los notifiers
    debugPrint(
      '📋 [DEBUG] affiliationPlayerDataNotifier: ${affiliationPlayerDataNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationEmailNotifier: ${affiliationEmailNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationUsernameNotifier: ${affiliationUsernameNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationPasswordNotifier: ${affiliationPasswordNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationDniNotifier: ${affiliationDniNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationTelefonoNotifier: ${affiliationTelefonoNotifier.value}',
    );
    debugPrint(
      '📋 [DEBUG] affiliationGeneroNotifier: ${affiliationGeneroNotifier.value}',
    );

    try {
      // Obtener datos de los notifiers
      final playerData = affiliationPlayerDataNotifier.value;
      final email = affiliationEmailNotifier.value;
      final username = affiliationUsernameNotifier.value;
      final password = affiliationPasswordNotifier.value;
      final dni = affiliationDniNotifier.value;
      final telefono = affiliationTelefonoNotifier.value;
      final genero = affiliationGeneroNotifier.value;

      if (playerData == null || email.isEmpty) {
        debugPrint('❌ [AF-2] Datos incompletos en notifiers');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: Datos de usuario no disponibles en memoria. Por favor intenta registrarte nuevamente.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      debugPrint('✅ [AF-3] Datos obtenidos de notifiers correctamente');

      // Generar WebSocket URL
      final wsUrl = WebSocketUrlService.generateAffiliationUrl();
      debugPrint('📡 [AF-4] WebSocket URL generado: $wsUrl');

      // Preparar payload para /affiliate
      final affiliatePayload = {
        'websocketLink': wsUrl,
        'playerData': {
          'nombre': playerData.nombre,
          'apellido': playerData.apellido,
          'email': email,
          'telefono': telefono,
          'genero': _normalizarGenero(genero),
          'dni': dni,
          'cuit': playerData.cuil,
          'calle': playerData.calle,
          'numCalle': playerData.numCalle,
          'provincia': playerData.provincia,
          'ciudad': playerData.localidad,
          'cp': playerData.cp?.toString() ?? '',
          'user': username,
          'password': password,
          'fecha_nacimiento': playerData.fechaNacimiento,
          'est_civil': playerData.estadoCivil,
        },
      };

      debugPrint('📦 [AF-5] Payload preparado');
      debugPrint('📡 [AF-6] Enviando POST a /api/users/auth/affiliate');

      // Enviar POST a /affiliate
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/affiliate');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(affiliatePayload),
          )
          .timeout(
            AppConstants.apiTimeout,
            onTimeout: () => http.Response('Request timeout', 408),
          );

      debugPrint('✉️ [AF-7] Response recibido: ${response.statusCode}');

      if (!mounted) {
        debugPrint('❌ [AF-8] Widget no está mounted');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [AF-9] Afiliación iniciada exitosamente');

        // Conectar WebSocket
        final affiliationService = AffiliationService();
        try {
          debugPrint('🔗 [AF-10] Conectando al WebSocket...');
          await affiliationService.connectToWebSocket(wsUrl: wsUrl);
          debugPrint('✅ [AF-11] WebSocket conectado exitosamente');

          // Navegar a LimitedHomePage
          debugPrint('🎯 [AF-12] Navegando a LimitedHomePage');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LimitedHomePage(affiliationService: affiliationService),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ [AF-13] Error conectando al WebSocket: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error conectando: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('❌ [AF-14] Error en /affiliate: ${response.statusCode}');

        if (!mounted) return;

        String errorMessage = 'Error ${response.statusCode} en afiliación';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint('⚠️ Error parseando respuesta: $e');
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
      debugPrint('❌ [AF-15] Error crítico en _startAffiliation: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  /// Carga los datos de afiliación desde SharedPreferences
  Future<void> _loadAffiliationData() async {
    debugPrint('💾 [LOAD] Iniciando carga de datos de SharedPreferences...');
    await loadAffiliationData();
    debugPrint('💾 [LOAD] Datos cargados:');
    debugPrint('💾 [LOAD] playerData: ${affiliationPlayerDataNotifier.value}');
    debugPrint('💾 [LOAD] email: ${affiliationEmailNotifier.value}');
    debugPrint('💾 [LOAD] username: ${affiliationUsernameNotifier.value}');
    debugPrint('💾 [LOAD] dni: ${affiliationDniNotifier.value}');
  }
}
