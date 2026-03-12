import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
    required this.primaryColor,
    required this.textColor,
  });

  final int currentPage;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final Color primaryColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrevious,
          onPressed: onPrev,
          tooltip: 'Página anterior',
          primaryColor: primaryColor,
          textColor: textColor,
        ),
        const SizedBox(width: 8),
        _PageLabel(
          currentPage: currentPage,
          primaryColor: primaryColor,
          textColor: textColor,
        ),
        const SizedBox(width: 8),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onPressed: onNext,
          tooltip: 'Página siguiente',
          primaryColor: primaryColor,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _PageLabel extends StatelessWidget {
  const _PageLabel({
    required this.currentPage,
    required this.primaryColor,
    required this.textColor,
  });

  final int currentPage;
  final Color primaryColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_rounded,
            size: 11,
            color: primaryColor.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 6),
          Text(
            'Página $currentPage',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.tooltip,
    required this.primaryColor,
    required this.textColor,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final String tooltip;
  final Color primaryColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? primaryColor.withValues(alpha: 0.12)
              : primaryColor.withValues(alpha: 0.04),
          border: Border.all(
            color: enabled
                ? primaryColor.withValues(alpha: 0.38)
                : primaryColor.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: const CircleBorder(),
            splashColor: primaryColor.withValues(alpha: 0.15),
            highlightColor: primaryColor.withValues(alpha: 0.08),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? primaryColor
                    : textColor.withValues(alpha: 0.20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
