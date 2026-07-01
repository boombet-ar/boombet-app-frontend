import 'dart:typed_data';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/raffle_model.dart';
import 'package:boombet_app/services/domain/ad_service.dart';
import 'package:boombet_app/services/domain/eventos_service.dart';
import 'package:boombet_app/services/domain/raffle_service.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateRaffleSection extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onCreated;
  final int? raffleId;
  final String? initialText;
  final DateTime? initialFechaFin;
  final int? initialCasinoGralId;
  final String? initialMediaUrl;
  final int? initialEventoId;
  final int? initialCantidadGanadores;
  final List<PremioModel>? initialPremios;
  final String? initialEmailPresentador;
  final String? initialInstrucciones;
  final bool initialActivo;
  final bool lockEvento;
  final bool hideEvento;

  const CreateRaffleSection({
    super.key,
    this.showHeader = true,
    this.onCreated,
    this.raffleId,
    this.initialText,
    this.initialFechaFin,
    this.initialCasinoGralId,
    this.initialMediaUrl,
    this.initialEventoId,
    this.initialCantidadGanadores,
    this.initialPremios,
    this.initialEmailPresentador,
    this.initialInstrucciones,
    this.initialActivo = false,
    this.lockEvento = false,
    this.hideEvento = false,
  });

  @override
  State<CreateRaffleSection> createState() => _CreateRaffleSectionState();
}

class _CreateRaffleSectionState extends State<CreateRaffleSection> {
  final _raffleService = RaffleService();
  final _adService = AdService();
  final _eventosService = EventosService();
  final _textController = TextEditingController();
  final _emailController = TextEditingController();
  final _instruccionesController = TextEditingController();
  final _imagePicker = ImagePicker();

  DateTime? _expiryDateTime;
  Uint8List? _imageBytes;
  String? _imageName;
  String _imageMimeType = 'image/jpeg';
  String? _existingImageUrl;
  bool _isSubmitting = false;

  // Casinos
  bool _isLoadingCasinos = false;
  int? _selectedCasinoId;
  List<_CasinoOption> _casinoOptions = const [
    _CasinoOption(id: null, nombre: 'Boombet', logoUrl: null),
  ];

  // Eventos
  bool _isLoadingEventos = false;
  int? _selectedEventoId;
  List<EventoModel> _eventoOptions = const [];

  bool _activo = false;

  // Premios
  int _cantidadGanadores = 1;
  List<TextEditingController> _premioControllers = [TextEditingController()];

  bool get _isEditMode => widget.raffleId != null;

  @override
  void initState() {
    super.initState();
    _hydrateInitialValues();
    _loadCasinos();
    _loadEventos();
  }

