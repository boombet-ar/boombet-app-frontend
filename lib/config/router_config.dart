import 'dart:convert';

import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/models/casino_response.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/confirm_player_data_page.dart';
import 'package:boombet_app/views/pages/affiliation_results_page.dart';
import 'package:boombet_app/views/pages/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/forum_post_detail_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/limited_home_page.dart';
import 'package:boombet_app/views/pages/login_page.dart';
import 'package:boombet_app/views/pages/no_casinos_available_page.dart';
import 'package:boombet_app/views/pages/onboarding_page.dart';
import 'package:boombet_app/views/pages/reset_password_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Redirect callback para manejar autenticaci├│n
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  debugPrint('­ƒöÇ ===== REDIRECT CALLBACK =====');
  debugPrint('­ƒöÇ state.uri.path: ${state.uri.path}');
  debugPrint('­ƒöÇ state.uri: ${state.uri}');
  debugPrint('­ƒöÇ state.matchedLocation: ${state.matchedLocation}');

  debugPrint('­ƒöÇ state.extra: ${state.extra}');
  if (state.extra != null) {
    try {
      debugPrint('­ƒöÇ state.extra json: ${jsonEncode(state.extra)}');
    } catch (_) {}
  }

  // Verificar si es la primera vez que abre la app
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = kIsWeb
      ? true
      : (prefs.getBool('hasSeenOnboarding') ?? false);

  // En Web no mostramos onboarding nunca (ni siquiera entrando directo a /onboarding)
  if (kIsWeb && state.uri.path == '/onboarding') {
    return '/';
  }

  // Si no ha visto el onboarding y no está en /onboarding, redirigir allí
  if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
    debugPrint('­ƒöÇ Primera vez - redirigiendo a onboarding');
    return '/onboarding';
  }

  // Permitir siempre el acceso a /confirm, /reset, /reset-password, /password-reset sin login
  final isWebDebug = kIsWeb && kDebugMode;
  const webDebugPaths = <String>{
    '/debug/confirm-player-data',
    '/debug/email-confirmation',
    '/debug/no-casinos',
    '/debug/limited-home',
    '/debug/affiliation-results',
  };
  final isWebDebugRoute = isWebDebug && webDebugPaths.contains(state.uri.path);

  final isPublicRoute =
      (!kIsWeb && state.uri.path == '/onboarding') ||
      state.uri.path == '/confirm' ||
      state.uri.path == '/reset' ||
      state.uri.path == '/reset-password' ||
      state.uri.path == '/password-reset' ||
      state.uri.path == '/affiliation-results' ||
      isWebDebugRoute;

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
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingPage(
        onComplete: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenOnboarding', true);
          if (context.mounted) {
            context.go('/');
          }
        },
      ),
    ),
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),

    // Deeplink: detalle de publicación del foro
    // Ejemplos soportados desde DeepLinkService:
    // - boombet://publicaciones/123
    // - boombet://foro/publicacion?id=123
    // - boombet://forum/post?postId=123
    GoRoute(
      path: '/forum/post/:id',
      builder: (context, state) {
        final rawId = state.pathParameters['id'] ?? '';
        final id = int.tryParse(rawId);
        if (id == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Foro')),
            body: const Center(child: Text('Publicación inválida')),
          );
        }
        final refresh = state.uri.queryParameters['refresh'] == '1';
        return ForumPostDetailPage(postId: id, forceRefresh: refresh);
      },
    ),
    GoRoute(
      path: '/affiliation-results',
      builder: (context, state) {
        final result = state.extra is AffiliationResult
            ? state.extra as AffiliationResult
            : null;
        debugPrint(
          '­ƒöù /affiliation-results builder result is null? ${result == null}',
        );
        if (result != null) {
          try {
            debugPrint(
              '­ƒöù /affiliation-results result: ${jsonEncode(result)}',
            );
          } catch (_) {
            debugPrint(
              '­ƒöù /affiliation-results result could not be jsonEncoded',
            );
          }
        }
        return AffiliationResultsPage(result: result);
      },
    ),
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

    if (kIsWeb && kDebugMode) ...[
      GoRoute(
        path: '/debug/confirm-player-data',
        builder: (context, state) {
          final player = PlayerData(
            nombre: 'Juan',
            apellido: 'Pérez',
            cuil: '20-12345678-9',
            dni: '12345678',
            sexo: 'M',
            estadoCivil: 'Soltero/a',
            telefono: '1133334444',
            correoElectronico: 'debug@boombet.test',
            direccionCompleta: 'Calle Falsa 123',
            calle: 'Calle Falsa',
            numCalle: '123',
            localidad: 'CABA',
            provincia: 'Buenos Aires',
            fechaNacimiento: '01-01-1990',
            anioNacimiento: '1990',
            username: 'debug_user',
          );

          return ConfirmPlayerDataPage(
            playerData: player,
            email: 'debug@boombet.test',
            username: 'debug_user',
            password: 'debug_password',
            dni: '12345678',
            telefono: '1133334444',
            genero: 'M',
          );
        },
      ),
      GoRoute(
        path: '/debug/email-confirmation',
        builder: (context, state) {
          final player = PlayerData(
            nombre: 'Juan',
            apellido: 'Pérez',
            cuil: '20-12345678-9',
            dni: '12345678',
            sexo: 'M',
            estadoCivil: 'Soltero/a',
            telefono: '1133334444',
            correoElectronico: 'debug@boombet.test',
            direccionCompleta: 'Calle Falsa 123',
            calle: 'Calle Falsa',
            numCalle: '123',
            localidad: 'CABA',
            provincia: 'Buenos Aires',
            fechaNacimiento: '01-01-1990',
            anioNacimiento: '1990',
            username: 'debug_user',
          );

          return EmailConfirmationPage(
            playerData: player,
            email: 'debug@boombet.test',
            username: 'debug_user',
            password: 'debug_password',
            dni: '12345678',
            telefono: '1133334444',
            genero: 'M',
            verificacionToken: 'debug',
            isFromDeepLink: false,
          );
        },
      ),
      GoRoute(
        path: '/debug/no-casinos',
        builder: (context, state) => const NoCasinosAvailablePage(),
      ),
      GoRoute(
        path: '/debug/limited-home',
        builder: (context, state) {
          return LimitedHomePage(affiliationService: AffiliationService());
        },
      ),
      GoRoute(
        path: '/debug/affiliation-results',
        builder: (context, state) {
          final result = AffiliationResult(
            playerData: const {
              'username': 'debug_user',
              'email': 'debug@boombet.test',
            },
            responses: {
              'Casino A': CasinoResponse(message: 'OK', success: true),
              'Casino B': CasinoResponse(
                message: 'Jugador previamente afiliado',
                success: false,
              ),
              'Casino C': CasinoResponse(
                message: 'Error',
                success: false,
                error: 'Sin conexión',
              ),
            },
          );
          return AffiliationResultsPage(result: result);
        },
      ),
    ],
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
