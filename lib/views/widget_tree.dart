import 'package:boombet_app/data/notifiers.dart';
import 'package:boombet_app/views/pages/discounts_page.dart';
import 'package:boombet_app/views/pages/home_page.dart';
import 'package:boombet_app/views/pages/raffles_page.dart';
import 'package:boombet_app/views/pages/store_page.dart';
import 'package:flutter/material.dart';

List<Widget> pages = [
  const HomePage(),
  const StorePage(),
  const DiscountsPage(),
  const RafflesPage(),
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
