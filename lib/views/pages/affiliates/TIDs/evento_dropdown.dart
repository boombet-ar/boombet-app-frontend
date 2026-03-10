import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

/// Representa una opción en el dropdown de eventos.
/// Cuando los endpoints de eventos estén disponibles, reemplazar [id] y [label]
/// con los datos reales de la API.
class EventoOption {
  final int? id;
  final String label;

  const EventoOption({required this.id, required this.label});
}

/// Opciones por defecto mientras los endpoints de eventos no estén disponibles.
const List<EventoOption> kDefaultEventoOptions = [
  EventoOption(id: null, label: 'Sin evento'),
];

class EventoDropdown extends StatelessWidget {
  final List<EventoOption> options;
  final int? selectedId;
  final Color accent;
  final Color textColor;
  final Color bgColor;
  final ValueChanged<int?> onChanged;

  const EventoDropdown({
    super.key,
    required this.options,
    required this.selectedId,
    required this.accent,
    required this.onChanged,
    this.textColor = AppConstants.textDark,
    this.bgColor = AppConstants.darkAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: selectedId,
          dropdownColor: bgColor,
          icon: Icon(Icons.keyboard_arrow_down, color: accent),
          hint: Text(
            'Evento',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem<int?>(
                  value: opt.id,
                  child: Text(
                    opt.label,
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
