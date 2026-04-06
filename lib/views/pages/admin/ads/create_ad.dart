import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/utils/inappropriate_content_guard.dart';
import 'package:boombet_app/services/ad_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateAdSection extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onCreated;
  final int? adId;
  final String? initialText;
  final DateTime? initialEndAt;
  final int? initialCasinoGralId;
  final String? initialMediaUrl;

  const CreateAdSection({
    super.key,
    this.showHeader = true,
    this.onCreated,
    this.adId,
    this.initialText,
    this.initialEndAt,
    this.initialCasinoGralId,
    this.initialMediaUrl,
  });

  @override
  State<CreateAdSection> createState() => _CreateAdSectionState();
}

class _CreateAdSectionState extends State<CreateAdSection> {
  final AdService _adService = AdService();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  DateTime? _expiryDateTime;
  Uint8List? _imageBytes;
  String? _imageName;
  String _imageMimeType = 'image/jpeg';
  String? _existingImageUrl;
  bool _isSubmitting = false;
  bool _sendPush = false;
  bool _isLoadingCasinos = false;
  String? _casinosError;
  int? _selectedCasinoId;
  List<_CasinoOption> _casinoOptions = const [
    _CasinoOption(id: null, nombre: 'Boombet', logoUrl: null),
  ];

  bool get _isEditMode => widget.adId != null;

  @override
  void initState() {
    super.initState();
    _hydrateInitialValues();
    _loadCasinos();
  }

