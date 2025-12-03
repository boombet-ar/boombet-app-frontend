# 📱 Reset Password Flow - BoomBet App

## 📋 Overview

Se ha implementado un flujo completo de recuperación de contraseña:

1. **Forgot Password Page** - Usuario solicita recuperación
2. **Email Enviado** - Backend envía email con link de reset
3. **Reset Password Page** - Usuario establece nueva contraseña
4. **Cambio Confirmado** - Usuario redirigido al login

---

## 📁 Archivos Creados/Modificados

### 1. **lib/views/pages/reset_password_page.dart** ✅ NUEVO

- Página para resetear la contraseña
- 2 campos: Contraseña + Repetir Contraseña
- **Validaciones en tiempo real:**
  - ✅ 8+ caracteres
  - ✅ 1 mayúscula
  - ✅ 1 número
  - ✅ 1 símbolo
  - ✅ Sin caracteres repetidos (3+)
  - ✅ Sin secuencias numéricas (123, 321)
  - ✅ Sin secuencias alfabéticas (abc, xyz)
  - ✅ Las contraseñas deben coincidir
- Muestra en vivo el estado de cada regla ✔️ ❌
- Integración con `ResetPasswordService`
- Tema claro/oscuro
- Botón de volver + toggle de tema

### 2. **lib/services/reset_password_service.dart** ✅ NUEVO

- Servicio para comunicación con backend
- **Endpoint:** `POST /api/users/auth/reset-password`
- **Payload:**
  ```json
  {
    "token": "xxxxx",
    "email": "user@example.com",
    "newPassword": "NewPass123!"
  }
  ```
- **Manejo de respuestas:**
  - ✅ 200/201: Éxito
  - ❌ 400: Bad Request (datos inválidos)
  - ❌ 401: Token inválido/expirado
  - ❌ 404: Usuario no encontrado
  - ❌ 429: Rate limit
  - ⏱️ 408: Timeout
- Timeout: 30 segundos
- Debug logs con emojis 📧 ✅ ❌ ⏱️

### 3. **lib/config/router_config.dart** ✅ MODIFICADO

```dart
// Agregado:
- Importación de ResetPasswordPage
- Ruta: /reset?token=xxxxx&email=user@example.com
- Permiso de acceso sin login (deep link)
- Extracción automática de parámetros
```

---

## 🔗 Flujo Completo

### 1️⃣ Usuario solicita recuperación (ForgetPasswordPage)

```dart
// El usuario ingresa su email y presiona "Enviar Correo"
ForgotPasswordService.sendPasswordResetEmail("user@example.com")
↓
Backend: POST /api/users/auth/forgot-password
Body: {"email": "user@example.com"}
```

### 2️⃣ Backend envía email

```
El backend DEBE enviar un email con un link como:

🌐 Web:
https://boombet.com/reset?token=abc123def456&email=user@example.com

📱 App (Deep Link):
boombet://reset?token=abc123def456&email=user@example.com

O ambos, para que funcione en app y web
```

### 3️⃣ Usuario abre el link

```dart
// El router automáticamente:
GoRoute(
  path: '/reset',
  builder: (context, state) {
    final token = state.uri.queryParameters['token'];
    final email = state.uri.queryParameters['email'];
    return ResetPasswordPage(token: token, email: email);
  }
)
```

### 4️⃣ Usuario ingresa nueva contraseña

```dart
// Validaciones en vivo muestran requisitos
// Usuario ve ✅ o ❌ para cada regla
// Presiona "Restablecer Contraseña"

ResetPasswordService.resetPassword(
  token: "abc123def456",
  email: "user@example.com",
  newPassword: "NewPass123!"
)
↓
Backend: POST /api/users/auth/reset-password
Body: {"token": "...", "email": "...", "newPassword": "..."}
```

### 5️⃣ Contraseña actualizada

```dart
// Si éxito (200/201):
// ✅ Mostrar snackbar de éxito
// → Esperar 2 segundos
// → Navegar a login (/）

// Si error:
// ❌ Mostrar snackbar con error específico
// → Usuario puede intentar de nuevo
```

---

## 🎨 UI/UX

### Reset Password Page

```
┌─ AppBar ─────────────────────────┐
│ ← ☀️ [LOGO]                      │
├──────────────────────────────────┤
│                                  │
│     Restablecer Contraseña      │
│   Ingresa tu nueva contraseña    │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🔒 Contraseña             │  │
│  │ ••••••••••                │  │
│  └────────────────────────────┘  │
│                                  │
│  Validaciones en vivo:           │
│  ✅ 8+ caracteres               │
│  ✅ 1 mayúscula                │
│  ❌ 1 número                    │
│  ✅ 1 símbolo                  │
│  ✅ Sin repetidos              │
│  ✅ Sin secuencias             │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🔒 Repetir Contraseña      │  │
│  │ ••••••••••                │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │  Restablecer Contraseña    │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
```

