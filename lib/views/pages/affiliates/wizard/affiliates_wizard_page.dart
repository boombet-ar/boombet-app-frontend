import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/domain/eventos_service.dart';
import 'package:boombet_app/services/domain/tids_service.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/steps/evento_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/steps/formulario_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/steps/sorteo_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/steps/tids_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_step.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ── Pasos del wizard ──────────────────────────────────────────────────────────

const _kStepLabels = ['Evento', 'Sorteo', 'Formulario', 'TIDs', 'Resumen'];
const _kTotalSteps = 5; // 4 pasos de datos + 1 resumen

// ── Página principal ──────────────────────────────────────────────────────────

class AffiliatesWizardPage extends StatefulWidget {
  const AffiliatesWizardPage({super.key});

  @override
  State<AffiliatesWizardPage> createState() => _AffiliatesWizardPageState();
}

class _AffiliatesWizardPageState extends State<AffiliatesWizardPage> {
  final _pageCtrl = PageController();
  int _currentStep = 0;

  // Datos de cada paso
  EventoStepData? _eventoData;
  SorteoStepData? _sorteoData;
  FormularioStepData _formularioData = const FormularioStepData(skipped: false);
  TidsStepData _tidsData = const TidsStepData(entries: []);

  // Estado de creación
  bool _isCreating = false;
  WizardCreationResult? _result;
  String? _creationError;
  String _creationStatus = '';

  bool get _canProceed {
    return switch (_currentStep) {
      0 => _eventoData != null,
      1 => _sorteoData != null,
      2 => true, // Formulario siempre válido (password opcional)
      3 => true, // TIDs: 0 es válido
      _ => false,
    };
  }

