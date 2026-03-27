import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/services/token_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class NavbarWidget extends StatefulWidget {
  const NavbarWidget({
    super.key,
    this.showCasinos = true,
    this.profilePageIndex = -1,
    this.hiddenIndexes = const [],
    this.inicioTutorialTargetKey,
    this.descuentosTutorialTargetKey,
    this.sorteosTutorialTargetKey,
    this.foroTutorialTargetKey,
    this.juegosTutorialTargetKey,
  });

  /// Muestra la pestaña de casinos (oculta en flows limitados).
  final bool showCasinos;
  final int profilePageIndex; // -1 = ocultar tab de perfil
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

    // En web desktop no hace falta scroll: caben todos los ítems en el ancho
    final isDesktopWeb = kIsWeb && media.size.width > 600;
    const visibleItems = 5;
    const barHeight = 76.0;
    const iconSize = 26.0;
    // El itemWidth para mobile se calcula con visibleItems; en desktop se recalcula
    // dentro del FutureBuilder cuando ya conocemos la cantidad real de ítems.
    final mobileItemWidth = media.size.width / visibleItems;

    return RepaintBoundary(
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, _) {
          final items = <_NavItem>[
            _NavItem(
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Inicio',
              tutorialKey: widget.inicioTutorialTargetKey,
            ),
            _NavItem(
              index: 1,
              icon: Icons.local_offer_outlined,
              selectedIcon: Icons.local_offer,
              label: 'Descuentos',
              tutorialKey: widget.descuentosTutorialTargetKey,
            ),
            _NavItem(
              index: 2,
              icon: Icons.card_giftcard_outlined,
              selectedIcon: Icons.card_giftcard,
              label: 'Sorteos',
              tutorialKey: widget.sorteosTutorialTargetKey,
            ),
            _NavItem(
              index: 3,
              icon: Icons.forum_outlined,
              selectedIcon: Icons.forum,
              label: 'Foro',
              tutorialKey: widget.foroTutorialTargetKey,
            ),
            _NavItem(
              index: 4,
              icon: Icons.videogame_asset_outlined,
              selectedIcon: Icons.videogame_asset,
              label: 'Juegos',
              tutorialKey: widget.juegosTutorialTargetKey,
            ),
            _NavItem(
              index: 5,
              icon: Icons.qr_code_outlined,
              selectedIcon: Icons.qr_code,
              label: 'Scanner',
            ),
            _NavItem(
              index: 6,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Ajustes',
            ),
            _NavItem(
              index: 7,
              icon: Icons.workspace_premium_rounded,
              selectedIcon: Icons.workspace_premium,
              label: 'Premios',
            ),
            if (AppConstants.showClaimsPage)
              _NavItem(
                index: 11,
                icon: Icons.report_problem_outlined,
                selectedIcon: Icons.report_problem,
                label: 'Reclamos',
              ),
          ];

          if (widget.showCasinos) {
            items.add(
              _NavItem(
                index: 8,
                icon: Icons.casino_outlined,
                selectedIcon: Icons.casino,
                label: 'Casinos',
              ),
            );
          }

          if (widget.profilePageIndex >= 0) {
            items.add(
              _NavItem(
                index: widget.profilePageIndex,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Perfil',
              ),
            );
          }

          return FutureBuilder<List<bool>>(
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
              final displayItems = [
                ...items,
                if (hasSession && isAdmin)
                  const _NavItem(
                    index: 10,
                    icon: Icons.build_outlined,
                    selectedIcon: Icons.build_rounded,
                    label: 'Admin',
                  ),
              ].where((item) => !widget.hiddenIndexes.contains(item.index)).toList();
              final itemWidth = isDesktopWeb
                  ? media.size.width / displayItems.length
                  : mobileItemWidth;

              Widget navItems = Row(
                children: displayItems.map((item) {
                  final isSelected = selectedPage == item.index;
                  return GestureDetector(
                    onTap: () => saveSelectedPage(item.index),
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
                                      color: isSelected ? selectedColor : unselectedColor,
                                      size: iconSize,
                                    ),
                                  )
                                : Icon(
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Línea separadora neon
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
                          // Desktop web: Row simple, sin scroll, clicks directos
                          ? navItems
                          // Mobile: scroll horizontal con hint de gradiente
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
          );
        },
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final GlobalKey? tutorialKey;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.tutorialKey,
  });
}
