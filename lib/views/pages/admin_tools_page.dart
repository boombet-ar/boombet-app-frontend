import 'dart:developer';

import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/services/afiliadores_service.dart';
import 'package:boombet_app/services/password_validation_service.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/section_header_widget.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightBg;

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
      final nameController = TextEditingController();
      final emailController = TextEditingController();
      final dniController = TextEditingController();
      final phoneController = TextEditingController();
      final messenger = ScaffoldMessenger.of(context);

      try {
        bool isSubmitting = false;

        await showDialog<void>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                Future<void> handleSubmit() async {
                  if (isSubmitting) return;

                  final nombre = nameController.text.trim();
                  final email = emailController.text.trim();
                  final dni = dniController.text.trim();
                  final telefono = phoneController.text.trim();

                  void showValidationDialog(String title, String message) {
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;
                    final dialogBg = isDark
                        ? AppConstants.darkAccent
                        : AppConstants.lightDialogBg;
                    final textColor = isDark
                        ? AppConstants.textDark
                        : AppConstants.lightLabelText;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: dialogBg,
                        title: Text(title, style: TextStyle(color: textColor)),
                        content: Text(
                          message,
                          style: TextStyle(color: textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Entendido',
                              style: TextStyle(
                                color: AppConstants.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (nombre.isEmpty ||
                      email.isEmpty ||
                      dni.isEmpty ||
                      telefono.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Completa todos los campos.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  if (!PasswordValidationService.isEmailValid(email)) {
                    showValidationDialog(
                      'Email inválido',
                      PasswordValidationService.getEmailValidationMessage(
                        email,
                      ),
                    );
                    return;
                  }

                  if (!PasswordValidationService.isPhoneValid(telefono)) {
                    showValidationDialog(
                      'Teléfono inválido',
                      PasswordValidationService.getPhoneValidationMessage(
                        telefono,
                      ),
                    );
                    return;
                  }

                  if (!PasswordValidationService.isDniValid(dni)) {
                    showValidationDialog(
                      'DNI inválido',
                      PasswordValidationService.getDniValidationMessage(dni),
                    );
                    return;
                  }

                  try {
                    setState(() {
                      isSubmitting = true;
                    });

                    await _afiliadoresService.createAfiliador(
                      nombre: nombre,
                      email: email,
                      dni: dni,
                      telefono: telefono,
                    );

                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.pop(context);
                    }
                    _loadAffiliators(force: true);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Afiliador creado correctamente.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      setState(() {
                        isSubmitting = false;
                      });
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo crear el afiliador.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }

                return _buildPopupDialog(
                  context: context,
                  title: 'Crear afiliador',
                  subtitle: 'Completa los datos del nuevo afiliador.',
                  icon: Icons.person_add_alt_1,
                  actionLabel: isSubmitting ? 'Guardando...' : 'Guardar',
                  isSubmitting: isSubmitting,
                  onSubmit: handleSubmit,
                  fields: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        hintText: 'Ej: Juan Pérez',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'afiliador@boombet.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dniController,
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        hintText: '12345678',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: '+54 9 11 1234-5678',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                );
              },
            );
          },
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el formulario.'),
            duration: Duration(seconds: 2),
          ),
        );
      } finally {
        Future.delayed(const Duration(milliseconds: 200), () {
          nameController.dispose();
          emailController.dispose();
          dniController.dispose();
          phoneController.dispose();
        });
      }
    }

    Future<void> showEventForm() async {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return _buildPopupDialog(
            context: context,
            title: 'Crear evento',
            subtitle: 'Configura los datos del nuevo evento (mock).',
            icon: Icons.event_available,
            actionLabel: 'Crear (mock)',
            fields: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Evento BoomBet',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  hintText: '26/01/2026',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cupo',
                  hintText: '150',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalle breve del evento',
                ),
                maxLines: 3,
              ),
            ],
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
              showThemeToggle: true,
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
              showThemeToggle: true,
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
            showThemeToggle: true,
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
              onSelectEvents: () => _setSection(_AdminSection.events),
              onBack: () => _setSection(_AdminSection.home),
              onCreateAffiliator: showAffiliatorForm,
              onCreateEvent: showEventForm,
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

  Widget _buildPopupDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required List<Widget> fields,
    VoidCallback? onSubmit,
    bool isSubmitting = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppConstants.textDark : AppConstants.textLight;
    final accent = theme.colorScheme.primary;
    final dialogBg = isDark
        ? AppConstants.darkAccent
        : AppConstants.lightDialogBg;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 6),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.25),
                    accent.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadius + 6),
                  topRight: Radius.circular(AppConstants.borderRadius + 6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: fields),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : (onSubmit ?? () => Navigator.pop(context)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: AppConstants.textLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppConstants.textLight,
                              ),
                            )
                          : Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionBody extends StatelessWidget {
  final _AdminSection section;
  final VoidCallback onSelectAffiliators;
  final VoidCallback onSelectEvents;
  final VoidCallback onBack;
  final VoidCallback onCreateAffiliator;
  final VoidCallback onCreateEvent;
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
    required this.onSelectEvents,
    required this.onBack,
    required this.onCreateAffiliator,
    required this.onCreateEvent,
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
                // _AdminPrimaryActionButton(
                //   title: 'Eventos',
                //   subtitle: 'Eventos y sorteos (mock)',
                //   icon: Icons.event_available,
                //   accentColor: const Color(0xFF4FC3F7),
                //   onTap: onSelectEvents,
                // ),
                // const SizedBox(height: 18),
                // _AdminMockCard(
                //   title: 'Usuarios activos',
                //   value: '1.245',
                //   icon: Icons.people_alt_outlined,
                //   accentColor: theme.colorScheme.primary,
                // ),
                // const SizedBox(height: 12),
                // _AdminMockCard(
                //   title: 'Registros del día',
                //   value: '58',
                //   icon: Icons.person_add_alt_1,
                //   accentColor: const Color(0xFF4FC3F7),
                // ),
                // const SizedBox(height: 12),
                // _AdminMockCard(
                //   title: 'Beneficios canjeados',
                //   value: '312',
                //   icon: Icons.local_offer_outlined,
                //   accentColor: const Color(0xFFFFB74D),
                // ),
                // const SizedBox(height: 12),
                // _AdminMockCard(
                //   title: 'Última sincronización',
                //   value: 'Hace 3 min',
                //   icon: Icons.sync,
                //   accentColor: const Color(0xFF81C784),
                // ),
              ],
            ),
          ),
        ],
        if (section == _AdminSection.affiliators)
          _AdminAffiliatorsSection(
            onBack: onBack,
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
        if (section == _AdminSection.events)
          _AdminEventsSection(onBack: onBack, onCreate: onCreateEvent),
      ],
    );
  }
}

