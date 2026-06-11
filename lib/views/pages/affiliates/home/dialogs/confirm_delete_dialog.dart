import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String body;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30)),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700)),
      content: Text(body,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65), height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar',
              style: TextStyle(color: green)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar',
              style: TextStyle(color: AppConstants.errorRed)),
        ),
      ],
    );
  }
}
