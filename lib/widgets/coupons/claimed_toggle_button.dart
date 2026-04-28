import 'package:flutter/material.dart';

class ClaimedToggleButton extends StatelessWidget {
  const ClaimedToggleButton({
    super.key,
    required this.isActive,
    required this.primaryGreen,
    required this.onToggle,
  });

  final bool isActive;
  final Color primaryGreen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isActive ? 'Ver descuentos' : 'Mis cupones reclamados',
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? primaryGreen.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isActive
                  ? primaryGreen.withValues(alpha: 0.50)
                  : primaryGreen.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isActive
                  ? Icons.local_offer_rounded
                  : Icons.check_circle_outline,
              key: ValueKey(isActive),
              color:
                  isActive ? primaryGreen : primaryGreen.withValues(alpha: 0.65),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
