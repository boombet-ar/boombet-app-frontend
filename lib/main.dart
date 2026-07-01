import 'dart:async';
import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/env.dart';
import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/core/session_handler.dart';
import 'package:boombet_app/core/web_lifecycle.dart';
import 'package:boombet_app/firebase_options.dart';
import 'package:boombet_app/services/device/biometric_service.dart';
import 'package:boombet_app/services/device/deep_link_service.dart';
import 'package:boombet_app/services/device/push_notification_service.dart';
import 'package:boombet_app/services/infra/token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

const MethodChannel _deepLinkChannel = MethodChannel('boombet/deep_links');

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void _scheduleNavigationToRoute(String route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      appRouter.go(route);
    } catch (e) {}
  });
}

void _handleDeepLinkNavigation(DeepLinkPayload payload) {
  final route = DeepLinkService.instance.navigationPathForPayload(payload);
  if (route == null) return;

  _scheduleNavigationToRoute(route);
  DeepLinkService.instance.markPayloadHandled(payload);
}

void _initializeDeepLinkHandling() {
  _deepLinkChannel.setMethodCallHandler((call) async {
    if (call.method != 'onDeepLink') return;

    final Object? arguments = call.arguments;
    if (arguments is! Map) return;

    final raw = Map<dynamic, dynamic>.from(arguments);
    final uriString = raw['uri'] as String?;
    if (uriString == null) return;

    try {
      final uri = Uri.parse(uriString);
      final token = DeepLinkService.extractToken(uri, raw);

      DeepLinkService.instance.emit(DeepLinkPayload(uri: uri, token: token));

      final payload = DeepLinkService.instance.lastPayload;
      if (payload != null) {
        _handleDeepLinkNavigation(payload);
      }
    } catch (error) {}
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquea la app en vertical en todas las pantallas.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  debugPrint = (String? message, {int? wrapWidth}) {};

  // Web: usar URLs con path (/confirm?token=...) en lugar de hash (/#/confirm?...)
  // Requiere que el hosting haga rewrite de cualquier ruta a index.html.
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notificaciones: SOLO en mobile. En Web no pedimos permisos ni inicializamos push.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await PushNotificationService.initialize();
  }

  await Env.load();

  _initializeDeepLinkHandling();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pendingPayload = DeepLinkService.instance.lastPayload;
    if (pendingPayload != null) {
      _handleDeepLinkNavigation(pendingPayload);
    }
  });

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    log('[FlutterError] ${details.exceptionAsString()}', stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log('[UnhandledError] $error', stackTrace: stack);
    return true;
  };

  // Asegurar que los tokens temporales no sobrevivan entre reinicios.
  await TokenService.deleteTemporaryToken();

  // Si hay sesión activa, exigir biometría una sola vez al abrir la app.
  final hasSession = await TokenService.hasActiveSession();
  if (hasSession) {
    final ok = await BiometricService.requireBiometricIfEnabled(
      reason: 'Confirma para ingresar',
      skipIfAlreadyValidated: false,
    );

    if (!ok) {
      await TokenService.clearTokens();
    }
  }

  // Proteger flujos críticos (afiliación, verificación) contra F5 / cierre de pestaña en web.
  registerBeforeUnloadHandler();

  // Cargar preferencias de accesibilidad.
  await loadFontSizeMultiplier();
  await loadSelectedPage();

  // Registrar callbacks de sesión expirada / 401.
  registerSessionCallbacks();

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => log('[ZoneError] $error', stackTrace: stack),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    return ValueListenableBuilder<double>(
      valueListenable: fontSizeMultiplierNotifier,
      builder: (context, fontSizeMultiplier, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'BoomBet',
          themeAnimationDuration: const Duration(milliseconds: 150),
          themeAnimationCurve: Curves.fastOutSlowIn,
          theme: _darkTheme,
          routerConfig: appRouter,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(fontSizeMultiplier),
              ),
              child: SafeArea(
                top: true,
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
  }
}
