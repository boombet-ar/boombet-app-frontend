import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/infra/http_client.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_step.dart';
import 'package:boombet_app/views/pages/affiliates/wizard/wizard_widgets.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SorteoStep extends StatefulWidget {
  final SorteoStepData? initialData;
  final void Function(SorteoStepData? data) onDataChanged;
  /// Fecha de fin del evento padre — se usa como fecha del sorteo (no editable).
  final DateTime? eventoFechaFin;

  const SorteoStep({
    super.key,
    this.initialData,
    required this.onDataChanged,
    this.eventoFechaFin,
  });

  @override
  State<SorteoStep> createState() => _SorteoStepState();
}

class _SorteoStepState extends State<SorteoStep> {
  static final _fmt = DateFormat("dd/MM/yyyy 'a las' HH:mm");

  late bool _skipped = widget.initialData?.skipped ?? false;
  late final _nombreCtrl = TextEditingController(
    text: widget.initialData?.nombre ?? '',
  );
  late final _fechaCtrl = TextEditingController(
    text: (widget.eventoFechaFin ?? widget.initialData?.fechaFin) != null
        ? _fmt.format(widget.eventoFechaFin ?? widget.initialData!.fechaFin!)
        : '',
  );
  late DateTime? _fechaFin = widget.eventoFechaFin ?? widget.initialData?.fechaFin;

  late Uint8List? _imageBytes = widget.initialData?.imageBytes;
  late String? _imageName = widget.initialData?.imageName;
  late String _imageMimeType = widget.initialData?.imageMimeType ?? 'image/jpeg';

  late final _emailCtrl = TextEditingController(
    text: widget.initialData?.emailPresentador ?? '',
  );
  late final _instruccionesCtrl = TextEditingController(
    text: widget.initialData?.instrucciones ?? '',
  );
  late int? _selectedCasinoId = widget.initialData?.casinoGralId;

  late int _cantidadGanadores = widget.initialData?.cantidadGanadores ?? 1;
  late final List<TextEditingController> _premioControllers = _initPremioControllers();

  List<TextEditingController> _initPremioControllers() {
    final premios = widget.initialData?.premios;
    if (premios != null && premios.isNotEmpty) {
      return premios.map((p) => TextEditingController(text: p)).toList();
    }
    return [TextEditingController()];
  }

