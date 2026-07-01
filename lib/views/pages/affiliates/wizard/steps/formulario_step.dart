import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/auth/password_validation_service.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_widgets.dart';
import 'package:boombet_app/widgets/password_rules_panel.dart';
import 'package:flutter/material.dart';

class FormularioStep extends StatefulWidget {
  final FormularioStepData? initialData;
  /// Nombre del sorteo previo para mostrar la vinculación automática.
  final String? sorteoNombre;
  /// Nombre del evento para mostrar la vinculación automática.
  final String? eventoNombre;
  final void Function(FormularioStepData? data) onDataChanged;

  const FormularioStep({
    super.key,
    this.initialData,
    this.sorteoNombre,
    this.eventoNombre,
    required this.onDataChanged,
  });

  @override
  State<FormularioStep> createState() => _FormularioStepState();
}

class _FormularioStepState extends State<FormularioStep> {
  late bool _skipped = widget.initialData?.skipped ?? false;
  late final _passCtrl = TextEditingController(
    text: widget.initialData?.contrasena ?? '',
  );
  bool _obscure = true;
  Map<String, bool> _passwordStatus = const {};

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_onPasswordChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPasswordChanged);
    _passCtrl.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final pw = _passCtrl.text;
    setState(() {
      _passwordStatus =
          pw.isEmpty ? const {} : PasswordValidationService.getValidationStatus(pw);
    });
    _notify();
  }

  void _notify() {
    if (_skipped) {
      widget.onDataChanged(const FormularioStepData(skipped: true));
      return;
    }
    final pw = _passCtrl.text.trim();
    // Contraseña opcional, pero si la escriben tiene que cumplir las reglas.
    if (pw.isNotEmpty && !PasswordValidationService.isPasswordValid(pw)) {
      widget.onDataChanged(null);
      return;
    }
    widget.onDataChanged(
      FormularioStepData(
        skipped: false,
        contrasena: pw.isEmpty ? null : pw,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final hasSorteo = widget.sorteoNombre != null;
    final hasEvento = widget.eventoNombre != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardSkipToggle(
            value: _skipped,
            label: 'Saltear: no crear formulario en este evento',
            onChanged: (v) => setState(() {
              _skipped = v;
              _notify();
            }),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _skipped ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: _skipped,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Vinculación automática ───────────────────────────────
                  if (hasSorteo || hasEvento) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: green.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                color: green.withValues(alpha: 0.75),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Se vincula automáticamente a:',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (hasEvento) ...[
                            WizardBindingIndicator(
                              label: 'Evento',
                              value: widget.eventoNombre!,
                              icon: Icons.event_note_outlined,
                            ),
                            const SizedBox(height: 6),
                          ],
                          if (hasSorteo)
                            WizardBindingIndicator(
                              label: 'Sorteo',
                              value: widget.sorteoNombre!,
                              icon: Icons.emoji_events_outlined,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Contraseña (opcional) ────────────────────────────────
                  const WizardFieldLabel('Contraseña del formulario'),
                  const SizedBox(height: 4),
                  Text(
                    'Opcional. Los jugadores la necesitarán para completarlo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  WizardTextField(
                    controller: _passCtrl,
                    hint: 'Sin contraseña',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.45),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    PasswordRulesPanel(status: _passwordStatus),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
