import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRefresh;
  final VoidCallback? onSwitch;
  final IconData? switchIcon;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onRefresh,
    this.onSwitch,
    this.switchIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.15),
            accent.withOpacity(0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (onSwitch != null)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.darkCardBg
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(switchIcon ?? Icons.swap_horiz),
                  onPressed: onSwitch,
                  color: accent,
                  tooltip: 'Cambiar vista',
                ),
              ),
            if (onRefresh != null && onSwitch == null)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.darkCardBg
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: onRefresh,
                  color: accent,
                  tooltip: 'Actualizar',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
