import 'dart:async';
import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/limited_home_page.dart';
import 'package:boombet_app/views/pages/no_casinos_available_page.dart';
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
  final String? verificacionToken;
  final bool isFromDeepLink;
  final bool preview;
  const EmailConfirmationPage({
    super.key,
    this.playerData,
    this.email,
    this.username,
    this.password,
    this.dni,
    this.telefono,
    this.genero,
    this.verificacionToken,
    this.isFromDeepLink = false,
    this.preview = false,
  });

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage>
    with WidgetsBindingObserver {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  final AffiliationService _affiliationService = AffiliationService();
  bool _isProcessing = false;
  bool _isVerified = false;
  bool _isCheckingVerification = false;
  Timer? _verificationTimer;

  PlayerData? get _resolvedPlayerData =>
      widget.playerData ?? affiliationPlayerDataNotifier.value;

  String? _valueOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? get _resolvedUsername =>
      _valueOrNull(widget.username) ??
      _valueOrNull(affiliationUsernameNotifier.value);

  String? get _resolvedPassword =>
      _valueOrNull(widget.password) ??
      _valueOrNull(affiliationPasswordNotifier.value);

  String? get _resolvedDni =>
      _valueOrNull(widget.dni) ?? _valueOrNull(affiliationDniNotifier.value);

  String? get _resolvedTelefono =>
      _valueOrNull(widget.telefono) ??
      _valueOrNull(affiliationTelefonoNotifier.value);

  String? get _resolvedGenero =>
      _valueOrNull(widget.genero) ??
      _valueOrNull(affiliationGeneroNotifier.value);

  void _syncControllersWithPlayerData() {
    final data = _resolvedPlayerData;
    if (data == null) return;

    if (_nombreController.text.isEmpty) {
      _nombreController.text = data.nombre;
    }
    if (_apellidoController.text.isEmpty) {
      _apellidoController.text = data.apellido;
    }
  }

  @override
  void initState() {
    super.initState();

    // Agregar observer para detectar cuando vuelve a la app
    if (!widget.preview) {
      WidgetsBinding.instance.addObserver(this);
    }

    final initialPlayer = _resolvedPlayerData;
    if (initialPlayer != null) {
      final data = initialPlayer;
      _nombreController = TextEditingController(text: data.nombre);
      _apellidoController = TextEditingController(text: data.apellido);
    } else {
      _nombreController = TextEditingController();
      _apellidoController = TextEditingController();
    }

    if (!widget.preview) {
      _loadAffiliationData();

      // Iniciar verificación de is_verified usando email
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startVerificationPolling();
      });
    }
  }

  @override
  void dispose() {
    if (!widget.preview) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _verificationTimer?.cancel();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cuando la app vuelve al foreground, reiniciar polling si no está verificado
    if (state == AppLifecycleState.resumed && !_isVerified) {
      _verificationTimer?.cancel();
      _startVerificationPolling();
    }
  }

  String? get _resolvedEmail {
    final widgetEmail = widget.email?.trim();
    if (widgetEmail != null && widgetEmail.isNotEmpty) {
      return widgetEmail;
    }

    final persisted = affiliationEmailNotifier.value.trim();
    return persisted.isEmpty ? null : persisted;
  }

  /// Inicia polling para verificar is_verified cada 3 segundos
  void _startVerificationPolling() {
    // Verificar inmediatamente
    _checkIsVerified();

    // Luego verificar cada 3 segundos
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkIsVerified(),
    );
  }

  /// Verifica el estado is_verified del usuario usando su email
  Future<void> _checkIsVerified() async {
    if (widget.preview) return;
    if (_isCheckingVerification || _isVerified) return;

    // Obtener el email del usuario
    final email = _resolvedEmail;
    if (email == null || email.isEmpty) {
      _verificationTimer?.cancel();
      return;
    }

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // GET request con email como query parameter
      final url =
          '${ApiConfig.baseUrl}/users/auth/isVerified?email=${Uri.encodeComponent(email)}';

      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Intentar múltiples formas de parsear is_verified
        bool isVerified = false;

        if (data is Map<String, dynamic>) {
          // Caso 1: {is_verified: true}
          if (data.containsKey('is_verified')) {
            isVerified =
                data['is_verified'] == true || data['is_verified'] == 1;
          }
          // Caso 2: {isVerified: true}
          else if (data.containsKey('isVerified')) {
            isVerified = data['isVerified'] == true || data['isVerified'] == 1;
          }
          // Caso 3: {verified: true}
          else if (data.containsKey('verified')) {
            isVerified = data['verified'] == true || data['verified'] == 1;
          }
        }
        // Caso 4: respuesta directa booleana
        else if (data is bool) {
          isVerified = data;
        }

        if (isVerified && !_isVerified) {
          setState(() {
            _isVerified = true;
          });

          // Detener el polling
          _verificationTimer?.cancel();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Email verificado! Ya podés continuar.'),
              backgroundColor: Color.fromARGB(255, 41, 255, 94),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (!isVerified) {
          setState(() {
            _isVerified = false;
          });
        }
      } else if (response.statusCode == 403) {
        // NO detener el polling, seguir intentando
      } else if (response.statusCode == 400) {
        // Detener polling si es Bad Request
        _verificationTimer?.cancel();
      } else if (response.statusCode == 404) {
        _verificationTimer?.cancel();
      } else {}
    } catch (e, stackTrace) {
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
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

  bool _isNoCasinosAvailableResponse({required String body}) {
    final lowered = body.toLowerCase();
    if (lowered.contains('no hay casinos disponibles') ||
        lowered.contains('sin casinos disponibles') ||
        lowered.contains('no contamos con casinos') ||
        lowered.contains('no casinos available')) {
      return true;
    }

    try {
      final decoded = jsonDecode(body);
      return _containsNoCasinosFlag(decoded);
    } catch (_) {
      return false;
    }
  }

  bool _containsNoCasinosFlag(dynamic value) {
    if (value == null) return false;

    if (value is String) {
      final lowered = value.toLowerCase();
      return lowered.contains('no hay casinos') ||
          lowered.contains('sin casinos') ||
          lowered.contains('no contamos con casinos') ||
          lowered.contains('no casinos');
    }

    if (value is List) {
      for (final item in value) {
        if (_containsNoCasinosFlag(item)) return true;
      }
      return false;
    }

    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();

      final noCasinos =
          map['noCasinosAvailable'] ??
          map['no_casinos_available'] ??
          map['noCasinos'] ??
          map['no_casinos'];
      if (noCasinos == true) return true;

      final casinosAvailable =
          map['casinosAvailable'] ??
          map['casinos_available'] ??
          map['casinoAvailable'] ??
          map['casino_available'];
      if (casinosAvailable == false) return true;

      final hasCasinos = map['hasCasinos'] ?? map['has_casinos'];
      if (hasCasinos == false) return true;

      final casinos =
          map['casinos'] ??
          map['availableCasinos'] ??
          map['casinosDisponibles'] ??
          map['available_casinos'];
      if (casinos is List && casinos.isEmpty) return true;

      final availableCount =
          map['availableCasinosCount'] ??
          map['available_casinos_count'] ??
          map['casinosCount'] ??
          map['casinos_count'];
      if (availableCount is num && availableCount == 0) return true;

      final message = map['message'] ?? map['error'] ?? map['details'];
      if (message is String && _containsNoCasinosFlag(message)) return true;

      for (final entry in map.values) {
        if (_containsNoCasinosFlag(entry)) return true;
      }
    }

    return false;
  }

  bool _isMissingProvinceResponse({required String body}) {
    final lowered = body.toLowerCase();
    if (lowered.contains('no hay provincia') ||
        lowered.contains('sin provincia') ||
        lowered.contains('falta provincia') ||
        lowered.contains('missing provincia') ||
        lowered.contains('missing province') ||
        lowered.contains('province is required') ||
        lowered.contains('provincia es requerida') ||
        lowered.contains('provincia requerida')) {
      return true;
    }

    try {
      final decoded = jsonDecode(body);
      return _containsMissingProvinceFlag(decoded);
    } catch (_) {
      return false;
    }
  }

  bool _containsMissingProvinceFlag(dynamic value) {
    if (value == null) return false;

    if (value is String) {
      final lowered = value.toLowerCase();
      return lowered.contains('no hay provincia') ||
          lowered.contains('sin provincia') ||
          lowered.contains('falta provincia') ||
          lowered.contains('missing province') ||
          lowered.contains('province is required') ||
          lowered.contains('provincia es requerida') ||
          lowered.contains('provincia requerida');
    }

    if (value is List) {
      for (final item in value) {
        if (_containsMissingProvinceFlag(item)) return true;
      }
      return false;
    }

    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();

      final provinceRequired =
          map['provinceRequired'] ??
          map['provinciaRequired'] ??
          map['provincia_required'] ??
          map['province_required'];
      if (provinceRequired == true) return true;

      final missingProvince =
          map['missingProvince'] ??
          map['missing_province'] ??
          map['missingProvincia'] ??
          map['missing_provincia'];
      if (missingProvince == true) return true;

      final field = map['field'] ?? map['campo'] ?? map['param'] ?? map['name'];
      if (field is String && field.toLowerCase().contains('provincia')) {
        final message = map['message'] ?? map['error'] ?? map['details'];
        if (message is String && _containsMissingProvinceFlag(message)) {
          return true;
        }
      }

      for (final entry in map.values) {
        if (_containsMissingProvinceFlag(entry)) return true;
      }
    }

    return false;
  }

  Future<void> _processAfiliation() async {
    if (widget.preview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview: afiliación deshabilitada (solo visual).'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isProcessing) return;

    // Validar que tenemos los datos necesarios
    final playerData = _resolvedPlayerData;
    if (playerData == null) {
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
      final provincia = playerData.provincia.trim();
      if (provincia.isEmpty) {
        LoadingOverlay.hide(context);
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NoCasinosAvailablePage()),
        );

        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Generar WebSocket URL
      final wsUrl = _generateWebSocketUrl();

      // Preparar payload con estructura exacta requerida por el backend
      final payload = {
        'websocketLink': wsUrl,
        'playerData': {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'email': _resolvedEmail ?? '',
          'telefono': _resolvedTelefono ?? '',
          'genero': _normalizarGenero(_resolvedGenero ?? ''),
          'dni': _resolvedDni ?? '',
          'cuit': playerData.cuil,
          'calle': playerData.calle,
          'numCalle': playerData.numCalle,
          'provincia': provincia,
          'ciudad': playerData.localidad,
          'cp': playerData.cp?.toString() ?? '',
          'user': _resolvedUsername ?? '',
          'password': _resolvedPassword ?? '',
          'fecha_nacimiento': playerData.fechaNacimiento,
          'est_civil': playerData.estadoCivil,
        },
      };

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

      if (!mounted) return;

      LoadingOverlay.hide(context);

      if (_isNoCasinosAvailableResponse(body: response.body)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NoCasinosAvailablePage()),
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      if (_isMissingProvinceResponse(body: response.body)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NoCasinosAvailablePage()),
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ AFILIACIÓN EXITOSA

        // 🔌 CONECTAR WEBSOCKET
        _affiliationService
            .connectToWebSocket(wsUrl: wsUrl, token: '')
            .then((_) {})
            .catchError((e) {});

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Afiliación completada exitosamente!'),
            backgroundColor: AppConstants.primaryGreen,
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

        if (_isMissingProvinceResponse(body: errorMessage)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NoCasinosAvailablePage()),
          );

          setState(() {
            _isProcessing = false;
          });
          return;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black87 : AppConstants.lightBg;
    const primaryGreen = AppConstants.primaryGreen;
    final resolvedEmail = _resolvedEmail;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: ResponsiveWrapper(
        // En web, limitar el ancho para que se vea como en móvil (centrado)
        // y evitar componentes full-width.
        maxWidth: 560,
        constrainOnWeb: true,
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
                        Icons.mail_outline,
                        size: 60,
                        color: primaryGreen.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Título
                    Text(
                      'Confirmación de email',
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
                      'Te enviamos un enlace de confirmación a:',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white70
                            : AppConstants.lightHintText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    if (resolvedEmail != null)
                      Text(
                        resolvedEmail,
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
                        'Haz click en el enlace que recibiste para verificar tu email. Una vez verificado, podés continuar con tu afiliación haciendo click en el botón de abajo.',
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

                    // Botón siempre visible
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
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isVerified
                                  ? _processAfiliation
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.grey.withValues(
                                  alpha: 0.3,
                                ),
                                disabledForegroundColor: Colors.grey.withValues(
                                  alpha: 0.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isCheckingVerification)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _isVerified
                                          ? Icons.check_circle
                                          : Icons.lock,
                                      size: 24,
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isCheckingVerification
                                        ? 'Verificando...'
                                        : 'Completar afiliación',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!_isVerified && !_isCheckingVerification)
                            const SizedBox(height: 16),
                          Text(
                            'Esperando verificación de email...',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : AppConstants.lightHintText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                  ],
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
    await loadAffiliationData();

    if (!mounted) return;

    _syncControllersWithPlayerData();

    if (widget.playerData == null) {
      setState(() {});
    }
  }
}
