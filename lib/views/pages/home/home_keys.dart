import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:flutter/material.dart';

/// GlobalKeys estáticos y mapa de rutas compartidos entre el shell de
/// navegación (HomePage) y los widgets de cada branch.
class HomePageKeys {
  HomePageKeys._();

  // ── Constantes de ruta ─────────────────────────────────────────────
  static const String home      = '/home';
  static const String discounts = '/discounts';
  static const String raffles   = '/raffles';
  static const String forum     = '/forum';
  static const String games     = '/games';
  static const String scanner   = '/scanner';
  static const String settings  = '/settings';
  static const String prizes    = '/prizes';
  static const String casinos   = '/casinos';
  static const String profile   = '/profile';
  static const String admin     = '/admin';
  static const String claims       = '/claims';
  static const String profileEdit     = '/profile/edit';
  static const String faq             = '/faq';
  static const String forgotPassword  = '/forgot-password';
  static const String referToCash     = '/refer-to-cash';

  // ── Mapas de conversión índice ↔ ruta ─────────────────────────────
  // Orden: Descuentos, Club, Juegos, Sorteos, Premios, Foro, Casinos, Ajustes, Admin, Claims, Scanner
  static const Map<int, String> indexToRoute = {
    0:  discounts,
    1:  home,
    2:  games,
    3:  raffles,
    4:  prizes,
    5:  forum,
    6:  casinos,
    7:  settings,
    8:  admin,
    9:  claims,
    10: scanner,
  };

  static const Map<String, int> routeToIndex = {
    discounts: 0,
    home:      1,
    games:     2,
    raffles:   3,
    prizes:    4,
    forum:     5,
    casinos:   6,
    settings:  7,
    admin:     8,
    claims:    9,
    scanner:   10,
  };

  /// Devuelve el índice correspondiente a [path], o 0 si no hay coincidencia.
  static int indexForPath(String path) {
    for (final entry in routeToIndex.entries) {
      if (path == entry.key || path.startsWith('${entry.key}/')) {
        return entry.value;
      }
    }
    return 0;
  }

  /// Lista ordenada de todas las rutas del shell.
  static List<String> get allRoutes => indexToRoute.values.toList();

  // ── Keys para DiscountsContent ↔ ClaimedCouponsContent ────────────
  static final GlobalKey<DiscountsContentState> discountsKey =
      GlobalKey<DiscountsContentState>();
  static final GlobalKey<ClaimedCouponsContentState> claimedKey =
      GlobalKey<ClaimedCouponsContentState>();

  // ── Keys para el tutorial – NavBar ────────────────────────────────
  static final GlobalKey inicioNavbarKey     = GlobalKey();
  static final GlobalKey descuentosNavbarKey = GlobalKey();
  static final GlobalKey sorteosNavbarKey    = GlobalKey();
  static final GlobalKey foroNavbarKey       = GlobalKey();
  static final GlobalKey juegosNavbarKey     = GlobalKey();
  static final GlobalKey premiosNavbarKey    = GlobalKey();
  static final GlobalKey ajustesNavbarKey    = GlobalKey();

  // ── Keys para el tutorial – AppBar ────────────────────────────────
  static final GlobalKey faqAppbarKey      = GlobalKey();
  static final GlobalKey profileAppbarKey  = GlobalKey();
  static final GlobalKey settingsAppbarKey = GlobalKey();
  static final GlobalKey logoutAppbarKey   = GlobalKey();

  // ── Keys para el tutorial – Páginas hijas ─────────────────────────
  static final GlobalKey firstCouponKey          = GlobalKey();
  static final GlobalKey claimedSwitchKey        = GlobalKey();
  static final GlobalKey firstGameKey            = GlobalKey();
  static final GlobalKey forumBoomBetSelectorKey = GlobalKey();
  static final GlobalKey forumAddPostKey         = GlobalKey();
  static final GlobalKey forumMyPostsKey         = GlobalKey();
}
