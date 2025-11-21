import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/views/pages/pending_afiliacion.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

class ConfirmPlayerDataPage extends StatefulWidget {
  final PlayerData playerData;
  final String? token;

  const ConfirmPlayerDataPage({
    super.key,
    required this.playerData,
    this.token,
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

  final PlayerService _playerService = PlayerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.playerData;

    _nombreController = TextEditingController(text: data.nombre);
    _apellidoController = TextEditingController(text: data.apellido);
    _correoController = TextEditingController(text: data.correoElectronico);
    _telefonoController = TextEditingController(text: data.telefono);
    _estadoCivilController = TextEditingController(text: data.estadoCivil);
    _sexoController = TextEditingController(text: data.sexo);
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

  Future<void> _onConfirmarDatos() async {
    setState(() {
      _isLoading = true;
    });

    // Crear PlayerData actualizado (solo campos editables)
    final updatedData = widget.playerData.copyWith(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correoElectronico: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      estadoCivil: _estadoCivilController.text.trim(),
      sexo: _sexoController.text.trim(),
      // Dirección no se actualiza (campos read-only)
    );

    // TODO: Descomentar cuando el backend implemente el endpoint /auth/confirmData
    // Enviar datos al backend
    // final result = await _playerService.sendConfirmedPlayerData(
    //   updatedData,
    //   widget.token,
    // );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // TODO: Validar resultado del backend cuando esté implementado
    // Por ahora, navegamos directamente sin validar backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos confirmados correctamente'),
        backgroundColor: Color.fromARGB(255, 41, 255, 94),
        duration: Duration(seconds: 2),
      ),
    );

    // Navegar a la página de espera de afiliación
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PendingAfiliacionPage()),
    );

    // TODO: Descomentar cuando el backend esté listo
    // if (result['success'] == true) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(result['message'] ?? 'Datos confirmados correctamente'),
    //       backgroundColor: const Color.fromARGB(255, 41, 255, 94),
    //     ),
    //   );
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => const PendingAfiliacionPage()),
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text(result['message'] ?? 'Error al confirmar datos'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.playerData;
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: const MainAppBar(
        showSettings: false,
        showProfileButton: false,
        showBackButton: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text(
                'Confirmá tus datos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Verificá que todos tus datos sean correctos',
                style: TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --------- DATOS PERSONALES ---------
              const Text(
                'Datos Personales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),

              _buildReadOnlyField('DNI', data.dni),
              _buildReadOnlyField('CUIL', data.cuil),
              _buildReadOnlyField('Fecha de Nacimiento', data.fechaNacimiento),
              _buildReadOnlyField('Año de Nacimiento', data.anioNacimiento),
              if (data.edad != null)
                _buildReadOnlyField('Edad', data.edad.toString()),

              const SizedBox(height: 16),

              _buildEditableField('Nombre', _nombreController),
              _buildEditableField('Apellido', _apellidoController),
              _buildEditableField('Sexo', _sexoController),
              _buildEditableField('Estado Civil', _estadoCivilController),

              const SizedBox(height: 24),

              // --------- CONTACTO ---------
              const Text(
                'Contacto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),

              _buildEditableField(
                'Correo Electrónico',
                _correoController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildEditableField(
                'Teléfono',
                _telefonoController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // --------- DIRECCIÓN ---------
              const Text(
                'Dirección',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 16),

              _buildReadOnlyField('Calle', data.calle),
              _buildReadOnlyField('Número', data.numCalle),
              _buildReadOnlyField('Localidad', data.localidad),
              _buildReadOnlyField('Provincia', data.provincia),
              if (data.cp != null)
                _buildReadOnlyField('Código Postal', data.cp.toString()),

              const SizedBox(height: 32),

              // --------- BOTÓN CONFIRMAR ---------
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onConfirmarDatos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Confirmar datos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        readOnly: true,
        enabled: false,
        controller: TextEditingController(text: value),
        style: const TextStyle(color: Colors.white60),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    const primaryGreen = Color.fromARGB(255, 41, 255, 94);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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
