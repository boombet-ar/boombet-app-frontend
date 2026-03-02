import 'dart:convert';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
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
          SectionHeaderWidget(
            title: 'Mis casinos',
            subtitle:
                'Estos son los casinos a los que te encontrás afiliado por medio de BoomBet.',
            icon: Icons.casino_rounded,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: accent,
                      strokeWidth: 3,
                    ),
                  )
                : _errorMessage != null
                ? _buildError()
                : _casinos.isEmpty
                ? _buildEmpty(isDark, accent)
                : _buildList(isDark, accent, isWeb: isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Error desconocido'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCasinos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color accent) {
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
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.casino_rounded, size: 64, color: accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no estás asociado',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán los casinos a los que te unas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
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
                  // Mobile web: use the mobile list layout so cards and CTA
                  // don't get cramped into multiple columns.
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
    final surfaceVariant = isDark
        ? const Color(0xFF2A2A2A)
        : AppConstants.lightSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.18)
              : AppConstants.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: surfaceVariant,
                      child: casino.logoUrl.isNotEmpty
                          ? Image.network(
                              casino.logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.casino, color: accent, size: 48),
                            )
                          : Icon(Icons.casino, color: accent, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  casino.nombreGral,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _CasinoButton(accent: accent, onTap: onTap, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppConstants.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? accent.withOpacity(0.15) : AppConstants.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : AppConstants.lightSurfaceVariant,
                      child: casino.logoUrl.isNotEmpty
                          ? Image.network(
                              casino.logoUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.casino, color: accent, size: 42),
                            )
                          : Icon(Icons.casino, color: accent, size: 42),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(height: 10),
                _CasinoButton(accent: accent, onTap: onTap, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CasinoButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  final bool isDark;

  const _CasinoButton({
    required this.accent,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withOpacity(0.95), accent.withOpacity(0.75)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : AppConstants.borderLight.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino_outlined, color: textColor, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Acceder al casino',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.north_east, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

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
