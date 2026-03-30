import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/raffle_service.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateRaffleSection extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onCreated;
  final int? raffleId;
  final String? initialText;
  final DateTime? initialEndAt;
  final int? initialCasinoGralId;
  final String? initialMediaUrl;

  const CreateRaffleSection({
    super.key,
    this.showHeader = true,
    this.onCreated,
    this.raffleId,
    this.initialText,
    this.initialEndAt,
    this.initialCasinoGralId,
    this.initialMediaUrl,
  });

  @override
  State<CreateRaffleSection> createState() => _CreateRaffleSectionState();
}

class _CreateRaffleSectionState extends State<CreateRaffleSection> {
  final RaffleService _raffleService = RaffleService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _expiryDateTime;
  Uint8List? _imageBytes;
  String? _imageName;
  String _imageMimeType = 'image/jpeg';
  String? _existingImageUrl;
  bool _isSubmitting = false;
  bool _isLoadingCasinos = false;
  int? _selectedCasinoId;
  List<_CasinoOption> _casinoOptions = const [
    _CasinoOption(id: null, nombre: 'Boombet', logoUrl: null),
  ];

  bool get _isEditMode => widget.raffleId != null;

  @override
  void initState() {
    super.initState();
    _hydrateInitialValues();
    _loadCasinos();
  }

  void _hydrateInitialValues() {
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _textController.text = text;
    }
    if (widget.initialEndAt != null) {
      _expiryDateTime = widget.initialEndAt;
    }
    _selectedCasinoId = widget.initialCasinoGralId;
    final mediaUrl = widget.initialMediaUrl?.trim();
    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      _existingImageUrl = mediaUrl;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadCasinos() async {
    if (_isLoadingCasinos) return;
    setState(() {
      _isLoadingCasinos = true;
    });

    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/sorteos/casinos',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> rawItems = const [];
      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        final content = decoded['content'];
        if (data is List) {
          rawItems = data;
        } else if (content is List) {
          rawItems = content;
        }
      }

      final fetched = <_CasinoOption>[];
      for (final item in rawItems) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final nombre = map['nombre']?.toString().trim() ?? '';
        if (nombre.isEmpty) continue;

        int? parsedId;
        final idValue = map['id'];
        if (idValue is int) {
          parsedId = idValue;
        } else if (idValue != null) {
          parsedId = int.tryParse(idValue.toString());
        }

