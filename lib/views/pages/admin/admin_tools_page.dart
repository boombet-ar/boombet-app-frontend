import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/admin/affiliates/create_affiliate.dart';
import 'package:boombet_app/views/pages/admin/affiliates/affiliates_management_view.dart';
import 'package:boombet_app/views/pages/admin/ads/ad_management_view.dart';
import 'package:boombet_app/views/pages/admin/raffles/raffles_management_view.dart';
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
    setState(() => _activeSection = section);
    if (section != _AdminSection.home) {
      pageBackCallbacks[10] = () => _setSection(_AdminSection.home);
    } else {
      pageBackCallbacks.remove(10);
    }
    if (section == _AdminSection.affiliators) {
      _loadAffiliators();
    }
  }

  @override
  void dispose() {
    pageBackCallbacks.remove(10);
    super.dispose();
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
        SnackBar(
          content: const Text(
            'No se pudo actualizar el estado del afiliador.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.40)),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAffiliator(AfiliadorModel affiliator) async {
    if (_affiliatorsDeleting.contains(affiliator.id)) return;

    const dialogBg = Color(0xFF1A1A1A);
    const green = AppConstants.primaryGreen;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.30)),
        ),
        title: const Text(
          'Eliminar afiliador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Querés eliminar a ${affiliator.nombre}? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: green),
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
        SnackBar(
          content: const Text(
            'No se pudo eliminar el afiliador.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppConstants.errorRed.withValues(alpha: 0.40)),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0E0E0E);

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

    void showAffiliationsCount(AfiliadorModel afiliador) {
      const dialogBg = Color(0xFF1A1A1A);
      const green = AppConstants.primaryGreen;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          bool isFetching = false;
          int? totalJugadores;
          String? fetchError;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              if (!isFetching && totalJugadores == null && fetchError == null) {
                isFetching = true;
                _afiliadoresService
                    .fetchAfiliadorTotalJugadores(id: afiliador.id)
                    .then((count) {
                  setDialogState(() {
                    totalJugadores = count;
                    isFetching = false;
                  });
                }).catchError((e) {
                  setDialogState(() {
                    fetchError = 'No se pudo obtener la cantidad.';
                    isFetching = false;
                  });
                });
              }

              return Dialog(
                backgroundColor: dialogBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: green.withValues(alpha: 0.20)),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header ────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: green.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: green.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    afiliador.nombre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Afiliador registrado',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.38),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Contenido ─────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: totalJugadores != null
                            ? Column(
                                children: [
                                  Text(
                                    'Total de afiliaciones',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontSize: 12,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: green.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: green.withValues(alpha: 0.18),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$totalJugadores',
                                          style: const TextStyle(
                                            color: green,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          totalJugadores == 1
                                              ? 'jugador afiliado'
                                              : 'jugadores afiliados',
                                          style: TextStyle(
                                            color: green.withValues(alpha: 0.60),
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : fetchError != null
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppConstants.errorRed,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fetchError!,
                                          style: const TextStyle(
                                            color: AppConstants.errorRed,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: green,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                      ),

                      // ── Acción ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              backgroundColor: green.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: green.withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(
                                color: green,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return FutureBuilder<bool>(
      future: TokenService.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            body: const Center(child: CircularProgressIndicator()),
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
              onSelectRaffles: () => _setSection(_AdminSection.raffles),
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
              onViewAffiliationsCount: showAffiliationsCount,
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
  final VoidCallback onSelectRaffles;
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
  final void Function(AfiliadorModel) onViewAffiliationsCount;

  const _AdminSectionBody({
    super.key,
    required this.section,
    required this.onSelectAffiliators,
    required this.onSelectAds,
    required this.onSelectRaffles,
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
    required this.onViewAffiliationsCount,
  });

  @override
  Widget build(BuildContext context) {
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
                  onTap: onSelectAffiliators,
                ),
                const SizedBox(height: 12),
                _AdminPrimaryActionButton(
                  title: 'Publicidades',
                  subtitle: 'Gestión de banners publicitarios',
                  icon: Icons.campaign_outlined,
                  onTap: onSelectAds,
                ),
                const SizedBox(height: 12),
                _AdminPrimaryActionButton(
                  title: 'Sorteos',
                  subtitle: 'Gestión de sorteos y premios',
                  icon: Icons.emoji_events_outlined,
                  onTap: onSelectRaffles,
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
            onViewAffiliations: onViewAffiliationsCount,
          ),
        if (section == _AdminSection.ads) const AdManagementView(),
        if (section == _AdminSection.raffles) const RafflesManagementView(),
      ],
    );
  }
}

enum _AdminSection { home, affiliators, ads, raffles }

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
