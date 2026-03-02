import 'dart:convert';
import 'dart:typed_data';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/ad_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
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
        const SnackBar(
          content: Text('No se pudo cargar la imagen.'),
          duration: Duration(seconds: 2),
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

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
    );

    if (selected == null || !mounted) return;

    final initialTime = _expiryDateTime != null
        ? TimeOfDay.fromDateTime(_expiryDateTime!)
        : TimeOfDay(hour: now.hour, minute: now.minute);

    final selectedTime = await showTimePicker(
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
        const SnackBar(
          content: Text('La fecha y hora de baja debe ser futura.'),
          duration: Duration(seconds: 2),
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

    if (!hasImage || adText.isEmpty || _expiryDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá imagen, texto y fecha/hora de baja.'),
          duration: Duration(seconds: 2),
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
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
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
          ),
          duration: Duration(seconds: 2),
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
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    final formCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditMode ? 'Editar publicidad' : 'Nueva publicidad',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 190,
                height: 320,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.22)
                      : AppConstants.lightCardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : (_existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 34,
                                      color: accent,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Imagen actual\nno disponible',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.75),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 34,
                                  color: accent,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cargar imagen\nvertical',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )),
              ),
            ),
          ),
          if (_imageName != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                _imageName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Bono especial fin de semana',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _selectedCasinoId,
            decoration: const InputDecoration(
              labelText: 'Casino de la publicación',
              hintText: 'Seleccioná un casino',
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
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_casinosError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _casinosError!,
                      style: const TextStyle(
                        color: AppConstants.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadCasinos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickExpiryDateTime,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora de baja',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _expiryDateTime == null
                          ? 'Seleccionar fecha y hora'
                          : _formatDateTime(_expiryDateTime!),
                      style: TextStyle(
                        color: _expiryDateTime == null
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              )
                            : theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveAd,
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
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.textLight,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSubmitting
                    ? (_isEditMode ? 'Actualizando...' : 'Guardando...')
                    : (_isEditMode
                          ? 'Actualizar publicidad'
                          : 'Guardar publicidad'),
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
        SectionHeaderWidget(
          title: 'Publicidades',
          subtitle: 'Carga de banner vertical para carrusel publicitario.',
          icon: Icons.campaign_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: formCard,
        ),
      ],
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
