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
    final isDark = theme.brightness == Brightness.dark;
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
                : _buildList(isDark, accent, isWeb: isWeb),
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
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(Icons.casino_rounded, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no estás asociado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán los casinos a los que te unas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isDark, Color accent, {required bool isWeb}) {
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
                      isDark: isDark,
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
                    isDark: isDark,
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
                isDark: isDark,
                accent: accent,
                onTap: () => _openCasinoUrl(_casinos[index].url),
              ),
            ),
    );
  }
}

// ─── Grid card (desktop wide) ───────────────────────────────────────────────

class _CasinoGridCard extends StatelessWidget {
  final CasinoData casino;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _CasinoGridCard({
    required this.casino,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          hoverColor: accent.withValues(alpha: 0.04),
          splashColor: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Online badge
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.7),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Logo area
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.10),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: casino.logoUrl.isNotEmpty
                          ? Image.network(
                              casino.logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.casino_rounded,
                                color: accent.withValues(alpha: 0.4),
                                size: 48,
                              ),
                            )
                          : Icon(
                              Icons.casino_rounded,
                              color: accent.withValues(alpha: 0.4),
                              size: 48,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Casino name
                Text(
                  casino.nombreGral,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                // CTA button
                _CasinoButton(accent: accent, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List card (mobile / narrow web) ────────────────────────────────────────

class _CasinoCard extends StatelessWidget {
  final CasinoData casino;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _CasinoCard({
    required this.casino,
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          hoverColor: accent.withValues(alpha: 0.04),
          splashColor: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Online badge row
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.7),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Logo area — hero height
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: casino.logoUrl.isNotEmpty
                        ? Image.network(
                            casino.logoUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.casino_rounded,
                              color: accent.withValues(alpha: 0.4),
                              size: 52,
                            ),
                          )
                        : Icon(
                            Icons.casino_rounded,
                            color: accent.withValues(alpha: 0.4),
                            size: 52,
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                // Casino name
                Text(
                  casino.nombreGral,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                // CTA button
                _CasinoButton(accent: accent, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared CTA button ───────────────────────────────────────────────────────

class _CasinoButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _CasinoButton({
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          shadowColor: accent.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino_outlined, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Acceder al casino',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.north_east_rounded, size: 15, color: Colors.black),
          ],
        ),
      ),
    );
  }
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
