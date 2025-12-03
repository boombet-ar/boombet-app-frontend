import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Redirect callback para manejar autenticación
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  // Permitir siempre el acceso a /confirm (deep link de confirmación de email)
  if (state.uri.path == '/confirm') {
    return null; // No redirigir, permitir acceso sin login
  }

  // Verificar si hay sesión activa
  final isLoggedIn = await TokenService.isTokenValid();

  // Si no está logueado y no está en / o /confirm, ir al login
  if (!isLoggedIn && state.uri.path != '/' && state.uri.path != '/confirm') {
    return '/';
  }

  // Si está logueado e intenta ir al login, ir al home
  if (isLoggedIn && state.uri.path == '/') {
    return '/home';
  }

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
  ],
);
