import 'package:boombet_app/core/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 41, 255, 94);

    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home, color: greenColor),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.stars, color: greenColor),
                label: "Puntos",
              ),
              NavigationDestination(
                icon: Icon(Icons.discount, color: greenColor),
                label: "Descuentos",
              ),
              NavigationDestination(
                icon: Icon(Icons.sort, color: greenColor),
                label: "Sorteos",
              ),
              NavigationDestination(
                icon: Icon(Icons.forum, color: greenColor),
                label: "Foro",
              ),
            ],
            onDestinationSelected: (int value) {
              selectedPageNotifier.value = value;
            },
            selectedIndex: selectedPage,
          );
        },
      ),
    );
  }
}
