import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';

// GlobalKey para acceder al Navigator desde cualquier lugar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey:
              navigatorKey, // Agregar GlobalKey para navegación desde HttpClient
          scaffoldMessengerKey: scaffoldMessengerKey,
          title: 'BoomBet App',
          themeAnimationDuration: const Duration(milliseconds: 150),
          themeAnimationCurve: Curves.fastOutSlowIn,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
          home: child!,
        );
      },
      child: const MyHomePage(title: 'Boombet App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Eliminar token temporal SOLO cuando la app se cierra completamente
      // (no cuando pasa a segundo plano - paused)
      TokenService.deleteTemporaryToken();
    }
  }

  Future<void> _checkSession() async {
    // Verificar cualquier token válido (persistente O temporal)
    final hasActiveSession = await TokenService.isTokenValid();
    if (!mounted) return;
    setState(() {
      _hasSession = hasActiveSession;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SafeArea(child: _hasSession ? const HomePage() : const LoginPage());
  }
}
