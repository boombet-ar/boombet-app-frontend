/// Mock data para testing sin backend
/// Este archivo contiene datos de prueba que simulan la respuesta del backend
class MockData {
  static const Map<String, dynamic> playerDataJson = {
    "nombre": "MARTIN",
    "apellido": "GOMEZ",
    "cuil": "20-39566212-7",
    "dni": 39566212,
    "sexo": "Masculino",
    "estado_civil": "SOLTERO",
    "telefono": "1165482231",
    "correoElectronico": "martin.gomez@example.com",
    "direccion": "AV. SAN MARTIN 1024",
    "calle": "AV. SAN MARTIN",
    "numCalle": "1024",
    "localidad": "RAFAEL CASTILLO",
    "provincia": "BUENOS AIRES",
    "cp": 1755,
    "fecha_nacimiento": "15-04-1998",
    "añoNacimiento": "1998",
    "edad": 26,
  };

  /// Credenciales de prueba para el login
  static const String testEmail = "test@boombet.com";
  static const String testPassword = "Test123!";
}
