import 'dart:async';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/env.dart';
import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/firebase_options.dart';
import 'package:boombet_app/services/biometric_service.dart';
import 'package:boombet_app/services/deep_link_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/push_notification_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
const MethodChannel _deepLinkChannel = MethodChannel('boombet/deep_links');

bool _sessionExpiredDialogOpen = false;

NavigatorState? _routerNavigator() {
  return appRouter.routerDelegate.navigatorKey.currentState;
}

BuildContext? _routerContext() {
  return appRouter.routerDelegate.navigatorKey.currentContext;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  if (route == null) {
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

      // Aceptar múltiples nombres de query para el token (backend puede variar)
      String? _extractToken(Uri uri) {
        const candidates = [
          'token',
          'verificacionToken',
          'verification_token',
          'verificationToken',
          'verify_token',
        ];

        for (final key in candidates) {
          final value = uri.queryParameters[key];
          if (value != null && value.isNotEmpty) return value;
        }

        // Fallback: si el token viene como último segmento en rutas tipo /confirm/<token>
        final segments = uri.pathSegments;
        if (segments.length >= 2 &&
            segments.first.toLowerCase().contains('confirm')) {
          final last = segments.last.trim();
          if (last.isNotEmpty) return last;
        }

        return null;
      }

      final token = (raw['token'] as String?) ?? _extractToken(uri);

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

  debugPrint = (String? message, {int? wrapWidth}) {};

  // Web: usar URLs con path (/confirm?token=...) en lugar de hash (/#/confirm?...)
  // Requiere que el hosting haga rewrite de cualquier ruta a index.html.
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Notificaciones: SOLO en mobile. En Web no pedimos permisos ni inicializamos push.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Suscribirse a notificaciones en foreground / openedApp
    await PushNotificationService.initialize();
  } else {}

  // Cargar variables de entorno
  await Env.load();

  // ============================================
  // 🌐 Environment Configuration Verification
  // ============================================

  _initializeDeepLinkHandling();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pendingPayload = DeepLinkService.instance.lastPayload;
    if (pendingPayload != null) {
      _handleDeepLinkNavigation(pendingPayload);
    }
  });

  // Capturar errores de Flutter no manejados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    log(
      '[FlutterError] ${details.exceptionAsString()}',
      stackTrace: details.stack,
    );
  };

  // Capturar errores no manejados fuera del árbol de Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    log('[UnhandledError] $error', stackTrace: stack);
    return true;
  };
  // Asegurar que los tokens temporales no sobrevivan entre reinicios
  await TokenService.deleteTemporaryToken();

  // Si hay sesión activa, exigir biometría una sola vez al abrir la app
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

  // Cargar preferencias de accesibilidad
  await loadFontSizeMultiplier();
  await loadSelectedPage();

  // Configurar callback para manejar 401 (token expirado)
  HttpClient.onUnauthorized = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        appRouter.go('/');
      } catch (e) {}

      // Mostrar SnackBar después de navegar
      final messenger = scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(
            'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
          ),
          backgroundColor: AppConstants.warningOrange,
          duration: AppConstants.longSnackbarDuration,
        ),
      );
    });
  };

  // Si falla el refresh token, mostrar popup con el estilo de la app.
  HttpClient.onSessionExpired = () {
    if (_sessionExpiredDialogOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionExpiredDialogOpen) return;

      final context = _routerContext();
      if (context == null) {
        HttpClient.onUnauthorized?.call();
        return;
      }

      _sessionExpiredDialogOpen = true;

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final dialogBg = isDark
          ? AppConstants.darkAccent
          : AppConstants.lightDialogBg;
      final textColor = isDark
          ? AppConstants.textDark
          : AppConstants.lightLabelText;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Sesión expirada', style: TextStyle(color: textColor)),
          content: Text(
            'Tu sesión expiró. Por favor, inicia sesión nuevamente.',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Forzar vuelta al login incluso si la pantalla actual fue abierta
                // con Navigator.push(...) o si hay rutas apiladas que tapan el router.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final nav =
                      appRouter.routerDelegate.navigatorKey.currentState;
                  if (nav == null) {
                    // Fallback: al menos intentar cambiar la ubicación del router.
                    appRouter.go('/');
                    return;
                  }

                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );

                  // Mantener el router sincronizado en '/'
                  try {
                    appRouter.go('/');
                  } catch (_) {}
                });
              },
              child: const Text(
                'Volver al login',
                style: TextStyle(color: AppConstants.primaryGreen),
              ),
            ),
          ],
        ),
      ).then((_) {
        _sessionExpiredDialogOpen = false;
      });
    });
  };

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => log('[ZoneError] $error', stackTrace: stack),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Cache themes to avoid rebuilding
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppConstants.lightBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.lightSurfaceVariant,
      foregroundColor: AppConstants.textLight,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppConstants.primaryGreen,
      secondary: AppConstants.primaryGreen,
      surface: AppConstants.lightSurfaceVariant,
      background: AppConstants.lightBg,
      error: AppConstants.errorRed,
      onPrimary: AppConstants.textLight,
      onSecondary: AppConstants.textLight,
      onSurface: AppConstants.textLight,
      onBackground: AppConstants.textLight,
      onError: AppConstants.textLight,
    ),
    cardColor: AppConstants.lightCardBg,
    cardTheme: const CardThemeData(
      color: AppConstants.lightCardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      margin: EdgeInsets.zero,
    ),
    dialogBackgroundColor: AppConstants.lightDialogBg,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppConstants.lightDialogBg,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppConstants.lightDialogBg,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.lightSurfaceVariant,
      selectedColor: AppConstants.primaryGreen.withValues(alpha: 0.15),
      disabledColor: AppConstants.borderLight,
      secondarySelectedColor: AppConstants.primaryGreen.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: const TextStyle(color: AppConstants.textLight),
      secondaryLabelStyle: const TextStyle(color: AppConstants.textLight),
      brightness: Brightness.light,
      shape: StadiumBorder(side: BorderSide(color: AppConstants.borderLight)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppConstants.lightAccent,
      indicatorColor: AppConstants.primaryGreen.withValues(alpha: 0.15),
      labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
        final color = states.contains(MaterialState.selected)
            ? AppConstants.textLight
            : AppConstants.lightHintText;
        return TextStyle(color: color, fontSize: 12);
      }),
      iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
        final color = states.contains(MaterialState.selected)
            ? AppConstants.primaryGreen
            : AppConstants.lightHintText;
        return IconThemeData(color: color);
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      contentTextStyle: TextStyle(color: AppConstants.textLight),
      actionTextColor: AppConstants.textLight,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.lightInputBg,
      hintStyle: TextStyle(color: AppConstants.lightHintText),
      labelStyle: TextStyle(color: AppConstants.lightLabelText),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppConstants.lightInputBorder),
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.borderRadius),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppConstants.lightInputBorderFocus),
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.borderRadius),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppConstants.errorRed),
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.borderRadius),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppConstants.errorRed),
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.borderRadius),
        ),
      ),
    ),
    dividerColor: AppConstants.lightDivider,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppConstants.textLight,
      displayColor: AppConstants.textLight,
    ),
    primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
      bodyColor: AppConstants.textLight,
      displayColor: AppConstants.textLight,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(foregroundColor: AppConstants.textLight),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppConstants.textLight),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: AppConstants.textLight),
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
              title: 'BoomBet',
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
