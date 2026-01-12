import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({super.key, this.showCasinos = true});

  /// Muestra la pestaña de casinos (oculta en flows limitados).
  final bool showCasinos;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 380;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = theme.colorScheme.primary;
    final bgColor = isDark ? AppConstants.darkBg : AppConstants.lightAccent;
    final selectedColor = primaryGreen;
    final unselectedColor = isDark
        ? const Color(0xFF808080)
        : AppConstants.lightHintText;
    final iconSize = isCompact ? 22.0 : 26.0;
    final barHeight = isCompact ? 62.0 : 70.0;

    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          final destinations = <NavigationDestination>[
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: selectedPage == 0 ? selectedColor : unselectedColor,
                size: iconSize,
              ),
              selectedIcon: Icon(
                Icons.home,
                color: selectedColor,
                size: iconSize,
              ),
              label: "Home",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.local_offer_outlined,
                color: selectedPage == 1 ? selectedColor : unselectedColor,
                size: iconSize,
              ),
              selectedIcon: Icon(
                Icons.local_offer,
                color: selectedColor,
                size: iconSize,
              ),
              label: "Descuentos",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.card_giftcard_outlined,
                color: selectedPage == 2 ? selectedColor : unselectedColor,
                size: iconSize,
              ),
              selectedIcon: Icon(
                Icons.card_giftcard,
                color: selectedColor,
                size: iconSize,
              ),
              label: "Sorteos",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.forum_outlined,
                color: selectedPage == 3 ? selectedColor : unselectedColor,
                size: iconSize,
              ),
              selectedIcon: Icon(
                Icons.forum,
                color: selectedColor,
                size: iconSize,
              ),
              label: "Foro",
            ),
            NavigationDestination(
              icon: Icon(
                Icons.videogame_asset_outlined,
                color: selectedPage == 4 ? selectedColor : unselectedColor,
                size: iconSize,
              ),
              selectedIcon: Icon(
                Icons.videogame_asset,
                color: selectedColor,
                size: iconSize,
              ),
              label: "Juegos",
            ),
          ];

          if (showCasinos) {
            destinations.add(
              NavigationDestination(
                icon: Icon(
                  Icons.casino_outlined,
                  color: selectedPage == 5 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
                selectedIcon: Icon(
                  Icons.casino,
                  color: selectedColor,
                  size: iconSize,
                ),
                label: "Casinos",
              ),
            );
          }

          final safeIndex = selectedPage.clamp(0, destinations.length - 1);

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
                        ? AppConstants.borderDark.withValues(alpha: 0.6)
                        : AppConstants.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                height: barHeight,
                backgroundColor: bgColor,
                indicatorColor: primaryGreen.withValues(alpha: 0.15),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: destinations,
                onDestinationSelected: (int value) {
                  selectedPageNotifier.value = value;
                },
                selectedIndex: safeIndex,
              ),
            ),
          );
        },
      ),
    );
  }
}
