import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/formulario_model.dart';
import 'package:boombet_app/services/formularios_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:flutter/material.dart';

typedef _Option = ({int id, String label});

Future<void> showCreateFormDialog({
  required BuildContext context,
  required void Function(FormularioModel created) onCreated,
  // Modo pre-fijado: uno de los dos debe estar seteado
  int? preTidId,
  int? preSorteoId,
  // Opciones para el dropdown (solo usadas sin pre-fijado)
  List<_Option> tidOptions = const [],
  List<_Option> sorteoOptions = const [],
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CreateFormDialog(
      tidOptions: tidOptions,
      sorteoOptions: sorteoOptions,
      preTidId: preTidId,
      preSorteoId: preSorteoId,
      onCreated: onCreated,
    ),
  );
}

class _CreateFormDialog extends StatefulWidget {
  final List<_Option> tidOptions;
  final List<_Option> sorteoOptions;
  final int? preTidId;
  final int? preSorteoId;
  final void Function(FormularioModel) onCreated;

  const _CreateFormDialog({
    required this.tidOptions,
    required this.sorteoOptions,
    required this.onCreated,
    this.preTidId,
    this.preSorteoId,
  });

  @override
  State<_CreateFormDialog> createState() => _CreateFormDialogState();
}

class _CreateFormDialogState extends State<_CreateFormDialog> {
  static const _dialogBg = Color(0xFF1A1A1A);
  static const _green = AppConstants.primaryGreen;

  final _formularioService = FormulariosService();
  final _passwordController = TextEditingController();

  // 'tid' | 'sorteo'
  late String _vinculoTipo;
  late int? _selectedTidId;
  late int? _selectedSorteoId;
  bool _isLoading = false;
  String? _error;

  bool get _isPreFixed => widget.preTidId != null || widget.preSorteoId != null;

  Map<String, bool> _passwordRules = {
    '8+ caracteres': false,
    '1 mayúscula': false,
    '1 número': false,
    '1 símbolo': false,
    'Sin repetidos': false,
    'Sin secuencias': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.preTidId != null) {
      _vinculoTipo = 'tid';
      _selectedTidId = widget.preTidId;
      _selectedSorteoId = null;
    } else if (widget.preSorteoId != null) {
      _vinculoTipo = 'sorteo';
      _selectedSorteoId = widget.preSorteoId;
      _selectedTidId = null;
    } else {
      _vinculoTipo = 'tid';
      _selectedTidId = null;
      _selectedSorteoId = null;
    }
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final pw = _passwordController.text;
    if (pw.isEmpty) {
      setState(() => _passwordRules = {
            '8+ caracteres': false,
            '1 mayúscula': false,
            '1 número': false,
            '1 símbolo': false,
            'Sin repetidos': false,
            'Sin secuencias': false,
          });
      return;
    }
    final status = PasswordValidationService.getValidationStatus(pw);
    setState(() {
      _passwordRules['8+ caracteres'] = status['minimum_length']!;
      _passwordRules['1 mayúscula'] = status['uppercase']!;
      _passwordRules['1 número'] = status['number']!;
      _passwordRules['1 símbolo'] = status['symbol']!;
      _passwordRules['Sin repetidos'] = status['no_repetition']!;
      _passwordRules['Sin secuencias'] = status['no_sequence']!;
    });
  }

  bool get _isPasswordValid {
    final pw = _passwordController.text.trim();
    if (pw.isEmpty) return true;
    return PasswordValidationService.isPasswordValid(pw);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final created = await _formularioService.createFormulario(
        contrasena: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
        tidId: _vinculoTipo == 'tid' ? _selectedTidId : null,
        sorteoId: _vinculoTipo == 'sorteo' ? _selectedSorteoId : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo crear el formulario.';
        _isLoading = false;
      });
    }
  }

  bool get _canSubmit {
    if (_isLoading) return false;
    if (!_isPasswordValid) return false;
    if (_vinculoTipo == 'tid' && _selectedTidId == null) return false;
    if (_vinculoTipo == 'sorteo' && _selectedSorteoId == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _green.withValues(alpha: 0.22)),
      ),
      title: const Row(
        children: [
          Icon(Icons.dynamic_form_outlined, color: _green, size: 20),
          SizedBox(width: 10),
          Text(
            'Nuevo formulario',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contraseña ───────────────────────────────────────────────
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña (opcional)',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _green),
                ),
              ),
            ),
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _green.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _passwordRules.entries.map((e) {
                    final isValid = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.check_circle_outline_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isValid
                                ? _green
                                : Colors.white.withValues(alpha: 0.25),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: TextStyle(
                              color: isValid
                                  ? _green
                                  : Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                              fontWeight: isValid
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: _green.withValues(alpha: 0.65)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Esta contraseña será la misma para todos los usuarios que se registren con este formulario. Si la dejás vacía, se generará una automáticamente y podrás verla una vez creado.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Vínculo — solo mostrar si no hay pre-fijado ──────────────
            if (!_isPreFixed) ...[
              const SizedBox(height: 20),
              Text(
                'Vincular a',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _VinculoSelector(
                selected: _vinculoTipo,
                onSelect: (v) => setState(() {
                  _vinculoTipo = v;
                  _selectedTidId = null;
                  _selectedSorteoId = null;
                }),
              ),
              if (_vinculoTipo == 'tid' && widget.tidOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DropdownField<int>(
                  label: 'Seleccionar TID',
                  value: _selectedTidId,
                  items: widget.tidOptions
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.label,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTidId = v),
                ),
              ],
              if (_vinculoTipo == 'sorteo' &&
                  widget.sorteoOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DropdownField<int>(
                  label: 'Seleccionar sorteo',
                  value: _selectedSorteoId,
                  items: widget.sorteoOptions
                      .map((o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(o.label,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSorteoId = v),
                ),
              ],
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: const TextStyle(
                      color: AppConstants.errorRed, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.55)),
          ),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _green),
                )
              : const Text(
                  'Crear',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

// ── Selector de vínculo ────────────────────────────────────────────────────────

class _VinculoSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _VinculoSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    Widget chip(String label, String value, IconData icon) {
      final isSelected = selected == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? green.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? green.withValues(alpha: 0.40)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 13,
                    color: isSelected
                        ? green
                        : Colors.white.withValues(alpha: 0.40)),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? green
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          chip('TID', 'tid', Icons.track_changes_outlined),
          chip('Sorteo', 'sorteo', Icons.emoji_events_outlined),
        ],
      ),
    );
  }
}

// ── Dropdown genérico ──────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: green),
        ),
      ),
      iconEnabledColor: green.withValues(alpha: 0.60),
    );
  }
}