---

## 🔐 Validaciones Reutilizadas (de RegisterPage)

```dart
// PasswordValidationService.getValidationStatus()
Map<String, bool> {
  'minimum_length': password.length >= 8,
  'uppercase': password.contains(RegExp(r'[A-Z]')),
  'number': password.contains(RegExp(r'[0-9]')),
  'symbol': password.contains(RegExp(r'[!@#$%...]')),
  'no_repetition': !RegExp(r'(.)\1{2,}').hasMatch(password),
  'no_sequence': !hasNumericOrAlphabeticSequence(password),
}
```

---

## ✅ TODO - Backend

El backend debe implementar:

### 1. Endpoint: `POST /api/users/auth/forgot-password`

- ✅ Ya existe
- Input: `{"email": "string"}`
- Output:
  ```json
  {
    "success": true,
    "message": "Correo enviado correctamente",
    "statusCode": 200
  }
  ```
- **Debe enviar email con:**
  - Token de recuperación
  - Link: `boombet://reset?token=xxx&email=user@example.com`
  - Instrucciones claras

### 2. Endpoint: `POST /api/users/auth/reset-password`

- ❓ Necesita implementarse
- Input:
  ```json
  {
    "token": "string",
    "email": "string",
    "newPassword": "string"
  }
  ```
- Output:
  ```json
  {
    "success": true,
    "message": "Contraseña actualizada correctamente",
    "statusCode": 200
  }
  ```
- **Validaciones (backend):**
  - Verificar que el token es válido
  - Verificar que el email coincide con el token
  - Verificar que el token no haya expirado (ej: 15 minutos)
  - Actualizar contraseña en BD
  - Invalidar token (para que no se reutilice)

---

## 🧪 Testing

### Caso de éxito:

```
1. Ir a ForgetPasswordPage
2. Ingresar email válido
3. Presionar "Enviar Correo"
4. ✅ Recibir email con link
5. Abrir link → Abre ResetPasswordPage
6. Ingresar contraseña nueva (válida)
7. Confirmar contraseña
8. Presionar "Restablecer Contraseña"
9. ✅ Snackbar verde "Contraseña actualizada"
10. → Redirigido a login
```

### Caso de error - Token expirado:

```
1. Abrir link antiguo (>15 minutos)
2. ❌ Snackbar rojo "Token inválido o expirado"
3. Usuario debe solicitar nuevo email
```

### Caso de error - Contraseñas no coinciden:

```
1. Ingresar contraseña en primer campo
2. Ingresar diferente en segundo campo
3. Presionar botón
4. ❌ Snackbar rojo "Las contraseñas no coinciden"
```

---

## 🔗 Deep Linking

### Android (AndroidManifest.xml)

```xml
<!-- Ya debe estar configurado, similar a /confirm -->
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="boombet" android:host="reset" />
  <!-- Para URLs web: -->
  <data android:scheme="https" android:host="boombet.com" android:path="/reset" />
</intent-filter>
```

### iOS (Info.plist)

```xml
<!-- Ya debe estar configurado, similar a /confirm -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>boombet</string>
    </array>
  </dict>
</array>
```

---

## 📊 Estado del Proyecto

✅ **Frontend Completado:**

- Página de reset password
- Validaciones en vivo
- Servicio de comunicación
- Routing con deep linking
- UI con tema claro/oscuro

❓ **Backend Pendiente:**

- Implementar `/api/users/auth/reset-password`
- Enviar emails con link de reset
- Validar tokens
- Expiración de tokens (15 minutos recomendado)

⚠️ **Configuración Pendiente:**

- Android: AndroidManifest.xml (deep linking)
- iOS: Info.plist (deep linking)

---

## 🚀 Próximos Pasos

1. Implementar endpoint `/api/users/auth/reset-password` en backend
2. Configurar envío de emails con link de reset
3. Probar deep linking en ambas plataformas
4. Ajustar mensajes de error según respuestas del backend
5. Agregar analytics para rastrear uso

---

## 📞 Notas Importantes

- El token debe ser **único, seguro y con expiración**
- El token debe invalidarse después de usarse (no reutilizable)
- El email en la URL debe ir en parámetro de query por seguridad
- Considerar HTTPS/HSTS en producción
- Registrar eventos de reset en logs de seguridad

---

**Última actualización:** 2024-12-03
