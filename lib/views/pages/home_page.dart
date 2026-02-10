import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/forum_page.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_content.dart';
import 'package:boombet_app/views/pages/my_casinos_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:boombet_app/views/pages/games_page.dart';
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

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
    _pages = List<Widget?>.filled(6, null);
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

    if (!affiliateCodeValidatedNotifier.value) {
      setState(() => _allowQrScanner = false);
      return;
    }

    final tipo = affiliateTypeNotifier.value.trim().toUpperCase();
    setState(() => _allowQrScanner = tipo == 'RULETA');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final safeIndex = selectedPage.clamp(0, 5);
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
              children: List<Widget>.generate(6, (index) {
                final page = _pages[index];
                return page ?? const SizedBox.shrink();
              }),
            ),
          ),
          bottomNavigationBar: const NavbarWidget(),
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
