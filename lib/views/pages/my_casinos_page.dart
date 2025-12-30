import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
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
        cacheTtl: Duration.zero,
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

    return ColoredBox(
      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
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
                : _buildList(isDark, accent),
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
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán los casinos a los que te unas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: (isDark ? Colors.white : Colors.black87).withOpacity(
                  0.65,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isDark, Color accent) {
    return RefreshIndicator(
      onRefresh: () => _loadCasinos(refresh: true),
      child: ListView.builder(
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
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
          color: isDark
              ? accent.withOpacity(0.15)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF3F3F3),
                child: casino.logoUrl.isNotEmpty
                    ? Image.network(
                        casino.logoUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.casino, color: accent, size: 36),
                      )
                    : Icon(Icons.casino, color: accent, size: 36),
              ),
            ),
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
