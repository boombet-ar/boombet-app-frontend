import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_widgets.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventoStep extends StatefulWidget {
  final EventoStepData? initialData;
  final void Function(EventoStepData? data) onDataChanged;

  const EventoStep({super.key, this.initialData, required this.onDataChanged});

  @override
  State<EventoStep> createState() => _EventoStepState();
}

class _EventoStepState extends State<EventoStep> {
  static final _fmt = DateFormat("dd/MM/yyyy 'a las' HH:mm");

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fechaCtrl;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _fechaFin = widget.initialData?.fechaFin;
    _nombreCtrl = TextEditingController(
      text: widget.initialData?.nombre ?? '',
    );
    _fechaCtrl = TextEditingController(
      text: _fechaFin != null ? _fmt.format(_fechaFin!) : '',
    );
    _nombreCtrl.addListener(_notify);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final nombre = _nombreCtrl.text.trim();
    widget.onDataChanged(
      (nombre.isNotEmpty && _fechaFin != null)
          ? EventoStepData(nombre: nombre, fechaFin: _fechaFin!)
          : null,
    );
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final initial = (_fechaFin != null && _fechaFin!.isAfter(now))
        ? _fechaFin!
        : now.add(const Duration(days: 1));

    final date = await showCustomDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showCustomTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    if (!combined.isAfter(DateTime.now())) return;

    setState(() {
      _fechaFin = combined;
      _fechaCtrl.text = _fmt.format(combined);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WizardFieldLabel('Nombre del evento', required: true),
          const SizedBox(height: 8),
          WizardTextField(
            controller: _nombreCtrl,
            hint: 'Ej: Mundial 2026',
            icon: Icons.event_note_outlined,
            capitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          const WizardFieldLabel('Fecha de fin', required: true),
          const SizedBox(height: 8),
          WizardTextField(
            controller: _fechaCtrl,
            hint: 'Seleccioná una fecha',
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _pickFecha,
            suffix: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppConstants.primaryGreen.withValues(alpha: 0.65),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
