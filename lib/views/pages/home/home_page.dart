import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/auth_service.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/utils/page_transitions.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/profile/profile_page.dart';
import 'package:boombet_app/views/pages/community/forum_page.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_login_tutorial_overlay.dart';
import 'package:boombet_app/views/pages/other/my_casinos_page.dart';
import 'package:boombet_app/views/pages/rewards/raffles_page.dart';
import 'package:boombet_app/views/pages/games/games_page.dart';
import 'package:boombet_app/views/pages/other/qr_scanner_page.dart';
import 'package:boombet_app/views/pages/profile/settings_page.dart';
import 'package:boombet_app/views/pages/rewards/my_prizes_page.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/views/pages/admin/admin_tools_page.dart';
import 'package:boombet_app/views/pages/other/claims_page.dart';
import 'package:boombet_app/widgets/appbar_widget.dart';
import 'package:boombet_app/widgets/navbar_widget.dart';
import 'package:boombet_app/widgets/responsive_wrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.showLoginTutorial = false});

  final bool showLoginTutorial;

  @override
  State<HomePage> createState() => _HomePageState();
}

Future<void> _subscribeToTopics() async {
  if (kIsWeb) return;
  await FirebaseMessaging.instance.subscribeToTopic('all');
}

class _HomePageState extends State<HomePage> {
  late GlobalKey<DiscountsContentState> _discountsKey;
  late GlobalKey<ClaimedCouponsContentState> _claimedKey;
  final GlobalKey _inicioNavbarTutorialKey = GlobalKey();
  final GlobalKey _descuentosNavbarTutorialKey = GlobalKey();
  final GlobalKey _sorteosNavbarTutorialKey = GlobalKey();
  final GlobalKey _foroNavbarTutorialKey = GlobalKey();
  final GlobalKey _juegosNavbarTutorialKey = GlobalKey();
  final GlobalKey _firstCouponTutorialKey = GlobalKey();
  final GlobalKey _firstGameTutorialKey = GlobalKey();
  final GlobalKey _faqAppbarTutorialKey = GlobalKey();
  final GlobalKey _profileAppbarTutorialKey = GlobalKey();
  final GlobalKey _settingsAppbarTutorialKey = GlobalKey();
  final GlobalKey _logoutAppbarTutorialKey = GlobalKey();
  final GlobalKey _claimedSwitchTutorialKey = GlobalKey();
  final GlobalKey _forumBoomBetSelectorTutorialKey = GlobalKey();
  final GlobalKey _forumAddPostTutorialKey = GlobalKey();
  final GlobalKey _forumMyPostsTutorialKey = GlobalKey();
  bool _tutorialInteractionLocked = false;
  late List<Widget?> _pages;

  bool get _hideCasinosOnMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  int get _pageCount => _hideCasinosOnMobile ? 12 : 12;