  // Casinos
  bool _loadingCasinos = false;
  List<({int? id, String nombre})> _casinos = const [
    (id: null, nombre: 'Boombet'),
  ];

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_notify);
    _emailCtrl.addListener(_notify);
    _instruccionesCtrl.addListener(_notify);
    for (final c in _premioControllers) { c.addListener(_notify); }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notify();
      _loadCasinos();
    });
  }

  @override
  void didUpdateWidget(SorteoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió la fecha del evento padre, sincronizar
    if (widget.eventoFechaFin != oldWidget.eventoFechaFin &&
        widget.eventoFechaFin != null) {
      setState(() {
        _fechaFin = widget.eventoFechaFin;
        _fechaCtrl.text = _fmt.format(widget.eventoFechaFin!);
      });
      _notify();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fechaCtrl.dispose();
    _emailCtrl.dispose();
    _instruccionesCtrl.dispose();
    for (final c in _premioControllers) { c.dispose(); }
    super.dispose();
  }

  void _addPremio() {
    final ctrl = TextEditingController()..addListener(_notify);
    setState(() {
      _premioControllers.add(ctrl);
      if (_premioControllers.length > 1) _cantidadGanadores = _premioControllers.length;
    });
  }

  void _removePremio(int index) {
    if (_premioControllers.length <= 1) return;
    final ctrl = _premioControllers[index];
    ctrl.removeListener(_notify);
    ctrl.dispose();
    setState(() {
      _premioControllers.removeAt(index);
      if (_premioControllers.length > 1) _cantidadGanadores = _premioControllers.length;
    });
    _notify();
  }

  void _updateCantidadGanadores(int v) {
    setState(() => _cantidadGanadores = v.clamp(1, 10));
    _notify();
  }

  Future<void> _loadCasinos() async {
    if (_loadingCasinos) return;
    setState(() => _loadingCasinos = true);
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/publicidades/casinos',
        includeAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final decoded = jsonDecode(response.body);
      final rawList = decoded is List
          ? decoded
          : (decoded is Map ? (decoded['data'] ?? decoded['content'] ?? const []) : const []);
      final fetched = <({int? id, String nombre})>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        final nombre = item['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;
        final rawId = item['id'];
        final id = rawId is int ? rawId : int.tryParse('$rawId');
        fetched.add((id: id, nombre: nombre));
      }
      if (!mounted) return;
      setState(() {
        _casinos = [(id: null, nombre: 'Boombet'), ...fetched];
        _loadingCasinos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCasinos = false);
    }
  }

  void _notify() {
    if (_skipped) {
      widget.onDataChanged(const SorteoStepData(skipped: true));
      return;
    }
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final instrucciones = _instruccionesCtrl.text.trim();
    widget.onDataChanged(
      (nombre.isNotEmpty && _fechaFin != null && email.isNotEmpty)
          ? SorteoStepData(
              skipped: false,
              nombre: nombre,
              fechaFin: _fechaFin,
              cantidadGanadores: _cantidadGanadores,
              premios: _premioControllers.map((c) => c.text.trim()).toList(),
              imageBytes: _imageBytes,
              imageName: _imageName,
              imageMimeType: _imageMimeType,
              emailPresentador: email,
              casinoGralId: _selectedCasinoId,
              instrucciones: instrucciones.isEmpty ? null : instrucciones,
            )
          : null,
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final raw = await file.readAsBytes();
    // Comprimimos y convertimos a JPEG para asegurar compatibilidad con el backend
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      quality: 80,
      minWidth: 1200,
      minHeight: 1,
      format: CompressFormat.jpeg,
    );
    final baseName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    if (!mounted) return;
    setState(() {
      _imageBytes = compressed;
      _imageName = '$baseName.jpg';
      _imageMimeType = 'image/jpeg';
    });
    _notify();
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
    const green = AppConstants.primaryGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardSkipToggle(
            value: _skipped,
            label: 'Saltear: no crear sorteo en este evento',
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
                  const WizardFieldLabel('Nombre del sorteo', required: true),
                  const SizedBox(height: 8),
                  WizardTextField(
                    controller: _nombreCtrl,
                    hint: 'Ej: Gran Sorteo 2026',
                    icon: Icons.emoji_events_outlined,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const WizardFieldLabel('Fecha y hora del sorteo',
                          required: true),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white.withValues(alpha: 0.25),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'del evento',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.30),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  WizardTextField(
                    controller: _fechaCtrl,
                    hint: 'Se copia del evento',
                    icon: Icons.calendar_today_outlined,
                    readOnly: true,
                    suffix: Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.25),
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const WizardFieldLabel('Imagen del sorteo'),
                  const SizedBox(height: 8),
                  _ImagePickerField(
                    imageBytes: _imageBytes,
                    imageName: _imageName,
                    onTap: _pickImage,
                    onRemove: () {
                      setState(() {
                        _imageBytes = null;
                        _imageName = null;
                        _imageMimeType = 'image/jpeg';
                      });
                      _notify();
                    },
                  ),
                  const SizedBox(height: 20),
                  const WizardFieldLabel('Email del presentador', required: true),
                  const SizedBox(height: 8),
                  WizardTextField(
                    controller: _emailCtrl,
                    hint: 'presentador@ejemplo.com',
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 20),
                  const WizardFieldLabel('Casino'),
                  const SizedBox(height: 8),
                  _CasinoDropdown(
                    casinos: _casinos,
                    selected: _selectedCasinoId,
                    loading: _loadingCasinos,
                    onChanged: (id) {
                      setState(() => _selectedCasinoId = id);
                      _notify();
                    },
                  ),
                  const SizedBox(height: 20),
                  const WizardFieldLabel('Instrucciones'),
                  const SizedBox(height: 8),
                  WizardTextField(
                    controller: _instruccionesCtrl,
                    hint: 'Instrucciones opcionales para los participantes…',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const WizardFieldLabel('Premios'),
                  const SizedBox(height: 8),
                  _buildPremiosSection(green),
                  const SizedBox(height: 20),
                  _buildGanadoresSection(green),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiosSection(Color green) {
    const ordinals = ['1°', '2°', '3°', '4°', '5°', '6°', '7°', '8°', '9°', '10°'];
    final count = _premioControllers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(count, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (count > 1) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    ordinals[i],
                    style: TextStyle(
                      color: green.withValues(alpha: 0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: WizardTextField(
                  controller: _premioControllers[i],
                  hint: i == 0 ? 'Ej: PS5' : i == 1 ? 'Ej: Gift card \$50' : 'Nombre del premio',
                  icon: Icons.card_giftcard_rounded,
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removePremio(i),
                  child: Container(
                    width: 40,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.close_rounded, color: AppConstants.errorRed, size: 18),
                  ),
                ),
              ],
            ],
          ),
        )),
        GestureDetector(
          onTap: count < 10 ? _addPremio : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: count < 10
                    ? green.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: count < 10 ? green.withValues(alpha: 0.70) : Colors.white.withValues(alpha: 0.20),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Agregar premio',
                  style: TextStyle(
                    color: count < 10 ? green.withValues(alpha: 0.80) : Colors.white.withValues(alpha: 0.20),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          count == 1
              ? 'Todos los ganadores recibirán este premio.'
              : 'Los premios se asignan por orden de prioridad según el puesto.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildGanadoresSection(Color green) {
    final locked = _premioControllers.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardFieldLabel('Cantidad de ganadores'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: green.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: (!locked && _cantidadGanadores > 1)
                    ? () => _updateCantidadGanadores(_cantidadGanadores - 1)
                    : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.remove_rounded,
                    color: (!locked && _cantidadGanadores > 1)
                        ? green
                        : green.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_cantidadGanadores',
                    style: TextStyle(
                      color: locked ? Colors.white.withValues(alpha: 0.40) : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: (!locked && _cantidadGanadores < 10)
                    ? () => _updateCantidadGanadores(_cantidadGanadores + 1)
                    : null,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.add_rounded,
                    color: (!locked && _cantidadGanadores < 10)
                        ? green
                        : green.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Se ajusta automáticamente a la cantidad de premios.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Dropdown de casino ────────────────────────────────────────────────────────

class _CasinoDropdown extends StatelessWidget {
  final List<({int? id, String nombre})> casinos;
  final int? selected;
  final bool loading;
  final void Function(int?) onChanged;

  const _CasinoDropdown({
    required this.casinos,
    required this.selected,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryGreen,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Cargando casinos…',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selected,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                iconEnabledColor: green.withValues(alpha: 0.65),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                hint: Text(
                  'Boombet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 13,
                  ),
                ),
                items: casinos
                    .map(
                      (c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(
                          c.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
    );
  }
}

// ── Widget de selección de imagen ─────────────────────────────────────────────

class _ImagePickerField extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ImagePickerField({
    required this.imageBytes,
    required this.imageName,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    if (imageBytes != null) {
      // Preview de imagen seleccionada
      return Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: green.withValues(alpha: 0.35)),
          color: const Color(0xFF1A1A1A),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
              child: Image.memory(
                imageBytes!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: green, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    imageName ?? 'imagen seleccionada',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      'Cambiar',
                      style: TextStyle(
                        color: green.withValues(alpha: 0.80),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.40),
                size: 18,
              ),
            ),
          ],
        ),
      );
    }

    // Estado vacío — botón para seleccionar
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            style: BorderStyle.solid,
          ),
          color: const Color(0xFF1A1A1A),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: green.withValues(alpha: 0.60),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Seleccionar imagen',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
