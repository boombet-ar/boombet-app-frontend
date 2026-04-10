import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminToolsPage extends StatelessWidget {
  const AdminToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0E0E0E);

    return FutureBuilder<bool>(
      future: TokenService.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: scaffoldBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAdmin) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConstants.errorRed.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.errorRed.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.gpp_bad_outlined,
                        color: AppConstants.errorRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso restringido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solo administradores pueden acceder a esta sección.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _AdminPrimaryActionButton(
                title: 'Afiliadores',
                subtitle: 'Gestión de afiliadores',
                icon: Icons.group_outlined,
                onTap: () => context.push('/admin/affiliates'),
              ),
              const SizedBox(height: 12),
              _AdminPrimaryActionButton(
                title: 'Publicidades',
                subtitle: 'Gestión de banners publicitarios',
                icon: Icons.campaign_outlined,
                onTap: () => context.push('/admin/ads'),
              ),
              if (AppConstants.showAdminRaffles) ...[
                const SizedBox(height: 12),
                _AdminPrimaryActionButton(
                  title: 'Sorteos',
                  subtitle: 'Gestión de sorteos y premios',
                  icon: Icons.emoji_events_outlined,
                  onTap: () => context.push('/admin/raffles'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdminPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = AppConstants.primaryGreen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        splashColor: green.withValues(alpha: 0.08),
        highlightColor: green.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: green.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: green.withValues(alpha: 0.20)),
                ),
                child: Icon(icon, color: green, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: green.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
