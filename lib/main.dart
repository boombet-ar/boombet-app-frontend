import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// GlobalKey para acceder al Navigator desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
const MethodChannel _deepLinkChannel = MethodChannel('boombet/deep_links');

void _scheduleNavigationToRoute(String route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      debugPrint('[MAIN] 🌐 Navigating to deep link route: $route');
      appRouter.go(route);
    } catch (e) {
      debugPrint('[MAIN] ❌ Error navigating to $route: $e');
    }
  });
}

void _handleDeepLinkNavigation(DeepLinkPayload payload) {
  final route = DeepLinkService.instance.navigationPathForPayload(payload);
  if (route == null) {
    debugPrint('[MAIN] ⚠️ Deep link recibido sin token válido: ${payload.uri}');
    return;
  }

  _scheduleNavigationToRoute(route);
  DeepLinkService.instance.markPayloadHandled(payload);
}

void _initializeDeepLinkHandling() {
  _deepLinkChannel.setMethodCallHandler((call) async {
    if (call.method != 'onDeepLink') {
      return;
    }

    final Object? arguments = call.arguments;
    if (arguments is! Map) return;

    final raw = Map<dynamic, dynamic>.from(arguments as Map);
    final uriString = raw['uri'] as String?;
    if (uriString == null) return;

    try {
      final uri = Uri.parse(uriString);
      DeepLinkService.instance.emit(
        DeepLinkPayload(
          uri: uri,
          token: (raw['token'] as String?) ?? uri.queryParameters['token'],
        ),
      );

      final payload = DeepLinkService.instance.lastPayload;
      if (payload != null) {
        _handleDeepLinkNavigation(payload);
      }
    } catch (error) {
      debugPrint('ÔØî [DeepLink] Invalid URI: $error');
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================
  // 🌐 Environment Configuration Verification
  // ============================================
  debugPrint('');
  debugPrint('╔════════════════════════════════════════╗');
  debugPrint('║   🌐 API CONFIGURATION                ║');
  debugPrint('╠════════════════════════════════════════╣');
  debugPrint('║  Base URL: ${ApiConfig.baseUrl.padRight(30)}║');
  debugPrint('║  WebSocket: ${ApiConfig.wsBaseUrl.padRight(28)}║');
  debugPrint('╚════════════════════════════════════════╝');
  debugPrint('');

  _initializeDeepLinkHandling();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pendingPayload = DeepLinkService.instance.lastPayload;
    if (pendingPayload != null) {
      _handleDeepLinkNavigation(pendingPayload);
    }
  });

  // Capturar errores de Flutter no manejados
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('ÔØî [FLUTTER ERROR] ${details.exception}');
    debugPrint('ÔØî [FLUTTER ERROR] ${details.stack}');
  };

  // Asegurar que los tokens temporales no sobrevivan entre reinicios
  await TokenService.deleteTemporaryToken();

  // Cargar preferencias de accesibilidad
  await loadFontSizeMultiplier();

  // Configurar callback para manejar 401 (token expirado)
  HttpClient.onUnauthorized = () {
    debugPrint('[MAIN] ­ƒö┤ 401 Detected - Navigating to LoginPage');

    // Usar navigatorKey para navegar sin contexto
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      debugPrint('[MAIN] Ô£à Navigator found - Pushing LoginPage');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Eliminar todas las rutas previas
      );

      // Mostrar SnackBar despu├®s de navegar
      Future.delayed(const Duration(milliseconds: 500), () {
        final messenger = scaffoldMessengerKey.currentState;
        messenger?.showSnackBar(
          SnackBar(
            content: const Text(
              'Tu sesi├│n ha expirado. Por favor, inicia sesi├│n nuevamente.',
            ),
            backgroundColor: AppConstants.warningOrange,
            duration: AppConstants.longSnackbarDuration,
          ),
        );
      });
    } else {
      debugPrint('[MAIN] ÔØî Navigator is null - Cannot navigate');
    }
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Cache themes to avoid rebuilding
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppConstants.lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.lightAccent,
      foregroundColor: AppConstants.textLight,
      elevation: 0,
    ),
    colorScheme: ColorScheme.light(
      primary: AppConstants.primaryGreen,
      secondary: AppConstants.textLight,
      surface: AppConstants.lightAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppConstants.textLight,
    ),
    cardColor: AppConstants.lightAccent,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppConstants.textLight),
      bodyMedium: TextStyle(color: AppConstants.textLight),
    ),
  );

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppConstants.darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.darkBg,
      foregroundColor: AppConstants.textDark,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppConstants.primaryGreen,
      secondary: AppConstants.darkAccent,
      surface: AppConstants.darkAccent,
      onPrimary: Colors.black,
      onSecondary: AppConstants.textDark,
      onSurface: AppConstants.textDark,
    ),
    cardColor: AppConstants.darkAccent,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppConstants.textDark),
      bodyMedium: TextStyle(color: AppConstants.textDark),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        return ValueListenableBuilder<double>(
          valueListenable: fontSizeMultiplierNotifier,
          builder: (context, fontSizeMultiplier, _) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: scaffoldMessengerKey,
              title: 'BoomBet App',
              themeAnimationDuration: const Duration(milliseconds: 150),
              themeAnimationCurve: Curves.fastOutSlowIn,
              theme: _lightTheme,
              darkTheme: _darkTheme,
              themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
              routerConfig: appRouter,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(fontSizeMultiplier),
                  ),
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    bottom: true,
                    child: child!,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

//comando para correr siempre en el mismo puerto en chrome
//flutter run -d chrome --web-hostname localhost --web-port 8080
//
//comando para buildear el apk
//flutter build apk --release
