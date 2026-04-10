import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:boombet_app/widgets/tutorial_overlay.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<void> _subscribeToTopics() async {
  if (kIsWeb) return;
  await FirebaseMessaging.instance.subscribeToTopic('all');
}

class _HomePageState extends State<HomePage> {
  bool get _hideCasinosOnMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    pendingLoginTutorialNotifier.value = false;
    rouletteTriggerAfterTutorialNotifier.value = true;
    _subscribeToTopics();
    juegosNavbarTutorialNotifier.addListener(_onJuegosNavbarTrigger);
    sorteosNavbarTutorialNotifier.addListener(_onSorteosNavbarTrigger);
    navbarScrolledToEndNotifier.addListener(_onNavbarScrolledToEnd);
    foroNavbarTutorialNotifier.addListener(_onForoNavbarTrigger);
    ajustesNavbarTutorialNotifier.addListener(_onAjustesNavbarTrigger);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstLogin());
  }

  @override
  void dispose() {
    juegosNavbarTutorialNotifier.removeListener(_onJuegosNavbarTrigger);
    sorteosNavbarTutorialNotifier.removeListener(_onSorteosNavbarTrigger);
    navbarScrolledToEndNotifier.removeListener(_onNavbarScrolledToEnd);
    foroNavbarTutorialNotifier.removeListener(_onForoNavbarTrigger);
    ajustesNavbarTutorialNotifier.removeListener(_onAjustesNavbarTrigger);
    super.dispose();
  }

  void _onNavbarScrolledToEnd() {
    if (navbarScrolledToEndNotifier.value && mounted) {
      navbarSwipeTutorialNotifier.value = false;
      navbarScrolledToEndNotifier.value = false;
      _launchPremiosNavbarTutorial();
    }
  }

  void _onForoNavbarTrigger() {
    if (foroNavbarTutorialNotifier.value && mounted) {
      foroNavbarTutorialNotifier.value = false;
      _launchForoNavbarTutorial();
    }
  }

  void _onAjustesNavbarTrigger() {
    if (ajustesNavbarTutorialNotifier.value && mounted) {
      ajustesNavbarTutorialNotifier.value = false;
      _launchAjustesNavbarTutorial();
    }
  }

  void _launchPremiosNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: 'premios_navbar',
            keyTarget: HomePageKeys.premiosNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premios',
                  description: '¡Vamos a ver la sección de premios!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'premios_navbar' && mounted) {
            context.go(HomePageKeys.prizes);
            premiosTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  void _launchForoNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: 'foro_navbar',
            keyTarget: HomePageKeys.foroNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.forum_rounded,
                  title: 'Foro',
                  description: '¡Vamos a ver el foro de BoomBet!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'foro_navbar' && mounted) {
            context.go(HomePageKeys.forum);
            foroTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  void _launchAjustesNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: 'ajustes_navbar',
            keyTarget: HomePageKeys.ajustesNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.settings_rounded,
                  title: 'Ajustes',
                  description: '¡Vamos a ver los ajustes de la app!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'ajustes_navbar' && mounted) {
            context.go(HomePageKeys.settings);
            ajustesTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  void _onJuegosNavbarTrigger() {
    if (juegosNavbarTutorialNotifier.value && mounted) {
      juegosNavbarTutorialNotifier.value = false;
      _launchJuegosNavbarTutorial();
    }
  }

  void _onSorteosNavbarTrigger() {
    if (sorteosNavbarTutorialNotifier.value && mounted) {
      sorteosNavbarTutorialNotifier.value = false;
      _launchSorteosNavbarTutorial();
    }
  }

  Future<void> _checkFirstLogin() async {
    if (AppConstants.forceTutorial) {
      if (mounted) loginTutorialActiveNotifier.value = true;
      return;
    }
    try {
      final isFirst = await PlayerService().getCurrentUserIsFirstLogin();
      if (isFirst == true && mounted) {
        loginTutorialActiveNotifier.value = true;
      }
    } catch (_) {}
  }

  void _launchJuegosNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: 'juegos_navbar',
            keyTarget: HomePageKeys.juegosNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.videogame_asset_rounded,
                  title: 'Juegos',
                  description: '¡Vamos a ver los juegos oficiales de BoomBet!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'juegos_navbar' && mounted) {
            context.go(HomePageKeys.games);
            gamesTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  void _launchSorteosNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: 'sorteos_navbar',
            keyTarget: HomePageKeys.sorteosNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Sorteos',
                  description: '¡Continuemos con los sorteos!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'sorteos_navbar' && mounted) {
            context.go(HomePageKeys.raffles);
            sorteosTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  void _launchNavbarTutorial() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      TutorialCoachMark(
        targets: [
          // Paso 1 — Club
          TargetFocus(
            identify: 'club_navbar',
            keyTarget: HomePageKeys.inicioNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: false,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.groups_rounded,
                  title: 'Club',
                  description:
                      'Esta es la página principal. Acá vas a poder enterarte de los últimos eventos y promociones de BoomBet, y de los casinos a los que estás afiliado.',
                  onContinue: controller.next,
                ),
              ),
            ],
          ),
          // Paso 2 — Descuentos (el usuario toca el botón para avanzar)
          TargetFocus(
            identify: 'descuentos_navbar',
            keyTarget: HomePageKeys.descuentosNavbarKey,
            shape: ShapeLightFocus.RRect,
            radius: 14,
            enableOverlayTab: false,
            enableTargetTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                builder: (ctx, controller) => TutorialStepCard(
                  icon: Icons.local_offer_rounded,
                  title: 'Descuentos',
                  description:
                      '¡Vamos a cambiar a la vista de descuentos!',
                  hint: 'Tocá el botón para continuar',
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black,
        opacityShadow: 0.88,
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        unFocusAnimationDuration: const Duration(milliseconds: 300),
        skipWidget: const SizedBox.shrink(),
        onClickTarget: (target) {
          if (target.identify == 'descuentos_navbar' && mounted) {
            context.go(HomePageKeys.discounts);
            discountsTutorialActiveNotifier.value = true;
          }
        },
        onFinish: () {},
        onSkip: () => true,
      ).show(context: context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = HomePageKeys.indexForPath(currentPath);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final back = pageBackCallbacks[currentIndex];
        if (back != null) {
          back();
          return;
        }
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Cerrar sesión?'),
            content: const Text(
              'Para volver atrás tenés que cerrar sesión. ¿Querés hacerlo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (shouldLogout == true && context.mounted) {
          await AuthService().logout();
          if (context.mounted) {
            context.go('/');
          }
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: ResponsiveWrapper(
              maxWidth: 1200,
              child: widget.navigationShell,
            ),
            bottomNavigationBar: NavbarWidget(
              showCasinos: !_hideCasinosOnMobile,
              inicioTutorialTargetKey:     HomePageKeys.inicioNavbarKey,
              descuentosTutorialTargetKey: HomePageKeys.descuentosNavbarKey,
              sorteosTutorialTargetKey:    HomePageKeys.sorteosNavbarKey,
              foroTutorialTargetKey:       HomePageKeys.foroNavbarKey,
              juegosTutorialTargetKey:     HomePageKeys.juegosNavbarKey,
              premiosTutorialTargetKey:    HomePageKeys.premiosNavbarKey,
              ajustesTutorialTargetKey:    HomePageKeys.ajustesNavbarKey,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: loginTutorialActiveNotifier,
            builder: (context, isActive, _) {
              if (!isActive) return const SizedBox.shrink();
              return TutorialOverlay(
                onContinue: () {
                  loginTutorialActiveNotifier.value = false;
                  _launchNavbarTutorial();
                },
              );
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: navbarSwipeTutorialNotifier,
            builder: (context, isActive, _) {
              if (!isActive) return const SizedBox.shrink();
              return const NavbarSwipeTutorial();
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: finalTutorialActiveNotifier,
            builder: (context, isActive, _) {
              if (!isActive) return const SizedBox.shrink();
              return TutorialFinalOverlay(
                onContinue: () {
                  finalTutorialActiveNotifier.value = false;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
