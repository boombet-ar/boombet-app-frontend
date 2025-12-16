import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = isDark ? Colors.black87 : const Color(0xFFF8F8F8);
    final selectedColor = primaryGreen;
    final unselectedColor = isDark
        ? const Color(0xFF808080)
        : const Color(0xFF6C6C6C);

    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF404040)
                        : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: bgColor,
                indicatorColor: primaryGreen.withValues(alpha: 0.15),
                height: 70,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_outlined,
                      color: selectedPage == 0
                          ? selectedColor
                          : unselectedColor,
                      size: 26,
                    ),
                    selectedIcon: Icon(
                      Icons.home,
                      color: selectedColor,
                      size: 26,
                    ),
                    label: "Home",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.local_offer_outlined,
                      color: selectedPage == 1
                          ? selectedColor
                          : unselectedColor,
                      size: 26,
                    ),
                    selectedIcon: Icon(
                      Icons.local_offer,
                      color: selectedColor,
                      size: 26,
                    ),
                    label: "Descuentos",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.card_giftcard_outlined,
                      color: selectedPage == 2
                          ? selectedColor
                          : unselectedColor,
                      size: 26,
                    ),
                    selectedIcon: Icon(
                      Icons.card_giftcard,
                      color: selectedColor,
                      size: 26,
                    ),
                    label: "Sorteos",
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.forum_outlined,
                      color: selectedPage == 3
                          ? selectedColor
                          : unselectedColor,
                      size: 26,
                    ),
                    selectedIcon: Icon(
                      Icons.forum,
                      color: selectedColor,
                      size: 26,
                    ),
                    label: "Foro",
                  ),
                ],
                onDestinationSelected: (int value) {
                  selectedPageNotifier.value = value;
                },
                selectedIndex: selectedPage,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
          );
        },
      ),
    );
  }
}
