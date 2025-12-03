import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Redirect callback para manejar autenticación
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  debugPrint('🔀 ===== REDIRECT CALLBACK =====');
  debugPrint('🔀 state.uri.path: ${state.uri.path}');
  debugPrint('🔀 state.uri: ${state.uri}');
  debugPrint('🔀 state.matchedLocation: ${state.matchedLocation}');

  // Permitir siempre el acceso a /confirm, /reset, /reset-password, /password-reset sin login
  final isPublicRoute =
      state.uri.path == '/confirm' ||
      state.uri.path == '/reset' ||
      state.uri.path == '/reset-password' ||
      state.uri.path == '/password-reset';

  if (isPublicRoute) {
    debugPrint('🔀 Path coincide con ruta pública, permitir acceso');
    return null; // No redirigir, permitir acceso sin login
  }

  // Verificar si hay sesión activa
  final isLoggedIn = await TokenService.isTokenValid();
  debugPrint('🔀 isLoggedIn: $isLoggedIn');

  // Si no está logueado y no está en / o rutas públicas, ir al login
  if (!isLoggedIn && state.uri.path != '/' && !isPublicRoute) {
    debugPrint('🔀 Redirigiendo a login (no logueado y path no permitido)');
    return '/';
  }

  // Si está logueado e intenta ir al login, ir al home
  if (isLoggedIn && state.uri.path == '/') {
    debugPrint('🔀 Redirigiendo a home (logueado en login)');
    return '/home';
  }

  debugPrint('🔀 No redirigir');
  return null; // No redirigir
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: _redirect,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    // Deep link para confirmación de email
    GoRoute(
      path: '/confirm',
      builder: (context, state) {
        // Intentar obtener el token de diferentes parámetros posibles
        final token =
            state.uri.queryParameters['token'] ??
            state.uri.queryParameters['verificacionToken'] ??
            state.uri.queryParameters['verification_token'] ??
            '';
        debugPrint('🔗 Deep Link recibido - token: $token');
        debugPrint('🔗 Query parameters: ${state.uri.queryParameters}');
        return EmailConfirmationPage(
          verificacionToken: token,
          isFromDeepLink: true,
        );
      },
    ),
    // Deep link para resetear contraseña - MÚLTIPLES RUTAS SOPORTADAS
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
    debugPrint('🔗 ===== RESET PASSWORD ROUTE =====');
    debugPrint('🔗 State path: ${state.uri.path}');
    debugPrint('🔗 State uri: ${state.uri}');
    debugPrint('🔗 Full URI string: ${state.uri.toString()}');
    debugPrint('🔗 Query parameters: ${state.uri.queryParameters}');

    final token = state.uri.queryParameters['token'] ?? '';
    debugPrint('🔗 Token extracted: $token');
    debugPrint('🔗 Token length: ${token.length}');
    debugPrint('🔗 Token isEmpty: ${token.isEmpty}');
    debugPrint('🔗 ============================');

    return ResetPasswordPage(token: token);
  } catch (e) {
    debugPrint('❌ Error en reset route builder: $e');
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
