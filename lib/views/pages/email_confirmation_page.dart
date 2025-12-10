import 'dart:async';
import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/email_verification_service.dart';
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
  final String? verificacionToken;
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
    this.verificacionToken,
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
  bool _isCheckingStatus = false;
  String? _statusMessage;
  String? _verificationToken;
  late final VoidCallback _emailVerifiedListener;
  StreamSubscription<DeepLinkPayload>? _deepLinkSubscription;
  bool _lockConfirmedView = false;

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
    debugPrint('📱 EmailConfirmationPage initState');

    _emailConfirmed = emailVerifiedNotifier.value;

    _emailVerifiedListener = () {
      if (!mounted) return;
      final verified = emailVerifiedNotifier.value;
      if (_lockConfirmedView && !verified) {
        debugPrint(
          '🔒 [EmailConfirmationPage] Ignorando cambio de emailVerifiedNotifier (false) porque la vista ya está confirmada.',
        );
        return;
      }

      if (_emailConfirmed != verified) {
        setState(() {
          _emailConfirmed = verified;
        });
      }
    };
    emailVerifiedNotifier.addListener(_emailVerifiedListener);

    _deepLinkSubscription = DeepLinkService.instance.stream.listen((payload) {
      _handleDeepLinkPayload(payload, silent: false);
    });

    final initialPlayer = _resolvedPlayerData;
    if (initialPlayer != null) {
      final data = initialPlayer;
      _nombreController = TextEditingController(text: data.nombre);
      _apellidoController = TextEditingController(text: data.apellido);
    } else {
      _nombreController = TextEditingController();
      _apellidoController = TextEditingController();
    }

    _loadAffiliationData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingPayload = DeepLinkService.instance.lastPayload;
      if (pendingPayload != null && pendingPayload.isEmailConfirmation) {
        _handleDeepLinkPayload(pendingPayload, silent: true);
        return;
      }

      final initialToken = widget.verificacionToken?.trim();
      if (initialToken != null && initialToken.isNotEmpty) {
        debugPrint(
          '🔗 [EmailConfirmationPage] Token recibido via widget: $initialToken',
        );
        _verificationToken = initialToken;
        _verifyEmailToken(initialToken, silent: true);
        return;
      }
    });
  }

  @override
  void dispose() {
    emailVerifiedNotifier.removeListener(_emailVerifiedListener);
    _deepLinkSubscription?.cancel();
    _nombreController.dispose();
    _apellidoController.dispose();
    super.dispose();
  }

  String? get _resolvedEmail {
    final widgetEmail = widget.email?.trim();
    if (widgetEmail != null && widgetEmail.isNotEmpty) {
      return widgetEmail;
    }

    final persisted = affiliationEmailNotifier.value.trim();
    return persisted.isEmpty ? null : persisted;
  }

  Future<void> _handleDeepLinkPayload(
    DeepLinkPayload payload, {
    required bool silent,
  }) async {
    if (!payload.isEmailConfirmation) return;

    final token = payload.token;
    if (!silent) {
      debugPrint('🔗 [DeepLink] Payload recibido: ${payload.uri}');
    }

    if (token == null || token.isEmpty) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enlace inválido: falta token.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if ((_emailConfirmed || _lockConfirmedView) &&
        _verificationToken == token) {
      debugPrint(
        '🔁 [EmailConfirmationPage] Token ya confirmado, se ignora payload duplicado.',
      );
      return;
    }

    _verificationToken = token;
    await _verifyEmailToken(token, silent: silent, sourcePayload: payload);
  }

  /// Verifica el email del usuario llamando a /api/users/auth/verify con el token
  Future<void> _verifyEmailToken(
    String token, {
    bool silent = false,
    DeepLinkPayload? sourcePayload,
  }) async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
      if (!silent) {
        _statusMessage = null;
      }
    });

    try {
      debugPrint(
        '🔑 [EmailConfirmationPage] Verificando email con token: $token',
      );

      final verified = await EmailVerificationService.verifyEmailWithToken(
        token,
      );

      if (!mounted) return;

      if (verified) {
        setState(() {
          _emailConfirmed = true;
          _lockConfirmedView = true;
          if (!silent) {
            _statusMessage =
                '¡Email confirmado! Ya podés completar la afiliación.';
          }
        });

        if (sourcePayload != null) {
          DeepLinkService.instance.markPayloadHandled(sourcePayload);
        }

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email confirmado.'),
              backgroundColor: Color.fromARGB(255, 41, 255, 94),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (!silent) {
        setState(() {
          _statusMessage =
              'El token no es válido o ya fue usado. Intenta con un nuevo enlace.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token inválido o expirado.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [EmailConfirmationPage] Error verificando email: $e');
      if (!mounted) return;

      if (!silent) {
        setState(() {
          _statusMessage = 'No pudimos verificar el email. Intenta luego.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verificando email: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
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

  Future<void> _processAfiliation() async {
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
      // Generar WebSocket URL
      final wsUrl = _generateWebSocketUrl();
      debugPrint('WebSocket URL generada: $wsUrl');

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
          'provincia': playerData.provincia,
          'ciudad': playerData.localidad,
          'cp': playerData.cp?.toString() ?? '',
          'user': _resolvedUsername ?? '',
          'password': _resolvedPassword ?? '',
          'fecha_nacimiento': playerData.fechaNacimiento,
          'est_civil': playerData.estadoCivil,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black87 : AppConstants.lightBg;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    final resolvedEmail = _resolvedEmail;

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

                    if (_emailConfirmed)
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
                        )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (_isCheckingStatus ||
                                      _verificationToken == null)
                                  ? null
                                  : () =>
                                        _verifyEmailToken(_verificationToken!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isCheckingStatus)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.email_outlined, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isCheckingStatus
                                        ? 'Verificando...'
                                        : 'Ya confirmé mi email',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppConstants.lightHintText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
    debugPrint('💾 [LOAD] Iniciando carga de datos de SharedPreferences...');
    await loadAffiliationData();
    debugPrint('💾 [LOAD] Datos cargados:');
    debugPrint('💾 [LOAD] playerData: ${affiliationPlayerDataNotifier.value}');
    debugPrint('💾 [LOAD] email: ${affiliationEmailNotifier.value}');
    debugPrint('💾 [LOAD] username: ${affiliationUsernameNotifier.value}');
    debugPrint('💾 [LOAD] dni: ${affiliationDniNotifier.value}');

    if (!mounted) return;

    _syncControllersWithPlayerData();

    if (widget.playerData == null) {
      setState(() {});
    }
  }
}
