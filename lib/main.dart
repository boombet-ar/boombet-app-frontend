import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(
              0xFFF5F5F5,
            ), // Gris claro suave
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFE8E8E8), // Gris claro para AppBar
              foregroundColor: Color(0xFF2C2C2C), // Texto oscuro
              elevation: 0,
            ),
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(
                255,
                35,
                200,
                75,
              ), // Verde más oscuro
              secondary: const Color(0xFF2C2C2C),
              surface: const Color(0xFFE8E8E8),
              background: const Color(0xFFF5F5F5),
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: const Color(0xFF2C2C2C),
              onBackground: const Color(0xFF2C2C2C),
            ),
            cardColor: const Color(0xFFE8E8E8),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF2C2C2C)),
              bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000), // Negro puro
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000),
              foregroundColor: Color(0xFFE0E0E0),
              elevation: 0,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 41, 255, 94), // Verde brillante
              secondary: Color(0xFF1A1A1A),
              surface: Color(0xFF1A1A1A),
              background: Color(0xFF000000),
              onPrimary: Colors.black,
              onSecondary: Color(0xFFE0E0E0),
              onSurface: Color(0xFFE0E0E0),
              onBackground: Color(0xFFE0E0E0),
            ),
            cardColor: const Color(0xFF1A1A1A),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
              bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
            ),
          ),
          themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
          home: const MyHomePage(title: 'Boombet App'),
        );
      },
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
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      // Eliminar token temporal cuando la app se cierra o pasa a segundo plano
      TokenService.deleteTemporaryToken();
    }
  }

  Future<void> _checkSession() async {
    final hasActiveSession = await TokenService.hasActiveSession();
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
