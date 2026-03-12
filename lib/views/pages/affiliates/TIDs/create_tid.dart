import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/evento_dropdown.dart';
import 'package:flutter/material.dart';

Future<void> showCreateTidDialog({
  required BuildContext context,
  required TidsService tidsService,
  required VoidCallback onCreated,
  List<EventoOption> eventoOptions = kDefaultEventoOptions,
  List<StandOption> standOptions = kDefaultStandOptions,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final tidController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateTidDialogBody(
      tidController: tidController,
      tidsService: tidsService,
      eventoOptions: eventoOptions,
      standOptions: standOptions,
      onCreated: () {
        onCreated();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('TID creado correctamente.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onError: (message) => messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      ),
    ),
  );

  Future.delayed(const Duration(milliseconds: 200), tidController.dispose);
}

class _CreateTidDialogBody extends StatefulWidget {
  final TextEditingController tidController;
  final TidsService tidsService;
  final VoidCallback onCreated;
  final void Function(String) onError;
  final List<EventoOption> eventoOptions;
  final List<StandOption> standOptions;

  const _CreateTidDialogBody({
    required this.tidController,
    required this.tidsService,
    required this.onCreated,
    required this.onError,
    required this.eventoOptions,
    required this.standOptions,
  });

  @override
  State<_CreateTidDialogBody> createState() => _CreateTidDialogBodyState();
}

class _CreateTidDialogBodyState extends State<_CreateTidDialogBody> {
  bool _isSubmitting = false;
  int? _selectedEventoId; // null = sin evento
  int? _selectedStandId; // null = sin stand

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final tid = widget.tidController.text.trim();
    if (tid.isEmpty) {
      widget.onError('Ingresá el código TID para continuar.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.tidsService.createTid(
        tid: tid,
        idEvento: _selectedEventoId,
        idStand: _selectedStandId,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.pop(context);
      }
      widget.onCreated();
    } catch (e) {
      if (mounted) setState(() => _isSubmitting = false);

      final raw = e.toString().toLowerCase();
      final isDuplicate =
          raw.contains('409') ||
          raw.contains('duplicate') ||
          raw.contains('duplicado') ||
          raw.contains('already exists') ||
          raw.contains('ya existe') ||
          raw.contains('unique');

      widget.onError(
        isDuplicate
            ? 'Ya existe un TID con ese código. Usá otro.'
            : 'No se pudo crear el TID.',
      );
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
            // ── Header ──────────────────────────────────────────────────
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
                    child: Icon(Icons.add_link, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear TID',
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
                                'Ingresá el código de tracking a registrar.',
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

            // ── Campos ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: widget.tidController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código TID',
                      hintText: 'Ej: SHOW_123',
                    ),
                  ),
                  const SizedBox(height: 16),
                  EventoDropdown(
                    options: widget.eventoOptions,
                    selectedId: _selectedEventoId,
                    accent: accent,
                    onChanged: (value) =>
                        setState(() => _selectedEventoId = value),
                  ),
                  const SizedBox(height: 16),
                  StandDropdown(
                    options: widget.standOptions,
                    selectedId: _selectedStandId,
                    accent: accent,
                    onChanged: (value) =>
                        setState(() => _selectedStandId = value),
                  ),
                ],
              ),
            ),

            // ── Acciones ────────────────────────────────────────────────
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
                          : const Text('Crear TID'),
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
