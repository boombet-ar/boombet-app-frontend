import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/stand_model.dart';
import 'package:boombet_app/services/domain/stands_service.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_step.dart';
import 'package:flutter/material.dart';

class TidsStep extends StatefulWidget {
  final TidsStepData? initialData;
  final String eventoNombre;
  final void Function(TidsStepData data) onDataChanged;

  const TidsStep({
    super.key,
    this.initialData,
    required this.eventoNombre,
    required this.onDataChanged,
  });

  @override
  State<TidsStep> createState() => _TidsStepState();
}

class _TidsStepState extends State<TidsStep> {
  late List<TextEditingController> _controllers;
  late List<int?> _standIds;
  late List<String?> _standNombres;

  List<StandModel>? _stands;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData?.entries ?? [];
    _controllers =
        initial.map((e) => TextEditingController(text: e.nombre)).toList();
    _standIds = initial.map((e) => e.standId).toList();
    _standNombres = initial.map((e) => e.standNombre).toList();
    for (final c in _controllers) {
      c.addListener(_notify);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
    _loadStands();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStands() async {
    try {
      final stands = await StandsService().fetchStands();
      if (mounted) setState(() => _stands = stands);
    } catch (_) {
      if (mounted) setState(() => _stands = []);
    }
  }

  void _notify() {
    final entries = List.generate(
      _controllers.length,
      (i) => TidEntry(
        nombre: _controllers[i].text.trim(),
        standId: _standIds[i],
        standNombre: _standNombres[i],
      ),
    );
    widget.onDataChanged(TidsStepData(entries: entries));
  }

  String _defaultName(int index) {
    final prefix = widget.eventoNombre
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${prefix}_${index + 1}';
  }

  void _addTid() {
    final index = _controllers.length;
    final ctrl = TextEditingController(text: _defaultName(index));
    ctrl.addListener(_notify);
    setState(() {
      _controllers.add(ctrl);
      _standIds.add(null);
      _standNombres.add(null);
    });
    _notify();
  }

  void _removeTid(int index) {
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
      _standIds.removeAt(index);
      _standNombres.removeAt(index);
    });
    _notify();
  }

  void _setStand(int index, int? standId, String? standNombre) {
    setState(() {
      _standIds[index] = standId;
      _standNombres[index] = standNombre;
    });
    _notify();
  }

  Future<void> _pickStand(int index) async {
    if (_stands == null || _stands!.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _StandPickerSheet(
        stands: _stands!,
        currentStandId: _standIds[index],
        tidNombre: _controllers[index].text.trim().isNotEmpty
            ? _controllers[index].text.trim()
            : _defaultName(index),
        onPicked: (id, nombre) {
          _setStand(index, id, nombre);
          if (ctx.mounted) Navigator.pop(ctx);
        },
        onCleared: () {
          _setStand(index, null, null);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Column(
      children: [
        // ── Contador ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: green.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              const Icon(Icons.track_changes_outlined, color: green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIDs a crear',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_controllers.length} TID${_controllers.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: green,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              _CounterButton(
                icon: Icons.remove_rounded,
                enabled: _controllers.isNotEmpty,
                onTap: _controllers.isEmpty
                    ? null
                    : () => _removeTid(_controllers.length - 1),
              ),
              const SizedBox(width: 8),
              _CounterButton(
                icon: Icons.add_rounded,
                enabled: true,
                onTap: _addTid,
              ),
            ],
          ),
        ),

        // ── Lista editable ────────────────────────────────────────────────
        if (_controllers.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.track_changes_outlined,
                    color: Colors.white.withValues(alpha: 0.20),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No vas a crear TIDs en este wizard.\nPodés agregarlos después.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.30),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: _controllers.length,
              itemBuilder: (_, i) {
                final hasStand = _standIds[i] != null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Número
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: green.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Campo nombre
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          cursorColor: green,
                          decoration: InputDecoration(
                            hintText: _defaultName(i),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.20),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: green.withValues(alpha: 0.14),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: green.withValues(alpha: 0.14),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: green),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Botón de stand
                      if (_stands == null)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppConstants.primaryGreen,
                          ),
                        )
                      else if (_stands!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _pickStand(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: hasStand
                                  ? green.withValues(alpha: 0.10)
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: hasStand
                                    ? green.withValues(alpha: 0.30)
                                    : Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 13,
                                  color: hasStand
                                      ? green
                                      : Colors.white.withValues(alpha: 0.35),
                                ),
                                if (hasStand) ...[
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 64),
                                    child: Text(
                                      _standNombres[i]!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      // Eliminar
                      GestureDetector(
                        onTap: () => _removeTid(i),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppConstants.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppConstants.errorRed.withValues(alpha: 0.70),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Sheet de selección de stand ───────────────────────────────────────────────

class _StandPickerSheet extends StatelessWidget {
  final List<StandModel> stands;
  final int? currentStandId;
  final String tidNombre;
  final void Function(int id, String nombre) onPicked;
  final VoidCallback onCleared;

  const _StandPickerSheet({
    required this.stands,
    required this.currentStandId,
    required this.tidNombre,
    required this.onPicked,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Título
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [green, green.withValues(alpha: 0.15)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: green.withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Asignar stand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tidNombre,
                      style: TextStyle(
                        color: green.withValues(alpha: 0.70),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Separador neon
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                green.withValues(alpha: 0.20),
                green.withValues(alpha: 0.40),
                green.withValues(alpha: 0.20),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Lista
        ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stands.length + (currentStandId != null ? 1 : 0),
          itemBuilder: (_, i) {
            // Opción "Sin stand" al final si hay uno seleccionado
            if (currentStandId != null && i == stands.length) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCleared,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppConstants.errorRed.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.close_rounded,
                            size: 14,
                            color: AppConstants.errorRed.withValues(alpha: 0.65)),
                        const SizedBox(width: 10),
                        Text(
                          'Quitar stand',
                          style: TextStyle(
                            color: AppConstants.errorRed.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final stand = stands[i];
            final isCurrent = stand.id == currentStandId;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onPicked(stand.id, stand.nombre),
                borderRadius: BorderRadius.circular(10),
                splashColor: green.withValues(alpha: 0.08),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? green.withValues(alpha: 0.08)
                        : const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? green.withValues(alpha: 0.30)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: green.withValues(alpha: 0.18)),
                        ),
                        child: Icon(Icons.storefront_outlined,
                            color: green.withValues(alpha: 0.70), size: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stand.nombre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!stand.activo)
                              Text(
                                'Inactivo',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const Icon(Icons.check_rounded,
                            color: AppConstants.primaryGreen, size: 16)
                      else
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.20)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Counter button ────────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? green.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? green.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? green : Colors.white.withValues(alpha: 0.20),
          size: 18,
        ),
      ),
    );
  }
}
