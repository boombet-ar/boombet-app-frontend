import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/config/debug_affiliation_previews.dart';
import 'package:boombet_app/models/afiliador_model.dart';
import 'package:boombet_app/models/evento_model.dart';
import 'package:boombet_app/models/tid_model.dart';
import 'package:boombet_app/services/affiliates_service.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/eventos_service.dart';
import 'package:boombet_app/services/tids_service.dart';
import 'package:boombet_app/views/pages/admin/admin_tools_page.dart';
import 'package:boombet_app/views/pages/admin/ads/ad_management_view.dart';
import 'package:boombet_app/views/pages/admin/ads/create_ad.dart';
import 'package:boombet_app/views/pages/admin/affiliates/affiliates_management_view.dart';
import 'package:boombet_app/views/pages/admin/affiliates/create_affiliate.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/create_tid.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/evento_dropdown.dart';
import 'package:boombet_app/views/pages/affiliates/TIDs/tids_management_view.dart';
import 'package:boombet_app/views/pages/affiliates/affiliates_tools_page.dart';
import 'package:boombet_app/views/pages/affiliates/events/create_event.dart';
import 'package:boombet_app/views/pages/affiliates/events/event_detail_page.dart';
import 'package:boombet_app/views/pages/affiliates/events/event_management_view.dart';
import 'package:boombet_app/views/pages/auth/confirm_player_data_page.dart';
import 'package:boombet_app/views/pages/auth/email_confirmation_page.dart';
import 'package:boombet_app/views/pages/auth/forget_password_page.dart';
import 'package:boombet_app/views/pages/auth/login_page.dart';
import 'package:boombet_app/views/pages/auth/register_page.dart';
import 'package:boombet_app/views/pages/auth/reset_password_page.dart';
import 'package:boombet_app/views/pages/community/forum_page.dart';
import 'package:boombet_app/views/pages/community/forum_post_detail_page.dart';
import 'package:boombet_app/views/pages/games/games_page.dart';
import 'package:boombet_app/views/pages/games/play_roulette_page.dart';
import 'package:boombet_app/views/pages/home/home_page.dart' as home_main;
import 'package:boombet_app/views/pages/home/limited_home_page.dart';
import 'package:boombet_app/views/pages/home/widgets/claimed_coupons_content.dart';
import 'package:boombet_app/views/pages/home/widgets/discounts_content.dart';
import 'package:boombet_app/views/pages/home/widgets/games_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_content.dart';
import 'package:boombet_app/views/pages/home/widgets/home_login_tutorial_overlay.dart';
import 'package:boombet_app/views/pages/home/widgets/home_page.dart'
    as home_widgets;
import 'package:boombet_app/views/pages/home/widgets/loading_badge.dart';
import 'package:boombet_app/views/pages/home/widgets/pagination_bar.dart';
import 'package:boombet_app/views/pages/home/widgets/section_headers.dart';
import 'package:boombet_app/views/pages/other/affiliation_results_page.dart';
import 'package:boombet_app/views/pages/other/faq_page.dart';
import 'package:boombet_app/views/pages/other/my_casinos_page.dart';
import 'package:boombet_app/views/pages/other/no_casinos_available_page.dart';
import 'package:boombet_app/views/pages/other/onboarding_page.dart';
import 'package:boombet_app/views/pages/other/qr_scanner_page.dart';
import 'package:boombet_app/views/pages/other/unaffiliate_result_page.dart';
import 'package:boombet_app/views/pages/profile/edit_profile_page.dart';
import 'package:boombet_app/views/pages/profile/profile_page.dart';
import 'package:boombet_app/views/pages/profile/settings_page.dart';
import 'package:boombet_app/views/pages/rewards/discounts_page.dart';
import 'package:boombet_app/views/pages/rewards/my_prizes_page.dart';
import 'package:boombet_app/views/pages/rewards/raffles_page.dart';
import 'package:flutter/material.dart';

