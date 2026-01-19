import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/casino_response.dart';
import 'package:boombet_app/models/player_model.dart';

class DebugAffiliationPreviews {
  static PlayerData samplePlayerData() {
    return PlayerData(
      nombre: 'Juan',
      apellido: 'Pérez',
      cuil: '20-12345678-3',
      dni: '12345678',
      sexo: 'Masculino',
      estadoCivil: 'Soltero',
      telefono: '1122334455',
      correoElectronico: 'juan.perez@example.com',
      direccionCompleta: 'Av. Siempre Viva 742',
      calle: 'Av. Siempre Viva',
      numCalle: '742',
      localidad: 'CABA',
      provincia: 'Buenos Aires',
      fechaNacimiento: '01-01-1990',
      anioNacimiento: '1990',
      username: 'juanperez',
      cp: 1000,
      edad: 35,
    );
  }

  static AffiliationResult sampleAffiliationResult() {
    return AffiliationResult(
      playerData: {'nombre': 'Juan', 'apellido': 'Pérez', 'dni': '12345678'},
      responses: {
        'Casino Central': CasinoResponse(message: 'OK', success: true),
        'Casino del Río': CasinoResponse(
          message: 'Jugador previamente afiliado',
          success: true,
        ),
        'Casino Norte': CasinoResponse(
          message: 'Error',
          success: false,
          error: 'Servicio no disponible',
        ),
      },
    );
  }
}
