import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/core/utils/inappropriate_content_guard.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/notification_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/error_parser.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/auth/email_confirmation_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/form_fields.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmPlayerDataPage extends StatefulWidget {
  final PlayerData playerData;
  final String email;
  final String username;
  final String password;
  final String dni;
  final String telefono;
  final String genero;
  final String? affiliateToken;
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
    this.affiliateToken,
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

  Future<String?> _resolveFcmToken() async {
    try {
      final stored = await TokenService.getFcmToken();
      if (stored != null && stored.isNotEmpty) return stored;

      if (kIsWeb) return null;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await TokenService.saveFcmToken(token);
        return token;
      }
    } catch (_) {}
    return null;
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

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.18),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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

  void _showSuccessDialog({required String message, VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        title: const Text(
          '¡Éxito!',
          style: TextStyle(color: AppConstants.primaryGreen, fontSize: 17),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk?.call();
            },
            child: const Text(
              'Continuar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _extractBackendErrorMessage(
    String rawBody, {
    required String fallback,
  }) {
    String normalizeMessage(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is List) {
        final joined = value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join('\n');
        if (joined.isNotEmpty) return joined;
      }
      if (value is Map) {
        final joined = value.values
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .join('\n');
        if (joined.isNotEmpty) return joined;
      }
      return '';
    }

    var candidate = rawBody.trim();

    final statusPrefix = RegExp(r'^\s*\d{3}\s+[^:]+:\s*');
    final statusPrefixMatch = statusPrefix.firstMatch(candidate);
    if (statusPrefixMatch != null) {
      candidate = candidate.substring(statusPrefixMatch.end).trim();
    }

    if (candidate.length >= 2) {
      final first = candidate[0];
      final last = candidate[candidate.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        candidate = candidate.substring(1, candidate.length - 1).trim();
      }
    }

    for (var i = 0; i < 2; i++) {
      dynamic decoded;
      try {
        decoded = jsonDecode(candidate);
      } catch (_) {
        decoded = null;
      }

      if (decoded is Map) {
        final dynamic messageLike =
            decoded['message'] ??
            decoded['mensaje'] ??
            decoded['error'] ??
            decoded['detail'] ??
            decoded['errors'];

        final normalized = normalizeMessage(messageLike);
        if (normalized.isNotEmpty) return normalized;

        break;
      }

      if (decoded is String && decoded.trim().isNotEmpty) {
        candidate = decoded.trim();
        continue;
      }

      break;
    }

    for (final key in ['message', 'mensaje', 'error', 'detail']) {
      final match = RegExp('"$key"\\s*:\\s*"([^"]+)"').firstMatch(candidate);
      final message = match?.group(1)?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }

  Future<void> _onConfirmarDatos() async {
    if (widget.preview) {
      _showErrorDialog(
        title: 'Modo Preview',
        message: 'Acción deshabilitada (solo visual).',
      );
      return;
    }

    if (_isLoading) return; // Prevenir doble tap

    final blocked =
        await InappropriateContentGuard.blockIfAnyFieldContainsInappropriateContent(
          context: context,
          values: [
            _nombreController.text.trim(),
            _apellidoController.text.trim(),
            _correoController.text.trim(),
            _telefonoController.text.trim(),
            _estadoCivilController.text.trim(),
          ],
        );
    if (blocked) return;

    // Validar Nombre
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      _showErrorDialog(
        title: 'Campo incompleto',
        message: 'Por favor, ingresa tu nombre.',
      );
      return;
    }
    if (nombre.length < 2) {
      _showErrorDialog(
        title: 'Validación de nombre',
        message: 'El nombre debe tener al menos 2 caracteres.',
      );
      return;
    }

    // Validar Apellido
    final apellido = _apellidoController.text.trim();
    if (apellido.isEmpty) {
      _showErrorDialog(
        title: 'Campo incompleto',
        message: 'Por favor, ingresa tu apellido.',
      );
      return;
    }
    if (apellido.length < 2) {
      _showErrorDialog(
        title: 'Validación de apellido',
        message: 'El apellido debe tener al menos 2 caracteres.',
      );
      return;
    }

    // Validar Género
    if (_selectedGenero == null || _selectedGenero!.isEmpty) {
      _showErrorDialog(
        title: 'Campo incompleto',
        message: 'Por favor, selecciona tu género.',
      );
      return;
    }

    // Validar Estado Civil
    final estadoCivil = _estadoCivilController.text.trim();
    if (estadoCivil.isEmpty) {
      _showErrorDialog(
        title: 'Campo incompleto',
        message: 'Por favor, ingresa tu estado civil.',
      );
      return;
    }

    // Validar formato de email
    final email = _correoController.text.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog(
        title: 'Email inválido',
        message: 'Por favor, ingresa un email válido.',
      );
      return;
    }

    // Validar formato de teléfono
    final telefono = _telefonoController.text.trim();
    if (!RegExp(r'^\d{10,15}$').hasMatch(telefono)) {
      _showErrorDialog(
        title: 'Teléfono inválido',
        message: 'El teléfono debe contener solo números (10-15 dígitos).',
      );
      return;
    }

    LoadingOverlay.show(context, message: 'Creando cuenta...');

    try {
      final fcmToken = await _resolveFcmToken();

      // Crear PlayerData actualizado (solo campos editables)
      final updatedData = widget.playerData.copyWith(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        correoElectronico: email,
        telefono: telefono,
        estadoCivil: _estadoCivilController.text.trim(),
        sexo: _selectedGenero ?? '',
      );

      // Preparar payload con estructura exacta requerida por el backend
      final payload = {
        'websocketLink': WebSocketUrlService.generateAffiliationUrl(),
        'playerData': () {
          final data = <String, dynamic>{
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
          };

          final token = widget.affiliateToken?.trim();
          if (token != null && token.isNotEmpty) {
            data['token_afiliador'] = token;
          }

          return data;
        }(),
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      };

      // Enviar POST al endpoint de registro
      final url = Uri.parse('${ApiConfig.baseUrl}/users/auth/register');

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ REGISTRO EXITOSO - El token se envía por mail
        if (!mounted) return;

        // Evitar reutilizar tokens viejos/vencidos de sesiones anteriores
        // durante el flujo de afiliación del registro actual.
        await TokenService.deleteToken();

        final affiliateToken = widget.affiliateToken?.trim();
        try {
          final prefs = await SharedPreferences.getInstance();
          final eligible = affiliateToken == null || affiliateToken.isEmpty;
          await prefs.setBool('roulette_eligible', eligible);
          if (eligible) {
            await prefs.setBool('roulette_shown', false);
            await clearAffiliateCodeUsage();
          } else {
            await prefs.setBool('roulette_shown', true);
            await saveAffiliateCodeUsage(
              validated: true,
              token: affiliateToken,
            );
          }
        } catch (_) {}

        if (!mounted) return;

        // Extraer los datos que devuelve el backend (estos son los datos confirmados)
        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {}

        // Guardar tokens que devuelve el backend
        String? tokenFromResponse;
        try {
          final accessToken =
              responseData['accessToken'] ??
              responseData['token'] ??
              responseData['jwt'];
          if (accessToken is String && accessToken.isNotEmpty) {
            tokenFromResponse = accessToken;
            await TokenService.saveToken(accessToken);
          }

          final refreshToken = responseData['refreshToken'];
          if (refreshToken is String && refreshToken.isNotEmpty) {
            await TokenService.saveRefreshToken(refreshToken);
          }

          final fcmTokenFromResponse =
              responseData['fcm_token'] ?? responseData['fcmToken'];
          if (fcmTokenFromResponse is String &&
              fcmTokenFromResponse.isNotEmpty) {
            await TokenService.saveFcmToken(fcmTokenFromResponse);
          }
        } catch (e) {}

        // Durante onboarding evitamos llamadas autenticadas extra (ej. FCM)
        // para no disparar falsos "sesión expirada" con tokens recién emitidos.

        // Guardar datos en notifiers para acceso posterior en EmailConfirmationPage
        // Usar los datos devueltos por el backend si están disponibles, si no usar updatedData
        final playerDataFromResponse = responseData['playerData'];

        if (playerDataFromResponse != null) {
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

        // Mostrar mensaje de éxito y navegar
        _showSuccessDialog(
          message: 'Cuenta creada. Verifica tu email para continuar...',
          onOk: () {
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
          },
        );
      } else if (response.statusCode == 409) {
        // ❌ ERROR 409 - Usuario/Email ya existe
        if (!mounted) return;

        final errorMessage = _extractBackendErrorMessage(
          response.body,
          fallback:
              'El usuario o email ya están registrados. Por favor, intenta con otros datos.',
        );

        _showErrorDialog(title: 'Usuario duplicado', message: errorMessage);
      } else {
        // ❌ OTROS ERRORES
        if (!mounted) return;

        String errorMessage = _extractBackendErrorMessage(
          response.body,
          fallback: ErrorParser.parseResponse(response),
        );

        if (errorMessage.toLowerCase().contains('duplicate key') ||
            errorMessage.contains('jugadores_dni_key')) {
          errorMessage =
              'El DNI ya está registrado. Usá un DNI diferente o recuperá acceso.';
        }

        _showErrorDialog(title: 'Error de registro', message: errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      LoadingOverlay.hide(context);

      final errorTitle = 'Error de conexión';
      final errorMessage = ErrorParser.parse(e);

      _showErrorDialog(title: errorTitle, message: errorMessage);
    }
  }

  // ─── Helpers de estilo ──────────────────────────────────────────────────────

  static const _green = AppConstants.primaryGreen;
  static const _scaffoldBg = Color(0xFF0E0E0E);
  static const _cardBg = Color(0xFF111111);
  static const _tileBg = Color(0xFF141414);

  /// Sub-header con barra verde izquierda (igual que en settings_page)
  Widget _buildSectionTitle(String title, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra izquierda degradada
            Container(
              width: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_green, Color(0xFF1ADB4E)],
                ),
              ),
            ),
            // Contenido
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _cardBg,
                  border: Border.all(
                    color: _green.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: _green, size: 15),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
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

  /// Campo de solo lectura — tile con lock icon y badge verde
  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _tileBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _green.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.35),
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _green.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: _green.withValues(alpha: 0.55),
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'fijo',
                    style: TextStyle(
                      color: _green.withValues(alpha: 0.55),
                      fontSize: 10,
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

  /// Campo editable con estilo dark neon
  Widget _buildEditableField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'Campo de $label',
        hint: 'Puedes editar este campo',
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: _green,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            prefixIcon: icon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(icon, color: _green.withValues(alpha: 0.6), size: 18),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: _tileBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _green.withValues(alpha: 0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _green.withValues(alpha: 0.14), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Dropdown de género con estilo dark neon
  Widget _buildGeneroDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: 'Campo de Sexo',
        hint: 'Puedes seleccionar tu sexo',
        child: Container(
          decoration: BoxDecoration(
            color: _tileBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _green.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButton<String>(
            value: _selectedGenero,
            hint: Text(
              'Selecciona tu sexo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1C1C1C),
            icon: Icon(
              Icons.expand_more_rounded,
              color: _green.withValues(alpha: 0.6),
              size: 20,
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
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

  /// Card de sección para el layout web
  Widget _buildWebSectionCard({
    required BuildContext context,
    required String title,
    required IconData sectionIcon,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _green.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: _green.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Icon(sectionIcon, color: _green, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _green,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _green.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = widget.playerData;

    final header = Column(
      children: [
        // Ícono decorativo
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: _green.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.assignment_turned_in_outlined,
            color: _green,
            size: 28,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Confirmá tus datos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _green,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Verificá que todos tus datos sean correctos',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    // Botón de confirmar reutilizable
    Widget confirmButton({double height = 52}) => AppButton(
      label: 'Confirmar datos',
      onPressed: _onConfirmarDatos,
      isLoading: _isLoading,
      icon: Icons.check_circle_outline_rounded,
      borderRadius: AppConstants.borderRadius,
      height: height,
    );

    return Scaffold(
      backgroundColor: _scaffoldBg,
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
                    const SizedBox(height: 28),
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
                                  sectionIcon: Icons.edit_outlined,
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildEditableField(
                                        context,
                                        'Nombre',
                                        _nombreController,
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      _buildEditableField(
                                        context,
                                        'Apellido',
                                        _apellidoController,
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      _buildGeneroDropdown(context),
                                      _buildEditableField(
                                        context,
                                        'Estado Civil',
                                        _estadoCivilController,
                                        icon: Icons.favorite_border_rounded,
                                      ),
                                    ],
                                  ),
                                );
                              case 1:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Contacto',
                                  sectionIcon: Icons.contact_mail_outlined,
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildEditableField(
                                        context,
                                        'Correo Electrónico',
                                        _correoController,
                                        keyboardType: TextInputType.emailAddress,
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      _buildEditableField(
                                        context,
                                        'Teléfono',
                                        _telefonoController,
                                        keyboardType: TextInputType.phone,
                                        icon: Icons.phone_outlined,
                                      ),
                                    ],
                                  ),
                                );
                              case 2:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Datos personales',
                                  sectionIcon: Icons.badge_outlined,
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildReadOnlyField(
                                        context, 'DNI', data.dni,
                                        icon: Icons.credit_card_outlined,
                                      ),
                                      _buildReadOnlyField(
                                        context, 'CUIL', data.cuil,
                                        icon: Icons.numbers_rounded,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Fecha de Nacimiento',
                                        data.fechaNacimiento,
                                        icon: Icons.calendar_today_outlined,
                                      ),
                                      _buildReadOnlyField(
                                        context,
                                        'Año de Nacimiento',
                                        data.anioNacimiento,
                                        icon: Icons.event_outlined,
                                      ),
                                      if (data.edad != null)
                                        _buildReadOnlyField(
                                          context,
                                          'Edad',
                                          data.edad.toString(),
                                          icon: Icons.cake_outlined,
                                        ),
                                    ],
                                  ),
                                );
                              case 3:
                              default:
                                return _buildWebSectionCard(
                                  context: context,
                                  title: 'Dirección',
                                  sectionIcon: Icons.home_outlined,
                                  padding: cardPadding,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildReadOnlyField(
                                        context, 'Calle', data.calle,
                                        icon: Icons.signpost_outlined,
                                      ),
                                      _buildReadOnlyField(
                                        context, 'Número', data.numCalle,
                                        icon: Icons.pin_outlined,
                                      ),
                                      _buildReadOnlyField(
                                        context, 'Localidad', data.localidad,
                                        icon: Icons.location_city_outlined,
                                      ),
                                      _buildReadOnlyField(
                                        context, 'Provincia', data.provincia,
                                        icon: Icons.map_outlined,
                                      ),
                                      if (data.cp != null)
                                        _buildReadOnlyField(
                                          context,
                                          'Código Postal',
                                          data.cp.toString(),
                                          icon: Icons.markunread_mailbox_outlined,
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
                        child: confirmButton(height: 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  header,
                  const SizedBox(height: 32),

                  // ── DATOS PERSONALES ─────────────────────────────────────
                  _buildSectionTitle('Datos Personales', Icons.badge_outlined),
                  const SizedBox(height: 12),

                  _buildReadOnlyField(
                    context, 'DNI', data.dni,
                    icon: Icons.credit_card_outlined,
                  ),
                  _buildReadOnlyField(
                    context, 'CUIL', data.cuil,
                    icon: Icons.numbers_rounded,
                  ),
                  _buildReadOnlyField(
                    context,
                    'Fecha de Nacimiento',
                    data.fechaNacimiento,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _buildReadOnlyField(
                    context,
                    'Año de Nacimiento',
                    data.anioNacimiento,
                    icon: Icons.event_outlined,
                  ),
                  if (data.edad != null)
                    _buildReadOnlyField(
                      context, 'Edad', data.edad.toString(),
                      icon: Icons.cake_outlined,
                    ),

                  const SizedBox(height: 20),

                  // ── DATOS EDITABLES ──────────────────────────────────────
                  _buildSectionTitle('Datos Editables', Icons.edit_outlined),
                  const SizedBox(height: 12),

                  _buildEditableField(
                    context, 'Nombre', _nombreController,
                    icon: Icons.person_outline_rounded,
                  ),
                  _buildEditableField(
                    context, 'Apellido', _apellidoController,
                    icon: Icons.person_outline_rounded,
                  ),
                  _buildGeneroDropdown(context),
                  _buildEditableField(
                    context, 'Estado Civil', _estadoCivilController,
                    icon: Icons.favorite_border_rounded,
                  ),

                  const SizedBox(height: 20),

                  // ── CONTACTO ─────────────────────────────────────────────
                  _buildSectionTitle('Contacto', Icons.contact_mail_outlined),
                  const SizedBox(height: 12),

                  _buildEditableField(
                    context,
                    'Correo Electrónico',
                    _correoController,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded,
                  ),
                  _buildEditableField(
                    context,
                    'Teléfono',
                    _telefonoController,
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_outlined,
                  ),

                  const SizedBox(height: 20),

                  // ── DIRECCIÓN ────────────────────────────────────────────
                  _buildSectionTitle('Dirección', Icons.home_outlined),
                  const SizedBox(height: 12),

                  _buildReadOnlyField(
                    context, 'Calle', data.calle,
                    icon: Icons.signpost_outlined,
                  ),
                  _buildReadOnlyField(
                    context, 'Número', data.numCalle,
                    icon: Icons.pin_outlined,
                  ),
                  _buildReadOnlyField(
                    context, 'Localidad', data.localidad,
                    icon: Icons.location_city_outlined,
                  ),
                  _buildReadOnlyField(
                    context, 'Provincia', data.provincia,
                    icon: Icons.map_outlined,
                  ),
                  if (data.cp != null)
                    _buildReadOnlyField(
                      context,
                      'Código Postal',
                      data.cp.toString(),
                      icon: Icons.markunread_mailbox_outlined,
                    ),

                  const SizedBox(height: 28),

                  // ── BOTÓN CONFIRMAR ──────────────────────────────────────
                  confirmButton(height: 52),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }
}
