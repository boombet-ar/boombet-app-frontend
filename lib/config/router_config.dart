import 'dart:convert';

import 'package:boombet_app/config/debug_affiliation_previews.dart';
import 'package:boombet_app/models/affiliation_result.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/other/affiliation_results_page.dart';
import 'package:boombet_app/views/pages/admin/admin_tools_page.dart';
import 'package:boombet_app/views/pages/auth/confirm_player_data_page.dart';
import 'package:boombet_app/views/pages/auth/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/community/forum_post_detail_page.dart';
import 'package:boombet_app/views/pages/home/home_page.dart';
import 'package:boombet_app/views/pages/home/limited_home_page.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/other/no_casinos_available_page.dart';
import 'package:boombet_app/views/pages/other/onboarding_page.dart';
import 'package:boombet_app/views/pages/games/play_roulette_page.dart';
import 'package:boombet_app/views/pages/auth/reset_password_page.dart';
import 'package:boombet_app/views/pages/other/unaffiliate_result_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _affiliationFlowRouteKey = 'affiliation_flow_route';
const Duration _isVerifiedTtl = Duration(seconds: 20);
bool? _cachedIsVerified;
DateTime? _cachedIsVerifiedAt;

bool _parseIsVerified(dynamic data) {
  if (data is Map<String, dynamic>) {
    final direct = data['is_verified'] ?? data['isVerified'] ?? data['verified'];
    if (_parseIsVerified(direct)) return true;

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return _parseIsVerified(nested);
    }
  }

  if (data is bool) return data;
  if (data is num) return data == 1;
  if (data is String) {
    final lowered = data.toLowerCase().trim();
    return lowered == 'true' || lowered == '1';
  }

  return false;
}

Future<bool?> _fetchIsVerified() async {
  final now = DateTime.now();
  if (_cachedIsVerifiedAt != null &&
      now.difference(_cachedIsVerifiedAt!) < _isVerifiedTtl) {
    return _cachedIsVerified;
  }

  try {
    final data = await PlayerService().getCurrentUser();
    final parsed = _parseIsVerified(data);
    _cachedIsVerified = parsed;
    _cachedIsVerifiedAt = now;
    return parsed;
  } catch (_) {
    return null;
  }
}

Future<String?> _loadAffiliationFlowRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_affiliationFlowRouteKey);
    return route?.trim().isEmpty == true ? null : route;
  } catch (_) {
    return null;
  }
}

