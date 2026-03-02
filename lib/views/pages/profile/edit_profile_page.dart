import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class EditProfilePage extends StatefulWidget {
  final PlayerData player;

  const EditProfilePage({super.key, required this.player});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Map<String, TextEditingController> _c = {};
  late PlayerData _player;
  String _avatarUrl = '';
  bool _loading = false;
  bool _uploadingAvatar = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _avatarUrl = widget.player.avatarUrl;
    _hydrateAvatar();

    final p = widget.player;

    _c["nombre"] = TextEditingController(text: p.nombre);
    _c["apellido"] = TextEditingController(text: p.apellido);
    _c["email"] = TextEditingController(text: p.correoElectronico);
    _c["telefono"] = TextEditingController(text: p.telefono);
    _c["genero"] = TextEditingController(text: p.sexo);
    _c["estadoCivil"] = TextEditingController(text: p.estadoCivil);
    _c["fechaNacimiento"] = TextEditingController(text: p.fechaNacimiento);

    _c["dni"] = TextEditingController(text: p.dni);
    _c["cuit"] = TextEditingController(text: p.cuil);

    _c["calle"] = TextEditingController(text: p.calle);
    _c["numCalle"] = TextEditingController(text: p.numCalle);
    _c["ciudad"] = TextEditingController(text: p.localidad);
    _c["provincia"] = TextEditingController(text: p.provincia);
    _c["cp"] = TextEditingController(text: p.cp?.toString() ?? "");
  }

  Future<void> _hydrateAvatar() async {
    try {
      final fresh = await PlayerService().getCurrentUserAvatarUrl();
      if (!mounted || fresh == null || fresh.isEmpty) return;
      setState(() {
        _avatarUrl = fresh;
        _player = _player.copyWith(avatarUrl: fresh);
      });
    } catch (_) {
      // Silencio: si falla seguimos mostrando el avatar existente
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String msg) {
    debugPrint('[UNAFFILIATE][UI] showError: $msg');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snackTextColor = isDark ? Colors.white : AppConstants.textLight;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: snackTextColor)),
        backgroundColor: AppConstants.errorRed,
        duration: AppConstants.longSnackbarDuration,
        action: SnackBarAction(
          label: 'OK',
          textColor: snackTextColor,
          onPressed: () {},
        ),
      ),
    );
  }

  Uint8List _resizeAvatarForWeb(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final squared = img.copyResizeCropSquare(decoded, size: 512);
      return Uint8List.fromList(img.encodeJpg(squared, quality: 82));
    } catch (_) {
      return bytes;
    }
  }

  Future<Uint8List?> _pickCropAndProcessAvatarBytes(XFile pickedFile) async {
    final canUseNativeCropper =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    if (!kIsWeb && !canUseNativeCropper) {
      // Fallback (desktop): sin recorte por ahora.
      return pickedFile.readAsBytes();
    }

    final cropped = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        if (kIsWeb)
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            barrierColor: Colors.black.withValues(alpha: 0.65),
            initialAspectRatio: 1,
            viewwMode: WebViewMode.mode_1,
            dragMode: WebDragMode.move,
            zoomable: true,
            rotatable: true,
            scalable: true,
            guides: true,
            center: true,
            highlight: true,
            modal: true,
            cropBoxResizable: true,
            cropBoxMovable: true,
            themeData: WebThemeData(
              rotateIconColor: primaryGreen,
              doneIcon: Icons.check,
              backIcon: Icons.close,
              rotateLeftIcon: Icons.rotate_left,
              rotateRightIcon: Icons.rotate_right,
            ),
          ),
        if (defaultTargetPlatform == TargetPlatform.android)
          AndroidUiSettings(
            toolbarTitle: 'Editar foto',
            toolbarColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
            toolbarWidgetColor: isDark ? Colors.white : Colors.black,
            activeControlsWidgetColor: primaryGreen,
            statusBarColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
            backgroundColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
            cropStyle: CropStyle.circle,
            hideBottomControls: false,
            lockAspectRatio: true,
          ),
        if (defaultTargetPlatform == TargetPlatform.iOS)
          IOSUiSettings(
            title: 'Editar foto',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            rotateButtonsHidden: false,
            resetButtonHidden: false,
          ),
      ],
    );

    if (cropped == null) return null;

    final croppedBytes = await cropped.readAsBytes();

    if (kIsWeb) {
      // En Web no usamos flutter_image_compress: reescalamos/normalizamos en Dart.
      return _resizeAvatarForWeb(croppedBytes);
    }

    // Ajuste final para avatar (se ve en círculo): tamaño razonable + compresión.
    try {
      final processedBytes = await FlutterImageCompress.compressWithList(
        croppedBytes,
        quality: 82,
        minHeight: 512,
        minWidth: 512,
        format: CompressFormat.jpeg,
      );

      return processedBytes;
    } catch (_) {
      // Si la compresión falla, subimos el recorte igual.
      return croppedBytes;
    }
  }

  Future<void> _saveChanges() async {
    if (_loading) return;

    if (!_c["email"]!.text.contains("@")) {
      _showError("Ingresá un email válido");
      return;
    }

    if (_c["telefono"]!.text.length < 6) {
      _showError("Ingresá un teléfono válido");
      return;
    }

    final token = await TokenService.getToken();
    if (token == null) {
      _showError("Sesión expirada");
      return;
    }

    final request = PlayerUpdateRequest(
      nombre: _c["nombre"]!.text.trim(),
      apellido: _c["apellido"]!.text.trim(),
      email: _c["email"]!.text.trim(),
      telefono: _c["telefono"]!.text.trim(),
      genero: _c["genero"]!.text.trim(),
      fechaNacimiento: _c["fechaNacimiento"]!.text.trim(),
      dni: _c["dni"]!.text.trim(),
      cuit: _c["cuit"]!.text.trim(),
      estadoCivil: _c["estadoCivil"]!.text.trim(),
      calle: _c["calle"]!.text.trim(),
      numCalle: _c["numCalle"]!.text.trim(),
      provincia: _c["provincia"]!.text.trim(),
      ciudad: _c["ciudad"]!.text.trim(),
      cp: _c["cp"]!.text.trim(),
    );

    setState(() => _loading = true);

    try {
      final updatedPlayer = await PlayerService().updatePlayerData(request);

      _player = updatedPlayer.copyWith(
        avatarUrl: _avatarUrl.isNotEmpty ? _avatarUrl : updatedPlayer.avatarUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Datos actualizados correctamente',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppConstants.textLight,
            ),
          ),
          backgroundColor: AppConstants.successGreen,
          duration: AppConstants.snackbarDuration,
          action: SnackBarAction(
            label: 'OK',
            textColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppConstants.textLight,
            onPressed: () {},
          ),
        ),
      );

      Navigator.pop(context, _player);
    } catch (e) {
      _showError("Error al actualizar: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 2000,
      maxWidth: 2000,
    );

    if (pickedFile == null) return;

    setState(() => _uploadingAvatar = true);

    try {
      final processedBytes = await _pickCropAndProcessAvatarBytes(pickedFile);
      if (processedBytes == null) {
        // Usuario canceló el recorte
        if (!mounted) return;
        setState(() => _uploadingAvatar = false);
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final filename = kIsWeb ? pickedFile.name : 'avatar_$now.jpg';
      final mimeType = kIsWeb
          ? (pickedFile.mimeType ?? 'image/jpeg')
          : 'image/jpeg';

      final avatarUrl = await PlayerService().uploadAvatar(
        bytes: processedBytes,
        filename: filename,
        mimeType: mimeType,
      );

      if (!mounted) return;

      setState(() {
        _avatarUrl = avatarUrl;
        _player = _player.copyWith(avatarUrl: avatarUrl);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Avatar actualizado',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppConstants.textLight,
            ),
          ),
          backgroundColor: AppConstants.successGreen,
          duration: AppConstants.snackbarDuration,
          action: SnackBarAction(
            label: 'OK',
            textColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppConstants.textLight,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError("No pudimos subir la foto: $e");
    } finally {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: isWeb
          ? _buildWebBody(theme, onSurface, primaryGreen)
          : ResponsiveWrapper(
              maxWidth: 800,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Editar Información",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Modificá tus datos personales",
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  _avatarSection(theme, onSurface, primaryGreen),

                  const SizedBox(height: 12),

                  // --- SECCIÓN 1 ---
                  _section("Datos Personales"),
                  _field("Nombre", _c["nombre"]!),
                  _field("Apellido", _c["apellido"]!),
                  _field("Género", _c["genero"]!),
                  _field("Estado Civil", _c["estadoCivil"]!),
                  _field("Fecha de Nacimiento", _c["fechaNacimiento"]!),

                  const SizedBox(height: 24),

                  // --- SECCIÓN 2 ---
                  _section("Contacto"),
                  _field(
                    "Email",
                    _c["email"]!,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    "Teléfono",
                    _c["telefono"]!,
                    keyboard: TextInputType.phone,
                  ),

                  const SizedBox(height: 24),

                  // --- SECCIÓN 3 ---
                  _section("Documentación"),
                  _field("DNI", _c["dni"]!, readOnly: true),
                  _field("CUIL", _c["cuit"]!, readOnly: true),

                  const SizedBox(height: 24),

                  // --- SECCIÓN 4 ---
                  _section("Dirección"),
                  _field("Calle", _c["calle"]!, readOnly: true),
                  _field("Número", _c["numCalle"]!, readOnly: true),
                  _field("Ciudad", _c["ciudad"]!, readOnly: true),
                  _field("Provincia", _c["provincia"]!, readOnly: true),
                  _field("Código Postal", _c["cp"]!, readOnly: true),

                  const SizedBox(height: 32),

                  // --- BOTÓN ---
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  "Guardar Cambios",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildWebBody(ThemeData theme, Color onSurface, Color primaryGreen) {
    const double outerPadding = 28;
    const double gap = 18;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isNarrowWeb = width < 900;
        if (isNarrowWeb) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Editar Información",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Modificá tus datos personales",
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      _avatarSection(theme, onSurface, primaryGreen),
                      const SizedBox(height: 16),
                      _webCard(
                        theme: theme,
                        primaryGreen: primaryGreen,
                        title: 'Contacto',
                        icon: Icons.contact_mail_outlined,
                        children: [
                          _field(
                            "Email",
                            _c["email"]!,
                            keyboard: TextInputType.emailAddress,
                          ),
                          _field(
                            "Teléfono",
                            _c["telefono"]!,
                            keyboard: TextInputType.phone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _webCard(
                        theme: theme,
                        primaryGreen: primaryGreen,
                        title: 'Datos Personales',
                        icon: Icons.badge_outlined,
                        children: [
                          _field("Nombre", _c["nombre"]!),
                          _field("Apellido", _c["apellido"]!),
                          _field("Género", _c["genero"]!),
                          _field("Estado Civil", _c["estadoCivil"]!),
                          _field("Fecha de Nacimiento", _c["fechaNacimiento"]!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _webCard(
                        theme: theme,
                        primaryGreen: primaryGreen,
                        title: 'Documentación',
                        icon: Icons.assignment_ind_outlined,
                        children: [
                          _field("DNI", _c["dni"]!, readOnly: true),
                          _field("CUIL", _c["cuit"]!, readOnly: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _webCard(
                        theme: theme,
                        primaryGreen: primaryGreen,
                        title: 'Ubicación',
                        icon: Icons.location_on_outlined,
                        children: [
                          _field("Provincia", _c["provincia"]!, readOnly: true),
                          _field("Código Postal", _c["cp"]!, readOnly: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _webCard(
                        theme: theme,
                        primaryGreen: primaryGreen,
                        title: 'Dirección',
                        icon: Icons.home_outlined,
                        children: [
                          _field("Calle", _c["calle"]!, readOnly: true),
                          _field("Número", _c["numCalle"]!, readOnly: true),
                          _field("Ciudad", _c["ciudad"]!, readOnly: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      "Guardar Cambios",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final int columns = width >= 1400
            ? 12
            : width >= 1100
            ? 10
            : width >= 900
            ? 8
            : 6;

        final int leftSpan = (columns * 0.58).round().clamp(3, columns - 2);
        final int rightSpan = (columns - leftSpan).clamp(2, columns);

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(outerPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Editar Información",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Modificá tus datos personales",
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    StaggeredGrid.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      children: [
                        StaggeredGridTile.fit(
                          crossAxisCellCount: leftSpan,
                          child: _avatarSection(theme, onSurface, primaryGreen),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: rightSpan,
                          child: _webCard(
                            theme: theme,
                            primaryGreen: primaryGreen,
                            title: 'Contacto',
                            icon: Icons.contact_mail_outlined,
                            children: [
                              _field(
                                "Email",
                                _c["email"]!,
                                keyboard: TextInputType.emailAddress,
                              ),
                              _field(
                                "Teléfono",
                                _c["telefono"]!,
                                keyboard: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: leftSpan,
                          child: _webCard(
                            theme: theme,
                            primaryGreen: primaryGreen,
                            title: 'Datos Personales',
                            icon: Icons.badge_outlined,
                            children: [
                              _field("Nombre", _c["nombre"]!),
                              _field("Apellido", _c["apellido"]!),
                              _field("Género", _c["genero"]!),
                              _field("Estado Civil", _c["estadoCivil"]!),
                              _field(
                                "Fecha de Nacimiento",
                                _c["fechaNacimiento"]!,
                              ),
                            ],
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: rightSpan,
                          child: _webCard(
                            theme: theme,
                            primaryGreen: primaryGreen,
                            title: 'Documentación',
                            icon: Icons.assignment_ind_outlined,
                            children: [
                              _field("DNI", _c["dni"]!, readOnly: true),
                              _field("CUIL", _c["cuit"]!, readOnly: true),
                            ],
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: rightSpan,
                          child: _webCard(
                            theme: theme,
                            primaryGreen: primaryGreen,
                            title: 'Ubicación',
                            icon: Icons.location_on_outlined,
                            children: [
                              _field(
                                "Provincia",
                                _c["provincia"]!,
                                readOnly: true,
                              ),
                              _field(
                                "Código Postal",
                                _c["cp"]!,
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: columns,
                          child: _webCard(
                            theme: theme,
                            primaryGreen: primaryGreen,
                            title: 'Dirección',
                            icon: Icons.home_outlined,
                            children: [
                              _field("Calle", _c["calle"]!, readOnly: true),
                              _field("Número", _c["numCalle"]!, readOnly: true),
                              _field("Ciudad", _c["ciudad"]!, readOnly: true),
                            ],
                          ),
                        ),
                        StaggeredGridTile.fit(
                          crossAxisCellCount: columns,
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save, size: 22),
                                            SizedBox(width: 12),
                                            Text(
                                              "Guardar Cambios",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _webCard({
    required ThemeData theme,
    required Color primaryGreen,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1A1A1A)
        : AppConstants.lightCardBg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryGreen),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ------------------------
  // COMPONENTES UI
  // ------------------------

  Widget _avatarSection(ThemeData theme, Color onSurface, Color primaryGreen) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1A1A1A)
        : AppConstants.lightCardBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera_back_outlined, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 64,
                backgroundColor: primaryGreen.withValues(alpha: 0.12),
                child: ClipOval(
                  child: _avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _avatarUrl,
                          key: ValueKey(_avatarUrl),
                          width: 116,
                          height: 116,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.person,
                            size: 70,
                            color: onSurface.withValues(alpha: 0.7),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 70,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                ),
              ),
              if (_uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _uploadingAvatar ? null : _pickAndUploadAvatar,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Cambiar foto'),
          ),
          const SizedBox(height: 0),
        ],
      ),
    );
  }

  Widget _section(String title) {
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryGreen,
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);
    final borderColor = primaryGreen.withValues(alpha: readOnly ? 0.35 : 0.8);
    final textColor = onSurface.withValues(alpha: readOnly ? 0.8 : 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        readOnly: readOnly,
        enableInteractiveSelection: !readOnly,
        enabled: !readOnly,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF1A1A1A)
              : AppConstants.lightInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 2),
          ),
        ),
      ),
    );
  }
}
