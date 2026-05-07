import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
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
  late List<Widget?> _pages;

  int get _pageCount => AppConstants.showMyCasinos ? 6 : 5;

  @override
  void initState() {
    super.initState();
    _discountsKey = GlobalKey<DiscountsContentState>();
    _claimedKey = GlobalKey<ClaimedCouponsContentState>();
    _pages = List<Widget?>.filled(_pageCount, null);
    _subscribeToTopics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb || !selectedPageWasRestored) {
        saveSelectedPage(0);
      }
    });
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
          bottomNavigationBar: NavbarWidget(showCasinos: AppConstants.showMyCasinos),
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
