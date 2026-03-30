import 'package:boombet_app/services/token_service.dart';
import 'package:boombet_app/views/pages/home/home_keys.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({
    super.key,
    this.showCasinos = true,
    this.hiddenIndexes = const [],
    this.inicioTutorialTargetKey,
    this.descuentosTutorialTargetKey,
    this.sorteosTutorialTargetKey,
    this.foroTutorialTargetKey,
    this.juegosTutorialTargetKey,
  });

  /// Muestra la pestaña de casinos (oculta en flows limitados).
  final bool showCasinos;

  /// Índices de tabs a ocultar (ej: [6, 7] para Ajustes y Premios).
  final List<int> hiddenIndexes;
  final GlobalKey? inicioTutorialTargetKey;
  final GlobalKey? descuentosTutorialTargetKey;
  final GlobalKey? sorteosTutorialTargetKey;
  final GlobalKey? foroTutorialTargetKey;
  final GlobalKey? juegosTutorialTargetKey;

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  late final ScrollController _scrollController;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final newVal = max > 0 && _scrollController.offset < max - 1;
    if (newVal != _canScrollRight) setState(() => _canScrollRight = newVal);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final primaryGreen = theme.colorScheme.primary;
    const bgColor = Color(0xFF080808);
    final selectedColor = primaryGreen;
    const unselectedColor = Color(0xFF5A5A5A);

    final isDesktopWeb = kIsWeb && media.size.width > 600;
    const visibleItems = 5;
    const barHeight = 76.0;
    const iconSize = 26.0;
    final mobileItemWidth = media.size.width / visibleItems;

    // Ruta activa actual del GoRouter
    final currentPath = GoRouterState.of(context).uri.path;

    // Rutas a ocultar según los índices proporcionados
    final hiddenRoutes = widget.hiddenIndexes
        .map((i) => HomePageKeys.indexToRoute[i])
        .whereType<String>()
        .toSet();

    return RepaintBoundary(
      child: FutureBuilder<List<bool>>(
        future: Future.wait([
          TokenService.hasActiveSession(),
          TokenService.isAdmin(),
        ]),
        builder: (context, snapshot) {
          final results = snapshot.data;
          final hasSession =
              results != null && results.isNotEmpty ? results[0] : false;
          final isAdmin =
              results != null && results.length > 1 ? results[1] : false;

          final items = <_NavItem>[
            _NavItem(
              route: HomePageKeys.discounts,
              icon: Icons.local_offer_outlined,
              selectedIcon: Icons.local_offer,
              label: 'Descuentos',
              tutorialKey: widget.descuentosTutorialTargetKey,
            ),
            _NavItem(
              route: HomePageKeys.home,
              icon: Icons.groups_outlined,
              selectedIcon: Icons.groups,
              label: 'Club',
              tutorialKey: widget.inicioTutorialTargetKey,
            ),
            _NavItem(
              route: HomePageKeys.games,
              icon: Icons.videogame_asset_outlined,
              selectedIcon: Icons.videogame_asset,
              label: 'Juegos',
              tutorialKey: widget.juegosTutorialTargetKey,
            ),
            _NavItem(
              route: HomePageKeys.raffles,
              icon: Icons.card_giftcard_outlined,
              selectedIcon: Icons.card_giftcard,
              label: 'Sorteos',
              tutorialKey: widget.sorteosTutorialTargetKey,
            ),
            _NavItem(
              route: HomePageKeys.prizes,
              icon: Icons.workspace_premium_rounded,
              selectedIcon: Icons.workspace_premium,
              label: 'Premios',
            ),
            _NavItem(
              route: HomePageKeys.forum,
              icon: Icons.forum_outlined,
              selectedIcon: Icons.forum,
              label: 'Foro',
              tutorialKey: widget.foroTutorialTargetKey,
            ),
            if (widget.showCasinos)
              _NavItem(
                route: HomePageKeys.casinos,
                icon: Icons.casino_outlined,
                selectedIcon: Icons.casino,
                label: 'Casinos',
              ),
            _NavItem(
              route: HomePageKeys.settings,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Ajustes',
            ),
            if (hasSession && isAdmin)
              _NavItem(
                route: HomePageKeys.admin,
                icon: Icons.build_outlined,
                selectedIcon: Icons.build_rounded,
                label: 'Admin',
              ),
          ];

          final displayItems = items
              .where((item) => !hiddenRoutes.contains(item.route))
              .toList();

          final itemWidth = isDesktopWeb
              ? media.size.width / displayItems.length
              : mobileItemWidth;

          Widget navItems = Row(
            children: displayItems.map((item) {
              final isSelected = currentPath == item.route ||
                  currentPath.startsWith('${item.route}/');
              return GestureDetector(
                onTap: () => context.go(item.route),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: itemWidth,
                  height: barHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: primaryGreen.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryGreen.withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              )
                            : null,
                        child: item.tutorialKey != null
                            ? Container(
                                key: item.tutorialKey,
                                child: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  color: isSelected
                                      ? selectedColor
                                      : unselectedColor,
                                  size: iconSize,
                                ),
                              )
                            : Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color:
                                    isSelected ? selectedColor : unselectedColor,
                                size: iconSize,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? selectedColor : unselectedColor,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );

          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Container(
                  height: barHeight,
                  color: bgColor,
                  child: isDesktopWeb
                      ? navItems
                      : Stack(
                          children: [
                            SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: navItems,
                            ),
                            if (_canScrollRight)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          bgColor.withValues(alpha: 0),
                                          bgColor.withValues(alpha: 0.9),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

class _NavItem {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final GlobalKey? tutorialKey;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tutorialKey,
  });
}
