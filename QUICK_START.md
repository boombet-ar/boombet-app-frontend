# 🚀 Quick Reference - Environment Configuration

## TL;DR

### Local Development (Docker)

```bash
flutter run
```

→ Uses `http://10.0.2.2:7070/api` (Android) or `http://localhost:7070/api` (iOS/Web)

### Production Build (Azure)

```bash
# PowerShell (Windows)
flutter build apk --release `
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io `
  --dart-define=API_SCHEME=https `
  --dart-define=API_PORT=

# Bash (Linux/Mac)
flutter build apk --release \
  --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=
```

→ Uses `https://boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io/api`

---

## Variables

| Variable     | Default                     | Production      |
| ------------ | --------------------------- | --------------- |
| `API_HOST`   | (empty) = platform defaults | Azure hostname  |
| `API_SCHEME` | `http`                      | `https`         |
| `API_PORT`   | `7070`                      | (empty) for 443 |

---

## Verification

On app startup, check the console:

```
╔════════════════════════════════════════╗
║   🌐 API CONFIGURATION                ║
╠════════════════════════════════════════╣
║  Base URL: http://10.0.2.2:7070/api   ║
║  WebSocket: ws://10.0.2.2:7070        ║
╚════════════════════════════════════════╝
```

---

## Common Scenarios

### Test Azure on emulator

```bash
flutter run --dart-define=API_HOST=boombetbackend.calmpebble-5d8daaab.brazilsouth.azurecontainerapps.io --dart-define=API_SCHEME=https --dart-define=API_PORT=
```

### Physical device with local backend

1. Get your computer's local IP (e.g., `192.168.1.100`)
2. Update Docker to bind to `0.0.0.0:7070`
3. Run:

```bash
flutter run --dart-define=API_HOST=192.168.1.100
```

### Custom staging server

```bash
flutter build apk --release \
  --dart-define=API_HOST=staging.example.com \
  --dart-define=API_SCHEME=https \
  --dart-define=API_PORT=8080
```

---

## Files Changed

✅ `lib/config/api_config.dart` - Now uses `String.fromEnvironment`  
✅ `lib/main.dart` - Shows config on startup  
✅ All services - Already using `ApiConfig.baseUrl` (no changes needed)

---

## What Changed?

**Before:**

```dart
// Had to manually comment/uncomment
// static String customUrl = 'https://azure-host.com/api';
static String customUrl = ''; // Local Docker
```

**After:**

```dart
// Automatically switches based on --dart-define
static const String _envHost = String.fromEnvironment('API_HOST', defaultValue: '');
```

---

## Troubleshooting

**Problem:** APK still connects to local Docker  
**Solution:** You forgot `--dart-define` flags. The configuration is baked at compile time.

**Problem:** "Connection refused" on physical device  
**Solution:** Physical devices can't reach `10.0.2.2`. Use your computer's LAN IP instead.

**Problem:** "Certificate verification failed" on Azure  
**Solution:** Normal for self-signed certs. Azure uses proper SSL, should work.

---

## Next Steps

1. ✅ Run locally: `flutter run`
2. ✅ Verify console shows correct URL
3. ✅ Build for production: Use command from top
4. ✅ Install APK on device
5. ✅ Check logs to confirm Azure connection

Done! 🎉
