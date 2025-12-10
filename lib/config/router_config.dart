import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Redirect callback para manejar autenticaci├│n
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  debugPrint('­ƒöÇ ===== REDIRECT CALLBACK =====');
  debugPrint('­ƒöÇ state.uri.path: ${state.uri.path}');
  debugPrint('­ƒöÇ state.uri: ${state.uri}');
  debugPrint('­ƒöÇ state.matchedLocation: ${state.matchedLocation}');

  // Permitir siempre el acceso a /confirm, /reset, /reset-password, /password-reset sin login
  final isPublicRoute =
      state.uri.path == '/confirm' ||
      state.uri.path == '/reset' ||
      state.uri.path == '/reset-password' ||
      state.uri.path == '/password-reset';

  if (isPublicRoute) {
    debugPrint('­ƒöÇ Path coincide con ruta p├║blica, permitir acceso');
    return null; // No redirigir, permitir acceso sin login
  }

  // Verificar si hay sesi├│n activa
  final isLoggedIn = await TokenService.isTokenValid();
  debugPrint('­ƒöÇ isLoggedIn: $isLoggedIn');

  // Si no est├í logueado y no est├í en / o rutas p├║blicas, ir al login
  if (!isLoggedIn && state.uri.path != '/' && !isPublicRoute) {
    debugPrint('­ƒöÇ Redirigiendo a login (no logueado y path no permitido)');
    return '/';
  }

  // Si est├í logueado e intenta ir al login, ir al home
  if (isLoggedIn && state.uri.path == '/') {
    debugPrint('­ƒöÇ Redirigiendo a home (logueado en login)');
    return '/home';
  }

  debugPrint('­ƒöÇ No redirigir');
  return null; // No redirigir
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: _redirect,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    // Deep link para confirmaci├│n de email
    GoRoute(
      path: '/confirm',
      builder: (context, state) {
        // Intentar obtener el token de diferentes par├ímetros posibles
        final token =
            state.uri.queryParameters['token'] ??
            state.uri.queryParameters['verificacionToken'] ??
            state.uri.queryParameters['verification_token'] ??
            '';
        debugPrint('­ƒöù Deep Link recibido - token: $token');
        debugPrint('­ƒöù Query parameters: ${state.uri.queryParameters}');
        return EmailConfirmationPage(
          verificacionToken: token,
          isFromDeepLink: true,
        );
      },
    ),
    // Deep link para resetear contrase├▒a - M├ÜLTIPLES RUTAS SOPORTADAS
    // Soporta: /reset, /reset-password, /password-reset, etc.
    GoRoute(
      path: '/reset',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/password-reset',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
  ],
);

Widget _buildResetPasswordPage(BuildContext context, GoRouterState state) {
  try {
    debugPrint('­ƒöù ===== RESET PASSWORD ROUTE =====');
    debugPrint('­ƒöù State path: ${state.uri.path}');
    debugPrint('­ƒöù State uri: ${state.uri}');
    debugPrint('­ƒöù Full URI string: ${state.uri.toString()}');
    debugPrint('­ƒöù Query parameters: ${state.uri.queryParameters}');

    final token = state.uri.queryParameters['token'] ?? '';
    debugPrint('­ƒöù Token extracted: $token');
    debugPrint('­ƒöù Token length: ${token.length}');
    debugPrint('­ƒöù Token isEmpty: ${token.isEmpty}');
    debugPrint('­ƒöù ============================');

    return ResetPasswordPage(token: token);
  } catch (e) {
    debugPrint('ÔØî Error en reset route builder: $e');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error al procesar el link'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
