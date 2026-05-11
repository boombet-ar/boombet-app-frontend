import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/models/affiliated_casino_model.dart';
import 'package:boombet_app/services/casino_service.dart';
import 'package:boombet_app/views/widgets/casino/casino_card.dart';
import 'package:flutter/material.dart';

class CasinoVerificationPage extends StatefulWidget {
  const CasinoVerificationPage({super.key});

  @override
  State<CasinoVerificationPage> createState() => _CasinoVerificationPageState();
}

class _CasinoVerificationPageState extends State<CasinoVerificationPage> {
  final _service = CasinoService();

  List<AffiliatedCasino> _casinos = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getAffiliatedCasinos();
      if (!mounted) return;
      setState(() {
        _casinos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        backgroundColor: AppConstants.darkBg,
        foregroundColor: AppConstants.primaryGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Verificación de Casinos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppConstants.textDark,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _casinos.isEmpty) return const _LoadingState();
    if (_error != null && _casinos.isEmpty) return _ErrorState(onRetry: _load);
    if (_casinos.isEmpty) return _EmptyState(onRefresh: _load);
    return _CasinoList(casinos: _casinos, onRefresh: _load);
  }
}

// ── Lista principal ────────────────────────────────────────────────────────

class _CasinoList extends StatelessWidget {
  final List<AffiliatedCasino> casinos;
  final Future<void> Function() onRefresh;

  const _CasinoList({required this.casinos, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppConstants.primaryGreen,
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const _PageHeader(),
          ...casinos.map(
            (casino) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CasinoCard(casino: casino),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryGreen.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.verified_outlined,
              size: 22,
              color: AppConstants.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus casinos afiliados',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textDark,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Verificá tu afiliación ingresando tu ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textDark.withValues(alpha: 0.5),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estados ────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppConstants.primaryGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando casinos...',
            style: TextStyle(
              fontSize: 13,
              color: AppConstants.textDark.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppConstants.textDark.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los casinos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textDark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppConstants.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    // También scrolleable para que pull-to-refresh funcione en estado vacío
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppConstants.primaryGreen,
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.casino_outlined,
                  size: 48,
                  color: AppConstants.textDark.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tenés casinos afiliados aún',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textDark.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
