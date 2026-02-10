import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

class PlayRoulettePage extends StatefulWidget {
  final String? codigoRuleta;
  final String? qrRawValue;
  final String? qrParsedUri;

  const PlayRoulettePage({
    super.key,
    this.codigoRuleta,
    this.qrRawValue,
    this.qrParsedUri,
  });

  @override
  State<PlayRoulettePage> createState() => _PlayRoulettePageState();
}

class _PlayRoulettePageState extends State<PlayRoulettePage> {
  bool _isLoading = false;
  String? _rouletteStatus;
  String? _statusMessage;
  String? _resolvedCodigo;

  Future<String> _resolveCodigoRuleta() async {
    final direct = widget.codigoRuleta?.trim() ?? '';
    if (direct.isNotEmpty) return direct;

    await loadAffiliateCodeUsage();
    return affiliateCodeTokenNotifier.value.trim();
  }

  Future<void> _playRoulette() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final code = await _resolveCodigoRuleta();
    if (mounted) {
      setState(() {
        _resolvedCodigo = code.isEmpty ? null : code;
      });
    }
    if (!mounted) return;

    if (code.isEmpty) {
      setState(() {
        _isLoading = false;
        _rouletteStatus = 'locked';
        _statusMessage = 'No se encontró el código de afiliador.';
      });
      return;
    }

    final encoded = Uri.encodeComponent(code);
    final url = '${ApiConfig.baseUrl}/ruleta/jugar?codigoRuleta=$encoded';

    try {
      final response = await HttpClient.post(
        url,
        body: const {},
        includeAuth: true,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _rouletteStatus = 'available';
          _statusMessage = 'Ruleta disponible.';
        });
      } else {
        setState(() {
          _rouletteStatus = 'locked';
          _statusMessage = response.body.isNotEmpty
              ? response.body
              : 'Ruleta ocupada o código inválido.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rouletteStatus = 'locked';
        _statusMessage = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const MainAppBar(
        showSettings: false,
        showLogo: true,
        showBackButton: true,
        showProfileButton: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'RULETA',
                  style: TextStyle(
                    fontSize: AppConstants.headingLarge,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    'Apreta el siguiente boton para poder jugar a la ruleta en la pantalla',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_rouletteStatus != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _rouletteStatus == 'available'
                        ? 'Estado: available'
                        : 'Estado: locked',
                    style: TextStyle(
                      color: _rouletteStatus == 'available'
                          ? AppConstants.primaryGreen
                          : AppConstants.warningOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (widget.qrRawValue != null || widget.qrParsedUri != null) ...[
                  const SizedBox(height: 16),
                  _buildDebugPanel(textColor),
                ],
                const SizedBox(height: 20),
                _buildPlayButton(accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: 220,
        height: 52,
        child: TextButton(
          onPressed: _isLoading ? null : _playRoulette,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Jugar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel(Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug QR',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _buildDebugRow('Raw', widget.qrRawValue, textColor),
          _buildDebugRow('URI', widget.qrParsedUri, textColor),
          _buildDebugRow('Codigo usado', _resolvedCodigo, textColor),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String? value, Color textColor) {
    final display = (value == null || value.trim().isEmpty)
        ? '-'
        : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $display',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 12,
        ),
      ),
    );
  }
}
