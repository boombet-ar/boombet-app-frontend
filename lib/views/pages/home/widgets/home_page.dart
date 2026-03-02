import 'dart:convert';

import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/views/pages/community/forum_page.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_content.dart';
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
  const HomePage({super.key});

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
    _pages = List<Widget?>.filled(_pageCount, null);
    _subscribeToTopics();
    _loadQrScannerAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb || !selectedPageWasRestored) {
        saveSelectedPage(0);
      }
    });
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
          bottomNavigationBar: NavbarWidget(showCasinos: !_hideCasinosOnMobile),
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
          onCuponClaimed: () {
            _claimedKey.currentState?.refreshClaimedCupones();
            _discountsKey.currentState?.refreshClaimedIds();
          },
          claimedKey: _claimedKey,
        );
      case 2:
        return const RafflesPage();
      case 3:
        return const ForumPage();
      case 4:
        return const GamesPage();
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
