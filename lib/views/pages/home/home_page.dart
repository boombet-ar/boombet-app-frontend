import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:boombet_app/views/pages/home/widgets/home_login_tutorial_overlay.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  bool _tutorialInteractionLocked = false;

  bool get _hideCasinosOnMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();

    final showTutorial = pendingLoginTutorialNotifier.value;
    pendingLoginTutorialNotifier.value = false;

    _tutorialInteractionLocked = showTutorial && !kIsWeb;
    if (_tutorialInteractionLocked) {
      loginTutorialActiveNotifier.value = true;
    }
    rouletteTriggerAfterTutorialNotifier.value = !showTutorial || kIsWeb;

    _subscribeToTopics();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (showTutorial && !kIsWeb) {
        _maybeShowLoginTutorialOverlay();
      }
    });
  }

  Future<void> _maybeShowLoginTutorialOverlay() async {
    if (kIsWeb) return;

    final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
    if (!mounted) return;

    if (isFirstLogin == false) {
      setState(() => _tutorialInteractionLocked = false);
      loginTutorialActiveNotifier.value = false;
      return;
    }

    await _showLoginTutorialOverlay();
  }

  Future<void> _showLoginTutorialOverlay() async {
    if (kIsWeb) return;
    if (!mounted) return;

    final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
    if (!mounted) return;
    if (isFirstLogin == false) {
      if (mounted) setState(() => _tutorialInteractionLocked = false);
      loginTutorialActiveNotifier.value = false;
      return;
    }

    final shouldShowRoulette = await _shouldShowRouletteForCurrentUser();

    loginTutorialActiveNotifier.value = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'tutorial',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return HomeLoginTutorialOverlay(
            inicioTargetKey:        HomePageKeys.inicioNavbarKey,
            descuentosTargetKey:    HomePageKeys.descuentosNavbarKey,
            sorteosTargetKey:       HomePageKeys.sorteosNavbarKey,
            foroTargetKey:          HomePageKeys.foroNavbarKey,
            juegosTargetKey:        HomePageKeys.juegosNavbarKey,
            firstCouponTargetKey:   HomePageKeys.firstCouponKey,
            firstGameTargetKey:     HomePageKeys.firstGameKey,
            faqTargetKey:           HomePageKeys.faqAppbarKey,
            profileTargetKey:       HomePageKeys.profileAppbarKey,
            settingsTargetKey:      HomePageKeys.settingsAppbarKey,
            logoutTargetKey:        HomePageKeys.logoutAppbarKey,
            claimedSwitchTargetKey: HomePageKeys.claimedSwitchKey,
            forumBoomBetTargetKey:  HomePageKeys.forumBoomBetSelectorKey,
            forumAddPostTargetKey:  HomePageKeys.forumAddPostKey,
            forumMyPostsTargetKey:  HomePageKeys.forumMyPostsKey,
            onRequestOpenDiscounts: () => context.go(HomePageKeys.discounts),
            onRequestOpenRaffles:   () => context.go(HomePageKeys.raffles),
            onRequestOpenForum:     () => context.go(HomePageKeys.forum),
            onRequestOpenGames:     () => context.go(HomePageKeys.games),
            onRequestOpenClaimedCoupons: () {
              context.go(HomePageKeys.discounts);
              HomePageKeys.discountsKey.currentState
                  ?.openClaimedFromTutorial();
            },
            onTutorialCompleted: () async {
              if (shouldShowRoulette) {
                rouletteTriggerAfterTutorialNotifier.value = true;
                return;
              }
              await _setFirstLoginFalseSafely();
            },
            onClose: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    } finally {
      if (mounted) setState(() => _tutorialInteractionLocked = false);
      loginTutorialActiveNotifier.value = false;
    }
  }

  Future<void> _setFirstLoginFalseSafely() async {
    try {
      await PlayerService().setFirstLoginFalse();
    } catch (_) {}
  }

  Future<bool> _shouldShowRouletteForCurrentUser() async {
    if (kIsWeb) return false;
    try {
      final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
      if (isFirstLogin == false) return false;
      await loadAffiliateCodeUsage();
      return !affiliateCodeValidatedNotifier.value;
    } catch (_) {
      return false;
    }
  }

  Future<bool?> _getCurrentUserIsFirstLoginSafely() async {
    try {
      return await PlayerService().getCurrentUserIsFirstLogin();
    } catch (_) {
      return null;
    }
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
            Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(page: const LoginPage()),
              (route) => false,
            );
          }
        }
      },
      child: AbsorbPointer(
        absorbing: _tutorialInteractionLocked,
        child: Scaffold(
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
          ),
        ),
      ),
    );
  }
}