bool _isAffiliationRoute(String path) {
  return path == '/confirm' ||
      path.startsWith('/confirm/') ||
      path == '/limited-home' ||
      path == '/affiliation-results';
}

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

  // Debug-only preview routes: nunca requieren sesión.
  if (kDebugMode && state.uri.path.startsWith('/__debug')) {
    return null;
  }

  // Si no ha visto el onboarding y no está en /onboarding, redirigir allí
  if (!hasSeenOnboarding && state.uri.path != '/onboarding') {
    debugPrint('­ƒöÇ Primera vez - redirigiendo a onboarding');
    return '/onboarding';
  }

  // Permitir siempre el acceso a /confirm, /reset, /reset-password, /password-reset sin login
  final isPublicRoute =
      (!kIsWeb && state.uri.path == '/onboarding') ||
      state.uri.path == '/confirm' ||
      state.uri.path.startsWith('/confirm/') ||
      (kIsWeb && state.uri.path == '/confirm/verify') ||
      state.uri.path == '/reset' ||
      state.uri.path.startsWith('/reset/') ||
      state.uri.path == '/reset-password' ||
      state.uri.path.startsWith('/reset-password/') ||
      state.uri.path == '/password-reset' ||
      state.uri.path.startsWith('/password-reset/') ||
      (kIsWeb && state.uri.path == '/reset-password/change-password') ||
      state.uri.path == '/affiliation-results';

  // Verificar si hay sesi├│n activa
  final isLoggedIn = await TokenService.isTokenValid();
  debugPrint('­ƒöÇ isLoggedIn: $isLoggedIn');

  final path = state.uri.path;

  // Si no est├í logueado y no est├í en / o rutas p├║blicas, ir al login
  if (!isLoggedIn) {
    if (path == '/' || isPublicRoute) {
      debugPrint('­ƒöÇ Path coincide con ruta p├║blica, permitir acceso');
      return null;
    }

    debugPrint('­ƒöÇ Redirigiendo a login (no logueado y path no permitido)');
    return '/';
  }

  final isVerified = await _fetchIsVerified();
  final flowRoute = await _loadAffiliationFlowRoute();

  if (isVerified == true) {
    if (path == '/' || _isAffiliationRoute(path)) {
      debugPrint('­ƒöÇ Redirigiendo a home (verificado)');
      return '/home';
    }
  } else if (isVerified == false) {
    if (path == '/' || path == '/home') {
      debugPrint('­ƒöÇ Redirigiendo a confirm (no verificado)');
      return flowRoute ?? '/confirm';
    }
  } else if (path == '/' && flowRoute != null) {
    return flowRoute;
  }

  if (path == '/admin-tools') {
    final role = await TokenService.getUserRole();
    if (role == null || role.toUpperCase() != 'ADMIN') {
      return '/home';
    }
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
    GoRoute(
      path: '/play-roulette',
      builder: (context, state) => PlayRoulettePage(
        codigoRuleta: state.uri.queryParameters['codigoRuleta'],
      ),
    ),
    GoRoute(
      path: '/limited-home',
      builder: (context, state) =>
          LimitedHomePage(affiliationService: AffiliationService()),
    ),
    GoRoute(
      path: '/admin-tools',
      builder: (context, state) => const AdminToolsPage(),
    ),

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
      path: '/confirm/:token',
      builder: (context, state) {
        final token =
            state.pathParameters['token']?.trim() ??
            state.uri.queryParameters['token'] ??
            state.uri.queryParameters['verificacionToken'] ??
            state.uri.queryParameters['verification_token'] ??
            '';
        debugPrint('📩 Deep Link recibido - token: $token');
        debugPrint('📩 Query parameters: ${state.uri.queryParameters}');
        return EmailConfirmationPage(
          verificacionToken: token,
          isFromDeepLink: true,
        );
      },
    ),
    if (kIsWeb)
      GoRoute(
        path: '/confirm/:token/verify',
        builder: (context, state) {
          final token =
              state.pathParameters['token']?.trim() ??
              state.uri.queryParameters['token'] ??
              state.uri.queryParameters['verificacionToken'] ??
              state.uri.queryParameters['verification_token'] ??
              '';
          debugPrint('📩 Deep Link recibido - token: $token');
          debugPrint('📩 Query parameters: ${state.uri.queryParameters}');
          return EmailConfirmationPage(
            verificacionToken: token,
            isFromDeepLink: true,
          );
        },
      ),
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
    if (kIsWeb)
      GoRoute(
        path: '/confirm/verify',
        redirect: (context, state) => _redirectWithQuery('/confirm', state),
      ),
    // Deep link para resetear contrase├▒a - M├ÜLTIPLES RUTAS SOPORTADAS
    // Soporta: /reset, /reset-password, /password-reset, etc.
    GoRoute(
      path: '/reset',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/reset/:token',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    if (kIsWeb)
      GoRoute(
        path: '/reset-password/change-password',
        redirect: (context, state) =>
            _redirectWithQuery('/reset-password', state),
      ),
    GoRoute(
      path: '/reset-password/:token',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/password-reset',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),
    GoRoute(
      path: '/password-reset/:token',
      builder: (context, state) => _buildResetPasswordPage(context, state),
    ),

    if (kDebugMode) ...[
      GoRoute(
        path: '/__debug',
        builder: (context, state) {
          final items = <({String title, String path})>[
            (
              title: 'Affiliation Results (preview)',
              path: '/__debug/affiliation-results',
            ),
            (
              title: 'Confirm Player Data (preview)',
              path: '/__debug/confirm-player-data',
            ),
            (
              title: 'Email Confirmation (preview)',
              path: '/__debug/email-confirmation',
            ),
            (title: 'Limited Home (preview)', path: '/__debug/limited-home'),
            (
              title: 'No Casinos Available (preview)',
              path: '/__debug/no-casinos',
            ),
            (
              title: 'Reset Password (preview)',
              path: '/__debug/reset-password',
            ),
            (
              title: 'Unaffiliate Result (preview)',
              path: '/__debug/unaffiliate-result',
            ),
          ];

          return Scaffold(
            appBar: AppBar(title: const Text('Debug Previews')),
            body: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.path),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(item.path),
                );
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/__debug/affiliation-results',
        builder: (context, state) {
          final result = DebugAffiliationPreviews.sampleAffiliationResult();
          return AffiliationResultsPage(result: result, preview: true);
        },
      ),
      GoRoute(
        path: '/__debug/confirm-player-data',
        builder: (context, state) {
          final player = DebugAffiliationPreviews.samplePlayerData();
          return ConfirmPlayerDataPage(
            playerData: player,
            email: 'juan.perez@example.com',
            username: 'juanperez',
            password: '********',
            dni: player.dni,
            telefono: player.telefono,
            genero: player.sexo,
            preview: true,
          );
        },
      ),
      GoRoute(
        path: '/__debug/email-confirmation',
        builder: (context, state) {
          final player = DebugAffiliationPreviews.samplePlayerData();
          return EmailConfirmationPage(
            playerData: player,
            email: player.correoElectronico,
            username: player.username,
            password: '********',
            dni: player.dni,
            telefono: player.telefono,
            genero: player.sexo,
            verificacionToken: 'debug-token',
            isFromDeepLink: true,
            preview: true,
          );
        },
      ),
      GoRoute(
        path: '/__debug/limited-home',
        builder: (context, state) {
          return LimitedHomePage(
            affiliationService: AffiliationService(),
            preview: true,
            previewStatusMessage:
                'Afiliación en progreso (preview) — esperando confirmación...',
          );
        },
      ),
      GoRoute(
        path: '/__debug/no-casinos',
        builder: (context, state) =>
            const NoCasinosAvailablePage(preview: true),
      ),
      GoRoute(
        path: '/__debug/reset-password',
        builder: (context, state) {
          return const ResetPasswordPage(token: 'debug-token', preview: true);
        },
      ),
      GoRoute(
        path: '/__debug/unaffiliate-result',
        builder: (context, state) => const UnaffiliateResultPage(preview: true),
      ),
    ],
  ],
);

String _redirectWithQuery(String targetPath, GoRouterState state) {
  final query = state.uri.query;
  if (query.isEmpty) return targetPath;
  return '$targetPath?$query';
}

Widget _buildResetPasswordPage(BuildContext context, GoRouterState state) {
  try {
    debugPrint('­ƒöù ===== RESET PASSWORD ROUTE =====');
    debugPrint('­ƒöù State path: ${state.uri.path}');
    debugPrint('­ƒöù State uri: ${state.uri}');
    debugPrint('­ƒöù Full URI string: ${state.uri.toString()}');
    debugPrint('­ƒöù Query parameters: ${state.uri.queryParameters}');

    final token =
        state.uri.queryParameters['token'] ??
        state.pathParameters['token'] ??
        '';
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
