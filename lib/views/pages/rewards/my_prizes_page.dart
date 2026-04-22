import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyPrizesPage extends StatefulWidget {
  const MyPrizesPage({super.key});

  @override
  State<MyPrizesPage> createState() => _MyPrizesPageState();
}

class _MyPrizesPageState extends State<MyPrizesPage> {
  bool _isLoading = true;
  String? _error;
  _PrizeItem? _prize;

  @override
  void initState() {
    super.initState();
    _loadPrize();
  }

  Future<void> _loadPrize() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/ruleta/usuario/mi-premio',
        includeAuth: true,
        expireSessionOnAuthFailure: false,
        cacheTtl: Duration.zero,
      );

      log('[MyPrizesPage] status=${response.statusCode} body=${response.body}');

      // Any non-2xx response → no prize (no error shown to user)
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _prize = null;
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? payload;
      try {
        final decoded = jsonDecode(response.body);
        payload = _extractPrizePayload(decoded);
      } catch (e) {
        log('[MyPrizesPage] JSON parse error: $e');
      }

      final parsedPrize = payload != null ? _PrizeItem.fromMap(payload) : null;

      setState(() {
        // If already claimed, treat as no prize
        _prize = (parsedPrize?.reclamado == true) ? null : parsedPrize;
        _isLoading = false;
      });
    } catch (e, st) {
      log('[MyPrizesPage] exception loading prize', error: e, stackTrace: st);
      setState(() {
        _prize = null;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _extractPrizePayload(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['nombre'] != null || decoded['imgUrl'] != null) {
        return decoded;
      }
      final data = decoded['data'];
      if (data is Map<String, dynamic> &&
          (data['nombre'] != null || data['imgUrl'] != null)) {
        return data;
      }
      final content = decoded['content'];
      if (content is Map<String, dynamic> &&
          (content['nombre'] != null || content['imgUrl'] != null)) {
        return content;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = AppConstants.darkBg;

    return Scaffold(
      backgroundColor: bgColor,
      body: ResponsiveWrapper(
        maxWidth: 900,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPrize,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 52,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _error!,
                        style: TextStyle(color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : _prize == null
              ? CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (r) => const LinearGradient(
                                  colors: [AppConstants.primaryGreen, Color(0xFF00E5FF)],
                                ).createShader(r),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'SIN PREMIOS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'ThaleahFat',
                                  fontSize: 22,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Todavía no tenés ningún premio asignado.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [_buildPrizeCard(context, primaryGreen, textColor)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeCard(
    BuildContext context,
    Color primaryGreen,
    Color textColor,
  ) {
    final prize = _prize!;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(prize.imgUrl, primaryGreen),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prize name
                Text(
                  prize.name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),

                // Generar QR button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showQrDialog(context, prize),
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text(
                      'Generar QR',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imgUrl, Color primaryGreen) {
    if (imgUrl.isEmpty) return _imagePlaceholder(primaryGreen);
    return Image.network(
      imgUrl,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: primaryGreen.withValues(alpha: 0.08),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _imagePlaceholder(primaryGreen),
    );
  }

  Widget _imagePlaceholder(Color primaryGreen) {
    return Container(
      color: primaryGreen.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          Icons.workspace_premium_rounded,
          color: primaryGreen.withValues(alpha: 0.55),
          size: 52,
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, _PrizeItem prize) {
    const primaryGreen = AppConstants.primaryGreen;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withValues(alpha: 0.30),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: prize.idPremioUsuario != null
                  ? QrImageView(
                      data: prize.idPremioUsuario.toString(),
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    )
                  : const SizedBox(
                      width: 240,
                      height: 240,
                      child: Icon(
                        Icons.qr_code_rounded,
                        size: 160,
                        color: Colors.black87,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Prize name
            Text(
              prize.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            // Tap to close hint
            Text(
              'Tocá en cualquier lugar para cerrar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _PrizeItem {
  final String name;
  final String imgUrl;
  final int? idStand;
  final int? idPremioUsuario;
  final bool reclamado;

  const _PrizeItem({
    required this.name,
    required this.imgUrl,
    required this.idStand,
    required this.idPremioUsuario,
    required this.reclamado,
  });

  static _PrizeItem? fromMap(Map<String, dynamic> map) {
    final rawName = map['nombre']?.toString().trim() ?? '';
    if (rawName.isEmpty) return null;

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value == null) return null;
      return int.tryParse(value.toString().trim());
    }

    String parseImgUrl(dynamic value) {
      if (value == null) return '';
      final normalized = value.toString().trim();
      if (normalized.isEmpty || normalized.toLowerCase() == 'null') return '';
      return normalized;
    }

    return _PrizeItem(
      name: rawName,
      imgUrl: parseImgUrl(map['imgUrl']),
      idStand: parseInt(map['idStand']),
      idPremioUsuario: parseInt(map['idPremioUsuario']),
      reclamado: map['reclamado'] == true,
    );
  }
}
