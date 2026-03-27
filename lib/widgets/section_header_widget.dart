import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class SectionHeaderWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;
  final VoidCallback? onSwitch;
  final IconData? switchIcon;
  final Key? switchButtonKey;
  final VoidCallback? onInfo;
  final IconData? infoIcon;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onRefresh,
    this.onSwitch,
    this.switchIcon,
    this.switchButtonKey,
    this.onInfo,
    this.infoIcon,
  });

  @override
  State<SectionHeaderWidget> createState() => _SectionHeaderWidgetState();
}

class _SectionHeaderWidgetState extends State<SectionHeaderWidget>
    with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _pulseController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    // Ícono: fade + scale al montar, 150ms, una sola vez
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _iconScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOut));
    _iconOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeIn));
    _enterController.forward();

    // Punto: pulso continuo cada 1.4s
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.9, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Barra de acento neon ──────────────────────────────────────
          Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, accent.withValues(alpha: 0.15)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // ── Cuerpo ───────────────────────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF111111), const Color(0xFF171717)]
                      : [AppConstants.lightAccent, AppConstants.lightBg],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // ── Ícono animado ─────────────────────────────────────
                  FadeTransition(
                    opacity: _iconOpacity,
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.32),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: accent, size: 22),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Textos ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Punto pulsante
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseScale.value,
                                child: Opacity(
                                  opacity: _pulseOpacity.value,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(
                                      right: 8,
                                      bottom: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.65),
                                          blurRadius: 7,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: 0.2,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (widget.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.38),
                              letterSpacing: 0.1,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Botón info/FAQ ────────────────────────────────────
                  if (widget.onInfo != null) ...[
                    const SizedBox(width: 6),
                    _HeaderActionButton(
                      icon: widget.infoIcon ?? Icons.help_outline_rounded,
                      onTap: widget.onInfo!,
                      accent: accent,
                      tooltip: 'Ayuda',
                    ),
                  ],

                  // ── Botón switch ──────────────────────────────────────
                  if (widget.onSwitch != null) ...[
                    const SizedBox(width: 6),
                    _HeaderActionButton(
                      widgetKey: widget.switchButtonKey,
                      icon: widget.switchIcon ?? Icons.swap_horiz,
                      onTap: widget.onSwitch!,
                      accent: accent,
                      tooltip: 'Cambiar vista',
                    ),
                  ],

                  // ── Botón refresh ─────────────────────────────────────
                  if (widget.onRefresh != null && widget.onSwitch == null) ...[
                    const SizedBox(width: 6),
                    _HeaderActionButton(
                      icon: Icons.refresh_rounded,
                      onTap: widget.onRefresh!,
                      accent: accent,
                      tooltip: 'Actualizar',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final String tooltip;
  final Key? widgetKey;

  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    required this.accent,
    required this.tooltip,
    this.widgetKey,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: widgetKey,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
        ),
      ),
    );
  }
}
