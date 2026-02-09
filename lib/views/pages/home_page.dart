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

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
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
              children: [
                HomeContent(),
                DiscountsContent(
                  key: _discountsKey,
                  onCuponClaimed: () {
                    _claimedKey.currentState?.refreshClaimedCupones();
                    _discountsKey.currentState?.refreshClaimedIds();
                  },
                  claimedKey: _claimedKey,
                ),
                const RafflesPage(),
                const ForumPage(),
                const GamesPage(),
                const MyCasinosPage(),
              ],
            ),
          ),
          bottomNavigationBar: const NavbarWidget(),
        );
      },
    );
  }
}

extension DiscountsContentStateRefresh on DiscountsContentState {
  void refreshClaimedIds() {}
}
