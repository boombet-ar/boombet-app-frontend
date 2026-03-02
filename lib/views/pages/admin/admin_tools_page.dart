import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/admin/affiliates/create_affiliate.dart';
import 'package:boombet_app/views/pages/admin/affiliates/affiliates_managemente_view.dart';
import 'package:boombet_app/views/pages/admin/ads/ad_management_view.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  _AdminSection _activeSection = _AdminSection.home;
  final AfiliadoresService _afiliadoresService = AfiliadoresService();
  bool _isLoadingAffiliators = false;
  String? _affiliatorsError;
  List<AfiliadorModel> _affiliators = [];
  int _affiliatorsPage = 0;
  int _affiliatorsTotalPages = 0;
  int _affiliatorsTotalElements = 0;
  int _affiliatorsPageSize = 10;
  bool _affiliatorsFirst = true;
  bool _affiliatorsLast = true;
  bool _affiliatorsLoaded = false;
  final Set<int> _affiliatorsUpdating = {};
  final Set<int> _affiliatorsDeleting = {};

  void _setSection(_AdminSection section) {
    setState(() {
      _activeSection = section;
    });

    if (section == _AdminSection.affiliators) {
      _loadAffiliators();
    }
  }

  Future<void> _loadAffiliators({int page = 0, bool force = false}) async {
    if (_isLoadingAffiliators) return;
    if (_affiliatorsLoaded && !force && page == _affiliatorsPage) return;

    setState(() {
      _isLoadingAffiliators = true;
      _affiliatorsError = null;
    });

    try {
      final pageData = await _afiliadoresService.fetchAfiliadores(
        page: page,
        size: 10,
      );

      if (!mounted) return;
      setState(() {
        _affiliators = pageData.content;
        _affiliatorsPage = pageData.number;
        _affiliatorsTotalPages = pageData.totalPages;
        _affiliatorsTotalElements = pageData.totalElements;
        _affiliatorsPageSize = pageData.size;
        _affiliatorsFirst = pageData.first;
        _affiliatorsLast = pageData.last;
        _affiliatorsLoaded = true;
        _isLoadingAffiliators = false;
      });
    } catch (e, stack) {
      log('[AdminTools][Affiliators] load error: $e', stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _affiliatorsError = 'Error al cargar afiliadores: $e';
        _isLoadingAffiliators = false;
      });
    }
  }

  void _replaceAffiliatorInList(AfiliadorModel updated) {
    _affiliators = _affiliators
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
  }

  Future<void> _toggleAffiliatorActive(
    AfiliadorModel affiliator,
    bool isActive,
  ) async {
    if (_affiliatorsUpdating.contains(affiliator.id)) return;

    setState(() {
      _affiliatorsUpdating.add(affiliator.id);
      _replaceAffiliatorInList(
        AfiliadorModel(
          id: affiliator.id,
          nombre: affiliator.nombre,
          tokenAfiliador: affiliator.tokenAfiliador,
          tipoAfiliador: affiliator.tipoAfiliador,
          cantAfiliaciones: affiliator.cantAfiliaciones,
          activo: isActive,
          email: affiliator.email,
          dni: affiliator.dni,
          telefono: affiliator.telefono,
        ),
      );
    });

    try {
      final updated = await _afiliadoresService.toggleAfiliadorActivo(
        id: affiliator.id,
      );
      if (!mounted) return;
      setState(() {
        _replaceAffiliatorInList(updated);
        _affiliatorsUpdating.remove(affiliator.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _replaceAffiliatorInList(affiliator);
        _affiliatorsUpdating.remove(affiliator.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado del afiliador.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAffiliator(AfiliadorModel affiliator) async {
    if (_affiliatorsDeleting.contains(affiliator.id)) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;
    final textColor = isDark
        ? AppConstants.textDark
        : AppConstants.lightLabelText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('Eliminar afiliador', style: TextStyle(color: textColor)),
        content: Text(
          '¿Querés eliminar a ${affiliator.nombre}? Esta acción no se puede deshacer.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppConstants.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _affiliatorsDeleting.add(affiliator.id);
    });

    try {
      await _afiliadoresService.deleteAfiliador(id: affiliator.id);
      if (!mounted) return;

      final willBeEmpty = _affiliators.length <= 1;
      final shouldLoadPrev = willBeEmpty && _affiliatorsPage > 0;

      setState(() {
        _affiliators = _affiliators
            .where((item) => item.id != affiliator.id)
            .toList();
        if (_affiliatorsTotalElements > 0) {
          _affiliatorsTotalElements -= 1;
        }
        _affiliatorsDeleting.remove(affiliator.id);
      });

      if (shouldLoadPrev) {
        _loadAffiliators(page: _affiliatorsPage - 1, force: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _affiliatorsDeleting.remove(affiliator.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el afiliador.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = AppConstants.textDark;
    final bgColor = AppConstants.darkBg;

    void handleAppBarBack() {
      if (_activeSection != _AdminSection.home) {
        _setSection(_AdminSection.home);
        return;
      }
      if (context.mounted) {
        context.go('/home');
      }
    }

    void handleGoToAffiliatorsPage(int targetPage) {
      if (targetPage < 0) return;
      final lastIndex = _affiliatorsTotalPages > 0
          ? _affiliatorsTotalPages - 1
          : null;
      if (lastIndex != null && targetPage > lastIndex) return;
      _loadAffiliators(page: targetPage);
    }

    Future<void> showAffiliatorForm() async {
      await showCreateAffiliateDialog(
        context: context,
        service: _afiliadoresService,
        onCreated: () => _loadAffiliators(force: true),
      );
    }

    return FutureBuilder<bool>(
      future: TokenService.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: const MainAppBar(
              title: 'Herramientas Admin',
              showBackButton: true,
              showLogo: true,
              showSettings: false,
              showProfileButton: false,
              showLogoutButton: false,
              showFaqButton: false,
              showExitButton: false,
              showAdminTools: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAdmin) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: MainAppBar(
              title: 'Herramientas Admin',
              showBackButton: true,
              onBackPressed: handleAppBarBack,
              showLogo: true,
              showSettings: false,
              showProfileButton: false,
              showLogoutButton: false,
              showFaqButton: false,
              showExitButton: false,
              showAdminTools: false,
            ),
            body: Center(
              child: Text(
                'Acceso restringido. Solo administradores.',
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: MainAppBar(
            title: 'Herramientas Admin',
            showBackButton: true,
            onBackPressed: handleAppBarBack,
            showLogo: true,
            showSettings: false,
            showProfileButton: false,
            showLogoutButton: false,
            showFaqButton: false,
            showExitButton: false,
            showAdminTools: false,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOut));

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(offsetTween),
                  child: child,
                ),
              );
            },
            child: _AdminSectionBody(
              key: ValueKey(_activeSection),
              section: _activeSection,
              onSelectAffiliators: () => _setSection(_AdminSection.affiliators),
              onSelectAds: () => _setSection(_AdminSection.ads),
              onBack: () => _setSection(_AdminSection.home),
              onCreateAffiliator: showAffiliatorForm,
              affiliators: _affiliators,
              affiliatorsLoading: _isLoadingAffiliators,
              affiliatorsError: _affiliatorsError,
              affiliatorsTotalElements: _affiliatorsTotalElements,
              affiliatorsPage: _affiliatorsPage,
              affiliatorsTotalPages: _affiliatorsTotalPages,
              affiliatorsPageSize: _affiliatorsPageSize,
              affiliatorsFirst: _affiliatorsFirst,
              affiliatorsLast: _affiliatorsLast,
              affiliatorsUpdatingIds: _affiliatorsUpdating,
              affiliatorsDeletingIds: _affiliatorsDeleting,
              onReloadAffiliators: () => _loadAffiliators(force: true),
              onGoToAffiliatorsPage: handleGoToAffiliatorsPage,
              onToggleAffiliatorActive: _toggleAffiliatorActive,
              onDeleteAffiliator: _deleteAffiliator,
            ),
          ),
        );
      },
    );
  }
}

class _AdminSectionBody extends StatelessWidget {
  final _AdminSection section;
  final VoidCallback onSelectAffiliators;
  final VoidCallback onSelectAds;
  final VoidCallback onBack;
  final VoidCallback onCreateAffiliator;
  final List<AfiliadorModel> affiliators;
  final bool affiliatorsLoading;
  final String? affiliatorsError;
  final int affiliatorsTotalElements;
  final int affiliatorsPage;
  final int affiliatorsTotalPages;
  final int affiliatorsPageSize;
  final bool affiliatorsFirst;
  final bool affiliatorsLast;
  final Set<int> affiliatorsUpdatingIds;
  final Set<int> affiliatorsDeletingIds;
  final VoidCallback onReloadAffiliators;
  final ValueChanged<int> onGoToAffiliatorsPage;
  final void Function(AfiliadorModel, bool) onToggleAffiliatorActive;
  final void Function(AfiliadorModel) onDeleteAffiliator;

  const _AdminSectionBody({
    super.key,
    required this.section,
    required this.onSelectAffiliators,
    required this.onSelectAds,
    required this.onBack,
    required this.onCreateAffiliator,
    required this.affiliators,
    required this.affiliatorsLoading,
    required this.affiliatorsError,
    required this.affiliatorsTotalElements,
    required this.affiliatorsPage,
    required this.affiliatorsTotalPages,
    required this.affiliatorsPageSize,
    required this.affiliatorsFirst,
    required this.affiliatorsLast,
    required this.affiliatorsUpdatingIds,
    required this.affiliatorsDeletingIds,
    required this.onReloadAffiliators,
    required this.onGoToAffiliatorsPage,
    required this.onToggleAffiliatorActive,
    required this.onDeleteAffiliator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (section == _AdminSection.home) ...[
          SectionHeaderWidget(
            title: 'Panel de control',
            subtitle: 'Acceso rápido a herramientas internas.',
            icon: Icons.admin_panel_settings_outlined,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              children: [
                _AdminPrimaryActionButton(
                  title: 'Afiliadores',
                  subtitle: 'Gestión de afiliadores',
                  icon: Icons.group_outlined,
                  accentColor: theme.colorScheme.primary,
                  onTap: onSelectAffiliators,
                ),
                const SizedBox(height: 12),
                _AdminPrimaryActionButton(
                  title: 'Publicidades',
                  subtitle: 'Gestión de banners publicitarios',
                  icon: Icons.campaign_outlined,
                  accentColor: theme.colorScheme.primary,
                  onTap: onSelectAds,
                ),
              ],
            ),
          ),
        ],
        if (section == _AdminSection.affiliators)
          AffiliatesManagementeView(
            onCreate: onCreateAffiliator,
            items: affiliators,
            isLoading: affiliatorsLoading,
            errorMessage: affiliatorsError,
            totalElements: affiliatorsTotalElements,
            page: affiliatorsPage,
            totalPages: affiliatorsTotalPages,
            pageSize: affiliatorsPageSize,
            isFirstPage: affiliatorsFirst,
            isLastPage: affiliatorsLast,
            updatingIds: affiliatorsUpdatingIds,
            deletingIds: affiliatorsDeletingIds,
            onRetry: onReloadAffiliators,
            onGoToPage: onGoToAffiliatorsPage,
            onToggleActive: onToggleAffiliatorActive,
            onDelete: onDeleteAffiliator,
          ),
        if (section == _AdminSection.ads) const AdManagementView(),
      ],
    );
  }
}

enum _AdminSection { home, affiliators, ads }

class _AdminPrimaryActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _AdminPrimaryActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              accentColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: AppConstants.darkAccent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
