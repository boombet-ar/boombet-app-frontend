import 'package:boombet_app/core/notifiers.dart';
import 'package:flutter/material.dart';

class NavbarWidget extends StatelessWidget {
  const NavbarWidget({
    super.key,
    this.showCasinos = true,
    this.inicioTutorialTargetKey,
    this.descuentosTutorialTargetKey,
    this.sorteosTutorialTargetKey,
    this.foroTutorialTargetKey,
    this.juegosTutorialTargetKey,
  });

  /// Muestra la pestaña de casinos (oculta en flows limitados).
  final bool showCasinos;
  final GlobalKey? inicioTutorialTargetKey;
  final GlobalKey? descuentosTutorialTargetKey;
  final GlobalKey? sorteosTutorialTargetKey;
  final GlobalKey? foroTutorialTargetKey;
  final GlobalKey? juegosTutorialTargetKey;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    const bgColor = Color(0xFF080808);
    final selectedColor = primaryGreen;
    const unselectedColor = Color(0xFF5A5A5A);
    final destinationCount = showCasinos ? 6 : 5;
    final perItemWidth = media.size.width / destinationCount;
    final isUltraCompact = perItemWidth < 62;
    final isCompact = perItemWidth < 72;
    final useShortLabels = perItemWidth < 82;
    final useTinyLabels = perItemWidth < 70;

    String resolveLabel(String full, String short, String tiny) {
      if (useTinyLabels) return tiny;
      if (useShortLabels) return short;
      return full;
    }

    final iconSize = isUltraCompact ? 18.0 : (isCompact ? 20.0 : 24.0);
    final barHeight = isUltraCompact ? 56.0 : (isCompact ? 60.0 : 68.0);
    final compactLabelStyle = TextStyle(
      fontSize: isUltraCompact ? 7.5 : (isCompact ? 8.5 : 10),
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
    final regularLabelStyle = TextStyle(
      fontSize: isUltraCompact ? 7.0 : (isCompact ? 8.0 : 9.5),
      fontWeight: FontWeight.w500,
      height: 1.0,
    );

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
              selectedIcon: Container(
                key: inicioTutorialTargetKey,
                child: Icon(Icons.home, color: selectedColor, size: iconSize),
              ),
              label: resolveLabel('Inicio', 'Inicio', 'Ini.'),
            ),
            NavigationDestination(
              icon: Container(
                key: descuentosTutorialTargetKey,
                child: Icon(
                  Icons.local_offer_outlined,
                  color: selectedPage == 1 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
              ),
              selectedIcon: Icon(
                Icons.local_offer,
                color: selectedColor,
                size: iconSize,
              ),
              label: resolveLabel('Descuentos', 'Desc.', 'Desc'),
            ),
            NavigationDestination(
              icon: Container(
                key: sorteosTutorialTargetKey,
                child: Icon(
                  Icons.card_giftcard_outlined,
                  color: selectedPage == 2 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
              ),
              selectedIcon: Icon(
                Icons.card_giftcard,
                color: selectedColor,
                size: iconSize,
              ),
              label: resolveLabel('Sorteos', 'Sort.', 'Sort'),
            ),
            NavigationDestination(
              icon: Container(
                key: foroTutorialTargetKey,
                child: Icon(
                  Icons.forum_outlined,
                  color: selectedPage == 3 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
              ),
              selectedIcon: Icon(
                Icons.forum,
                color: selectedColor,
                size: iconSize,
              ),
              label: resolveLabel('Foro', 'Foro', 'Foro'),
            ),
            NavigationDestination(
              icon: Container(
                key: juegosTutorialTargetKey,
                child: Icon(
                  Icons.videogame_asset_outlined,
                  color: selectedPage == 4 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
              ),
              selectedIcon: Icon(
                Icons.videogame_asset,
                color: selectedColor,
                size: iconSize,
              ),
              label: resolveLabel('Juegos', 'Juegos', 'Jue.'),
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
                label: resolveLabel('Casinos', 'Casino', 'Cas.'),
              ),
            );
          }

          final safeIndex = selectedPage.clamp(0, destinations.length - 1);

          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Línea separadora neon (espejo del appbar)
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryGreen.withValues(alpha: 0.25),
                        primaryGreen.withValues(alpha: 0.50),
                        primaryGreen.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                NavigationBarTheme(
                  data: NavigationBarThemeData(
                    labelTextStyle:
                        WidgetStateProperty.resolveWith<TextStyle>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return compactLabelStyle.copyWith(
                          color: primaryGreen,
                        );
                      }
                      return regularLabelStyle.copyWith(
                        color: unselectedColor,
                      );
                    }),
                    indicatorColor: primaryGreen.withValues(alpha: 0.14),
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: primaryGreen.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    overlayColor: WidgetStateProperty.all(
                      primaryGreen.withValues(alpha: 0.06),
                    ),
                  ),
                  child: NavigationBar(
                    height: barHeight,
                    backgroundColor: bgColor,
                    elevation: 0,
                    labelBehavior: isUltraCompact
                        ? NavigationDestinationLabelBehavior.onlyShowSelected
                        : NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: destinations,
                    onDestinationSelected: (int value) {
                      saveSelectedPage(value);
                    },
                    selectedIndex: safeIndex,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
