import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/ad_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/views/pages/admin/ads/create_ad.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdManagementView extends StatefulWidget {
  const AdManagementView({super.key});

  @override
  State<AdManagementView> createState() => _AdManagementViewState();
}

class _AdManagementViewState extends State<AdManagementView> {
  static const int _pageSize = 5;
  final AdService _adService = AdService();

  bool _isLoading = true;
  String? _errorMessage;
  List<_AdPreview> _ads = const [];
  Map<int, String> _casinoNamesById = const {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadCasinoNames();
    _loadAds();
  }

  Future<void> _loadCasinoNames() async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/publicidades/casinos',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> rawItems = const [];
      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final content = decoded['content'];
        if (data is List) {
          rawItems = data;
        } else if (content is List) {
          rawItems = content;
        }
      }

      final parsed = <int, String>{};
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nombre = map['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;

        final idValue = map['id'];
        final parsedId = idValue is int ? idValue : int.tryParse('$idValue');
        if (parsedId == null) continue;

        parsed[parsedId] = nombre;
      }

      if (!mounted) return;
      setState(() {
        _casinoNamesById = parsed;
      });
    } catch (_) {
      // si falla el catálogo, dejamos fallback al id numérico
    }
  }

  Future<void> _loadAds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/publicidades',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> rawList = const [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final content = decoded['content'];
        if (data is List) {
          rawList = data;
        } else if (content is List) {
          rawList = content;
        }
      }

      final loadedAds = rawList
          .whereType<Map>()
          .map((item) => _AdPreview.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _ads = loadedAds;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar las publicidades activas.';
      });
    }
  }

  Future<void> _refreshAds() async {
    await _loadAds();
  }

  int get _totalPages {
    if (_ads.isEmpty) return 0;
    return (_ads.length / _pageSize).ceil();
  }

  List<_AdPreview> get _currentAds {
    if (_ads.isEmpty) return const [];
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _ads.length);
    return _ads.sublist(start, end);
  }

  String _formatEndAt(String raw) {
    if (raw.trim().isEmpty) return '-';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  String _casinoLabel(int? casinoGralId) {
    if (casinoGralId == null) return 'Boombet';
    return _casinoNamesById[casinoGralId] ?? casinoGralId.toString();
  }

  DateTime? _parseDateTime(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleEdit(_AdPreview ad) async {
    if (ad.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar: id de publicidad inválido.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateAdSection(
              showHeader: false,
              adId: ad.id,
              initialText: ad.text,
              initialCasinoGralId: ad.casinoGralId,
              initialEndAt: _parseDateTime(ad.endAt),
              initialMediaUrl: ad.mediaUrl,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadAds();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(_AdPreview ad) async {
    if (ad.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar: id de publicidad inválido.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicidad'),
        content: const Text('¿Querés eliminar esta publicidad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _adService.deleteAd(ad.id!);

      await _loadAds();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicidad eliminada correctamente.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la publicidad: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCreateAdDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 760),
          child: SingleChildScrollView(
            child: CreateAdSection(
              showHeader: false,
              onCreated: () {
                Navigator.of(dialogContext).pop();
                _loadAds();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;

    return RefreshIndicator(
      onRefresh: _refreshAds,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SectionHeaderWidget(
              title: 'Publicidades',
              subtitle: 'Preview de publicidades activas (5 por página).',
              icon: Icons.campaign_outlined,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                children: [
                  _AdsCreateButton(
                    onPressed: _openCreateAdDialog,
                    label: 'Cargar publicidad',
                    icon: Icons.campaign_outlined,
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.darkAccent
                            : AppConstants.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(
                          color: AppConstants.errorRed.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: textColor),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _loadAds,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  else if (_ads.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppConstants.darkAccent
                            : AppConstants.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'No hay publicidades activas para mostrar.',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    )
                  else ...[
                    ..._currentAds.map((ad) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppConstants.darkAccent
                                : AppConstants.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadius,
                            ),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 88,
                                  height: 156,
                                  child: ad.mediaUrl.isEmpty
                                      ? Container(
                                          color: accent.withValues(alpha: 0.12),
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: accent,
                                            size: 30,
                                          ),
                                        )
                                      : Image.network(
                                          ad.mediaUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: accent.withValues(
                                              alpha: 0.12,
                                            ),
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: accent,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad.text.isEmpty ? '-' : ad.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Casino: ${_casinoLabel(ad.casinoGralId)}',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Finaliza: ${_formatEndAt(ad.endAt)}',
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _AdActionButton(
                                          label: 'Editar',
                                          icon: Icons.edit_outlined,
                                          color: accent,
                                          onTap: () => _handleEdit(ad),
                                        ),
                                        const SizedBox(width: 8),
                                        _AdActionButton(
                                          label: 'Eliminar',
                                          icon: Icons.delete_outline,
                                          color: AppConstants.errorRed,
                                          onTap: () => _handleDelete(ad),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A1A)
                            : AppConstants.lightAccent,
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: PaginationBar(
                          currentPage: _currentPage + 1,
                          canGoPrevious: _currentPage > 0,
                          canGoNext: _currentPage < (_totalPages - 1),
                          onPrev: () {
                            if (_currentPage <= 0) return;
                            setState(() => _currentPage -= 1);
                          },
                          onNext: () {
                            if (_currentPage >= (_totalPages - 1)) return;
                            setState(() => _currentPage += 1);
                          },
                          primaryColor: accent,
                          textColor: textColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdPreview {
  final int? id;
  final int? casinoGralId;
  final String endAt;
  final String mediaUrl;
  final String text;

  const _AdPreview({
    required this.id,
    required this.casinoGralId,
    required this.endAt,
    required this.mediaUrl,
    required this.text,
  });

  factory _AdPreview.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['publicidadId'];
    int? parsedAdId;
    if (rawId is int) {
      parsedAdId = rawId;
    } else if (rawId != null) {
      parsedAdId = int.tryParse(rawId.toString());
    }

    final idValue = map['casinoGralId'];
    int? parsedId;
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue != null) {
      parsedId = int.tryParse(idValue.toString());
    }

    return _AdPreview(
      id: parsedAdId,
      casinoGralId: parsedId,
      endAt: map['endAt']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
    );
  }
}

class _AdsCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _AdsCreateButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppConstants.darkAccent
              : AppConstants.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _AdActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