        fetched.add(
          _CasinoOption(
            id: parsedId,
            nombre: nombre,
            logoUrl: map['logoUrl']?.toString(),
          ),
        );
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
        _casinoOptions = const [
          _CasinoOption(id: null, nombre: 'Boombet', logoUrl: null),
        ];
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo cargar la imagen.',
            style: TextStyle(color: Colors.white),
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
      );
    }
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate =
        _expiryDateTime != null && _expiryDateTime!.isAfter(today)
            ? _expiryDateTime!
            : today;

    final selected = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
    );

    if (selected == null || !mounted) return;

    final initialTime =
        _expiryDateTime != null
            ? TimeOfDay.fromDateTime(_expiryDateTime!)
            : TimeOfDay(hour: now.hour, minute: now.minute);

    final selectedTime = await showCustomTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null || !mounted) return;

    final selectedDateTime = DateTime(
      selected.year,
      selected.month,
      selected.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'La fecha y hora de cierre debe ser futura.',
            style: TextStyle(color: Colors.white),
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
      );
      return;
    }

    setState(() {
      _expiryDateTime = selectedDateTime;
    });
  }

  Future<void> _saveSorteo() async {
    if (_isSubmitting) return;

    final text = _textController.text.trim();

    // En creación la imagen es requerida; en edición puede mantenerse la existente
    if (!_isEditMode && _imageBytes == null) {
      _showErrorSnack('Seleccioná una imagen para el sorteo.');
      return;
    }
    if (text.isEmpty) {
      _showErrorSnack('Completá el texto del sorteo.');
      return;
    }
    if (_expiryDateTime == null) {
      _showErrorSnack('Seleccioná la fecha y hora de cierre.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        await _raffleService.updateRaffle(
          id: widget.raffleId!,
          text: text,
          endAt: _expiryDateTime!,
          casinoGralId: _selectedCasinoId,
          imageBytes: _imageBytes,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
        );
      } else {
        await _raffleService.createRaffle(
          imageBytes: _imageBytes!,
          text: text,
          endAt: _expiryDateTime!,
          casinoGralId: _selectedCasinoId,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _textController.clear();
        _expiryDateTime = null;
        _imageBytes = null;
        _existingImageUrl = null;
        _imageName = null;
        _imageMimeType = 'image/jpeg';
        _selectedCasinoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Sorteo actualizado correctamente.'
                : 'Sorteo creado correctamente.',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppConstants.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onCreated?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnack(
        '${_isEditMode ? 'No se pudo actualizar' : 'No se pudo crear'} el sorteo: $error',
      );
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
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
        color: Colors.white.withValues(alpha: 0.28),
        fontSize: 13,
      ),
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
              // ── Imagen ────────────────────────────────────────────────────
              _buildImageLabel(green),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(color: green.withValues(alpha: 0.22)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(green),
                ),
              ),

              const SizedBox(height: 20),

              // ── Casino ────────────────────────────────────────────────────
              _buildCasinoDropdown(green),

              const SizedBox(height: 16),

              // ── Texto ─────────────────────────────────────────────────────
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

              // ── Fecha de cierre ────────────────────────────────────────────
              GestureDetector(
                onTap: _pickExpiryDateTime,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _expiryDateTime != null
                              ? green.withValues(alpha: 0.40)
                              : green.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color:
                            _expiryDateTime != null
                                ? green
                                : green.withValues(alpha: 0.45),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _expiryDateTime != null
                              ? _formatDateTime(_expiryDateTime!)
                              : 'Fecha y hora de cierre',
                          style: TextStyle(
                            color:
                                _expiryDateTime != null
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_expiryDateTime != null)
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: green.withValues(alpha: 0.70),
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón guardar ──────────────────────────────────────────────
              SizedBox(
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
                        color:
                            _isSubmitting
                                ? green.withValues(alpha: 0.06)
                                : green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              _isSubmitting
                                  ? green.withValues(alpha: 0.20)
                                  : green.withValues(alpha: 0.45),
                        ),
                        boxShadow: _isSubmitting
                            ? null
                            : [
                                BoxShadow(
                                  color: green.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                      ),
                      child:
                          _isSubmitting
                              ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: green,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                              : Center(
                                child: Text(
                                  _isEditMode
                                      ? 'Guardar cambios'
                                      : 'Publicar sorteo',
                                  style: TextStyle(
                                    color:
                                        _isSubmitting
                                            ? green.withValues(alpha: 0.40)
                                            : green,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageLabel(Color green) {
    return Row(
      children: [
        Icon(
          Icons.image_outlined,
          size: 14,
          color: green.withValues(alpha: 0.60),
        ),
        const SizedBox(width: 6),
        Text(
          _isEditMode
              ? 'Imagen (dejá vacío para mantener la actual)'
              : 'Imagen del sorteo *',
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
    if (_imageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_imageBytes!, fit: BoxFit.cover),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withValues(alpha: 0.55),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Cambiar imagen',
                    style: TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_existingImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _emptyImagePlaceholder(green),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.black.withValues(alpha: 0.55),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded, color: green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Cambiar imagen',
                    style: TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _emptyImagePlaceholder(green);
  }

  Widget _emptyImagePlaceholder(Color green) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: green.withValues(alpha: 0.40),
          size: 36,
        ),
        const SizedBox(height: 10),
        Text(
          'Tocá para elegir una imagen',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.30),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCasinoDropdown(Color green) {
    if (_isLoadingCasinos) {
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
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: green.withValues(alpha: 0.55),
                strokeWidth: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Cargando casinos...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int?>(
      value: _selectedCasinoId,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _fieldDecoration(
        label: 'Casino',
        hint: 'Seleccioná un casino',
        icon: Icons.casino_outlined,
      ),
      items: _casinoOptions
          .map(
            (casino) => DropdownMenuItem<int?>(
              value: casino.id,
              child: Text(
                casino.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCasinoId = value),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: green.withValues(alpha: 0.55),
      ),
    );
  }
}

// ── Modelo interno de casino ───────────────────────────────────────────────────

class _CasinoOption {
  final int? id;
  final String nombre;
  final String? logoUrl;

  const _CasinoOption({
    required this.id,
    required this.nombre,
    required this.logoUrl,
  });
}
