# Build and Run Commands - Environment Configuration

## Overview

The app uses compile-time environment variables (`--dart-define`) to switch between local Docker and Azure backends.

## Environment Variables

| Variable     | Description           | Default                        |
| ------------ | --------------------- | ------------------------------ |
| `API_HOST`   | Backend hostname      | Empty (uses platform defaults) |
| `API_PORT`   | Backend port          | `7070`                         |
| `API_SCHEME` | Protocol (http/https) | `http`                         |

## Commands

### 1. Local Development (Docker)

**Android Emulator:**

```bash
flutter run
```

→ Connects to `http://10.0.2.2:7070/api` (Docker host)

**iOS Simulator:**

```bash
flutter run
```

→ Connects to `http://localhost:7070/api`

**Web:**

```bash
flutter run -d chrome
```

→ Connects to `http://localhost:7070/api`

---

### 2. Production Build (Azure)

**Android APK (Release):**

```bash
flutter build apk --release \
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=
```

→ Connects to `https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api`

**Android App Bundle:**

```bash
flutter build appbundle --release \
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=
```

---

### 3. Testing on Physical Device (Azure)

**Debug mode with Azure backend:**

```bash
flutter run --release \
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=
```

---

### 4. Custom Backend (e.g., staging)

```bash
flutter build apk --release \
  --dart-define=API_HOST=staging.example.com \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=8080
```

→ Connects to `https://staging.example.com:8080/api`

---

## PowerShell Commands (Windows)

For PowerShell, use backticks for line continuation:

```powershell
flutter build apk --release `
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io `
  --dart-define=API_SCHEME=https `
  --dart-define=API_PORT=
```

---

## Verification

To verify which endpoint is being used, check the logs when the app starts:

```dart
print('🌐 API Base URL: ${ApiConfig.baseUrl}');
print('🔌 WebSocket URL: ${ApiConfig.wsBaseUrl}');
```

Or add to `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print configuration
  debugPrint('🌐 API Base URL: ${ApiConfig.baseUrl}');
  debugPrint('🔌 WebSocket URL: ${ApiConfig.wsBaseUrl}');

  runApp(const MyApp());
}
```

---

## CI/CD Integration

**GitHub Actions Example:**

```yaml
- name: Build APK (Production)
  run: |
    flutter build apk --release \
      --dart-define=API_HOST=${{ secrets.AZURE_HOST }} \
      --dart-define=API_SCHEME=https \
      --dart-define=API_PORT=
```

---

## Notes

1. **Empty `API_PORT`**: When port is empty, it won't append `:port` to the URL (standard for HTTPS on port 443).

2. **Default Behavior**: Without any `--dart-define`, the app uses local Docker:

   - Android emulator: `10.0.2.2:7070`
   - iOS/Web: `localhost:7070`

3. **Port Configuration**:

   - Local Docker: `7070` (default)
   - Azure HTTPS: Empty (port 443 is implicit)
   - Custom: Set explicitly with `--dart-define=API_PORT=8080`

4. **No .env files**: This solution uses compile-time variables only, no runtime configuration files.

5. **APK Location**: After building, find your APK at:
   ```
   build\app\outputs\flutter-apk\app-release.apk
   ```