  void _animateTo(int step) {
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _onNext() {
    if (!_canProceed) return;
    if (_currentStep < _kTotalSteps - 1) _animateTo(_currentStep + 1);
  }

  void _onBack() {
    if (_currentStep > 0) _animateTo(_currentStep - 1);
  }

  // ── Lógica de creación (bulk) ─────────────────────────────────────────────

  Future<void> _createAll() async {
    if (_isCreating) return;
    setState(() {
      _isCreating = true;
      _creationError = null;
      _creationStatus = 'Creando…';
    });

    try {
      final sorteoData = _sorteoData;
      final hasSorteo = !(sorteoData?.skipped ?? true);
      final hasFormulario = !_formularioData.skipped;
      final tidStrings = _tidsData.entries
          .where((e) => e.nombre.isNotEmpty)
          .map((e) => e.nombre)
          .toList();

      final apiResult = await EventosService().createWizard(WizardInput(
        eventoNombre: _eventoData!.nombre,
        eventoFechaFin: _eventoData!.fechaFin,
        hasSorteo: hasSorteo,
        sorteoText: hasSorteo ? sorteoData!.nombre : null,
        sorteoFechaFin: hasSorteo ? sorteoData!.fechaFin : null,
        sorteoGanadores: hasSorteo ? sorteoData!.cantidadGanadores : 1,
        sorteoEmail: hasSorteo ? sorteoData!.emailPresentador : null,
        sorteoInstrucciones: hasSorteo ? sorteoData!.instrucciones : null,
        sorteoPremios: hasSorteo
            ? () {
                final filtered = sorteoData!.premios
                    .where((p) => p.isNotEmpty)
                    .toList();
                final single = filtered.length == 1;
                return filtered.asMap().entries
                    .map((e) => <String, dynamic>{
                          'nombre': e.value,
                          'orden': single ? null : e.key + 1,
                        })
                    .toList();
              }()
            : const [],
        sorteoCasinoGralId: hasSorteo ? sorteoData!.casinoGralId : null,
        sorteoImageBytes: hasSorteo ? sorteoData!.imageBytes : null,
        sorteoImageName: hasSorteo ? sorteoData!.imageName : null,
        sorteoImageMimeType: hasSorteo ? sorteoData!.imageMimeType : 'image/jpeg',
        hasFormulario: hasFormulario,
        formularioContrasena: hasFormulario ? _formularioData.contrasena : null,
        tidStrings: tidStrings,
      ));

      // Asignar stands a los TIDs que lo requieran
      final entriesWithStand = _tidsData.entries
          .where((e) => e.nombre.isNotEmpty && e.standId != null)
          .toList();

      for (int i = 0; i < entriesWithStand.length; i++) {
        final entry = entriesWithStand[i];
        final created = apiResult.tids.where((t) => t.tid == entry.nombre).firstOrNull;
        if (created == null) continue;
        if (mounted) {
          setState(() => _creationStatus =
              'Asignando stand ${i + 1}/${entriesWithStand.length}…');
        }
        await TidsService().updateTid(
          id: created.id,
          tid: created.tid,
          idEvento: apiResult.eventoId,
          idStand: entry.standId,
          sendIdStand: true,
        );
        if (!mounted) return;
      }

      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _result = WizardCreationResult(
          eventoId: apiResult.eventoId,
          eventoNombre: apiResult.eventoNombre,
          sorteoId: apiResult.sorteoId,
          formularioId: apiResult.formularioId,
          tids: List.unmodifiable(apiResult.tids),
        );
      });
    } catch (e, stack) {
      log('[WizardPage] creation error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _creationError = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('409') || lower.contains('duplicate') || lower.contains('ya existe')) {
      return 'Uno de los elementos ya existe. Revisá los nombres e intentá de nuevo.';
    }
    if (lower.contains('network') || lower.contains('connection') || lower.contains('timeout')) {
      return 'Sin conexión. Verificá tu internet e intentá de nuevo.';
    }
    return 'Ocurrió un error. Podés reintentar.';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Si ya hay resultado, mostramos la pantalla de resultado
    if (_result != null) {
      return _WizardResultPage(
        result: _result!,
        onBackToPanel: () => context.go('/affiliates-tools'),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        backgroundColor: AppConstants.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => _confirmClose(context),
        ),
        title: const Text(
          'Nuevo evento',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: _StepProgressBar(
            current: _currentStep,
            total: _kTotalSteps,
            labels: _kStepLabels,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Contenido del paso ─────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EventoStep(
                  initialData: _eventoData,
                  onDataChanged: (d) => setState(() => _eventoData = d),
                ),
                SorteoStep(
                  initialData: _sorteoData,
                  onDataChanged: (d) => setState(() => _sorteoData = d),
                  eventoFechaFin: _eventoData?.fechaFin,
                ),
                FormularioStep(
                  initialData: _formularioData,
                  eventoNombre: _eventoData?.nombre,
                  sorteoNombre: _sorteoData?.skipped == false
                      ? _sorteoData?.nombre
                      : null,
                  onDataChanged: (d) {
                    if (d != null) setState(() => _formularioData = d);
                  },
                ),
                TidsStep(
                  initialData: _tidsData,
                  eventoNombre: _eventoData?.nombre ?? 'EVENTO',
                  onDataChanged: (d) => setState(() => _tidsData = d),
                ),
                // Paso 5: Resumen
                _SummaryStep(
                  eventoData: _eventoData,
                  sorteoData: _sorteoData,
                  formularioData: _formularioData,
                  tidsData: _tidsData,
                  isCreating: _isCreating,
                  creationStatus: _creationStatus,
                  creationError: _creationError,
                  onConfirm: _createAll,
                ),
              ],
            ),
          ),

          // ── Navegación ─────────────────────────────────────────────────
          if (_currentStep < _kTotalSteps - 1)
            _WizardNavBar(
              currentStep: _currentStep,
              canProceed: _canProceed,
              onBack: _currentStep > 0 ? _onBack : null,
              onNext: _onNext,
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dlg) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppConstants.errorRed.withValues(alpha: 0.30),
          ),
        ),
        title: const Text(
          'Cancelar wizard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés cancelar? Los datos ingresados se perderán.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlg, false),
            child: const Text('Seguir editando',
                style: TextStyle(color: AppConstants.primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlg, true),
            child: const Text('Cancelar',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) ctx.go('/affiliates-tools');
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }
}

