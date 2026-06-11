import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/views/pages/affiliates/tids/evento_dropdown.dart';
import 'package:flutter/material.dart';

class EditTidDialog extends StatefulWidget {
  final TidModel tid;
  final List<EventoOption> eventoOptions;
  final List<StandOption> standOptions;

  const EditTidDialog({
    super.key,
    required this.tid,
    required this.eventoOptions,
    required this.standOptions,
  });

  @override
  State<EditTidDialog> createState() => _EditTidDialogState();
}

class _EditTidDialogState extends State<EditTidDialog> {
  late final TextEditingController _tidController;
  late int? _selectedEventoId;
  late int? _selectedStandId;

  @override
  void initState() {
    super.initState();
    _tidController = TextEditingController(text: widget.tid.tid);
    _selectedEventoId =
        widget.tid.idEvento == 0 ? null : widget.tid.idEvento;
    _selectedStandId = widget.tid.idStand;
  }

  @override
  void dispose() {
    _tidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;
    const textColor = Colors.white;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: green.withValues(alpha: 0.22)),
      ),
      title: const Text('Editar TID',
          style:
              TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tidController,
            style: const TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'TID',
              labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 16),
          EventoDropdown(
            options: widget.eventoOptions,
            selectedId: _selectedEventoId,
            accent: green,
            textColor: textColor,
            bgColor: dialogBg,
            onChanged: (v) => setState(() => _selectedEventoId = v),
          ),
          const SizedBox(height: 16),
          StandDropdown(
            options: widget.standOptions,
            selectedId: _selectedStandId,
            accent: green,
            textColor: textColor,
            bgColor: dialogBg,
            onChanged: (v) => setState(() => _selectedStandId = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: green)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            _tidController.text.trim(),
            _selectedEventoId,
            _selectedStandId,
          )),
          child: const Text('Guardar',
              style: TextStyle(color: green)),
        ),
      ],
    );
  }
}
