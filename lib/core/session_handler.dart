import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/router_config.dart';
import 'package:boombet_app/services/infra/http_client.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

bool _sessionExpiredDialogOpen = false;

BuildContext? _routerContext() {
  return appRouter.routerDelegate.navigatorKey.currentContext;
}

void registerSessionCallbacks() {
  HttpClient.onUnauthorized = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        appRouter.go('/');
      } catch (e) {}

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

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppConstants.darkAccent,
          title: const Text(
            'Sesión expirada',
            style: TextStyle(color: AppConstants.textDark),
          ),
          content: Text(
            'Tu sesión expiró. Por favor, inicia sesión nuevamente.',
            style: const TextStyle(color: AppConstants.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Forzar vuelta al login incluso si hay rutas apiladas con
                // Navigator.push que bypassean GoRouter.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final nav =
                      appRouter.routerDelegate.navigatorKey.currentState;
                  if (nav == null) {
                    appRouter.go('/');
                    return;
                  }

                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );

                  // Mantener el router sincronizado en '/'.
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
}