  /// Índices siempre:
  /// 0: Inicio, 1: Descuentos, 2: Sorteos, 3: Foro, 4: Juegos, 5: Scanner, 6: Settings, 7: My Prizes
  /// 8: Casinos (si showCasinos) o Perfil (si móvil)
  /// 9: Perfil (si desktop y showCasinos)
  /// 10: Admin tools (solo visible para admins)
  int get _profilePageIndex => _hideCasinosOnMobile ? 8 : 9;

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
    _tutorialInteractionLocked = widget.showLoginTutorial && !kIsWeb;
    if (_tutorialInteractionLocked) {
      // Bloquea cualquier interacción desde el primer frame.
      loginTutorialActiveNotifier.value = true;
    }
    rouletteTriggerAfterTutorialNotifier.value =
        !widget.showLoginTutorial || kIsWeb;
    _pages = List<Widget?>.filled(_pageCount, null);
    _subscribeToTopics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb || !selectedPageWasRestored) {
        saveSelectedPage(0);
      }

      if (widget.showLoginTutorial && !kIsWeb) {
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
      if (mounted) {
        setState(() => _tutorialInteractionLocked = false);
      }
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
            inicioTargetKey: _inicioNavbarTutorialKey,
            descuentosTargetKey: _descuentosNavbarTutorialKey,
            sorteosTargetKey: _sorteosNavbarTutorialKey,
            foroTargetKey: _foroNavbarTutorialKey,
            juegosTargetKey: _juegosNavbarTutorialKey,
            firstCouponTargetKey: _firstCouponTutorialKey,
            firstGameTargetKey: _firstGameTutorialKey,
            faqTargetKey: _faqAppbarTutorialKey,
            profileTargetKey: _profileAppbarTutorialKey,
            settingsTargetKey: _settingsAppbarTutorialKey,
            logoutTargetKey: _logoutAppbarTutorialKey,
            claimedSwitchTargetKey: _claimedSwitchTutorialKey,
            forumBoomBetTargetKey: _forumBoomBetSelectorTutorialKey,
            forumAddPostTargetKey: _forumAddPostTutorialKey,
            forumMyPostsTargetKey: _forumMyPostsTutorialKey,
            onRequestOpenDiscounts: () {
              saveSelectedPage(1);
            },
            onRequestOpenRaffles: () {
              saveSelectedPage(2);
            },
            onRequestOpenForum: () {
              saveSelectedPage(3);
            },
            onRequestOpenGames: () {
              saveSelectedPage(4);
            },
            onRequestOpenClaimedCoupons: () {
              saveSelectedPage(1);
              _discountsKey.currentState?.openClaimedFromTutorial();
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
      if (mounted) {
        setState(() => _tutorialInteractionLocked = false);
      }
      loginTutorialActiveNotifier.value = false;
    }
  }

  Future<void> _setFirstLoginFalseSafely() async {
    try {
      await PlayerService().setFirstLoginFalse();
    } catch (_) {
      // Evitar romper el flujo si falla el endpoint.
    }
  }

  Future<bool> _shouldShowRouletteForCurrentUser() async {
    if (kIsWeb) return false;

    try {
      final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
      if (isFirstLogin == false) return false;

      await loadAffiliateCodeUsage();
      final eligible = !affiliateCodeValidatedNotifier.value;

      return eligible;
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
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final safeIndex = selectedPage.clamp(0, _pages.length - 1);
        if (safeIndex != selectedPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            saveSelectedPage(safeIndex);
          });
        }
        _pages[safeIndex] ??= _buildPage(safeIndex);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final back = pageBackCallbacks[selectedPage];
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
                child: IndexedStack(
                  index: safeIndex,
                  children: List<Widget>.generate(_pages.length, (index) {
                    final page = _pages[index];
                    return page ?? const SizedBox.shrink();
                  }),
                ),
              ),
              bottomNavigationBar: NavbarWidget(
                showCasinos: !_hideCasinosOnMobile,
                profilePageIndex: _profilePageIndex,
                inicioTutorialTargetKey: _inicioNavbarTutorialKey,
                descuentosTutorialTargetKey: _descuentosNavbarTutorialKey,
                sorteosTutorialTargetKey: _sorteosNavbarTutorialKey,
                foroTutorialTargetKey: _foroNavbarTutorialKey,
                juegosTutorialTargetKey: _juegosNavbarTutorialKey,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomeContent();
      case 1:
        return DiscountsContent(
          key: _discountsKey,
          firstCouponTutorialTargetKey: _firstCouponTutorialKey,
          claimedSwitchTutorialTargetKey: _claimedSwitchTutorialKey,
          onCuponClaimed: () {
            _claimedKey.currentState?.refreshClaimedCupones();
            _discountsKey.currentState?.refreshClaimedIds();
          },
          claimedKey: _claimedKey,
        );
      case 2:
        return const RafflesPage();
      case 3:
        return ForumPage(
          tutorialBoomBetForumTargetKey: _forumBoomBetSelectorTutorialKey,
          tutorialAddPostButtonKey: _forumAddPostTutorialKey,
          tutorialMyPostsButtonKey: _forumMyPostsTutorialKey,
        );
      case 4:
        return GamesPage(firstGameTutorialTargetKey: _firstGameTutorialKey);
      case 5:
        return const QrScannerPage();
      case 6:
        return const SettingsPage();
      case 7:
        return const MyPrizesPage();
      case 8:
        if (_hideCasinosOnMobile) return const ProfilePage();
        return const MyCasinosPage();
      case 9:
        return const ProfilePage();
      case 10:
        return const AdminToolsPage();
      case 11:
        if (AppConstants.showClaimsPage) return const ClaimsPage();
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}

extension DiscountsContentStateRefresh on DiscountsContentState {
  void refreshClaimedIds() {}
}