  void _hydrateInitialValues() {
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) _textController.text = text;
    if (widget.initialFechaFin != null) _expiryDateTime = widget.initialFechaFin;
    _selectedCasinoId = widget.initialCasinoGralId;
    final mediaUrl = widget.initialMediaUrl?.trim();
    if (mediaUrl != null && mediaUrl.isNotEmpty) _existingImageUrl = mediaUrl;
    _selectedEventoId = widget.initialEventoId;
    final email = widget.initialEmailPresentador?.trim();
    if (email != null && email.isNotEmpty) _emailController.text = email;
    final instrucciones = widget.initialInstrucciones?.trim();
    if (instrucciones != null && instrucciones.isNotEmpty) _instruccionesController.text = instrucciones;
    _activo = widget.initialActivo;
    final initialPremios = widget.initialPremios;
    if (initialPremios != null && initialPremios.isNotEmpty) {
      final sorted = [...initialPremios]..sort((a, b) => a.orden.compareTo(b.orden));
      _premioControllers = sorted.map((p) => TextEditingController(text: p.nombre)).toList();
      if (sorted.length == 1) {
        // Premio compartido por todos los ganadores: respetar cantidadGanadores del backend.
        final cantidad = widget.initialCantidadGanadores;
        _cantidadGanadores = (cantidad != null && cantidad >= 1) ? cantidad : 1;
      } else {
        // Premios individuales: ganadores = cantidad de premios.
        _cantidadGanadores = sorted.length;
      }
    } else {
      final cantidad = widget.initialCantidadGanadores;
      if (cantidad != null && cantidad >= 1) {
        _cantidadGanadores = cantidad;
        _premioControllers = List.generate(cantidad, (_) => TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _instruccionesController.dispose();
    for (final c in _premioControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Loaders ──────────────────────────────────────────────────────────────────

  Future<void> _loadCasinos() async {
    if (_isLoadingCasinos) return;
    setState(() => _isLoadingCasinos = true);
    try {
      final rawItems = await _adService.fetchCasinos();
      final fetched = <_CasinoOption>[];
      for (final map in rawItems) {
        final nombre = map['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;
        int? parsedId;
        final idValue = map['id'];
        if (idValue is int) parsedId = idValue;
        else if (idValue != null) parsedId = int.tryParse(idValue.toString());
        fetched.add(_CasinoOption(id: parsedId, nombre: nombre, logoUrl: map['logoUrl']?.toString()));
      }
      if (!mounted) return;
      setState(() {
        _casinoOptions = [
          const _CasinoOption(id: null, nombre: 'Boombet', logoUrl: null),
          ...fetched,
        ];
        _isLoadingCasinos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCasinos = false;
        _casinoOptions = const [_CasinoOption(id: null, nombre: 'Boombet', logoUrl: null)];
      });
    }
  }

  Future<void> _loadEventos() async {
    if (_isLoadingEventos) return;
    setState(() => _isLoadingEventos = true);
    try {
      final eventos = await _eventosService.fetchEventos();
      if (!mounted) return;
      setState(() {
        _eventoOptions = eventos;
        _isLoadingEventos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEventos = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _imageMimeType = file.mimeType ?? 'image/jpeg';
        _existingImageUrl = null;
      });
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack('No se pudo cargar la imagen.');
    }
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _expiryDateTime != null && _expiryDateTime!.isAfter(today)
        ? _expiryDateTime!
        : today;

    final selected = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
    );
    if (selected == null || !mounted) return;

    final initialTime = _expiryDateTime != null
        ? TimeOfDay.fromDateTime(_expiryDateTime!)
        : TimeOfDay(hour: now.hour, minute: now.minute);

    final selectedTime = await showCustomTimePicker(context: context, initialTime: initialTime);
    if (selectedTime == null || !mounted) return;

    final selectedDateTime = DateTime(
      selected.year, selected.month, selected.day,
      selectedTime.hour, selectedTime.minute,
    );
    if (selectedDateTime.isBefore(now)) {
      _showErrorSnack('La fecha y hora de cierre debe ser futura.');
      return;
    }
    setState(() => _expiryDateTime = selectedDateTime);
  }

  void _updateCantidadGanadores(int newValue) {
    setState(() => _cantidadGanadores = newValue.clamp(1, 10));
  }

  void _addPremio() {
    setState(() {
      _premioControllers.add(TextEditingController());
      // Si ahora hay más de 1 premio, los ganadores se sincronizan
      if (_premioControllers.length > 1) {
        _cantidadGanadores = _premioControllers.length;
      }
    });
  }

  void _removePremio(int index) {
    if (_premioControllers.length <= 1) return;
    setState(() {
      _premioControllers[index].dispose();
      _premioControllers.removeAt(index);
      // Mantener sincronía si sigue habiendo más de 1 premio
      if (_premioControllers.length > 1) {
        _cantidadGanadores = _premioControllers.length;
      }
    });
  }

  Future<void> _saveSorteo() async {
    if (_isSubmitting) return;
    final text = _textController.text.trim();
    final email = _emailController.text.trim();

    if (text.isEmpty) { _showErrorSnack('Completá el texto del sorteo.'); return; }
    if (_expiryDateTime == null) { _showErrorSnack('Seleccioná la fecha y hora de cierre.'); return; }
    if (_premioControllers.any((c) => c.text.trim().isEmpty)) {
      _showErrorSnack('Completá el nombre de cada premio.');
      return;
    }

    final premios = _premioControllers.asMap().entries.map((e) => <String, dynamic>{
      'nombre': e.value.text.trim(),
      'imgUrl': '',
      if (_premioControllers.length > 1) 'orden': e.key + 1,
    }).toList();

    setState(() => _isSubmitting = true);

    try {
      final instrucciones = _instruccionesController.text.trim();
      if (_isEditMode) {
        await _raffleService.updateRaffle(
          id: widget.raffleId!,
          text: text,
          fechaFin: _expiryDateTime!,
          cantidadGanadores: _cantidadGanadores,
          premios: premios,
          casinoGralId: _selectedCasinoId,
          emailPresentador: email.isNotEmpty ? email : null,
          activo: _activo,
          imageBytes: _imageBytes,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
          instrucciones: instrucciones.isNotEmpty ? instrucciones : null,
        );
      } else {
        await _raffleService.createRaffle(
          text: text,
          fechaFin: _expiryDateTime!,
          cantidadGanadores: _cantidadGanadores,
          premios: premios,
          casinoGralId: _selectedCasinoId,
          eventoId: _selectedEventoId,
          emailPresentador: email.isNotEmpty ? email : null,
          activo: _activo,
          imageBytes: _imageBytes,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
          instrucciones: instrucciones.isNotEmpty ? instrucciones : null,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _textController.clear();
        _emailController.clear();
        _instruccionesController.clear();
        _expiryDateTime = null;
        _imageBytes = null;
        _existingImageUrl = null;
        _imageName = null;
        _imageMimeType = 'image/jpeg';
        _selectedCasinoId = null;
        _selectedEventoId = null;
        _cantidadGanadores = 1;
        for (final c in _premioControllers) { c.dispose(); }
        _premioControllers = [TextEditingController()];
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _isEditMode ? 'Sorteo actualizado correctamente.' : 'Sorteo creado correctamente.',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppConstants.primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      widget.onCreated?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnack('${_isEditMode ? 'No se pudo actualizar' : 'No se pudo crear'} el sorteo: $error');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.40)),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _formatDateTime(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    const green = AppConstants.primaryGreen;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 13),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.55), size: 18),
      filled: true,
      fillColor: const Color(0xFF111111),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: green.withValues(alpha: 0.55)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Imagen ───────────────────────────────────────────────────────
              _buildFieldLabel(green, Icons.image_outlined,
                _isEditMode ? 'Imagen (dejá vacío para mantener la actual)' : 'Imagen del sorteo'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(color: green.withValues(alpha: 0.22)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(green),
                ),
              ),

              const SizedBox(height: 20),

              // ── Texto ────────────────────────────────────────────────────────
              TextFormField(
                controller: _textController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration(
                  label: 'Texto del sorteo',
                  hint: '¡Participá y ganá premios increíbles!',
                  icon: Icons.text_fields_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // ── Evento ───────────────────────────────────────────────────────
              _buildEventoDropdown(green),

              const SizedBox(height: 16),

              // ── Casino ───────────────────────────────────────────────────────
              _buildCasinoDropdown(green),

              const SizedBox(height: 16),

              // ── Cantidad de ganadores ────────────────────────────────────────
              _buildCantidadGanadoresStepper(green),

              const SizedBox(height: 16),

              // ── Premios ──────────────────────────────────────────────────────
              _buildPremiosSection(green),

              const SizedBox(height: 16),

              // ── Fecha de cierre ──────────────────────────────────────────────
              GestureDetector(
                onTap: _pickExpiryDateTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _expiryDateTime != null
                          ? green.withValues(alpha: 0.40)
                          : green.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _expiryDateTime != null ? green : green.withValues(alpha: 0.45),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _expiryDateTime != null
                              ? _formatDateTime(_expiryDateTime!)
                              : 'Fecha y hora de cierre',
                          style: TextStyle(
                            color: _expiryDateTime != null
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_expiryDateTime != null)
                        Icon(Icons.check_circle_outline_rounded,
                            color: green.withValues(alpha: 0.70), size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Email presentador ────────────────────────────────────────────
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration(
                  label: 'Email del presentador',
                  hint: 'presentador@boombet.com',
                  icon: Icons.alternate_email_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // ── Instrucciones ────────────────────────────────────────────────
              TextFormField(
                controller: _instruccionesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _fieldDecoration(
                  label: 'Instrucciones para el ganador',
                  hint: 'Ej: Comunicate por Instagram @boombet para reclamar tu premio.',
                  icon: Icons.info_outline_rounded,
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón guardar ────────────────────────────────────────────────
              _buildSaveButton(green),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(Color green, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: green.withValues(alpha: 0.60)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(Color green) {
    Widget? overlay;
    Widget? base;

    if (_imageBytes != null) {
      base = Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
    } else if (_existingImageUrl != null) {
      base = Image.network(_existingImageUrl!, fit: BoxFit.contain, width: double.infinity, height: double.infinity,
          errorBuilder: (_, __, ___) => _emptyImagePlaceholder(green));
    }

    if (base != null) {
      overlay = Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.black.withValues(alpha: 0.55),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz_rounded, color: green, size: 14),
              const SizedBox(width: 6),
              Text('Cambiar imagen',
                  style: TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
      return Stack(fit: StackFit.expand, children: [base, overlay]);
    }

    return _emptyImagePlaceholder(green);
  }

  Widget _emptyImagePlaceholder(Color green) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, color: green.withValues(alpha: 0.40), size: 36),
        const SizedBox(height: 10),
        Text('Tocá para elegir una imagen',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.30), fontSize: 12.5)),
      ],
    );
  }

  Widget _buildLoadingField(String label, Color green) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: green.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(
                color: green.withValues(alpha: 0.55), strokeWidth: 1.5),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEventoDropdown(Color green) {
    if (widget.hideEvento) return const SizedBox.shrink();
    if (_isLoadingEventos) return _buildLoadingField('Cargando eventos...', green);

    // Campo bloqueado cuando viene desde un evento
    if (widget.lockEvento && _selectedEventoId != null) {
      final evento = _eventoOptions.firstWhere(
        (e) => e.id == _selectedEventoId,
        orElse: () => EventoModel(id: _selectedEventoId!, nombre: 'Evento #$_selectedEventoId', activo: true, idAfiliador: 0),
      );
      final nombre = evento.nombre.isNotEmpty ? evento.nombre : 'Evento #${evento.id}';

      return InputDecorator(
        decoration: _fieldDecoration(
          label: 'Evento',
          hint: '',
          icon: Icons.event_note_outlined,
        ).copyWith(
          suffixIcon: Icon(Icons.lock_outline_rounded, color: green.withValues(alpha: 0.35), size: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: green.withValues(alpha: 0.10)),
          ),
          fillColor: const Color(0xFF0D0D0D),
        ),
        child: Text(
          nombre,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final validValue = _eventoOptions.any((e) => e.id == _selectedEventoId) ? _selectedEventoId : null;

    return DropdownButtonFormField<int?>(
      value: validValue,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _fieldDecoration(
        label: 'Evento (opcional)',
        hint: 'Seleccioná un evento',
        icon: Icons.event_note_outlined,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Sin evento', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        ..._eventoOptions.map((evento) => DropdownMenuItem<int?>(
          value: evento.id,
          child: Text(
            evento.nombre.isNotEmpty ? evento.nombre : 'Evento #${evento.id}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: (value) => setState(() => _selectedEventoId = value),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: green.withValues(alpha: 0.55)),
    );
  }

  Widget _buildCasinoDropdown(Color green) {
    if (_isLoadingCasinos) return _buildLoadingField('Cargando casinos...', green);

    return DropdownButtonFormField<int?>(
      value: _selectedCasinoId,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _fieldDecoration(
        label: 'Casino (opcional)',
        hint: 'Seleccioná un casino',
        icon: Icons.casino_outlined,
      ),
      items: _casinoOptions.map((casino) => DropdownMenuItem<int?>(
        value: casino.id,
        child: Text(casino.nombre, style: const TextStyle(color: Colors.white, fontSize: 14)),
      )).toList(),
      onChanged: (value) => setState(() => _selectedCasinoId = value),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: green.withValues(alpha: 0.55)),
    );
  }

  Widget _buildCantidadGanadoresStepper(Color green) {
    final locked = _premioControllers.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(green, Icons.emoji_events_outlined, 'Cantidad de ganadores'),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: locked
                  ? green.withValues(alpha: 0.08)
                  : green.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: (!locked && _cantidadGanadores > 1)
                    ? () => _updateCantidadGanadores(_cantidadGanadores - 1)
                    : null,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(
                      color: locked
                          ? green.withValues(alpha: 0.08)
                          : green.withValues(alpha: 0.18),
                    )),
                  ),
                  child: Icon(Icons.remove_rounded,
                      color: (!locked && _cantidadGanadores > 1)
                          ? green
                          : green.withValues(alpha: 0.18),
                      size: 20),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_cantidadGanadores',
                    style: TextStyle(
                      color: locked
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white,
                      fontSize: 18,
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
                    topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(
                      color: locked
                          ? green.withValues(alpha: 0.08)
                          : green.withValues(alpha: 0.18),
                    )),
                  ),
                  child: Icon(Icons.add_rounded,
                      color: (!locked && _cantidadGanadores < 10)
                          ? green
                          : green.withValues(alpha: 0.18),
                      size: 20),
                ),
              ),
            ],
          ),
        ),
        if (locked) ...[
          const SizedBox(height: 6),
          Text(
            'Se ajusta automáticamente a la cantidad de premios.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.30),
              fontSize: 11.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPremiosSection(Color green) {
    const ordinals = ['1°', '2°', '3°', '4°', '5°', '6°', '7°', '8°', '9°', '10°'];
    final count = _premioControllers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(green, Icons.card_giftcard_outlined, 'Premios'),
        const SizedBox(height: 8),

        // Campos de premios
        ...List.generate(count, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _premioControllers[i],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _fieldDecoration(
                    label: count == 1 ? 'Premio' : 'Premio ${ordinals[i]} lugar',
                    hint: i == 0 ? 'Ej: PS5' : i == 1 ? 'Ej: Gift card \$50' : 'Nombre del premio',
                    icon: Icons.card_giftcard_rounded,
                  ),
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removePremio(i),
                  child: Container(
                    width: 40,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppConstants.errorRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      color: AppConstants.errorRed.withValues(alpha: 0.70),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        )),

        // Botón agregar premio
        GestureDetector(
          onTap: _addPremio,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: green.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: green.withValues(alpha: 0.70), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Agregar premio',
                  style: TextStyle(
                    color: green.withValues(alpha: 0.70),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Hint
        Text(
          count == 1
              ? 'Todos los ganadores recibirán este premio.'
              : 'Los premios se asignan por orden de prioridad según el puesto.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color green) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _saveSorteo,
          borderRadius: BorderRadius.circular(10),
          splashColor: green.withValues(alpha: 0.20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _isSubmitting
                  ? green.withValues(alpha: 0.06)
                  : green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isSubmitting
                    ? green.withValues(alpha: 0.20)
                    : green.withValues(alpha: 0.45),
              ),
              boxShadow: _isSubmitting
                  ? null
                  : [BoxShadow(color: green.withValues(alpha: 0.15), blurRadius: 12)],
            ),
            child: _isSubmitting
                ? Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: green, strokeWidth: 2),
                    ),
                  )
                : Center(
                    child: Text(
                      _isEditMode ? 'Guardar cambios' : 'Publicar sorteo',
                      style: TextStyle(
                        color: _isSubmitting ? green.withValues(alpha: 0.40) : green,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Casino option ─────────────────────────────────────────────────────────────

class _CasinoOption {
  final int? id;
  final String nombre;
  final String? logoUrl;
  const _CasinoOption({required this.id, required this.nombre, required this.logoUrl});
}
