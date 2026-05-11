import 'dart:convert';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyCasinosPage extends StatefulWidget {
  const MyCasinosPage({super.key});

  @override
  State<MyCasinosPage> createState() => _MyCasinosPageState();
}

class _MyCasinosPageState extends State<MyCasinosPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<CasinoData> _casinos = [];

  @override
  void initState() {
    super.initState();
    _loadCasinos();
  }

  Future<void> _loadCasinos({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = "${ApiConfig.baseUrl}/users/casinos_afiliados";
      final response = await HttpClient.get(
        url,
        includeAuth: true,
        cacheTtl: const Duration(seconds: 45),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final casinos = data
              .map((e) => CasinoData.fromJson(e))
              .where((c) => c.logoUrl.isNotEmpty && c.url.isNotEmpty)
              .toList();

          if (!mounted) return;
          setState(() {
            _casinos = casinos;
            _isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Formato inesperado de respuesta';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar casinos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCasinoUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Enlace inválido');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showMessage('No se pudo abrir el casino');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isWeb = kIsWeb;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 3,
                    ),
                  )
                : _errorMessage != null
                ? _buildError(accent)
                : _casinos.isEmpty
                ? _buildEmpty(accent)
                : _buildList(accent, isWeb: isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color accent) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops, hubo un error',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCasinos,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: AppConstants.textLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [
                  AppConstants.primaryGreen,
                  Color(0xFF00E5FF),
                ],
              ).createShader(r),
              child: const Icon(
                Icons.casino_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIN CASINOS ASOCIADOS',
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
              'Aquí aparecerán los casinos a los que te unas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Color accent, {required bool isWeb}) {
    return RefreshIndicator(
      onRefresh: () => _loadCasinos(refresh: true),
      child: isWeb
          ? LayoutBuilder(
              builder: (context, constraints) {
                final isNarrowWeb = constraints.maxWidth < 700;

                if (isNarrowWeb) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _casinos.length,
                    itemBuilder: (context, index) => _CasinoCard(
                      casino: _casinos[index],
                      accent: accent,
                      onTap: () => _openCasinoUrl(_casinos[index].url),
                    ),
                  );
                }

                final maxExtent = (constraints.maxWidth * 0.33).clamp(
                  260.0,
                  420.0,
                );

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxExtent,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _casinos.length,
                  itemBuilder: (context, index) => _CasinoGridCard(
                    casino: _casinos[index],
                    accent: accent,
                    onTap: () => _openCasinoUrl(_casinos[index].url),
                  ),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _casinos.length,
              itemBuilder: (context, index) => _CasinoCard(
                casino: _casinos[index],
                accent: accent,
                onTap: () => _openCasinoUrl(_casinos[index].url),
              ),
            ),
    );
  }
}

// ─── Pressable wrapper (maneja escala + glow animado) ───────────────────────

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color accent;
  final EdgeInsetsGeometry margin;

  const _PressableCard({
    required this.child,
    required this.onTap,
    required this.accent,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap();
  }
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accent.withValues(alpha: _pressed ? 0.65 : 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(
                  alpha: _pressed ? 0.35 : 0.10,
                ),
                blurRadius: _pressed ? 36 : 20,
                spreadRadius: _pressed ? 2 : 0,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─── Badge "ONLINE" ──────────────────────────────────────────────────────────

// ─── Grid card (desktop wide) ───────────────────────────────────────────────

class _CasinoGridCard extends StatelessWidget {
  final CasinoData casino;
  final Color accent;
  final VoidCallback onTap;

  const _CasinoGridCard({
    required this.casino,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: onTap,
      accent: accent,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF080808),
            padding: const EdgeInsets.all(32),
            child: _logoWidget(casino.logoUrl, accent, size: 56),
          ),
          // Spotlight radial detrás del logo
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.75,
                    colors: [
                      accent.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Badge online
        ],
      ),
    );
  }
}

// ─── List card (mobile / narrow web) ────────────────────────────────────────

class _CasinoCard extends StatelessWidget {
  final CasinoData casino;
  final Color accent;
  final VoidCallback onTap;

  const _CasinoCard({
    required this.casino,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      onTap: onTap,
      accent: accent,
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: const Color(0xFF080808),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: _logoWidget(casino.logoUrl, accent, size: 52),
          ),
          // Spotlight radial detrás del logo
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      accent.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Gradiente inferior sutil
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _logoWidget(String logoUrl, Color accent, {required double size}) {
  if (logoUrl.isNotEmpty) {
    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Icon(
        Icons.casino_rounded,
        color: accent.withValues(alpha: 0.4),
        size: size,
      ),
    );
  }
  return Icon(
    Icons.casino_rounded,
    color: accent.withValues(alpha: 0.4),
    size: size,
  );
}

// ─── Data model ─────────────────────────────────────────────────────────────

class CasinoData {
  final String logoUrl;
  final String url;
  final String nombreGral;

  const CasinoData({
    required this.logoUrl,
    required this.url,
    required this.nombreGral,
  });

  factory CasinoData.fromJson(Map<String, dynamic> json) {
    return CasinoData(
      logoUrl: json['logoUrl']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      nombreGral: json['nombreGral']?.toString() ?? '',
    );
  }
}
