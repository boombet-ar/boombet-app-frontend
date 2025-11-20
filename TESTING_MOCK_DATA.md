# Modo Testing con Mock Data

## 📋 Descripción

El login y la confirmación de datos están configurados temporalmente para usar **datos mock** en lugar de conectarse al backend. Esto permite validar toda la UI y flujo de navegación sin necesidad de tener el backend corriendo.

## 🔑 Credenciales de Prueba

Para iniciar sesión, usa:

- **Usuario:** `testuser`
- **Contraseña:** `Test123!`

## 👤 Datos del Jugador Mock

Los datos que se cargarán en la página de confirmación son:

```dart
{
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
  "edad": 26
}
```

## ✅ Qué Validar en Testing

### 1. Página de Login

- [ ] Validación de campos vacíos
- [ ] Mensaje de error con credenciales incorrectas (muestra las credenciales correctas)
- [ ] Indicador de carga al hacer login
- [ ] Navegación exitosa a ConfirmPlayerDataPage

### 2. Página de Confirmación de Datos

**Campos de Solo Lectura (gris oscuro):**

- [ ] DNI: 39566212
- [ ] CUIL: 20-39566212-7
- [ ] Fecha de nacimiento: 15-04-1998
- [ ] Año de nacimiento: 1998
- [ ] Edad: 26
- [ ] Dirección completa: AV. SAN MARTIN 1024
- [ ] Calle: AV. SAN MARTIN
- [ ] Número: 1024
- [ ] Localidad: RAFAEL CASTILLO
- [ ] Provincia: BUENOS AIRES
- [ ] Código postal: 1755

**Campos Editables (borde verde):**

- [ ] Nombre: MARTIN
- [ ] Apellido: GOMEZ
- [ ] Sexo: Masculino
- [ ] Estado civil: SOLTERO
- [ ] Correo electrónico: martin.gomez@example.com
- [ ] Teléfono: 1165482231

**Funcionalidad:**

- [ ] Los campos editables permiten modificar el texto
- [ ] Los campos de solo lectura NO permiten editar
- [ ] El botón "Volver" navega al Login
- [ ] El botón "Confirmar datos" navega a HomePage

## 🔄 Cómo Activar el Backend Real

Cuando el backend esté listo, debes:

### 1. En `lib/views/pages/login_page.dart`:

**Descomentar los imports:**

```dart
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
```

**Descomentar las instancias de servicios:**

```dart
final AuthService _authService = AuthService();
final PlayerService _playerService = PlayerService();
```

**Reemplazar el bloque de validación mock** (línea ~79):

```dart
// Eliminar estas líneas:
await Future.delayed(const Duration(seconds: 1));
if (username == MockData.testUsername && password == MockData.testPassword) {
  final playerData = PlayerData.fromJson(MockData.playerDataJson);
  // ...
}

// Y descomentar:
final result = await _authService.login(
  _userController.text.trim(),
  _passwordController.text,
);

if (result['success'] == true) {
  final playerData = PlayerData.fromJson(result['data']);
  // ...
}
```

**En el callback `onConfirm`** (línea ~118):

```dart
// Descomentar el bloque completo de guardado real:
showDialog(...);
final result = await _playerService.updatePlayerData(datosConfirmados);
// ... manejo de errores
```

### 2. Eliminar referencias a MockData (opcional):

- Puedes eliminar el archivo `lib/data/mock_data.dart`
- Eliminar el import en login_page.dart

## 📝 Archivos Modificados

- ✅ `lib/data/mock_data.dart` - Datos de prueba
- ✅ `lib/views/pages/login_page.dart` - Modo testing activado
- ✅ `lib/views/pages/confirm_data_page.dart` - Campos de solo lectura configurados

## 🎯 Flujo Actual de Testing

```
1. LoginPage
   ↓ (credenciales: testuser / Test123!)
2. ConfirmPlayerDataPage (con datos mock de MARTIN GOMEZ)
   ↓ (editar campos editables, confirmar)
3. HomePage
   ↓ (botón volver)
4. LoginPage (permite re-testear)
```
