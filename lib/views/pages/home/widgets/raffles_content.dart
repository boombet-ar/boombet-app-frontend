import 'dart:async';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ── Casino info local ────────────────────────────────────────────────────────
class _CasinoInfo {
  final int id;
  final String nombre;
  final String logoUrl;
  const _CasinoInfo({
    required this.id,
    required this.nombre,
    required this.logoUrl,
  });
}

// ── Configuración de layout responsive ──────────────────────────────────────
class _LayoutConfig {
  final int columns;
  final double hPadding;
  final double spacing;
  final double? maxWidth;
  final bool isWide;
  final double aspectRatio;

  const _LayoutConfig({
    required this.columns,
    required this.hPadding,
    required this.spacing,
    this.maxWidth,
    required this.isWide,
    this.aspectRatio = 1.0,
  });

  static _LayoutConfig of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return const _LayoutConfig(
        columns: 1,
        hPadding: 16,
        spacing: 0,
        isWide: false,
      );
    }

    // Calcula el aspect ratio dinámicamente según el ancho real de la card,
    // evitando que en tablet las cards queden enormes (bug: antes era fijo 0.72)
    double _computeAspectRatio(int cols, double hPad, double sp) {
      final cardW = (w - hPad * 2 - sp * (cols - 1)) / cols;
      final imageH = cardW * 9.0 / 16.0; // imagen 16:9
      const bodyH = 165.0;               // texto + botón + padding ≈ 165px
      return (cardW / (imageH + bodyH)).clamp(0.62, 1.30);
    }

    if (w < 1100) {
      const hPad = 20.0, sp = 16.0, cols = 2;
      return _LayoutConfig(
        columns: cols,
        hPadding: hPad,
        spacing: sp,
        isWide: true,
        aspectRatio: _computeAspectRatio(cols, hPad, sp),
      );
    } else {
      const hPad = 40.0, sp = 20.0, cols = 3;
      return _LayoutConfig(
        columns: cols,
        hPadding: hPad,
        spacing: sp,
        maxWidth: 1400,
        isWide: true,
        aspectRatio: _computeAspectRatio(cols, hPad, sp),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RafflesContent
// ═══════════════════════════════════════════════════════════════════════════════
class RafflesContent extends StatefulWidget {
  const RafflesContent({super.key});

  @override
  State<RafflesContent> createState() => _RafflesContentState();
}

class _RafflesContentState extends State<RafflesContent> {
  final _service = RaffleService();

  List<RaffleModel> _raffles = [];
  Map<int, _CasinoInfo> _casinoMap = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });

    try {
      final results = await Future.wait([
        _service.fetchMyRaffles(),
        _service.fetchCasinos(),
      ]);

      final rafflesMaps = results[0];
      final casinosMaps = results[1];

      final raffles = rafflesMaps.map(RaffleModel.fromMap).toList();
      final casinoMap = <int, _CasinoInfo>{};
      for (final m in casinosMaps) {
        final rawId = m['id'];
        final id =
            rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
        casinoMap[id] = _CasinoInfo(
          id: id,
          nombre: m['nombre']?.toString() ?? '',
          logoUrl: m['logoUrl']?.toString() ?? '',
        );
      }

      if (mounted) {
        setState(() {
          _raffles = raffles;
          _casinoMap = casinoMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = e.toString(); });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading(context);
    if (_error != null) return _buildError();
    if (_raffles.isEmpty) return _buildEmpty();
    return _buildList(context);
  }

  // ── Loading ─────────────────────────────────────────────────────────────────
  Widget _buildLoading(BuildContext context) {
    final layout = _LayoutConfig.of(context);
    final shimmerCount = layout.columns * 2;

    Widget content;
    if (layout.columns == 1) {
      content = ListView.builder(
        padding: EdgeInsets.symmetric(
            horizontal: layout.hPadding, vertical: 20),
        itemCount: shimmerCount,
        itemBuilder: (_, i) =>
            _ShimmerCard(delay: Duration(milliseconds: i * 120)),
      );
    } else {
      content = GridView.builder(
        padding: EdgeInsets.symmetric(
            horizontal: layout.hPadding, vertical: 20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          crossAxisSpacing: layout.spacing,
          mainAxisSpacing: layout.spacing,
          childAspectRatio: layout.aspectRatio,
        ),
        itemCount: shimmerCount,
        itemBuilder: (_, i) =>
            _ShimmerCard(delay: Duration(milliseconds: i * 100)),
      );
    }

    return _centeredContainer(layout, content);
  }

  // ── Error ───────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.grey[700], size: 52),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los sorteos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryGreen,
                side: BorderSide(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ───────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => LinearGradient(
                colors: [
                  AppConstants.primaryGreen,
                  const Color(0xFF00E5FF),
                ],
              ).createShader(r),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIN SORTEOS ACTIVOS',
              style: TextStyle(
                fontFamily: 'ThaleahFat',
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Afíliate a más casinos para\nacceder a sorteos exclusivos.',
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

  // ── List / Grid ─────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context) {
    final layout = _LayoutConfig.of(context);

    Widget content;
    if (layout.columns == 1) {
      // Mobile: lista vertical
      content = RefreshIndicator(
        color: AppConstants.primaryGreen,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _loadData,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: 16,
            bottom: 32,
            left: layout.hPadding,
            right: layout.hPadding,
          ),
          itemCount: _raffles.length,
          itemBuilder: (ctx, i) => _buildCard(ctx, i, layout),
        ),
      );
    } else {
      // Tablet / Desktop: grid
      content = RefreshIndicator(
        color: AppConstants.primaryGreen,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _loadData,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: 16,
            bottom: 40,
            left: layout.hPadding,
            right: layout.hPadding,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.columns,
            crossAxisSpacing: layout.spacing,
            mainAxisSpacing: layout.spacing,
            childAspectRatio: layout.aspectRatio,
          ),
          itemCount: _raffles.length,
          itemBuilder: (ctx, i) => _buildCard(ctx, i, layout),
        ),
      );
    }

    return _centeredContainer(layout, content);
  }

  Widget _buildCard(BuildContext context, int index, _LayoutConfig layout) {
    final raffle = _raffles[index];
    final casino =
        raffle.casinoGralId != null ? _casinoMap[raffle.casinoGralId!] : null;
    return _RaffleCard(
      key: ValueKey(raffle.id),
      raffle: raffle,
      casino: casino,
      animationDelay: Duration(milliseconds: index * 80),
      isGrid: layout.isWide,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Centra el contenido y aplica maxWidth en desktop
  Widget _centeredContainer(_LayoutConfig layout, Widget child) {
    if (layout.maxWidth == null) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.maxWidth!),
        child: child,
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════════
// _RaffleCard
// ═══════════════════════════════════════════════════════════════════════════════
class _RaffleCard extends StatefulWidget {
  final RaffleModel raffle;
  final _CasinoInfo? casino;
  final Duration animationDelay;
  final bool isGrid;

  const _RaffleCard({
    super.key,
    required this.raffle,
    required this.casino,
    required this.animationDelay,
    this.isGrid = false,
  });

  @override
  State<_RaffleCard> createState() => _RaffleCardState();
}

class _RaffleCardState extends State<_RaffleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _entryCtrl.forward();
    });

    _initCountdown();
  }

  void _initCountdown() {
    final endAt = DateTime.tryParse(widget.raffle.fechaFin);
    if (endAt == null) return;
    _updateRemaining(endAt);
    _countdownTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateRemaining(endAt));
  }

  void _updateRemaining(DateTime endAt) {
    final diff = endAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  bool get _isUrgent => _remaining.inHours < 24 && _remaining > Duration.zero;

  String get _countdownLabel {
    if (_remaining == Duration.zero) return 'Finalizado';
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24);
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (d > 0) {
      return '${d}d ${h.toString().padLeft(2, '0')}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _openDetail(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 700 || kIsWeb;

    if (isWideScreen) {
      // Desktop / tablet ancho: Dialog centrado
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth > 1100 ? (screenWidth - 680) / 2 : 40,
            vertical: 40,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _RaffleDetailContent(
              raffle: widget.raffle,
              casino: widget.casino,
              remaining: _remaining,
              countdownLabel: _countdownLabel,
              isUrgent: _isUrgent,
              isDialog: true,
            ),
          ),
        ),
      );
    } else {
      // Mobile / tablet chico: bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RaffleDetailSheet(
          raffle: widget.raffle,
          casino: widget.casino,
          remaining: _remaining,
          countdownLabel: _countdownLabel,
          isUrgent: _isUrgent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // En grid, la card no tiene margin inferior (el grid ya gestiona spacing)
    final bottomMargin = widget.isGrid ? 0.0 : 22.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: EdgeInsets.only(bottom: bottomMargin),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppConstants.primaryGreen.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                _buildBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero image ─────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Stack(
      children: [
        // Imagen principal
        AspectRatio(
          aspectRatio: 16 / 9,
          child: widget.raffle.mediaUrl.isNotEmpty
              ? Image.network(
                  widget.raffle.mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF222222),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: AppConstants.primaryGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => _imageFallback(),
                )
              : _imageFallback(),
        ),

        // Gradiente superior
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: const Alignment(0, -0.1),
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Gradiente inferior
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: const Alignment(0, 0.0),
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Badge "SORTEO" (top-left)
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'SORTEO',
              style: TextStyle(
                fontFamily: 'ThaleahFat',
                fontSize: 13,
                color: Color(0xFF0A0A0A),
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        // Countdown chip (top-right)
        Positioned(
          top: 12,
          right: 12,
          child: _CountdownChip(
            label: _countdownLabel,
            isUrgent: _isUrgent,
          ),
        ),

        // Casino logo badge (bottom-left)
        if (widget.casino != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: _CasinoBadge(casino: widget.casino!),
          ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFF222222),
      child: Center(
        child: Icon(
          Icons.emoji_events_rounded,
          color: AppConstants.primaryGreen.withValues(alpha: 0.25),
          size: 64,
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.raffle.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          // const SizedBox(height: 14),
          // SizedBox(
          //   width: double.infinity,
          //   height: 50,
          //   child: _GlowButton(
          //     label: '¡PARTICIPAR!',
          //     onTap: () => _openDetail(context),
          //   ),
          // ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _CountdownChip
// ═══════════════════════════════════════════════════════════════════════════════
class _CountdownChip extends StatelessWidget {
  final String label;
  final bool isUrgent;
  const _CountdownChip({required this.label, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    final bg = isUrgent
        ? const Color(0xFFFF3B30)
        : Colors.black.withValues(alpha: 0.7);
    final fg = isUrgent ? Colors.white : Colors.white70;
    final icon = isUrgent
        ? Icons.local_fire_department_rounded
        : Icons.timer_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _CasinoBadge
// ═══════════════════════════════════════════════════════════════════════════════
class _CasinoBadge extends StatelessWidget {
  final _CasinoInfo casino;
  const _CasinoBadge({required this.casino});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (casino.logoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                casino.logoUrl,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.casino_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (casino.nombre.isNotEmpty)
            Text(
              casino.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _GlowButton
// ═══════════════════════════════════════════════════════════════════════════════
class _GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GlowButton({required this.label, required this.onTap});

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, _) {
        final glowOpacity = 0.25 + (_glow.value * 0.35);
        final glowBlur = 10.0 + (_glow.value * 14.0);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppConstants.primaryGreen.withValues(alpha: glowOpacity),
                    blurRadius: glowBlur,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFF0A0A0A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: 'ThaleahFat',
                        fontSize: 18,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _RaffleDetailSheet — bottom sheet (mobile)
// ═══════════════════════════════════════════════════════════════════════════════
class _RaffleDetailSheet extends StatelessWidget {
  final RaffleModel raffle;
  final _CasinoInfo? casino;
  final Duration remaining;
  final String countdownLabel;
  final bool isUrgent;

  const _RaffleDetailSheet({
    required this.raffle,
    required this.casino,
    required this.remaining,
    required this.countdownLabel,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _RaffleDetailContent(
                  raffle: raffle,
                  casino: casino,
                  remaining: remaining,
                  countdownLabel: countdownLabel,
                  isUrgent: isUrgent,
                  scrollController: scrollCtrl,
                  isDialog: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _RaffleDetailContent — contenido compartido entre sheet y dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _RaffleDetailContent extends StatelessWidget {
  final RaffleModel raffle;
  final _CasinoInfo? casino;
  final Duration remaining;
  final String countdownLabel;
  final bool isUrgent;
  final ScrollController? scrollController;
  final bool isDialog;

  const _RaffleDetailContent({
    required this.raffle,
    required this.casino,
    required this.remaining,
    required this.countdownLabel,
    required this.isUrgent,
    this.scrollController,
    required this.isDialog,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Imagen grande
          if (raffle.mediaUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    raffle.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF222222),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: AppConstants.primaryGreen.withValues(alpha: 0.3),
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Casino info
          if (casino != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (casino!.logoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        casino!.logoUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.casino_rounded,
                          color: Colors.white54,
                          size: 30,
                        ),
                      ),
                    ),
                  if (casino!.logoUrl.isNotEmpty) const SizedBox(width: 10),
                  Text(
                    casino!.nombre,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          if (casino != null) const SizedBox(height: 14),

          // Countdown grande
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
                    : AppConstants.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUrgent
                      ? const Color(0xFFFF3B30).withValues(alpha: 0.4)
                      : AppConstants.primaryGreen.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isUrgent
                        ? Icons.local_fire_department_rounded
                        : Icons.timer_outlined,
                    color: isUrgent
                        ? const Color(0xFFFF3B30)
                        : AppConstants.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrgent ? '¡Últimas horas!' : 'Tiempo restante',
                        style: TextStyle(
                          color: isUrgent
                              ? const Color(0xFFFF3B30)
                              : AppConstants.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        countdownLabel,
                        style: TextStyle(
                          fontFamily: 'ThaleahFat',
                          fontSize: 22,
                          color: isUrgent
                              ? const Color(0xFFFF3B30)
                              : AppConstants.primaryGreen,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Texto completo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              raffle.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info cómo participar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      casino != null
                          ? 'Para participar, ingresá a ${casino!.nombre} y seguí las instrucciones del sorteo. ¡Buena suerte!'
                          : 'Para participar, ingresá al casino correspondiente y seguí las instrucciones del sorteo.',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Botón cerrar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: const BorderSide(color: Colors.white12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 15)),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );

    // En Dialog envuelve en un Container con color de fondo
    if (isDialog) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: content,
      );
    }
    return content;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _ShimmerCard — skeleton de carga
// ═══════════════════════════════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  final Duration delay;
  const _ShimmerCard({this.delay = Duration.zero});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = _LayoutConfig.of(context);
    // En lista, el shimmer tiene margen inferior; en grid no
    final bottomMargin = layout.columns == 1 ? 22.0 : 0.0;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final opacity = 0.04 + _anim.value * 0.08;
        return Container(
          margin: EdgeInsets.only(bottom: bottomMargin),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: opacity),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerLine(opacity, double.infinity, 13),
                      const SizedBox(height: 8),
                      _shimmerLine(opacity, double.infinity, 13),
                      const SizedBox(height: 8),
                      _shimmerLine(opacity, 160, 13),
                      const Spacer(),
                      _shimmerLine(opacity, double.infinity, 46, radius: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerLine(double opacity, double width, double height,
      {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