// ── Barra de progreso ─────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final List<String> labels;

  const _StepProgressBar({
    required this.current,
    required this.total,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: List.generate(total * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isDoneConnector = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: isDoneConnector
                      ? LinearGradient(
                          colors: [
                            green.withValues(alpha: 0.70),
                            green.withValues(alpha: 0.45),
                          ],
                        )
                      : null,
                  color:
                      isDoneConnector ? null : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < current;
          final isCurrent = stepIndex == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? green
                      : isCurrent
                          ? green.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isCurrent || isDone
                        ? green
                        : Colors.white.withValues(alpha: 0.12),
                    width: isCurrent ? 2 : 1.5,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: green.withValues(alpha: 0.55),
                            blurRadius: 14,
                            spreadRadius: 0,
                          ),
                        ]
                      : isDone
                          ? [
                              BoxShadow(
                                color: green.withValues(alpha: 0.28),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.black, size: 14)
                    : Center(
                        child: Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? green
                                : Colors.white.withValues(alpha: 0.28),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  color: isCurrent
                      ? green
                      : isDone
                          ? green.withValues(alpha: 0.60)
                          : Colors.white.withValues(alpha: 0.20),
                  fontSize: 9,
                  fontWeight:
                      isCurrent || isDone ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: isCurrent ? 0.2 : 0,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Barra de navegación ───────────────────────────────────────────────────────

class _WizardNavBar extends StatelessWidget {
  final int currentStep;
  final bool canProceed;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  const _WizardNavBar({
    required this.currentStep,
    required this.canProceed,
    this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final isLastDataStep = currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      color: AppConstants.darkBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Separador neon en lugar del borde simple
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppConstants.primaryGreen.withValues(alpha: 0.20),
                  AppConstants.primaryGreen.withValues(alpha: 0.42),
                  AppConstants.primaryGreen.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canProceed ? onNext : null,
              icon: Icon(
                isLastDataStep
                    ? Icons.checklist_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
              ),
              label: Text(isLastDataStep ? 'Ver resumen' : 'Siguiente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.black,
                disabledBackgroundColor: green.withValues(alpha: 0.25),
                disabledForegroundColor: Colors.black.withValues(alpha: 0.40),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }
}

// ── Paso de resumen ───────────────────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  final EventoStepData? eventoData;
  final SorteoStepData? sorteoData;
  final FormularioStepData formularioData;
  final TidsStepData tidsData;
  final bool isCreating;
  final String creationStatus;
  final String? creationError;
  final VoidCallback onConfirm;

  const _SummaryStep({
    required this.eventoData,
    required this.sorteoData,
    required this.formularioData,
    required this.tidsData,
    required this.isCreating,
    required this.creationStatus,
    required this.creationError,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text(
            'Revisá antes de confirmar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // ── Items ────────────────────────────────────────────────────────
          _SummaryItem(
            icon: Icons.event_note_outlined,
            label: 'Evento',
            value: eventoData?.nombre ?? '—',
            sub: eventoData?.fechaFin != null
                ? 'Hasta ${fmt.format(eventoData!.fechaFin)}'
                : null,
          ),
          const SizedBox(height: 10),
          _SummaryItem(
            icon: Icons.emoji_events_outlined,
            label: 'Sorteo',
            value: sorteoData?.skipped == true
                ? 'Salteado'
                : sorteoData?.nombre ?? '—',
            skipped: sorteoData?.skipped == true,
          ),
          const SizedBox(height: 10),
          _SummaryItem(
            icon: Icons.dynamic_form_outlined,
            label: 'Formulario',
            value: formularioData.skipped
                ? 'Salteado'
                : formularioData.contrasena != null
                    ? 'Con contraseña'
                    : 'Sin contraseña',
            skipped: formularioData.skipped,
          ),
          const SizedBox(height: 10),
          _SummaryItem(
            icon: Icons.track_changes_outlined,
            label: 'TIDs',
            value: tidsData.nombres.isEmpty
                ? 'Sin TIDs'
                : '${tidsData.nombres.where((n) => n.isNotEmpty).length} TID${tidsData.nombres.length == 1 ? '' : 's'}',
            sub: tidsData.nombres.isNotEmpty
                ? tidsData.nombres.where((n) => n.isNotEmpty).take(3).join(', ') +
                    (tidsData.nombres.length > 3 ? '...' : '')
                : null,
          ),

          // ── Error ────────────────────────────────────────────────────────
          if (creationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.errorRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppConstants.errorRed.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppConstants.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      creationError!,
                      style: const TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Progreso de creación ──────────────────────────────────────
          if (isCreating) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(
              color: green,
              backgroundColor: Color(0xFF1A1A1A),
            ),
            const SizedBox(height: 8),
            Text(
              creationStatus.isNotEmpty ? creationStatus : 'Creando…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],

          // ── Botón confirmar ───────────────────────────────────────────
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCreating ? null : onConfirm,
              icon: isCreating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      creationError != null
                          ? Icons.refresh_rounded
                          : Icons.check_circle_outline_rounded,
                    ),
              label: Text(
                isCreating
                    ? 'Creando…'
                    : creationError != null
                        ? 'Reintentar'
                        : 'Confirmar y crear',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.black,
                disabledBackgroundColor: green.withValues(alpha: 0.30),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final bool skipped;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    this.skipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.40),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: skipped
                        ? Colors.white.withValues(alpha: 0.30)
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        skipped ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pantalla de resultado ─────────────────────────────────────────────────────

class _WizardResultPage extends StatelessWidget {
  final WizardCreationResult result;
  final VoidCallback onBackToPanel;

  const _WizardResultPage({
    required this.result,
    required this.onBackToPanel,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: green.withValues(alpha: 0.28)),
                boxShadow: [
                  BoxShadow(
                    color: green.withValues(alpha: 0.30),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: green, size: 14),
            ),
            const SizedBox(width: 10),
            const Text(
              'Evento creado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: onBackToPanel,
            child: Text(
              'Volver al panel',
              style: TextStyle(
                color: green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  green.withValues(alpha: 0.25),
                  green.withValues(alpha: 0.50),
                  green.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Banner de éxito ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: green.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: 0.12),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green.withValues(alpha: 0.12),
                    border: Border.all(
                      color: green.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.42),
                        blurRadius: 22,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: green,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '¡Todo creado!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.eventoNombre,
                  style: TextStyle(
                    color: green.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Pills de resumen
                Wrap(
                  spacing: 8,
                  children: [
                    if (result.sorteoId != null)
                      _ResultPill(
                        icon: Icons.emoji_events_outlined,
                        label: '1 sorteo',
                      ),
                    if (result.formularioId != null)
                      _ResultPill(
                        icon: Icons.dynamic_form_outlined,
                        label: '1 formulario',
                      ),
                    if (result.tids.isNotEmpty)
                      _ResultPill(
                        icon: Icons.track_changes_outlined,
                        label:
                            '${result.tids.length} TID${result.tids.length == 1 ? '' : 's'}',
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (result.tids.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'TIDs creados',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...result.tids.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TidResultCard(tid: t),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBackToPanel,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text(
                'Volver al panel',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ResultPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: green.withValues(alpha: 0.75), size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: green.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TidResultCard extends StatelessWidget {
  final ({int id, String tid}) tid;

  const _TidResultCard({required this.tid});

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: green.withValues(alpha: 0.18)),
            ),
            child: const Icon(Icons.track_changes_outlined,
                color: green, size: 15),
          ),
          const SizedBox(width: 10),
          Text(
            tid.tid,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          const Icon(Icons.check_circle_outline_rounded,
              color: AppConstants.primaryGreen, size: 16),
        ],
      ),
    );
  }
}
