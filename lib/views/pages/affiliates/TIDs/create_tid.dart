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
          SnackBar(
            content: const Text(
              'TID creado correctamente.',
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
  int? _selectedEventoId;
  int? _selectedStandId;

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
                    child: const Icon(Icons.add_link, color: green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crear TID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ingresá el código de tracking a registrar.',
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
                    controller: widget.tidController,
                    textCapitalization: TextCapitalization.characters,
                    style: fieldStyle,
                    cursorColor: green,
                    decoration: _fieldDecoration(
                      label: 'Código TID',
                      hint: 'Ej: SHOW_123',
                      icon: Icons.track_changes_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EventoDropdown(
                    options: widget.eventoOptions,
                    selectedId: _selectedEventoId,
                    accent: green,
                    onChanged: (value) =>
                        setState(() => _selectedEventoId = value),
                  ),
                  const SizedBox(height: 12),
                  StandDropdown(
                    options: widget.standOptions,
                    selectedId: _selectedStandId,
                    accent: green,
                    onChanged: (value) =>
                        setState(() => _selectedStandId = value),
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
                              'Crear TID',
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
