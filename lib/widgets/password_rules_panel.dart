import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

/// Panel de requisitos de contraseña. Recibe el mapa de estado tal como lo
/// devuelve `PasswordValidationService.getValidationStatus`.
class PasswordRulesPanel extends StatelessWidget {
  final Map<String, bool> status;

  const PasswordRulesPanel({super.key, required this.status});

  static const _labels = {
    'minimum_length': '8+ caracteres',
    'uppercase': '1 mayúscula',
    'number': '1 número',
    'symbol': '1 símbolo',
    'no_repetition': 'Sin repetidos',
    'no_sequence': 'Sin secuencias',
  };

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _labels.entries.map((entry) {
          final isValid = status[entry.key] ?? false;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  isValid
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isValid ? green : Colors.white.withValues(alpha: 0.25),
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: isValid ? green : Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
