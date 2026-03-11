import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/eventos_service.dart';
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
          const SnackBar(
            content: Text('Evento creado correctamente.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onError: (message) => messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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

  static final DateFormat _displayFormat = DateFormat("dd/MM/yyyy 'a las' HH:mm");

  Future<void> _pickFechaFin() async {
    final now = DateTime.now();
    final initialDate = _fechaFin != null && _fechaFin!.isAfter(now)
        ? _fechaFin!
        : now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
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
      widget.onError('La fecha y hora de fin debe ser posterior al momento actual.');
      return;
    }

    setState(() => _fechaFin = combined);
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
      widget.onError('La fecha y hora de fin debe ser posterior al momento actual.');
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

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppConstants.darkAccent,
            title: const Text(
              'Error al crear evento',
              style: TextStyle(color: AppConstants.textDark, fontSize: 16),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  e.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    const textColor = AppConstants.textDark;
    const dialogBg = AppConstants.darkAccent;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.event_note_outlined, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear evento',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Completá los datos del nuevo evento.',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Campos ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: widget.nombreController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del evento',
                      hintText: 'Ej: Mundial 2026',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickFechaFin,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.darkBg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadius,
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fechaFin != null
                                  ? _displayFormat.format(_fechaFin!)
                                  : 'Fecha de fin',
                              style: TextStyle(
                                color: _fechaFin != null
                                    ? textColor
                                    : textColor.withValues(alpha: 0.45),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: accent,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Acciones ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppConstants.textLight,
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
                                color: AppConstants.textLight,
                              ),
                            )
                          : const Text('Crear evento'),
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
