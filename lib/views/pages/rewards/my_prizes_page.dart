import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';

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
        '${ApiConfig.baseUrl}/ruleta/mi-premio',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode == 404) {
        setState(() {
          _prize = null;
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudo cargar tu premio asignado';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final payload = _extractPrizePayload(decoded);
      final parsedPrize = payload != null ? _PrizeItem.fromMap(payload) : null;

      setState(() {
        _prize = parsedPrize;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Ocurrió un error cargando tu premio';
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;

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
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 58,
                      color: primaryGreen.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Mis premios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tenés un premio asignado por ahora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : AppConstants.lightCardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : AppConstants.borderLight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: _prize!.imgUrl.isEmpty
                                    ? Container(
                                        color: primaryGreen.withValues(
                                          alpha: 0.12,
                                        ),
                                        child: Icon(
                                          Icons.workspace_premium_rounded,
                                          color: primaryGreen,
                                          size: 48,
                                        ),
                                      )
                                    : Image.network(
                                        _prize!.imgUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: primaryGreen.withValues(
                                            alpha: 0.12,
                                          ),
                                          child: Icon(
                                            Icons.workspace_premium_rounded,
                                            color: primaryGreen,
                                            size: 48,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _prize!.name,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PrizeItem {
  final int? id;
  final String name;
  final String imgUrl;
  final int? stock;

  const _PrizeItem({
    required this.id,
    required this.name,
    required this.imgUrl,
    required this.stock,
  });

  static _PrizeItem? fromMap(Map<String, dynamic> map) {
    final rawName = map['nombre']?.toString().trim() ?? '';
    if (rawName.isEmpty) return null;

    final rawId = map['id'];
    final rawStock = map['stock'];

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value == null) return null;
      return int.tryParse(value.toString().trim());
    }

    String parseImgUrl(dynamic value) {
      if (value == null) return '';
      final normalized = value.toString().trim();
      if (normalized.isEmpty || normalized.toLowerCase() == 'null') {
        return '';
      }
      return normalized;
    }

    return _PrizeItem(
      id: parseInt(rawId),
      name: rawName,
      imgUrl: parseImgUrl(map['imgUrl']),
      stock: parseInt(rawStock),
    );
  }
}
