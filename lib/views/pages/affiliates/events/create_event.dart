import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/eventos_service.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showCreateEventoDialog({
  required BuildContext context,
  required EventosService eventosService,
  required VoidCallback onCreated,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final nombreController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateEventoDialogBody(
      nombreController: nombreController,
      eventosService: eventosService,
      onCreated: () {
        onCreated();
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Evento creado correctamente.',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppConstants.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onError: (message) => messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: AppConstants.errorRed.withValues(alpha: 0.40),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      ),
    ),
  );

  Future.delayed(
    const Duration(milliseconds: 200),
    nombreController.dispose,
  );
}

class _CreateEventoDialogBody extends StatefulWidget {
  final TextEditingController nombreController;
  final EventosService eventosService;
  final VoidCallback onCreated;
  final void Function(String) onError;

  const _CreateEventoDialogBody({
    required this.nombreController,
    required this.eventosService,
    required this.onCreated,
    required this.onError,
  });

  @override
  State<_CreateEventoDialogBody> createState() =>
      _CreateEventoDialogBodyState();
}

class _CreateEventoDialogBodyState extends State<_CreateEventoDialogBody> {
  bool _isSubmitting = false;
  DateTime? _fechaFin;

  static final DateFormat _displayFormat =
      DateFormat("dd/MM/yyyy 'a las' HH:mm");

  final _fechaFinController = TextEditingController();

  @override
  void dispose() {
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _pickFechaFin() async {
    final now = DateTime.now();
    final initialDate = _fechaFin != null && _fechaFin!.isAfter(now)
        ? _fechaFin!
        : now.add(const Duration(days: 1));

    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showCustomTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!combined.isAfter(DateTime.now())) {
      widget.onError(
        'La fecha y hora de fin debe ser posterior al momento actual.',
      );
      return;
    }

    setState(() {
      _fechaFin = combined;
      _fechaFinController.text = _displayFormat.format(combined);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final nombre = widget.nombreController.text.trim();
    if (nombre.isEmpty) {
      widget.onError('Ingresá el nombre del evento para continuar.');
      return;
    }
    if (_fechaFin == null) {
      widget.onError('Seleccioná la fecha de fin del evento.');
      return;
    }
    if (!_fechaFin!.isAfter(DateTime.now())) {
      widget.onError(
        'La fecha y hora de fin debe ser posterior al momento actual.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.eventosService.createEvento(
        nombre: nombre,
        fechaFin: _fechaFin!,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      widget.onCreated();
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);
      widget.onError('No se pudo crear el evento.');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    const green = AppConstants.primaryGreen;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.22),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFF141414),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.65), size: 18),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    const dialogBg = Color(0xFF1A1A1A);
    const fieldStyle = TextStyle(color: Colors.white, fontSize: 14);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
        side: BorderSide(color: green.withValues(alpha: 0.20)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
                border: Border(
                  bottom: BorderSide(color: green.withValues(alpha: 0.12)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: green.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(
                      Icons.event_note_outlined,
                      color: green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear evento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Completá los datos del nuevo evento.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Campos ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: widget.nombreController,
                    textCapitalization: TextCapitalization.sentences,
                    style: fieldStyle,
                    cursorColor: green,
                    decoration: _fieldDecoration(
                      label: 'Nombre del evento',
                      hint: 'Ej: Mundial 2026',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fechaFinController,
                    readOnly: true,
                    onTap: _pickFechaFin,
                    style: fieldStyle,
                    cursorColor: green,
                    decoration: _fieldDecoration(
                      label: 'Fecha de fin',
                      hint: 'Seleccioná una fecha',
                      icon: Icons.calendar_today_outlined,
                      suffix: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: green.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Acciones ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Crear evento',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
