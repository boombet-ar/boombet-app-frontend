import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/prize_canje_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/stands_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _maxLogEntries = 80;

  late final AnimationController _scanController;
  late final MobileScannerController _scannerController;
  final TextEditingController _manualCodeController = TextEditingController();
  final List<String> _scanLogs = <String>[];
  bool _flashOn = false;
  String? _lastCode;
  DateTime? _lastScanAt;
  bool _isLaunching = false;
  bool _scannerActive = false;
  bool _handlingRouletteFlow = false;
  bool _handlingCanjeFlow = false;
  String? _userRole;
  final AffiliationService _affiliationService = AffiliationService();
  StreamSubscription<Map<String, dynamic>>? _rouletteWsSubscription;
  bool _spinResultHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scannerController = MobileScannerController();
    _scannerActive = true;
    _appendLog('Scanner initialized');
    _loadUserRole();
  }

  @override
  void dispose() {
    _rouletteWsSubscription?.cancel();
    _affiliationService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scanController.dispose();
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    _activateScanner();
  }

  @override
  void deactivate() {
    _deactivateScanner();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activateScanner();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _deactivateScanner();
    }
  }

  Future<void> _activateScanner() async {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    if (_scannerActive) return;

    try {
      await _scannerController.start();
      _appendLog('Scanner started');
    } catch (_) {
      _appendLog('Scanner start failed');
      return;
    }

    if (!mounted) return;
    _scanController.repeat(reverse: true);
    _scannerActive = true;
  }

  Future<void> _deactivateScanner() async {
    if (!_scannerActive) return;

    try {
      await _scannerController.stop();
      _appendLog('Scanner stopped');
    } catch (_) {
      _appendLog('Scanner stop failed');
      return;
    }

    if (!mounted) return;
    _scanController.stop();
    _scannerActive = false;
  }

  Future<void> _loadUserRole() async {
    final role = await TokenService.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = role);
    _appendLog('User role loaded: ${role ?? 'unknown'}');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppConstants.snackbarDuration),
    );
  }

  void _appendLog(String message) {
    if (!AppConstants.qrScannerDebugConsoleEnabled) return;
    if (!mounted) return;

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final mmm = now.millisecond.toString().padLeft(3, '0');
    final line = '[$hh:$mm:$ss.$mmm] $message';

    setState(() {
      _scanLogs.insert(0, line);
      if (_scanLogs.length > _maxLogEntries) {
        _scanLogs.removeRange(_maxLogEntries, _scanLogs.length);
      }
    });
  }

  void _submitManualCode() {
    final value = _manualCodeController.text.trim();
    if (value.isEmpty) {
      _appendLog('Manual code is empty');
      _showSnack('Ingresa un codigo valido');
      return;
    }
    setState(() {
      _lastCode = value;
    });
    _appendLog('Manual code received: $value');
    _showSnack('Codigo registrado');
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_handlingRouletteFlow) {
      _appendLog('Detection ignored: roulette flow in progress');
      return;
    }

    String? value;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }

    if (value == null) {
      _appendLog('Detection ignored: empty raw value');
      return;
    }

    _appendLog('QR detected: $value');

    final now = DateTime.now();
    final isDuplicate =
        value == _lastCode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 2);

    if (isDuplicate) {
      _appendLog('Detection ignored: duplicate within debounce window');
      return;
    }

    setState(() {
      _lastCode = value;
      _lastScanAt = now;
    });

    // STAND role: intercept every QR for prize canje
    if (_userRole == 'STAND') {
      if (_handlingCanjeFlow) {
        _appendLog('Detection ignored: canje flow in progress');
        return;
      }
      final canjeId = _extractStandCanjeId(value);
      if (canjeId == null) {
        _appendLog('STAND: no valid canje ID in QR value');
        _showSnack('QR inválido para canje de premios');
        return;
      }
      _appendLog('STAND: canje ID extracted: $canjeId');
      await _handleStandCanje(canjeId);
      return;
    }

    final uri = _normalizeUri(value);
    if (uri == null) {
      _appendLog('QR rejected: could not normalize to URI');
      return;
    }

    _appendLog('Normalized URI: $uri');

    if (_isRouletteDeepLink(uri)) {
      _appendLog('Roulette deeplink detected');
      if (!mounted) return;
      final codigo = _extractRouletteCode(uri);
      if (codigo == null || codigo.trim().isEmpty) {
        _appendLog('Roulette code missing/invalid');
        _showSnack('Codigo de ruleta invalido');
        return;
      }

      _appendLog('Roulette code extracted: $codigo');

      _handlingRouletteFlow = true;

      await _deactivateScanner();
      final rouletteWsUrl = await _joinRoulette(codigo.trim());
      if (!mounted) return;
      if (rouletteWsUrl == null || rouletteWsUrl.trim().isEmpty) {
        _appendLog('Roulette join failed: no wsUrl returned');
        _showSnack('No se pudo habilitar la ruleta');
        _handlingRouletteFlow = false;
        await _activateScanner();
        return;
      }

      _appendLog('Roulette wsUrl resolved: $rouletteWsUrl');

      await _connectAndSpinRoulette(rouletteWsUrl);
      return;
    }

    _appendLog('Non-roulette URI, opening external app');

    if (_isLaunching) return;
    _isLaunching = true;
    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) {
        _appendLog('Launch blocked: canLaunchUrl returned false');
        if (mounted) {
          _showSnack('No se pudo abrir el enlace');
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _appendLog('URI launched successfully');
    } catch (_) {
      _appendLog('Launch failed: exception thrown');
      if (mounted) {
        _showSnack('No se pudo abrir el enlace');
      }
    } finally {
      _isLaunching = false;
    }
  }

  Future<void> _connectAndSpinRoulette(String wsUrl) async {
    _spinResultHandled = false;

    // 1. Suscribirse ANTES de conectar para no perder ningún mensaje del servidor.
    //    El messageStream es broadcast: mensajes emitidos antes de suscribirse se pierden.
    _rouletteWsSubscription = _affiliationService.messageStream.listen(
      (payload) {
        if (_spinResultHandled) return;

        final spinFinishedValue = payload['spinFinished'];
        final isSpinFinished =
            spinFinishedValue == true ||
            spinFinishedValue?.toString().toLowerCase() == 'true';
        if (!isSpinFinished) return;

        _spinResultHandled = true;
        // Sin await: cancelar la suscripción desde dentro de su propio callback
        // con await puede interrumpir la ejecución del callback en Dart.
        _rouletteWsSubscription?.cancel();
        _rouletteWsSubscription = null;

        if (!mounted) return;

        final premioRaw = payload['premio'];
        if (premioRaw is Map<String, dynamic>) {
          final nombre = premioRaw['nombre']?.toString();
          final idStandRaw = premioRaw['idStand'];
          if (nombre != null && nombre.isNotEmpty && idStandRaw != null) {
            final idStand =
                idStandRaw is int
                    ? idStandRaw
                    : int.tryParse(idStandRaw.toString());
            // El overlay de Girando se cierra dentro de _handleRoulettePrize,
            // justo antes del showDialog del premio, para no dejar pantalla negra.
            _handleRoulettePrize(
              nombre: nombre,
              imgUrl: premioRaw['imgUrl']?.toString(),
              idStand: idStand,
            );
            return;
          }
        }

        _appendLog('Spin finished without valid prize');
        _affiliationService.closeWebSocket();
        // Cerrar el overlay de Girando
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      onError: (_) {},
      onDone: () {},
    );

    // 2. Conectar WS (connectToWebSocket no aguarda el handshake real, pero el
    //    canal bufferiza mensajes salientes hasta que la conexión esté lista).
    try {
      await _affiliationService.connectToWebSocket(wsUrl: wsUrl);
    } catch (e) {
      _appendLog('WS connection failed: $e');
      await _rouletteWsSubscription?.cancel();
      _rouletteWsSubscription = null;
      if (mounted) _showSnack('No se pudo conectar a la ruleta');
      _handlingRouletteFlow = false;
      await _activateScanner();
      return;
    }

    // 3. Resolver identidad del usuario
    final identity = await _resolveUserIdentityFromUsersMe();
    final username = identity['username']?.toString().trim() ?? '';
    final userId = identity['userId'];

    if (username.isEmpty || userId == null) {
      _appendLog('Could not resolve user identity for roulette');
      await _rouletteWsSubscription?.cancel();
      _rouletteWsSubscription = null;
      _affiliationService.closeWebSocket();
      if (mounted) _showSnack('No se pudo obtener tu identidad');
      _handlingRouletteFlow = false;
      await _activateScanner();
      return;
    }

    // 4. Enviar identidad
    _affiliationService.sendMessage({'username': username, 'userId': userId});
    _appendLog('Sent username/userId to WS');

    // 5. Mostrar overlay de espera
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      useRootNavigator: false,
      builder: (_) => const _RouletteSpinningOverlay(),
    );

    // 6. Disparar el giro
    _affiliationService.sendMessage({'spinRoulette': true});
    _appendLog('Sent spinRoulette: true');
  }

  Future<void> _handleRoulettePrize({
    required String nombre,
    String? imgUrl,
    int? idStand,
  }) async {
    // Fetch del stand mientras el overlay de Girando sigue visible (sin pantalla negra).
    String? standNombre;
    if (idStand != null && idStand > 0) {
      final stand = await StandsService().fetchStandById(idStand);
      standNombre = stand?.nombre;
    }

    _affiliationService.closeWebSocket();
    if (!mounted) return;

    // Cerrar el overlay de Girando justo antes de mostrar el premio,
    // para que no haya ningún frame de pantalla negra entre los dos.
    Navigator.of(context).pop();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      useRootNavigator: false,
      builder: (_) => _RouletteResultDialog(
        nombre: nombre,
        imgUrl: imgUrl,
        standNombre: standNombre,
      ),
    );
    // El scanner queda de fondo, no se cierra.
    _appendLog('Roulette prize dialog dismissed, scanner still active');
    _handlingRouletteFlow = false;
  }

  Future<Map<String, dynamic>> _resolveUserIdentityFromUsersMe() async {
    final url = '${ApiConfig.baseUrl}/users/me';
    try {
      final response = await HttpClient.get(
        url,
        includeAuth: true,
        cacheTtl: Duration.zero,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const {};
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const {};

      dynamic pickFirstId(Map<String, dynamic>? src) =>
          src == null ? null : src['id'] ?? src['usuario_id'] ?? src['user_id'];

      dynamic normalizeId(dynamic v) {
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString().trim()) ?? v;
      }

      final rootUserId = normalizeId(pickFirstId(decoded));
      final rootData = decoded['data'];
      final dataUserId = normalizeId(
        rootData is Map<String, dynamic> ? pickFirstId(rootData) : null,
      );

      Map<String, dynamic>? datosJugador;
      final direct = decoded['datos_jugador'];
      if (direct is Map<String, dynamic>) {
        datosJugador = direct;
      } else if (rootData is Map<String, dynamic>) {
        final nested = rootData['datos_jugador'];
        if (nested is Map<String, dynamic>) datosJugador = nested;
      }

      if (datosJugador == null) return const {};

      final username = datosJugador['username']?.toString().trim() ?? '';
      final userId = rootUserId ?? dataUserId;
      if (username.isNotEmpty && userId != null) {
        return {'username': username, 'userId': userId};
      }
      return const {};
    } catch (_) {
      return const {};
    }
  }

  Uri? _normalizeUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final baseUri = Uri.tryParse(trimmed);
    if (baseUri != null && baseUri.scheme.isNotEmpty) {
      return baseUri;
    }

    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
    if (isEmail) {
      return Uri.tryParse('mailto:$trimmed');
    }

    final isPhone = RegExp(r'^\+?[0-9]{6,}$').hasMatch(trimmed);
    if (isPhone) {
      return Uri.tryParse('tel:$trimmed');
    }

    final noSpaces = !trimmed.contains(' ');
    if (noSpaces) {
      return Uri.tryParse('https://$trimmed') ??
          Uri.tryParse('http://$trimmed');
    }

    return null;
  }

  bool _isRouletteDeepLink(Uri uri) {
    if (uri.scheme != 'boombet') return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host.contains('roulette') || path.contains('roulette');
  }

  String? _extractRouletteCode(Uri uri) {
    final queryCode =
        uri.queryParameters['codigoRuleta'] ??
        uri.queryParameters['codigo_ruleta'] ??
        uri.queryParameters['code'] ??
        uri.queryParameters['codigo'];
    if (queryCode != null && queryCode.trim().isNotEmpty) {
      return queryCode.trim();
    }

    if (uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty && last.toLowerCase() != 'roulette') {
        return last;
      }
    }

    return null;
  }

  Future<String?> _joinRoulette(String codigo) async {
    final encoded = Uri.encodeComponent(codigo);
    final url =
        '${ApiConfig.baseUrl}/ruleta/usuario/jugar?codigoRuleta=$encoded';
    _appendLog('Joining roulette via POST: $url');
    try {
      final role = await TokenService.getUserRole();
      final token = await TokenService.getToken();
      _appendLog(
        'Auth context -> role=${role ?? 'unknown'} | accessToken=${token == null || token.isEmpty ? 'missing' : 'present(len:${token.length})'}',
      );

      final response = await HttpClient.post(
        url,
        body: const {},
        includeAuth: true,
        expireSessionOnAuthFailure: false,
      );

      _appendLog('Join response status: ${response.statusCode}');
      if (response.statusCode == 401 || response.statusCode == 403) {
        _appendLog('Auth rejected by backend for roulette join');
      }

      if (response.statusCode != 200) {
        return null;
      }

      final roomId = _extractRoomIdFromJoinResponse(response.body);
      if (roomId == null || roomId.trim().isEmpty) {
        return null;
      }

      return _buildRouletteWsUrl(roomId.trim());
    } catch (e) {
      _appendLog('Join request failed with exception');
      return null;
    }
  }

  String? _extractRoomIdFromJoinResponse(String body) {
    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return null;
    }

    String? readFrom(dynamic node) {
      if (node is! Map) return null;

      final map = Map<String, dynamic>.from(node as Map);
      final direct =
          map['roomId'] ?? map['room_id'] ?? map['roomID'] ?? map['room'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }

      final data = map['data'];
      if (data is Map) {
        final nested = readFrom(data);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      }

      return null;
    }

    return readFrom(decoded);
  }

  String _buildRouletteWsUrl(String roomId) {
    final safeRoomId = Uri.encodeComponent(roomId);
    return '${ApiConfig.wsBaseUrl}/ruleta/$safeRoomId';
  }

  // ─── STAND CANJE ─────────────────────────────────────────────────────────

  /// Extracts the prize user ID from the raw QR value.
  /// Accepts: plain integer, boombet://...?idPremioUsuario=N, or last path segment.
  int? _extractStandCanjeId(String rawValue) {
    final trimmed = rawValue.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final qp =
        uri.queryParameters['idPremioUsuario'] ??
        uri.queryParameters['id_premio_usuario'] ??
        uri.queryParameters['id'];
    if (qp != null) {
      final parsed = int.tryParse(qp.trim());
      if (parsed != null) return parsed;
    }

    if (uri.pathSegments.isNotEmpty) {
      final last = int.tryParse(uri.pathSegments.last.trim());
      if (last != null) return last;
    }

    return null;
  }

  Future<void> _handleStandCanje(int idPremioUsuario) async {
    _handlingCanjeFlow = true;
    await _deactivateScanner();
    if (!mounted) return;

    _appendLog('Fetching canje info for idPremioUsuario: $idPremioUsuario');
    PrizeCanjeModel? info;
    try {
      info = await StandsService().fetchCanjeInfo(idPremioUsuario);
    } catch (e) {
      _appendLog('fetchCanjeInfo failed: $e');
      if (mounted) _showSnack('No se pudo obtener el premio');
      _handlingCanjeFlow = false;
      await _activateScanner();
      return;
    }

    if (!mounted) return;
    _appendLog(
      'Canje info: ${info.nombrePremio} / @${info.usernameUsuario} / reclamado=${info.reclamado}',
    );

    await _showCanjeBottomSheet(info);

    if (!mounted) return;
    _handlingCanjeFlow = false;
    await _activateScanner();
  }

  Future<void> _showCanjeBottomSheet(PrizeCanjeModel info) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CanjeBottomSheet(
        info: info,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _doConfirmarCanje(info.idPremioUsuario);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _doConfirmarCanje(int idPremioUsuario) async {
    _appendLog('Confirming canje for idPremioUsuario: $idPremioUsuario');
    try {
      await StandsService().confirmarCanje(idPremioUsuario);
      _appendLog('Canje confirmed successfully');
      if (mounted) _showSnack('¡Premio canjeado correctamente!');
    } catch (e) {
      _appendLog('confirmarCanje failed: $e');
      if (mounted) _showSnack('Error al canjear el premio');
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const primaryGreen = AppConstants.primaryGreen;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: AppConstants.darkBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Escáner QR',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Radial glow — top left
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Radial glow — bottom right
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryGreen.withValues(alpha: 0.038),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: ResponsiveWrapper(
              maxWidth: 900,
              child: Column(
                children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.paddingLarge,
                          8,
                          AppConstants.paddingLarge,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildScannerCard(),
                            const SizedBox(height: 14),
                            _buildControls(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: const _SearchingAnimation(),
                        ),
                      ),
                      if (AppConstants.qrScannerDebugConsoleEnabled) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppConstants.paddingLarge,
                            0,
                            AppConstants.paddingLarge,
                            AppConstants.paddingLarge,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 14),
                              _buildLogsPanel(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const primaryGreen = AppConstants.primaryGreen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent decoration
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primaryGreen.withValues(alpha: 0.50),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.80),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withValues(alpha: 0.50),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Apunta al codigo QR dentro del marco',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Mantiene la camara estable para una lectura rapida.',
          style: TextStyle(
            fontSize: AppConstants.bodySmall,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCard() {
    const primaryGreen = AppConstants.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              // Camera feed
              Positioned.fill(
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                ),
              ),
              // Vignette
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.28),
                      ],
                    ),
                  ),
                ),
              ),
              // Corner brackets
              Positioned.fill(
                child: CustomPaint(
                  painter: _CornerFramePainter(color: primaryGreen),
                ),
              ),
              // Scan line
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final lineY =
                          constraints.maxHeight * _scanController.value;
                      return Stack(
                        children: [
                          Positioned(
                            top: lineY,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryGreen.withValues(alpha: 0.0),
                                    primaryGreen.withValues(alpha: 0.95),
                                    primaryGreen.withValues(alpha: 0.0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    const primaryGreen = AppConstants.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
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
      child: Row(
        children: [
          Expanded(child: _buildTorchButton()),
          const SizedBox(width: 10),
          Expanded(child: _buildSwitchCameraButton()),
        ],
      ),
    );
  }

  Widget _buildTorchButton() {
    const primaryGreen = AppConstants.primaryGreen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: _flashOn
            ? primaryGreen.withValues(alpha: 0.12)
            : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _flashOn
              ? primaryGreen.withValues(alpha: 0.45)
              : const Color(0xFF272727),
          width: 1,
        ),
        boxShadow: _flashOn
            ? [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.20),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: primaryGreen.withValues(alpha: 0.12),
          onTap: () async {
            try {
              await _scannerController.toggleTorch();
              if (!mounted) return;
              setState(() => _flashOn = !_flashOn);
            } catch (_) {
              if (mounted) _showSnack('No se pudo activar la linterna');
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                size: 16,
                color: _flashOn
                    ? primaryGreen
                    : Colors.white.withValues(alpha: 0.50),
              ),
              const SizedBox(width: 7),
              Text(
                _flashOn ? 'Linterna activa' : 'Linterna apagada',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _flashOn
                      ? primaryGreen
                      : Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton() {
    const primaryGreen = AppConstants.primaryGreen;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.38),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.black.withValues(alpha: 0.12),
          onTap: () async {
            try {
              await _scannerController.switchCamera();
              _appendLog('Camera switched');
              if (mounted) _showSnack('Camara alternada');
            } catch (_) {
              _appendLog('Camera switch failed');
              if (mounted) _showSnack('No se pudo alternar la camara');
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cameraswitch_rounded,
                size: 16,
                color: Colors.black.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 7),
              Text(
                'Cambiar camara',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsPanel() {
    const primaryGreen = AppConstants.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryGreen.withValues(alpha: 0.10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 16,
                color: primaryGreen.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Logs del escaner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _scanLogs.clear();
                  });
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B0B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: _scanLogs.isEmpty
                ? Center(
                    child: Text(
                      'Sin eventos todavia',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    reverse: true,
                    itemCount: _scanLogs.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.06),
                      height: 8,
                    ),
                    itemBuilder: (context, index) {
                      final line = _scanLogs[_scanLogs.length - 1 - index];
                      return Text(
                        line,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── CANJE BOTTOM SHEET ──────────────────────────────────────────────────────

class _CanjeBottomSheet extends StatelessWidget {
  final PrizeCanjeModel info;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _CanjeBottomSheet({
    required this.info,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = AppConstants.primaryGreen;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.darkAccent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.card_giftcard_outlined,
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Canje de Premio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Prize image
          _buildImage(info.imgUrl, primaryGreen),
          const SizedBox(height: 16),

          // Prize name
          Text(
            info.nombrePremio,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Username
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: primaryGreen.withValues(alpha: 0.85),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                info.usernameUsuario,
                style: TextStyle(
                  color: primaryGreen.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Already claimed warning
          if (info.reclamado) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Este premio ya fue reclamado anteriormente.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          // Canjear button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: info.reclamado ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
              child: const Text(
                'Canjear Premio',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imgUrl, Color primaryGreen) {
    final hasImage = imgUrl.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: hasImage
          ? Image.network(
              imgUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(primaryGreen),
            )
          : _placeholder(primaryGreen),
    );
  }

  Widget _placeholder(Color primaryGreen) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.20)),
      ),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: primaryGreen.withValues(alpha: 0.45),
        size: 48,
      ),
    );
  }
}

// ─── CORNER FRAME PAINTER ────────────────────────────────────────────────────

class _CornerFramePainter extends CustomPainter {
  final Color color;

  const _CornerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final solidPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const margin = 22.0;
    const arm = 32.0;

    void drawCorner(double x, double y, double hDir, double vDir) {
      final path = Path()
        ..moveTo(x + hDir * arm, y)
        ..lineTo(x, y)
        ..lineTo(x, y + vDir * arm);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, solidPaint);
    }

    // Top-left
    drawCorner(margin, margin, 1, 1);
    // Top-right
    drawCorner(size.width - margin, margin, -1, 1);
    // Bottom-right
    drawCorner(size.width - margin, size.height - margin, -1, -1);
    // Bottom-left
    drawCorner(margin, size.height - margin, 1, -1);
  }

  @override
  bool shouldRepaint(_CornerFramePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── ROULETTE UI ─────────────────────────────────────────────────────────────

class _RouletteSpinningOverlay extends StatefulWidget {
  const _RouletteSpinningOverlay();

  @override
  State<_RouletteSpinningOverlay> createState() =>
      _RouletteSpinningOverlayState();
}

class _RouletteSpinningOverlayState extends State<_RouletteSpinningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _spinFast;
  late AnimationController _spinSlow;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _spinFast = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _spinSlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _spinFast.dispose();
    _spinSlow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C2E), Color(0xFF12121F), Color(0xFF0D0D18)],
          ),
          border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.30),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryGreen.withValues(alpha: 0.20),
              blurRadius: 48,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.70),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Roulette spinning graphic
                AnimatedBuilder(
                  animation: Listenable.merge([_spinFast, _spinSlow, _pulse]),
                  builder: (context, _) {
                    return SizedBox(
                      width: 110,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.primaryGreen.withValues(
                                    alpha: _pulseAnim.value * 0.45,
                                  ),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          // Slow outer ring
                          Transform.rotate(
                            angle: _spinSlow.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(110, 110),
                              painter: _ArcRingPainter(
                                color: AppConstants.primaryGreen.withValues(
                                  alpha: 0.25,
                                ),
                                strokeWidth: 2.5,
                                sweepFraction: 0.75,
                              ),
                            ),
                          ),
                          // Fast inner ring (reverse)
                          Transform.rotate(
                            angle: -_spinFast.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: _ArcRingPainter(
                                color: AppConstants.primaryGreen.withValues(
                                  alpha: 0.55,
                                ),
                                strokeWidth: 3.5,
                                sweepFraction: 0.45,
                              ),
                            ),
                          ),
                          // Center bright ring
                          Transform.rotate(
                            angle: _spinFast.value * 2 * math.pi * 1.5,
                            child: CustomPaint(
                              size: const Size(52, 52),
                              painter: _ArcRingPainter(
                                color: AppConstants.primaryGreen,
                                strokeWidth: 4,
                                sweepFraction: 0.30,
                              ),
                            ),
                          ),
                          // Casino icon center
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppConstants.primaryGreen.withValues(
                                alpha: _pulseAnim.value * 0.18,
                              ),
                            ),
                            child: Icon(
                              Icons.casino_outlined,
                              color: AppConstants.primaryGreen.withValues(
                                alpha: 0.6 + _pulseAnim.value * 0.4,
                              ),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  '¡GIRANDO!',
                  style: TextStyle(
                    color: AppConstants.primaryGreen,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    decoration: TextDecoration.none,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepFraction;

  const _ArcRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      0,
      math.pi * 2 * sweepFraction,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.sweepFraction != sweepFraction;
}

// ─── Prize dialog — migrado desde play_roulette_page.dart ────────────────────

class _RouletteResultDialog extends StatefulWidget {
  final String nombre;
  final String? imgUrl;
  final String? standNombre;

  const _RouletteResultDialog({
    required this.nombre,
    this.imgUrl,
    this.standNombre,
  });

  @override
  State<_RouletteResultDialog> createState() => _RouletteResultDialogState();
}

class _RouletteResultDialogState extends State<_RouletteResultDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _scaleAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entryController.forward();

    // Auto-close: el dialog se cierra solo después de 5 segundos.
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _entryController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => _buildCard(child!),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Widget content) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1C2E), Color(0xFF16213E), Color(0xFF0D1B2A)],
        ),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: _glowAnim.value),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withValues(
              alpha: _glowAnim.value * 0.55,
            ),
            blurRadius: 50,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder:
                    (context, _) => CustomPaint(
                      painter: _ConfettiPainter(
                        animation: _confettiController.value,
                      ),
                    ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrophyBadge(),
          const SizedBox(height: 14),
          _buildTitle(),
          const SizedBox(height: 24),
          _buildPrizeImage(),
          const SizedBox(height: 20),
          _buildPrizeName(),
          if (widget.standNombre != null) ...[
            const SizedBox(height: 14),
            _buildStandChip(),
          ],
          const SizedBox(height: 30),
          _buildDismissButton(),
        ],
      ),
    );
  }

  Widget _buildTrophyBadge() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.95),
                const Color(0xFFFF8C00).withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(
                  alpha: _glowAnim.value * 0.75,
                ),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 38,
            color: Color(0xFFFFD700),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback:
              (bounds) => LinearGradient(
                colors: const [
                  AppConstants.primaryGreen,
                  Color(0xFFFFD700),
                  AppConstants.primaryGreen,
                ],
                stops: [0.0, _glowController.value, 1.0],
              ).createShader(bounds),
          child: const Text(
            '¡GANASTE UN PREMIO!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildPrizeImage() {
    final imgUrl = widget.imgUrl;
    final hasImage = imgUrl != null && imgUrl.isNotEmpty;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen.withValues(
                  alpha: _glowAnim.value * 0.65,
                ),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child:
            hasImage
                ? Image.network(
                  imgUrl,
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackImageBox(),
                )
                : _fallbackImageBox(),
      ),
    );
  }

  Widget _fallbackImageBox() {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppConstants.primaryGreen.withValues(alpha: 0.12),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        size: 80,
        color: AppConstants.primaryGreen,
      ),
    );
  }

  Widget _buildPrizeName() {
    return Text(
      widget.nombre,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.4,
        height: 1.25,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStandChip() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: AppConstants.primaryGreen.withValues(alpha: 0.12),
            border: Border.all(
              color: AppConstants.primaryGreen.withValues(
                alpha: _glowAnim.value * 0.6,
              ),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 17,
                color: AppConstants.primaryGreen,
              ),
              const SizedBox(width: 7),
              Text(
                'Retirá en: ${widget.standNombre}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDismissButton() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppConstants.primaryGreen, Color(0xFF00D4FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen.withValues(
                  alpha: _glowAnim.value * 0.65,
                ),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '¡Genial!  🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchingAnimation extends StatefulWidget {
  const _SearchingAnimation();

  @override
  State<_SearchingAnimation> createState() => _SearchingAnimationState();
}

class _SearchingAnimationState extends State<_SearchingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _dotsController;
  late final AnimationController _scanLineController;
  late final Animation<double> _glowAnim;
  late final Animation<double> _scanLineAnim;

  static const _green = AppConstants.primaryGreen;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _scanLineAnim = CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _dotsController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
      width: 300,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _green.withValues(alpha: 0.15),
          width: 1,
        ),
        color: _green.withValues(alpha: 0.03),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Texto principal con glow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) {
                    final glowIntensity = 0.4 + _glowAnim.value * 0.6;
                    return AnimatedBuilder(
                      animation: _dotsController,
                      builder: (_, __) {
                        final dotsCount = (_dotsController.value * 4).floor() % 4;
                        final dots = '.' * dotsCount + ' ' * (3 - dotsCount);
                        return Text(
                          'Buscando codigo$dots',
                          style: TextStyle(
                            fontFamily: 'ThaleahFat',
                            fontSize: 20,
                            color: _green.withValues(alpha: glowIntensity),
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: _green.withValues(alpha: glowIntensity * 0.8),
                                blurRadius: 8 + _glowAnim.value * 10,
                              ),
                              Shadow(
                                color: _green.withValues(alpha: glowIntensity * 0.4),
                                blurRadius: 20 + _glowAnim.value * 16,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Barrita de progreso pulsante
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final delay = i / 5.0;
                      final t = ((_glowController.value - delay + 1) % 1.0);
                      final scale = 0.4 + (math.sin(t * math.pi) * 0.6).clamp(0.0, 0.6);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 10,
                        height: 4 + scale * 10,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.3 + scale * 0.7),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: _green.withValues(alpha: scale * 0.6),
                              blurRadius: 4 + scale * 6,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double animation;
  static const _colors = [
    AppConstants.primaryGreen,
    Color(0xFFFFD700),
    Color(0xFF00D4FF),
    Color(0xFFFF6B6B),
    Colors.white,
    Color(0xFFFF9EFF),
  ];

  const _ConfettiPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99887);
    for (int i = 0; i < 22; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.6;
      final y = (baseY + animation * size.height * speed) % (size.height + 20);
      final color = _colors[random.nextInt(_colors.length)];
      final w = 4.0 + random.nextDouble() * 6;
      final h = 5.0 + random.nextDouble() * 9;
      final opacity = 0.15 + random.nextDouble() * 0.35;
      final angle = animation * math.pi * 2 * (random.nextDouble() * 4 - 2);

      final paint = Paint()..color = color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => animation != old.animation;
}
