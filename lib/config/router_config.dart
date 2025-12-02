import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Redirect callback para manejar autenticación
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  // Permitir siempre el acceso a /confirm (deep link de confirmación)
  if (state.uri.path == '/confirm') {
    return null; // No redirigir
  }

  // Verificar si hay sesión activa
  final isLoggedIn = await TokenService.isTokenValid();

  // Si no está logueado y no está en /confirm, ir al login
  if (!isLoggedIn && state.uri.path != '/') {
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
        final token = state.uri.queryParameters['token'] ?? '';
        return EmailConfirmationPage(
          verificacionToken: token,
          isFromDeepLink: true,
        );
      },
    ),
  ],
);
