import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
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

    try {
      await TokenService.deleteToken();
      await TokenService.saveToken(token);
      if (!mounted) return;

      if (widget.redirect != null && widget.redirect!.isNotEmpty) {
        context.go('/${widget.redirect}');
        return;
      }

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
    } catch (e) {
      log('[AuthCallback] Excepción guardando token: $e');
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
