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
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GlobalKey<DiscountsContentState> _discountsKey;
  late GlobalKey<ClaimedCouponsContentState> _claimedKey;

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedPageNotifier.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        final safeIndex = selectedPage.clamp(0, 5);
        return Scaffold(
          appBar: const MainAppBar(
            showSettings: true,
            showLogo: true,
            showProfileButton: true,
            showLogoutButton: true,
            showExitButton: false,
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
