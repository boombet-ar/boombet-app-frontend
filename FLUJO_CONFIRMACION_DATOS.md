# Flujo de Confirmación de Datos de Jugador - BoomBet App

## Resumen General

Se ha configurado el flujo completo para pasar los parámetros del jugador desde el backend a la página de confirmación de datos (`ConfirmPlayerDataPage`).

## Arquitectura del Flujo

### 1. **Modelo de Datos** (`lib/data/player_data.dart`)

La clase `PlayerData` contiene toda la información del jugador:

- Datos personales: nombre, apellido, dni, cuil, fechaNacimiento, edad, sexo, estadoCivil
- Contacto: telefono, correoElectronico
- Dirección: direccionCompleta, calle, numCalle, localidad, provincia, cp

**Métodos importantes:**

- `fromJson()`: Convierte la respuesta del backend (JSON) a objeto PlayerData
- `toJson()`: Convierte el objeto PlayerData a JSON para enviar al backend
- `copyWith()`: Crea una copia del objeto con campos modificados (usado en ConfirmPlayerDataPage)

### 2. **Servicios**

#### `AuthService` (`lib/services/auth_service.dart`)

- `login(username, password)`: Realiza el login y retorna los datos del usuario
  - Retorna: `{'success': bool, 'data': Map, 'message': String}`
  - El campo `data` contiene la información del jugador en formato JSON

#### `PlayerService` (`lib/services/player_service.dart`) - NUEVO

- `updatePlayerData(PlayerData)`: Actualiza los datos del jugador en el backend
  - Endpoint: `PUT /player/update`
  - Envía el JSON con los datos modificados
- `getPlayerData(String dni)`: Obtiene los datos de un jugador específico
  - Endpoint: `GET /player/{dni}`

### 3. **Flujo de Navegación**

```
LoginPage
   ↓ (login exitoso)
ConfirmPlayerDataPage (con datos del backend)
   ↓ (usuario confirma/edita datos)
HomePage (después de guardar en BD)
```

### 4. **Implementación Detallada**

#### En `login_page.dart`:

**Paso 1:** Cuando el usuario hace login exitoso:

```dart
final result = await _authService.login(username, password);
```

**Paso 2:** Convertir la respuesta JSON a PlayerData:

```dart
final playerData = PlayerData.fromJson(result['data']);
```

**Paso 3:** Navegar a ConfirmPlayerDataPage pasando los datos:

```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ConfirmPlayerDataPage(
      datosJugador: playerData,  // ← Datos del jugador
      onConfirm: (datosConfirmados) async {
        // ← Callback cuando confirma
        // Guardar datos modificados
        await _playerService.updatePlayerData(datosConfirmados);
        // Navegar a HomePage
      },
    ),
  ),
);
```

#### En `confirm_data_page.dart`:

**Campos de solo lectura:**

- DNI
- CUIL
- Fecha de nacimiento
- Edad

**Campos editables:**

- Nombre, Apellido
- Correo electrónico, Teléfono
- Dirección completa, Calle, Número, Localidad, Provincia, CP
- Estado civil, Sexo

**Cuando el usuario presiona "Confirmar":**

1. Se crea un nuevo PlayerData con los valores editados usando `copyWith()`
2. Se llama al callback `onConfirm(datosActualizados)`
3. El LoginPage recibe los datos y los guarda en el backend
4. Si el guardado es exitoso, navega a HomePage

### 5. **Manejo de Errores**

#### Error al parsear datos del jugador:

```dart
try {
  final playerData = PlayerData.fromJson(result['data']);
} catch (e) {
  // Muestra AlertDialog: "Error al cargar datos"
}
```

#### Error al guardar datos confirmados:

```dart
final result = await _playerService.updatePlayerData(datosConfirmados);
if (result['success'] == false) {
  // Muestra AlertDialog con el mensaje de error
}
```

## Requisitos del Backend

Para que este flujo funcione correctamente, el backend debe:

### 1. Endpoint de Login (`POST /api/auth/login`)

**Respuesta exitosa (200):**

```json
{
  "nombre": "Juan",
  "apellido": "Pérez",
  "dni": "12345678",
  "cuil": "20-12345678-9",
  "sexo": "M",
  "estado_civil": "Soltero",
  "telefono": "1234567890",
  "correoElectronico": "juan@example.com",
  "direccion": "Calle Falsa 123",
  "calle": "Calle Falsa",
  "numCalle": "123",
  "localidad": "Buenos Aires",
  "provincia": "Buenos Aires",
  "fecha_nacimiento": "1990-01-01",
  "añoNacimiento": "1990",
  "cp": 1234,
  "edad": 34
}
```

### 2. Endpoint de Actualización (`PUT /api/player/update`)

**Request:**

```json
{
  "nombre": "Juan Modificado",
  "apellido": "Pérez"
  // ... todos los campos de PlayerData
}
```

**Respuesta exitosa (200):**

```json
{
  "message": "Datos actualizados correctamente"
}
```

## Configuración de la API

La URL base está configurada en `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
}
```

**Nota:** `10.0.2.2` es la IP especial para que el emulador de Android acceda al localhost de la máquina host.

## Testing

Para probar el flujo completo:

1. Asegúrate de que el backend esté corriendo en `localhost:8080`
2. Inicia la app en el emulador de Android
3. Inicia sesión con credenciales válidas
4. Verifica que ConfirmPlayerDataPage muestra los datos correctos
5. Modifica algún campo editable
6. Presiona "Confirmar"
7. Verifica que los datos se guarden en la base de datos
8. La app debe navegar a HomePage

## Archivos Modificados

1. ✅ `lib/views/pages/login_page.dart` - Navegación a ConfirmPlayerDataPage
2. ✅ `lib/services/player_service.dart` - Servicio nuevo para guardar datos
3. ✅ `lib/main.dart` - Cambiado para iniciar en LoginPage
4. ✅ `lib/data/player_data.dart` - Ya existente, sin cambios
5. ✅ `lib/views/pages/confirm_data_page.dart` - Ya existente, sin cambios

## Próximos Pasos (Opcional)

1. **Agregar token de autenticación:**

   - Guardar token JWT después del login
   - Incluir token en headers de `updatePlayerData()`

2. **Manejo de sesión:**

   - Guardar estado de login en SharedPreferences
   - Auto-login si ya existe sesión válida

3. **Validación de campos:**

   - Validar formato de correo electrónico
   - Validar formato de teléfono
   - Validar código postal

4. **Confirmación visual:**
   - Mostrar toast/snackbar al guardar exitosamente
   - Animación de transición entre páginas
