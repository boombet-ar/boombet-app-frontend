import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import 'error_parser.dart';

/// Muestra un AlertDialog de error parseando la respuesta del backend.
///
/// Acepta [http.Response] (extrae "mensaje" y "detalles"), [Exception], o [String].
/// El backend siempre responde con {"status":"error","mensaje":"...","detalles":{...}}.
Future<void> showErrorDialog(BuildContext context, dynamic error) async {
  if (!context.mounted) return;

  String message;
  Map<String, dynamic>? detalles;

  if (error is http.Response) {
    try {
      final body = jsonDecode(error.body) as Map<String, dynamic>;
      message = (body['mensaje'] as String?) ??
          (body['message'] as String?) ??
          ErrorParser.parseResponse(error);
      final rawDetalles = body['detalles'];
      if (rawDetalles is Map<String, dynamic> && rawDetalles.isNotEmpty) {
        detalles = rawDetalles;
      }
    } catch (_) {
      message = ErrorParser.parseResponse(error);
    }
  } else if (error is String) {
    message = error.isNotEmpty ? error : 'Ocurrió un error inesperado.';
  } else {
    message = ErrorParser.parse(error);
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dialogBg =
      isDark ? AppConstants.darkAccent : AppConstants.lightDialogBg;
  final textColor =
      isDark ? AppConstants.textDark : AppConstants.lightLabelText;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppConstants.primaryGreen.withValues(alpha: 0.14),
        ),
      ),
      title: Text(
        'Error',
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (detalles != null && detalles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...detalles.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• ${e.key}: ${e.value}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text(
            'Entendido',
            style: TextStyle(
              color: AppConstants.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
