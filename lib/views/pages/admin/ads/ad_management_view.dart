import 'dart:convert';
import 'dart:ui';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/domain/ad_service.dart';
import 'package:boombet_app/services/infra/http_client.dart';
import 'package:boombet_app/views/pages/admin/ads/create_ad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdManagementView extends StatefulWidget {
  const AdManagementView({super.key});

  @override
  State<AdManagementView> createState() => _AdManagementViewState();
}

class _AdManagementViewState extends State<AdManagementView> {
  final AdService _adService = AdService();
  late final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  List<_AdPreview> _ads = const [];
  Map<int, String> _casinoNamesById = const {};

  @override
  void initState() {
    super.initState();
    _loadCasinoNames();
    _loadAds();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCasinoNames() async {
    try {
      final rawItems = await _adService.fetchCasinos();

      final parsed = <int, String>{};
      for (final map in rawItems) {
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
    } catch (_) {}
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
        _currentCarouselIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudieron cargar las publicidades activas.';
      });
    }
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
        SnackBar(
          content: const Text(
            'No se puede editar: id de publicidad inválido.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
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
        SnackBar(
          content: const Text(
            'No se pudo eliminar: id de publicidad inválido.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Eliminar publicidad',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar esta publicidad? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _adService.deleteAd(ad.id!);
      await _loadAds();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Publicidad eliminada correctamente.',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppConstants.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la publicidad: $error',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openCreateAdDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppConstants.primaryGreen.withValues(alpha: 0.20),
          ),
        ),
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
    const green = AppConstants.primaryGreen;
    final hasCarousel =
        !_isLoading && _errorMessage == null && _ads.length > 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _AdsCreateButton(
            onPressed: _openCreateAdDialog,
            label: 'Cargar publicidad',
            icon: Icons.campaign_outlined,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildBody(green),
          ),
        ),
        if (hasCarousel) ...[
          const SizedBox(height: 14),
          _CarouselDots(count: _ads.length, current: _currentCarouselIndex),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildBody(Color green) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppConstants.errorRed.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppConstants.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadAds,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.errorRed.withValues(alpha: 0.30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: AppConstants.errorRed,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Reintentar',
                          style: TextStyle(
                            color: AppConstants.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_ads.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: AppConstants.primaryGreen.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                color: green.withValues(alpha: 0.55),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay publicidades activas para mostrar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
      itemCount: _ads.length,
      itemBuilder: (context, i) {
        final ad = _ads[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _AdCarouselCard(
            ad: ad,
            casinoLabel: _casinoLabel(ad.casinoGralId),
            endAt: _formatEndAt(ad.endAt),
            onEdit: () => _handleEdit(ad),
            onDelete: () => _handleDelete(ad),
          ),
        );
      },
    );
  }
}

// ── Modelo ─────────────────────────────────────────────────────────────────────

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

// ── Botón crear ────────────────────────────────────────────────────────────────

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
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: green, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: green, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card del carrusel ──────────────────────────────────────────────────────────

class _AdCarouselCard extends StatelessWidget {
  final _AdPreview ad;
  final String casinoLabel;
  final String endAt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdCarouselCard({
    required this.ad,
    required this.casinoLabel,
    required this.endAt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          if (ad.mediaUrl.isEmpty)
            Container(
              color: green.withValues(alpha: 0.06),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: green.withValues(alpha: 0.35),
                  size: 40,
                ),
              ),
            )
          else
            Image.network(
              ad.mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: green.withValues(alpha: 0.06),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: green,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: green.withValues(alpha: 0.06),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: green.withValues(alpha: 0.35),
                    size: 40,
                  ),
                ),
              ),
            ),

          // Degradado transparente → negro 85%
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.35, 1.0],
              ),
            ),
          ),

          // Botón editar (arriba izquierda)
          Positioned(
            top: 12,
            left: 12,
            child: _CircularActionButton(
              icon: Icons.edit_outlined,
              color: green,
              onTap: onEdit,
            ),
          ),

          // Botón eliminar (arriba derecha)
          Positioned(
            top: 12,
            right: 12,
            child: _CircularActionButton(
              icon: Icons.delete_outline_rounded,
              color: AppConstants.errorRed,
              onTap: onDelete,
            ),
          ),

          // Info abajo sobre el degradado
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad.text.isEmpty ? '—' : ad.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                _AdInfoChip(
                  icon: Icons.casino_outlined,
                  label: casinoLabel,
                ),
                const SizedBox(height: 4),
                _AdInfoChip(
                  icon: Icons.schedule_rounded,
                  label: 'Baja: $endAt',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón circular con blur ────────────────────────────────────────────────────

class _CircularActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircularActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.25),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ── Dots indicadores ───────────────────────────────────────────────────────────

class _CarouselDots extends StatelessWidget {
  final int count;
  final int current;

  const _CarouselDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? green : green.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ── Chip de info ───────────────────────────────────────────────────────────────

class _AdInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppConstants.primaryGreen.withValues(alpha: 0.70),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
