import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/play_roulette_page.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  late final MobileScannerController _scannerController;
  final TextEditingController _manualCodeController = TextEditingController();
  bool _flashOn = false;
  String? _lastCode;
  DateTime? _lastScanAt;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppConstants.snackbarDuration),
    );
  }

  void _submitManualCode() {
    final value = _manualCodeController.text.trim();
    if (value.isEmpty) {
      _showSnack('Ingresa un codigo valido');
      return;
    }
    setState(() {
      _lastCode = value;
    });
    _showSnack('Codigo registrado');
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    String? value;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        value = raw;
        break;
      }
    }

    if (value == null) return;

    final now = DateTime.now();
    final isDuplicate =
        value == _lastCode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(seconds: 2);

    if (isDuplicate) return;

    setState(() {
      _lastCode = value;
      _lastScanAt = now;
    });

    final uri = _normalizeUri(value);
    if (uri == null) {
      return;
    }

    if (_isRouletteDeepLink(uri)) {
      if (!mounted) return;
      Navigator.push(context, FadeRoute(page: const PlayRoulettePage()));
      return;
    }

    if (_isLaunching) return;
    _isLaunching = true;
    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) {
        if (mounted) {
          _showSnack('No se pudo abrir el enlace');
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;
    final surfaceColor = isDark
        ? AppConstants.darkCardBg
        : AppConstants.lightCardBg;
    final appBarColor = isDark
        ? Colors.black38
        : AppConstants.lightSurfaceVariant;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: accent),
          tooltip: 'Volver',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: accent),
            const SizedBox(width: 10),
            Text(
              'Escanear QR',
              style: TextStyle(
                color: isDark ? AppConstants.textDark : AppConstants.textLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apunta al codigo QR dentro del marco',
                style: TextStyle(
                  fontSize: AppConstants.bodyLarge,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppConstants.textDark
                      : AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mantiene la camara estable para una lectura rapida.',
                style: TextStyle(
                  fontSize: AppConstants.bodySmall,
                  color: isDark
                      ? AppConstants.textDark.withValues(alpha: 0.7)
                      : AppConstants.textLight.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              _buildScannerCard(isDark, accent, surfaceColor),
              const SizedBox(height: 18),
              _buildControls(isDark, accent, surfaceColor),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      FadeRoute(page: const PlayRoulettePage()),
                    );
                  },
                  child: const Text('Ir a la ruleta (test)'),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerCard(bool isDark, Color accent, Color surfaceColor) {
    final frameBorder = Border.all(
      color: accent.withValues(alpha: 0.75),
      width: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0C0C0C), Color(0xFF151515)]
                        : const [Color(0xFFE6E6E6), Color(0xFFD9D9D9)],
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: frameBorder,
                  ),
                ),
              ),
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
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.0),
                                    accent.withValues(alpha: 0.9),
                                    accent.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              Center(
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _handleDetection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(bool isDark, Color accent, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(
                _flashOn ? Icons.flash_on : Icons.flash_off,
                color: accent,
              ),
              label: Text(
                _flashOn ? 'Linterna activa' : 'Linterna apagada',
                style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                try {
                  await _scannerController.toggleTorch();
                  if (!mounted) return;
                  setState(() {
                    _flashOn = !_flashOn;
                  });
                } catch (_) {
                  if (mounted) {
                    _showSnack('No se pudo activar la linterna');
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Cambiar camara'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            onPressed: () async {
              try {
                await _scannerController.switchCamera();
                if (mounted) {
                  _showSnack('Camara alternada');
                }
              } catch (_) {
                if (mounted) {
                  _showSnack('No se pudo alternar la camara');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
