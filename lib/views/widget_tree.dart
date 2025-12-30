import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/views/pages/discounts_page.dart';
import 'package:boombet_app/views/pages/forum_page.dart';
import 'package:boombet_app/views/pages/games_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/my_casinos_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:flutter/material.dart';

List<Widget> pages = [
  const HomePage(),
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
