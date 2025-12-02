import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';

// GlobalKey para acceder al Navigator desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Asegurar que los tokens temporales no sobrevivan entre reinicios
  await TokenService.deleteTemporaryToken();

  // Configurar callback para manejar 401 (token expirado)
  HttpClient.onUnauthorized = () {
    debugPrint('[MAIN] 🔴 401 Detected - Navigating to LoginPage');

    // Usar navigatorKey para navegar sin contexto
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      debugPrint('[MAIN] ✅ Navigator found - Pushing LoginPage');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Eliminar todas las rutas previas
      );

      // Mostrar SnackBar después de navegar
      Future.delayed(const Duration(milliseconds: 500), () {
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
    } else {
      debugPrint('[MAIN] ❌ Navigator is null - Cannot navigate');
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
        );
      },
    );
  }
}

//CUENTA
//username: test
//email: test@gmail.com
//DNI: 45614451
//contra: TGm.4751!

//