class DebugViewsMenuPage extends StatelessWidget {
  const DebugViewsMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_DebugEntry>[
      _DebugEntry('Auth: LoginPage', () => const LoginPage()),
      _DebugEntry('Auth: RegisterPage', () => const RegisterPage()),
      _DebugEntry('Auth: ForgetPasswordPage', () => const ForgetPasswordPage()),
      _DebugEntry(
        'Auth: ResetPasswordPage (preview)',
        () => const ResetPasswordPage(token: 'debug-token', preview: true),
      ),
      _DebugEntry('Auth: ConfirmPlayerDataPage (preview)', () {
        final p = DebugAffiliationPreviews.samplePlayerData();
        return ConfirmPlayerDataPage(
          playerData: p,
          email: p.correoElectronico,
          username: p.username,
          password: 'debug-pass',
          dni: p.dni,
          telefono: p.telefono,
          genero: p.sexo,
          preview: true,
        );
      }),
      _DebugEntry('Auth: EmailConfirmationPage (preview)', () {
        final p = DebugAffiliationPreviews.samplePlayerData();
        return EmailConfirmationPage(
          playerData: p,
          email: p.correoElectronico,
          username: p.username,
          password: 'debug-pass',
          dni: p.dni,
          telefono: p.telefono,
          genero: p.sexo,
          verificacionToken: 'debug-token',
          isFromDeepLink: true,
          preview: true,
        );
      }),
      _DebugEntry('Home: HomePage', () => const home_main.HomePage()),
      _DebugEntry(
        'Home Widgets: HomePage',
        () => const home_widgets.HomePage(),
      ),
      _DebugEntry(
        'Home: LimitedHomePage (preview)',
        () => LimitedHomePage(
          affiliationService: AffiliationService(),
          preview: true,
          previewStatusMessage: 'Preview de flujo limitado',
        ),
      ),
      _DebugEntry('Community: ForumPage', () => const ForumPage()),
      _DebugEntry(
        'Community: ForumPostDetailPage',
        () => const ForumPostDetailPage(postId: 1),
      ),
      _DebugEntry('Games: GamesPage', () => const GamesPage()),
      _DebugEntry(
        'Games: PlayRoulettePage',
        () => const PlayRoulettePage(codigoRuleta: 'DEBUG-RULETA-01'),
      ),
      _DebugEntry('Rewards: DiscountsPage', () => const DiscountsPage()),
      _DebugEntry('Rewards: RafflesPage', () => const RafflesPage()),
      _DebugEntry('Rewards: MyPrizesPage', () => const MyPrizesPage()),
      _DebugEntry(
        'Other: AffiliationResultsPage (preview)',
        () => AffiliationResultsPage(
          result: DebugAffiliationPreviews.sampleAffiliationResult(),
          preview: true,
        ),
      ),
      _DebugEntry('Other: FaqPage', () => const FaqPage()),
      _DebugEntry('Other: MyCasinosPage', () => const MyCasinosPage()),
      _DebugEntry(
        'Other: NoCasinosAvailablePage (preview)',
        () => const NoCasinosAvailablePage(preview: true),
      ),
      _DebugEntry(
        'Other: OnboardingPage',
        () => OnboardingPage(onComplete: () {}),
      ),
      _DebugEntry('Other: QrScannerPage', () => const QrScannerPage()),
      _DebugEntry(
        'Other: UnaffiliateResultPage (preview)',
        () => const UnaffiliateResultPage(preview: true),
      ),
      _DebugEntry('Profile: ProfilePage', () => const ProfilePage()),
      _DebugEntry(
        'Profile: EditProfilePage',
        () => EditProfilePage(
          player: DebugAffiliationPreviews.samplePlayerData(),
        ),
      ),
      _DebugEntry('Profile: SettingsPage', () => const SettingsPage()),
      _DebugEntry('Admin: AdminToolsPage', () => const AdminToolsPage()),
      _DebugEntry('Admin: AdManagementView', () => const AdManagementView()),
      _DebugEntry(
        'Admin Ads: CreateAdSection',
        () => Scaffold(
          appBar: AppBar(title: const Text('CreateAdSection')),
          body: const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: CreateAdSection(),
            ),
          ),
        ),
      ),
      _DebugEntry(
        'Affiliates: AffiliatesToolsPage',
        () => const AffiliatesToolsPage(),
      ),
      _DebugEntry(
        'Affiliates Events: EventDetailPage',
        () => EventDetailPage(
          eventoId: 1,
          evento: const EventoModel(
            id: 1,
            nombre: 'Evento Debug',
            activo: true,
            fechaFin: '2030-12-31T23:59:00',
            idAfiliador: 1,
          ),
        ),
      ),
      _DebugEntry(
        'Affiliates Events: EventManagementView',
        () => _simpleScaffold(
          title: 'EventManagementView',
          child: EventManagementView(
            onCreate: () {},
            items: const [
              EventoModel(
                id: 1,
                nombre: 'Evento Mock 1',
                activo: true,
                fechaFin: '2030-01-01T10:00:00',
                idAfiliador: 2,
              ),
              EventoModel(
                id: 2,
                nombre: 'Evento Mock 2',
                activo: false,
                fechaFin: '2030-06-15T18:30:00',
                idAfiliador: 2,
              ),
            ],
            totalItems: 2,
            isLoading: false,
            errorMessage: null,
            page: 0,
            totalPages: 1,
            pageSize: 10,
            isFirstPage: true,
            isLastPage: true,
            updatingIds: const {},
            deletingIds: const {},
            onRetry: () {},
            onGoToPage: (_) {},
            onToggleActive: (_, __) {},
            onDelete: (_) {},
            onViewAffiliations: (_) {},
          ),
        ),
      ),
      _DebugEntry(
        'Affiliates TIDs: TidsManagementView',
        () => _simpleScaffold(
          title: 'TidsManagementView',
          child: TidsManagementView(
            onCreate: () {},
            items: const [
              TidModel(
                id: 1,
                tid: 'TID-ABC-001',
                idEvento: 1,
                idAfiliador: 2,
                eventoNombre: 'Evento Mock',
              ),
            ],
            totalItems: 1,
            isLoading: false,
            errorMessage: null,
            editingIds: const {},
            deletingIds: const {},
            onRetry: () {},
            onEdit: (_) {},
            onDelete: (_) {},
            onViewAffiliations: (_) {},
            eventoNames: const {1: 'Evento Mock'},
          ),
        ),
      ),
      _DebugEntry(
        'Admin Affiliates: AffiliatesManagementeView',
        () => _simpleScaffold(
          title: 'AffiliatesManagementeView',
          child: AffiliatesManagementeView(
            onCreate: () {},
            items: const [
              AfiliadorModel(
                id: 1,
                nombre: 'Afiliador Mock',
                tokenAfiliador: 'token-debug',
                tipoAfiliador: 'CASINO',
                cantAfiliaciones: 12,
                activo: true,
                email: 'afiliador@example.com',
                dni: '30111222',
                telefono: '1122334455',
              ),
            ],
            isLoading: false,
            errorMessage: null,
            totalElements: 1,
            page: 0,
            totalPages: 1,
            pageSize: 10,
            isFirstPage: true,
            isLastPage: true,
            updatingIds: const {},
            deletingIds: const {},
            onRetry: () {},
            onGoToPage: (_) {},
            onToggleActive: (_, __) {},
            onDelete: (_) {},
            onViewAffiliations: (_) {},
          ),
        ),
      ),
      _DebugEntry(
        'Widgets: HomeContent',
        () => _simpleScaffold(title: 'HomeContent', child: HomeContent()),
      ),
      _DebugEntry(
        'Widgets: DiscountsContent',
        () => _simpleScaffold(
          title: 'DiscountsContent',
          child: const DiscountsContent(),
        ),
      ),
      _DebugEntry(
        'Widgets: ClaimedCouponsContent',
        () => _simpleScaffold(
          title: 'ClaimedCouponsContent',
          child: const ClaimedCouponsContent(),
        ),
      ),
      _DebugEntry(
        'Widgets: GamesContent',
        () =>
            _simpleScaffold(title: 'GamesContent', child: const GamesContent()),
      ),
      _DebugEntry(
        'Widgets: EventoDropdown',
        () => _simpleScaffold(
          title: 'EventoDropdown',
          child: EventoDropdown(
            options: const [
              EventoOption(id: null, label: 'Sin evento'),
              EventoOption(id: 1, label: 'Evento A'),
            ],
            selectedId: null,
            accent: AppConstants.primaryGreen,
            onChanged: (_) {},
          ),
        ),
      ),
      _DebugEntry(
        'Widgets: PaginationBar',
        () => _simpleScaffold(
          title: 'PaginationBar',
          child: PaginationBar(
            currentPage: 2,
            canGoPrevious: true,
            canGoNext: true,
            onPrev: () {},
            onNext: () {},
            primaryColor: AppConstants.primaryGreen,
            textColor: AppConstants.textDark,
          ),
        ),
      ),
      _DebugEntry(
        'Widgets: LoadingBadge',
        () => _simpleScaffold(
          title: 'LoadingBadge',
          child: const LoadingBadge(color: AppConstants.primaryGreen),
        ),
      ),
      _DebugEntry(
        'Widgets: section_headers.dart',
        () => _simpleScaffold(
          title: 'section_headers',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildSectionHeader(
                'Titulo',
                'Subtitulo demo',
                Icons.star_outline,
                AppConstants.primaryGreen,
                true,
              ),
              const SizedBox(height: 12),
              buildSectionHeaderWithSwitch(
                'Con switch',
                'Preview del helper con switch',
                Icons.tune,
                AppConstants.primaryGreen,
                true,
                isShowingClaimed: false,
                onSwitchPressed: () {},
              ),
            ],
          ),
        ),
      ),
      _DebugEntry(
        'Widgets: HomeLoginTutorialOverlay',
        () => const _HomeTutorialOverlayPreviewPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Views Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + 3,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const ListTile(
              title: Text('Cobertura de lib/views/pages y subcarpetas'),
              subtitle: Text(
                'Las vistas que dependen de backend pueden mostrar errores si no hay datos.',
              ),
            );
          }
          if (index == 1) {
            return ListTile(
              title: const Text('Dialogs: showCreateAffiliateDialog'),
              subtitle: const Text('Abre el dialog con servicios reales.'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                showCreateAffiliateDialog(
                  context: context,
                  service: AfiliadoresService(),
                  onCreated: () {},
                );
              },
            );
          }
          if (index == 2) {
            return ListTile(
              title: const Text('Dialogs: showCreateEventoDialog'),
              subtitle: const Text('Abre el dialog con servicios reales.'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                showCreateEventoDialog(
                  context: context,
                  eventosService: EventosService(),
                  onCreated: () {},
                );
              },
            );
          }

          final entry = entries[index - 3];
          return ListTile(
            title: Text(entry.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => entry.builder()));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showCreateTidDialog(
            context: context,
            tidsService: TidsService(),
            onCreated: () {},
            eventoOptions: const [
              EventoOption(id: null, label: 'Sin evento'),
              EventoOption(id: 1, label: 'Evento Demo'),
            ],
          );
        },
        label: const Text('Dialog: CreateTid'),
        icon: const Icon(Icons.add_link),
      ),
    );
  }

  static Widget _simpleScaffold({
    required String title,
    required Widget child,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _DebugEntry {
  final String title;
  final Widget Function() builder;

  _DebugEntry(this.title, this.builder);
}

class _HomeTutorialOverlayPreviewPage extends StatelessWidget {
  const _HomeTutorialOverlayPreviewPage();

  @override
  Widget build(BuildContext context) {
    final inicioKey = GlobalKey();
    final descuentosKey = GlobalKey();
    final sorteosKey = GlobalKey();
    final foroKey = GlobalKey();
    final juegosKey = GlobalKey();
    final firstCouponKey = GlobalKey();
    final firstGameKey = GlobalKey();
    final faqKey = GlobalKey();
    final profileKey = GlobalKey();
    final settingsKey = GlobalKey();
    final logoutKey = GlobalKey();
    final claimedSwitchKey = GlobalKey();
    final forumBoomBetKey = GlobalKey();
    final forumAddPostKey = GlobalKey();
    final forumMyPostsKey = GlobalKey();

    Widget target(GlobalKey key, String text) {
      return Container(
        key: key,
        width: 110,
        height: 38,
        alignment: Alignment.center,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.4),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('HomeLoginTutorialOverlay')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                target(inicioKey, 'Inicio'),
                target(descuentosKey, 'Descuentos'),
                target(sorteosKey, 'Sorteos'),
                target(foroKey, 'Foro'),
                target(juegosKey, 'Juegos'),
                target(firstCouponKey, 'FirstCoupon'),
                target(firstGameKey, 'FirstGame'),
                target(faqKey, 'FAQ'),
                target(profileKey, 'Profile'),
                target(settingsKey, 'Settings'),
                target(logoutKey, 'Logout'),
                target(claimedSwitchKey, 'ClaimedSwitch'),
                target(forumBoomBetKey, 'ForumBoomBet'),
                target(forumAddPostKey, 'ForumAddPost'),
                target(forumMyPostsKey, 'ForumMyPosts'),
              ],
            ),
          ),
          HomeLoginTutorialOverlay(
            onClose: () => Navigator.of(context).maybePop(),
            inicioTargetKey: inicioKey,
            descuentosTargetKey: descuentosKey,
            sorteosTargetKey: sorteosKey,
            foroTargetKey: foroKey,
            juegosTargetKey: juegosKey,
            firstCouponTargetKey: firstCouponKey,
            firstGameTargetKey: firstGameKey,
            faqTargetKey: faqKey,
            profileTargetKey: profileKey,
            settingsTargetKey: settingsKey,
            logoutTargetKey: logoutKey,
            claimedSwitchTargetKey: claimedSwitchKey,
            forumBoomBetTargetKey: forumBoomBetKey,
            forumAddPostTargetKey: forumAddPostKey,
            forumMyPostsTargetKey: forumMyPostsKey,
            onRequestOpenDiscounts: () {},
            onRequestOpenRaffles: () {},
            onRequestOpenForum: () {},
            onRequestOpenGames: () {},
            onRequestOpenClaimedCoupons: () {},
          ),
        ],
      ),
    );
  }
}
