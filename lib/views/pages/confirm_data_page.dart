import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';

class ConfirmPlayerDataPage extends StatefulWidget {
  final PlayerData datosJugador;
  final void Function(PlayerData datosConfirmados) onConfirm;

  const ConfirmPlayerDataPage({
    super.key,
    required this.datosJugador,
    required this.onConfirm,
  });

  @override
  State<ConfirmPlayerDataPage> createState() => _ConfirmPlayerDataPageState();
}

class _ConfirmPlayerDataPageState extends State<ConfirmPlayerDataPage> {
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _estadoCivilController;
  late TextEditingController _sexoController;

  @override
  void initState() {
    super.initState();
    final d = widget.datosJugador;

    _nombreController = TextEditingController(text: d.nombre);
    _apellidoController = TextEditingController(text: d.apellido);
    _correoController = TextEditingController(text: d.correoElectronico);
    _telefonoController = TextEditingController(text: d.telefono);
    _estadoCivilController = TextEditingController(text: d.estadoCivil);
    _sexoController = TextEditingController(text: d.sexo);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _estadoCivilController.dispose();
    _sexoController.dispose();
    super.dispose();
  }

  void _onConfirmar() {
    final actualizado = widget.datosJugador.copyWith(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correoElectronico: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      estadoCivil: _estadoCivilController.text.trim(),
      sexo: _sexoController.text.trim(),
    );

    widget.onConfirm(actualizado);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.datosJugador;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greenColor = theme.colorScheme.primary;
    final appBarBg = isDark ? Colors.black38 : const Color(0xFFE8E8E8);
    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: appBarBg,
          leading: null,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: greenColor),
                tooltip: 'Volver al Login',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLightMode, child) {
                    return Icon(
                      isLightMode ? Icons.dark_mode : Icons.light_mode,
                      color: greenColor,
                    );
                  },
                ),
                tooltip: 'Cambiar tema',
                onPressed: () {
                  isLightModeNotifier.value = !isLightModeNotifier.value;
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.asset('assets/images/boombetlogo.png', height: 80),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Confirmá tus datos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: greenColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Verificá que todos tus datos sean correctos. '
                  'Los campos en gris no se pueden modificar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // --------- BLOQUE DOCUMENTO (SOLO LECTURA) ---------
                _buildReadOnlyField(label: 'DNI', value: d.dni),
                _buildReadOnlyField(label: 'CUIL', value: d.cuil),
                _buildReadOnlyField(
                  label: 'Fecha de nacimiento',
                  value: d.fechaNacimiento,
                ),
                _buildReadOnlyField(
                  label: 'Año de nacimiento',
                  value: d.anioNacimiento,
                ),
                _buildReadOnlyField(
                  label: 'Edad',
                  value: d.edad?.toString() ?? '',
                ),

                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),

                // --------- DATOS PERSONALES EDITABLES ---------
                _buildEditableField(
                  label: 'Nombre',
                  controller: _nombreController,
                ),
                _buildEditableField(
                  label: 'Apellido',
                  controller: _apellidoController,
                ),
                _buildEditableField(label: 'Sexo', controller: _sexoController),
                _buildEditableField(
                  label: 'Estado civil',
                  controller: _estadoCivilController,
                ),

                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),

                // --------- CONTACTO ---------
                _buildEditableField(
                  label: 'Correo electrónico',
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildEditableField(
                  label: 'Teléfono',
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),

                // --------- DIRECCIÓN (SOLO LECTURA) ---------
                _buildReadOnlyField(
                  label: 'Dirección completa',
                  value: d.direccionCompleta,
                ),
                _buildReadOnlyField(label: 'Calle', value: d.calle),
                _buildReadOnlyField(label: 'Número', value: d.numCalle),
                _buildReadOnlyField(label: 'Localidad', value: d.localidad),
                _buildReadOnlyField(label: 'Provincia', value: d.provincia),
                _buildReadOnlyField(
                  label: 'Código postal',
                  value: d.cp?.toString() ?? '',
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _onConfirmar,
                    child: const Text(
                      'Confirmar datos',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    if (value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: true,
        enabled: false,
        controller: TextEditingController(text: value),
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF404040) : const Color(0xFFC0C0C0),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greenColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onBackground;
    final fillColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF5F5F5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greenColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: greenColor, width: 2),
          ),
        ),
      ),
    );
  }
}