enum _AdminSection { home, affiliators, events }

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
    final isDark = theme.brightness == Brightness.dark;

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
          color: isDark
              ? AppConstants.darkAccent
              : AppConstants.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.2 : 0.25),
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

class _AdminAffiliatorsSection extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCreate;
  final List<AfiliadorModel> items;
  final bool isLoading;
  final String? errorMessage;
  final int totalElements;
  final int page;
  final int totalPages;
  final int pageSize;
  final bool isFirstPage;
  final bool isLastPage;
  final Set<int> updatingIds;
  final Set<int> deletingIds;
  final VoidCallback onRetry;
  final ValueChanged<int> onGoToPage;
  final void Function(AfiliadorModel, bool) onToggleActive;
  final void Function(AfiliadorModel) onDelete;

  const _AdminAffiliatorsSection({
    required this.onBack,
    required this.onCreate,
    required this.items,
    required this.isLoading,
    required this.errorMessage,
    required this.totalElements,
    required this.page,
    required this.totalPages,
    required this.pageSize,
    required this.isFirstPage,
    required this.isLastPage,
    required this.updatingIds,
    required this.deletingIds,
    required this.onRetry,
    required this.onGoToPage,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listItems = items
        .map(
          (item) => _AdminListItemData(
            title: item.nombre,
            subtitle:
                'Código: ${item.tokenAfiliador} • Afiliaciones: ${item.cantAfiliaciones}',
            trailing: item.activo ? 'Activo' : 'Inactivo',
          ),
        )
        .toList();

    final lastIndex = totalPages > 0 ? totalPages - 1 : page;
    final canGoBack = page > 0 && !isFirstPage;
    final canGoForward = totalPages > 0 ? page < lastIndex : !isLastPage;

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Afiliadores',
          subtitle: 'Listado de afiliadores registrados.',
          icon: Icons.group_outlined,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _AdminCreateButton(
                label: 'Crear afiliador',
                icon: Icons.person_add_alt_1,
                onTap: onCreate,
              ),
              const SizedBox(height: 16),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                )
              else if (errorMessage != null)
                _AdminAffiliatorsError(message: errorMessage!, onRetry: onRetry)
              else if (listItems.isEmpty)
                _AdminAffiliatorsEmpty(onRetry: onRetry)
              else ...[
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final afiliador = entry.value;
                  final item = listItems[index];
                  final isUpdating = updatingIds.contains(afiliador.id);
                  final isDeleting = deletingIds.contains(afiliador.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AdminListTile(
                      item: item,
                      accentColor: theme.colorScheme.primary,
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              afiliador.activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: afiliador.activo,
                            onChanged: isUpdating || isDeleting
                                ? null
                                : (value) => onToggleActive(afiliador, value),
                            activeColor: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Eliminar afiliador',
                            onPressed: isDeleting || isUpdating
                                ? null
                                : () => onDelete(afiliador),
                            icon: isDeleting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppConstants.errorRed,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,
                                    color: AppConstants.errorRed,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppConstants.darkAccent
                        : AppConstants.lightSurfaceVariant,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadius,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mostrando $totalElements afiliadores · Página ${page + 1}${totalPages > 0 ? " de $totalPages" : ""}${pageSize > 0 ? " · $pageSize por página" : ""}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalPages > 1 || (!isLastPage && totalElements > 0)) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : AppConstants.lightAccent,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Center(
                      child: PaginationBar(
                        currentPage: page + 1,
                        canGoPrevious: canGoBack,
                        canGoNext: canGoForward,
                        onPrev: () => onGoToPage(page - 1),
                        onNext: () => onGoToPage(page + 1),
                        primaryColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminEventsSection extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCreate;

  const _AdminEventsSection({required this.onBack, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final items = const [
      _AdminListItemData(
        title: 'Sorteo BoomBet Enero',
        subtitle: 'Fecha: 30/01/2026 • Cupo: 200',
        trailing: 'Programado',
      ),
      _AdminListItemData(
        title: 'Evento VIP Córdoba',
        subtitle: 'Fecha: 05/02/2026 • Cupo: 80',
        trailing: 'En revisión',
      ),
      _AdminListItemData(
        title: 'Promo Verano',
        subtitle: 'Fecha: 12/02/2026 • Cupo: 500',
        trailing: 'Activo',
      ),
    ];

    return Column(
      children: [
        SectionHeaderWidget(
          title: 'Eventos',
          subtitle: 'Listado de eventos y sorteos (mock).',
          icon: Icons.event_available,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            children: [
              _AdminCreateButton(
                label: 'Crear evento',
                icon: Icons.event_available,
                onTap: onCreate,
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AdminListTile(
                    item: item,
                    accentColor: const Color(0xFF4FC3F7),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppConstants.darkAccent
                      : AppConstants.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mostrando 3 eventos mockeados.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminCreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminCreateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppConstants.darkAccent
              : AppConstants.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _AdminAffiliatorsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminAffiliatorsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No se pudieron cargar los afiliadores.',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAffiliatorsEmpty extends StatelessWidget {
  final VoidCallback onRetry;

  const _AdminAffiliatorsEmpty({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay afiliadores para mostrar.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Refrescar')),
        ],
      ),
    );
  }
}

class _AdminListItemData {
  final String title;
  final String subtitle;
  final String trailing;

  const _AdminListItemData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}

class _AdminListTile extends StatelessWidget {
  final _AdminListItemData item;
  final Color accentColor;
  final Widget? trailingWidget;

  const _AdminListTile({
    required this.item,
    required this.accentColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_shared, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailingWidget ??
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.trailing,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _AdminMockCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _AdminMockCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppConstants.darkAccent
            : AppConstants.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
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
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppConstants.darkAccent
              : AppConstants.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
