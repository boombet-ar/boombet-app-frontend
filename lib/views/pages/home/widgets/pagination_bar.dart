import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.canJumpBack5,
    required this.canJumpBack10,
    required this.canJumpForward,
    required this.onPrev,
    required this.onNext,
    required this.onJumpBack5,
    required this.onJumpBack10,
    required this.onJumpForward5,
    required this.onJumpForward10,
    required this.primaryColor,
    required this.textColor,
  });

  final int currentPage;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool canJumpBack5;
  final bool canJumpBack10;
  final bool canJumpForward;

  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onJumpBack5;
  final VoidCallback onJumpBack10;
  final VoidCallback onJumpForward5;
  final VoidCallback onJumpForward10;

  final Color primaryColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _squareButton(
          label: '-10',
          enabled: canJumpBack10,
          onPressed: onJumpBack10,
        ),
        const SizedBox(width: 2),
        _squareButton(
          label: '-5',
          enabled: canJumpBack5,
          onPressed: onJumpBack5,
        ),
        const SizedBox(width: 2),
        _squareButton(label: '-1', enabled: canGoPrevious, onPressed: onPrev),
        const SizedBox(width: 6),
        Text(
          'P$currentPage',
          style: TextStyle(
            color: textColor.withOpacity(0.65),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        _squareButton(label: '+1', enabled: canGoNext, onPressed: onNext),
        const SizedBox(width: 2),
        _squareButton(
          label: '+5',
          enabled: canJumpForward,
          onPressed: onJumpForward5,
        ),
        const SizedBox(width: 2),
        _squareButton(
          label: '+10',
          enabled: canJumpForward,
          onPressed: onJumpForward10,
        ),
      ],
    );
  }

  Widget _squareButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: primaryColor.withOpacity(enabled ? 0.65 : 0.12),
            width: 0.75,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? primaryColor : textColor.withOpacity(0.25),
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
