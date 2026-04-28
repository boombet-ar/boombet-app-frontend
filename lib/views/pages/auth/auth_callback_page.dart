import 'dart:convert';
import 'dart:developer';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthCallbackPage extends StatefulWidget {
  final String? token;
  final String? redirect;

  const AuthCallbackPage({super.key, this.token, this.redirect});

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    final token = widget.token;
    log('[AuthCallback] redirect param: ${widget.redirect}');

    if (token == null || token.isEmpty) {
      log('[AuthCallback] Token ausente en la URL');
      if (mounted) context.go('/');
      return;
    }

    // Si viene redirect, el token es directamente el JWT — no pasar por direct-login.
    if (widget.redirect != null && widget.redirect!.isNotEmpty) {
      try {
        await TokenService.deleteToken();
        await TokenService.saveToken(token);
        if (!mounted) return;
        context.go('/${widget.redirect}');
      } catch (e) {
        log('[AuthCallback] Excepción guardando token directo: $e');
        if (mounted) context.go('/');
      }
      return;
    }

    try {
      final url = '${ApiConfig.baseUrl}/users/auth/direct-login?token=$token';
      final response = await HttpClient.get(
        url,
        includeAuth: false,
        maxRetries: 1,
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final accessToken =
            (data['accessToken'] as String?) ?? (data['token'] as String?);
        final refreshToken = data['refreshToken'] as String?;

        if (accessToken == null || accessToken.isEmpty) {
          log('[AuthCallback] La respuesta no tiene accessToken');
          if (mounted) context.go('/');
          return;
        }

        await TokenService.deleteToken();
        await TokenService.saveToken(accessToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await TokenService.saveRefreshToken(refreshToken);
        }

        if (!mounted) return;

        final role = await TokenService.getUserRole();
        final roleUpper = role?.trim().toUpperCase();

        if (!mounted) return;

        if (roleUpper == 'AFILIADOR') {
          context.go('/affiliates-tools');
        } else if (roleUpper == 'STAND') {
          context.go('/stand-tools');
        } else {
          context.go(HomePageKeys.home);
        }
      } else {
        log('[AuthCallback] Error del backend: ${response.statusCode} ${response.body}');
        if (mounted) context.go('/');
      }
    } catch (e) {
      log('[AuthCallback] Excepción: $e');
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Center(
        child: CircularProgressIndicator(
          color: AppConstants.primaryGreen,
        ),
      ),
    );
  }
}
