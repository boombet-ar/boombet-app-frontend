import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/rewards/discounts_page.dart';
import 'package:boombet_app/views/pages/community/forum_page.dart';
import 'package:boombet_app/views/pages/games/games_page.dart';
import 'package:boombet_app/views/pages/other/my_casinos_page.dart';
import 'package:boombet_app/views/pages/rewards/raffles_page.dart';
import 'package:flutter/material.dart';

List<Widget> pages = [
  const SizedBox.shrink(), // HomePage ya no se instancia directamente (usa StatefulShellRoute)
  const DiscountsPage(),
  const RafflesPage(),
  const ForumPage(),
  const GamesPage(),
  const MyCasinosPage(),
];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
    );
  }
}
