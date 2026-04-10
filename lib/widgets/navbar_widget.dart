import 'package:boombet_app/core/notifiers.dart';
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
    this.premiosTutorialTargetKey,
    this.ajustesTutorialTargetKey,
    this.onTabTap,
  });

  /// Muestra la pestaña de casinos (oculta en flows limitados).
  final bool showCasinos;

  /// Índices de tabs a ocultar (ej: [6, 7] para Ajustes y Premios).
  final List<int> hiddenIndexes;

  /// Si se provee, intercepta el tap en un tab (recibe el índice global).
  /// Si es null, usa el comportamiento por defecto (context.go).
  final void Function(int index)? onTabTap;
  final GlobalKey? inicioTutorialTargetKey;
  final GlobalKey? descuentosTutorialTargetKey;
  final GlobalKey? sorteosTutorialTargetKey;
  final GlobalKey? foroTutorialTargetKey;
  final GlobalKey? juegosTutorialTargetKey;
  final GlobalKey? premiosTutorialTargetKey;
  final GlobalKey? ajustesTutorialTargetKey;

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _canScrollRight = false;
  bool _canScrollLeft = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
    navbarSwipeTutorialNotifier.addListener(_onSwipeTutorialActivated);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// Llamado cuando el tutorial de swipe se activa. Si la navbar no es
  /// desplazable (ej. escritorio), completa el paso automáticamente.
  void _onSwipeTutorialActivated() {
    if (!navbarSwipeTutorialNotifier.value) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navbarScrolledToEndNotifier.value = true;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final newRight = max > 0 && offset < max - 1;
    final newLeft = offset > 1;

    // Tutorial: detectar cuando se llegó al final del scroll
    if (navbarSwipeTutorialNotifier.value && _canScrollRight && !newRight) {
      navbarScrolledToEndNotifier.value = true;
    }

    if (newRight != _canScrollRight || newLeft != _canScrollLeft) {
      setState(() {
        _canScrollRight = newRight;
        _canScrollLeft = newLeft;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    navbarSwipeTutorialNotifier.removeListener(_onSwipeTutorialActivated);
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

    // Ruta activa: si hay onTabTap, usar selectedPageNotifier para determinar
    // el tab activo (estamos en un flow con IndexedStack, no en GoRouter shell).
    // Si no, usar la ruta actual del GoRouter.
    final currentPath = widget.onTabTap != null
        ? (HomePageKeys.indexToRoute[selectedPageNotifier.value] ?? '')
        : GoRouterState.of(context).uri.path;

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
              tutorialKey: widget.premiosTutorialTargetKey,
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
              tutorialKey: widget.ajustesTutorialTargetKey,
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

          // Peek: si hay más items que los visibles, reducir el ancho para que
          // el siguiente item asoma ~22px en el borde derecho.
          const peekAmount = 22.0;
          final itemWidth = isDesktopWeb
              ? media.size.width / displayItems.length
              : (displayItems.length > visibleItems
                  ? (media.size.width - peekAmount) / visibleItems
                  : mobileItemWidth);

          Widget navItems = Row(
            children: displayItems.map((item) {
              final isSelected = currentPath == item.route ||
                  currentPath.startsWith('${item.route}/');
              return GestureDetector(
                onTap: () {
                  if (widget.onTabTap != null) {
                    final idx = HomePageKeys.routeToIndex[item.route] ?? 0;
                    widget.onTabTap!(idx);
                  } else {
                    context.go(item.route);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: itemWidth,
                  height: barHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        key: item.tutorialKey,
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
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          color: isSelected ? selectedColor : unselectedColor,
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
                            if (_canScrollLeft)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: SizedBox(
                                    width: peekAmount + 28,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: [
                                                  bgColor.withValues(alpha: 0),
                                                  bgColor.withValues(alpha: 0.92),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 2,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: FadeTransition(
                                              opacity: _pulseAnimation,
                                              child: Icon(
                                                Icons.chevron_left_rounded,
                                                color: primaryGreen,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_canScrollRight)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: SizedBox(
                                    width: peekAmount + 28,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  bgColor.withValues(alpha: 0),
                                                  bgColor.withValues(alpha: 0.92),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 2,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: FadeTransition(
                                              opacity: _pulseAnimation,
                                              child: Icon(
                                                Icons.chevron_right_rounded,
                                                color: primaryGreen,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
