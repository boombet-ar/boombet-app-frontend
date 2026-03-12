import 'dart:async';
import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/games/play_roulette_page.dart';
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
  }

  @override
  void dispose() {
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppConstants.snackbarDuration),
    );
  }

  void _appendLog(String message) {
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

      final spinFinished = await Navigator.push<bool>(
        context,
        FadeRoute<bool>(
          page: PlayRoulettePage(
            codigoRuleta: codigo,
            rouletteWsUrl: rouletteWsUrl,
            qrRawValue: value,
            qrParsedUri: uri.toString(),
          ),
        ),
      );
      if (!mounted) return;

      if (spinFinished == true) {
        _appendLog('Roulette finished: closing scanner view');
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
      }

      _appendLog('Roulette page closed without spinFinished=true');
      _handlingRouletteFlow = false;
      await _activateScanner();
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

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const primaryGreen = AppConstants.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppConstants.primaryGreen,
            size: 20,
          ),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primaryGreen.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppConstants.primaryGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Escanear QR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
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
          ResponsiveWrapper(
            maxWidth: 900,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.paddingLarge,
                8,
                AppConstants.paddingLarge,
                AppConstants.paddingLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildScannerCard(),
                  const SizedBox(height: 14),
                  _buildControls(),
                  const SizedBox(height: 14),
                  _buildLogsPanel(),
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
