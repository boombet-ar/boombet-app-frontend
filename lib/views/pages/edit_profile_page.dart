import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/models/player_update_request.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class EditProfilePage extends StatefulWidget {
  final PlayerData player;

  const EditProfilePage({super.key, required this.player});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Map<String, TextEditingController> _c = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppConstants.errorRed,
        duration: AppConstants.longSnackbarDuration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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

    dynamic idJugador;
    try {
      final decoded = JwtDecoder.decode(token);
      idJugador = decoded["idJugador"];

      if (idJugador == null) {
        _showError("No se encontró el ID del jugador");
        return;
      }
    } catch (e) {
      _showError("Token inválido: $e");
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
      final updatedPlayer = await PlayerService().updatePlayerData(
        idJugador.toString(),
        request,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ Datos actualizados correctamente',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppConstants.successGreen,
          duration: AppConstants.snackbarDuration,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      Navigator.pop(context, updatedPlayer);
    } catch (e) {
      _showError("Error al actualizar: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: ResponsiveWrapper(
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
            _field("Email", _c["email"]!, keyboard: TextInputType.emailAddress),
            _field("Teléfono", _c["telefono"]!, keyboard: TextInputType.phone),

            const SizedBox(height: 24),

            // --- SECCIÓN 3 ---
            _section("Documentación"),
            _field("DNI", _c["dni"]!),
            _field("CUIL", _c["cuit"]!),

            const SizedBox(height: 24),

            // --- SECCIÓN 4 ---
            _section("Dirección"),
            _field("Calle", _c["calle"]!),
            _field("Número", _c["numCalle"]!),
            _field("Ciudad", _c["ciudad"]!),
            _field("Provincia", _c["provincia"]!),
            _field("Código Postal", _c["cp"]!),

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
          ],
        ),
      ),
    );
  }

  // ------------------------
  // COMPONENTES UI
  // ------------------------

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
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          filled: true,
          fillColor: isDark
              ? const Color(0xFF1A1A1A)
              : AppConstants.lightInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen.withValues(alpha: 0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryGreen.withValues(alpha: 0.8),
              width: 1.5,
            ),
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
