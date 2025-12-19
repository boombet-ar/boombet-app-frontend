import 'package:flutter/material.dart';

class LoadingBadge extends StatelessWidget {
  const LoadingBadge({
    super.key,
    required this.color,
    this.size = 36,
    this.spinnerSize = 18,
    this.backgroundColor,
  });

  final Color color;
  final double size;
  final double spinnerSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: spinnerSize,
          height: spinnerSize,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
      ),
    );
  }
}