  void _hydrateInitialValues() {
    final text = widget.initialText?.trim();
    if (text != null && text.isNotEmpty) {
      _titleController.text = text;
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
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadCasinos() async {
    if (_isLoadingCasinos) return;

    setState(() {
      _isLoadingCasinos = true;
      _casinosError = null;
    });

    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/publicidades/casinos',
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
        _casinosError = 'No se pudieron cargar los casinos.';
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

    final initialTime = _expiryDateTime != null
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
            'La fecha y hora de baja debe ser futura.',
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

  Future<void> _saveAd() async {
    if (_isSubmitting) return;

    final adText = _titleController.text.trim();
    final hasImage = _imageBytes != null || _existingImageUrl != null;

    final blocked =
        await InappropriateContentGuard.blockIfContainsInappropriateContent(
          context: context,
          text: adText,
        );
    if (blocked) return;

    if (!hasImage || adText.isEmpty || _expiryDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Completá imagen, texto y fecha/hora de baja.',
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
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        await _adService.updateAd(
          id: widget.adId!,
          text: adText,
          endAt: _expiryDateTime!,
          casinoGralId: _selectedCasinoId,
          imageBytes: _imageBytes,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
        );
      } else {
        await _adService.createAd(
          imageBytes: _imageBytes!,
          text: adText,
          endAt: _expiryDateTime!,
          casinoGralId: _selectedCasinoId,
          imageName: _imageName,
          imageMimeType: _imageMimeType,
          push: _sendPush,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _sendPush = false;
        _titleController.clear();
        _expiryDateTime = null;
        _imageBytes = null;
        _existingImageUrl = null;
        _imageName = null;
        _imageMimeType = 'image/jpeg';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Publicidad actualizada correctamente.'
                : 'Publicidad cargada correctamente.',
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
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isEditMode ? 'No se pudo actualizar' : 'No se pudo cargar'} la publicidad: $error',
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
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

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
        color: Colors.white.withValues(alpha: 0.22),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFF141414),
      prefixIcon: Icon(icon, color: green.withValues(alpha: 0.65), size: 18),
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
        borderSide: const BorderSide(color: AppConstants.primaryGreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    final hasImage = _imageBytes != null || _existingImageUrl != null;

    // ── Zona de imagen ─────────────────────────────────────────────────────────
    final imageZone = GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage
                ? green.withValues(alpha: 0.35)
                : green.withValues(alpha: 0.20),
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen o placeholder
              if (_imageBytes != null)
                Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                )
              else if (_existingImageUrl != null)
                Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF0D0D0D),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: green,
                          strokeWidth: 2.5,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _ImagePlaceholder(
                    icon: Icons.image_not_supported_outlined,
                    label: 'Imagen no\ndisponible',
                    green: green,
                  ),
                )
              else
                _ImagePlaceholder(
                  icon: Icons.add_photo_alternate_outlined,
                  label: 'Seleccioná una\nimagen vertical',
                  green: green,
                ),

              // Overlay gradiente abajo cuando hay imagen
              if (hasImage)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.80),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Badge "Cambiar" / "Toca para elegir"
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? const Color(0xFF0E0E0E).withValues(alpha: 0.90)
                        : green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: green.withValues(alpha: hasImage ? 0.40 : 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasImage
                            ? Icons.edit_outlined
                            : Icons.add_photo_alternate_outlined,
                        color: green,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasImage ? 'Cambiar' : 'Elegir imagen',
                        style: const TextStyle(
                          color: green,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nombre del archivo (top-left badge)
              if (_imageName != null)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E0E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _imageName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // ── Form card ──────────────────────────────────────────────────────────────
    final formCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: green.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del form
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: green.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  _isEditMode ? Icons.edit_outlined : Icons.campaign_outlined,
                  color: green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isEditMode ? 'Editar publicidad' : 'Nueva publicidad',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zona imagen
          imageZone,
          const SizedBox(height: 14),

          // Texto
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: green,
            decoration: _fieldDecoration(
              label: 'Texto',
              hint: 'Ej: Bono especial fin de semana',
              icon: Icons.text_fields_rounded,
            ),
          ),
          const SizedBox(height: 10),

          // Casino dropdown
          DropdownButtonFormField<int?>(
            value: _selectedCasinoId,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            iconEnabledColor: green.withValues(alpha: 0.65),
            decoration: InputDecoration(
              labelText: 'Casino',
              hintText: 'Seleccioná un casino',
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
              prefixIcon: Icon(
                Icons.casino_outlined,
                color: green.withValues(alpha: 0.65),
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
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
            ),
            items: _casinoOptions
                .map(
                  (casino) => DropdownMenuItem<int?>(
                    value: casino.id,
                    child: Text(casino.nombre),
                  ),
                )
                .toList(),
            onChanged: _isLoadingCasinos
                ? null
                : (value) {
                    setState(() {
                      _selectedCasinoId = value;
                    });
                  },
          ),

          if (_isLoadingCasinos)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cargando casinos...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),

          if (_casinosError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppConstants.errorRed,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _casinosError!,
                      style: const TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadCasinos,
                    child: Text(
                      'Reintentar',
                      style: TextStyle(
                        color: green.withValues(alpha: 0.80),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Date picker tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickExpiryDateTime,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _expiryDateTime != null
                        ? green.withValues(alpha: 0.35)
                        : green.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: _expiryDateTime != null
                          ? green
                          : green.withValues(alpha: 0.55),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha y hora de baja',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.50),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _expiryDateTime == null
                                ? 'Seleccionar fecha y hora'
                                : _formatDateTime(_expiryDateTime!),
                            style: TextStyle(
                              color: _expiryDateTime == null
                                  ? Colors.white.withValues(alpha: 0.30)
                                  : Colors.white,
                              fontSize: 13.5,
                              fontWeight: _expiryDateTime != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: green.withValues(alpha: 0.45),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Switch notificaciones push
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _sendPush
                    ? green.withValues(alpha: 0.35)
                    : green.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: _sendPush ? green : green.withValues(alpha: 0.45),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Activar notificaciones push',
                    style: TextStyle(
                      color: _sendPush
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Switch(
                  value: _sendPush,
                  onChanged: (val) => setState(() => _sendPush = val),
                  activeColor: green,
                  activeTrackColor: green.withValues(alpha: 0.25),
                  inactiveThumbColor: Colors.white.withValues(alpha: 0.35),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveAd,
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isEditMode
                              ? Icons.save_outlined
                              : Icons.cloud_upload_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEditMode
                              ? 'Actualizar publicidad'
                              : 'Guardar publicidad',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );

    if (!widget.showHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: formCard,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: formCard,
        ),
      ],
    );
  }
}

// ── Placeholder de imagen ──────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color green;

  const _ImagePlaceholder({
    required this.icon,
    required this.label,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: green.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, size: 30, color: green.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

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
