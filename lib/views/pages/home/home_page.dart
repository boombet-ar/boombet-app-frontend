import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/views/pages/community/forum_page.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_login_tutorial_overlay.dart';
import 'package:boombet_app/views/pages/other/my_casinos_page.dart';
import 'package:boombet_app/views/pages/rewards/raffles_page.dart';
import 'package:boombet_app/views/pages/games/games_page.dart';
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
  bool _allowQrScanner = false;
  late List<Widget?> _pages;

  bool get _hideCasinosOnMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  int get _pageCount => _hideCasinosOnMobile ? 5 : 6;

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
    rouletteTriggerAfterTutorialNotifier.value =
        !widget.showLoginTutorial || kIsWeb;
    _pages = List<Widget?>.filled(_pageCount, null);
    _subscribeToTopics();
    _loadQrScannerAvailability();
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
      return;
    }

    await _showLoginTutorialOverlay();
  }

  Future<void> _showLoginTutorialOverlay() async {
    if (kIsWeb) return;
    if (!mounted) return;

    final isFirstLogin = await _getCurrentUserIsFirstLoginSafely();
    if (!mounted) return;
    if (isFirstLogin == false) return;

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

  Future<void> _loadQrScannerAvailability() async {
    await loadAffiliateCodeUsage();
    await loadAffiliateType();
    if (!mounted) return;

    final storedValidated = affiliateCodeValidatedNotifier.value;
    final storedType = affiliateTypeNotifier.value.trim().toUpperCase();
    var allowQr = storedValidated && storedType == 'RULETA';

    if (!allowQr) {
      allowQr = await _resolveRuletaAffiliationFromUsersMe();
      if (!mounted) return;
    }

    setState(() => _allowQrScanner = allowQr);
  }

  Future<bool> _resolveRuletaAffiliationFromUsersMe() async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/users/me',
        includeAuth: true,
        cacheTtl: Duration.zero,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      bool hasRuletaType(dynamic value) {
        if (value is String) {
          return value.trim().toUpperCase() == 'RULETA';
        }

        if (value is List) {
          for (final item in value) {
            if (hasRuletaType(item)) return true;
          }
          return false;
        }

        if (value is Map) {
          for (final entry in value.entries) {
            final key = entry.key.toString().toLowerCase();
            final entryValue = entry.value;

            if (entryValue is String) {
              final normalized = entryValue.trim().toUpperCase();
              if (normalized == 'RULETA') {
                if (key.contains('tipo') ||
                    key.contains('affiliate') ||
                    key.contains('afilia')) {
                  return true;
                }
              }
            }

            if (hasRuletaType(entryValue)) {
              return true;
            }
          }
        }

        return false;
      }

      return hasRuletaType(decoded);
    } catch (_) {
      return false;
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
        return Scaffold(
          appBar: MainAppBar(
            showSettings: true,
            showLogo: true,
            showProfileButton: true,
            showLogoutButton: true,
            showExitButton: false,
            showQrScannerButton: _allowQrScanner,
            faqTutorialTargetKey: _faqAppbarTutorialKey,
            profileTutorialTargetKey: _profileAppbarTutorialKey,
            settingsTutorialTargetKey: _settingsAppbarTutorialKey,
            logoutTutorialTargetKey: _logoutAppbarTutorialKey,
          ),
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
            inicioTutorialTargetKey: _inicioNavbarTutorialKey,
            descuentosTutorialTargetKey: _descuentosNavbarTutorialKey,
            sorteosTutorialTargetKey: _sorteosNavbarTutorialKey,
            foroTutorialTargetKey: _foroNavbarTutorialKey,
            juegosTutorialTargetKey: _juegosNavbarTutorialKey,
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
        return const MyCasinosPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

extension DiscountsContentStateRefresh on DiscountsContentState {
  void refreshClaimedIds() {}
}
