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
        _navButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrevious,
          onPressed: onPrev,
          tooltip: 'Página anterior',
        ),
        const SizedBox(width: 12),
        Text(
          'Página $currentPage',
          style: TextStyle(
            color: textColor.withOpacity(0.65),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        _navButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onPressed: onNext,
          tooltip: 'Página siguiente',
        ),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: primaryColor.withOpacity(enabled ? 0.12 : 0.04),
          side: BorderSide(
            color: primaryColor.withOpacity(enabled ? 0.35 : 0.12),
            width: 1,
          ),
          shape: const CircleBorder(),
        ),
        icon: Icon(
          icon,
          size: 22,
          color: enabled ? primaryColor : textColor.withOpacity(0.25),
        ),
      ),
    );
  }
}
