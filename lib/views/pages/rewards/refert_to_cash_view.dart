import 'dart:convert';
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefKeyCasino = 'refer_to_cash_casino';
const String _prefKeyCode = 'refer_to_cash_code';

class _CasinoData {
  final int? id;
  final String logoUrl;
  final String url;
  final String nombreGral;

  const _CasinoData({
    this.id,
    required this.logoUrl,
    required this.url,
    required this.nombreGral,
  });

  factory _CasinoData.fromJson(Map<String, dynamic> json) {
    return _CasinoData(
      id: json['id'] as int?,
      logoUrl: json['logoUrl']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      nombreGral: json['nombreGral']?.toString() ?? '',
    );
  }
}

class ReferToCashView extends StatefulWidget {
  const ReferToCashView({super.key});

  @override
  State<ReferToCashView> createState() => _ReferToCashViewState();
}

class _ReferToCashViewState extends State<ReferToCashView>
    with SingleTickerProviderStateMixin {
  _CasinoData? _selectedCasino;
  List<_CasinoData> _casinos = [];
  bool _loadingCasinos = true;
  bool _selectingCasino = false;
  String? _referCode;
  Map<String, dynamic>? _resumen;
  bool _loadingResumen = false;

  late final AnimationController _qrCtrl;
  late final Animation<double> _qrFade;
  late final Animation<double> _qrScale;

  @override
  void initState() {
    super.initState();
    _qrCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _qrFade = CurvedAnimation(parent: _qrCtrl, curve: Curves.easeOut);
    _qrScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _qrCtrl, curve: Curves.easeOutBack),
    );
    _loadCasinos();
    _loadResumen();
  }

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCasinos() async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/users/casinos_afiliados',
        includeAuth: true,
        cacheTtl: const Duration(seconds: 45),
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final loaded = data.map((e) => _CasinoData.fromJson(e)).toList();
          final prefs = await SharedPreferences.getInstance();
          final savedCasino = prefs.getString(_prefKeyCasino);
          final savedCode = prefs.getString(_prefKeyCode);
          final restored = savedCasino != null
              ? loaded.where((c) => c.nombreGral == savedCasino).firstOrNull
              : null;
          if (!mounted) return;
          setState(() {
            _casinos = loaded;
            _selectedCasino = restored;
            _referCode = savedCode;
            _loadingCasinos = false;
          });
          if (savedCode != null) _qrCtrl.forward(from: 1);
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCasinos = false);
  }

  Future<void> _loadResumen() async {
    if (!mounted) return;
    setState(() => _loadingResumen = true);
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/referidos/resumen',
        includeAuth: true,
        cacheTtl: const Duration(seconds: 30),
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _resumen = data;
          _loadingResumen = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingResumen = false);
  }

  Future<void> _selectCasino(_CasinoData casino) async {
    if (_selectingCasino || casino.id == null) return;
    final isFirstTime = _referCode == null;
    setState(() {
      _selectedCasino = casino;
      _selectingCasino = true;
    });
    try {
      final response = await HttpClient.post(
        '${ApiConfig.baseUrl}/referidos/casino',
        body: {'casinoId': casino.id},
        includeAuth: true,
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['codigo']?.toString();
        if (code != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKeyCasino, casino.nombreGral);
          await prefs.setString(_prefKeyCode, code);
          if (!mounted) return;
          setState(() {
            _referCode = code;
            _selectingCasino = false;
          });
          if (isFirstTime) _qrCtrl.forward(from: 0);
          _loadResumen();
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _selectingCasino = false);
  }

  String get _referUrl {
    final base = kIsWeb ? Uri.base.origin : 'https://app.boombet.com';
    return '$base/register?ref=${_referCode ?? ''}';
  }

  void _copyCode() {
    if (_referCode == null) return;
    Clipboard.setData(ClipboardData(text: _referCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Código copiado'),
        backgroundColor: AppConstants.primaryGreen.withValues(alpha: 0.15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: AppConstants.snackbarDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width > 600;
    final maxWidth = isLarge ? 800.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: _buildResponsiveAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isLarge ? 24 : 16,
                14,
                isLarge ? 24 : 16,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ① Instrucciones
                  _buildInstructions(),
                  const SizedBox(height: 14),

                  // ② Selector de casinos
                  _buildCasinoSelector(),
                  const SizedBox(height: 14),

                  // ③ Área del QR
                  Expanded(child: _buildQRArea()),
                  const SizedBox(height: 14),

                  // ④ Stats
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar() {
    final isLarge = MediaQuery.of(context).size.width > 600;

    return AppBar(
      backgroundColor: AppConstants.darkBg,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: isLarge
          ? _buildAppBarTitleDesktop()
          : _buildAppBarTitleMobile(),
      centerTitle: isLarge ? false : true,
      toolbarHeight: isLarge ? 70 : 80,
    );
  }

  Widget _buildAppBarTitleDesktop() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 12,
      children: [
        Image.asset(
          'assets/images/boombetlogo.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppConstants.primaryGreen, Color(0xFF7FFF9F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'REFER-TO-CASH',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Color(0xFF29FF5E),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarTitleMobile() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppConstants.primaryGreen, Color(0xFF7FFF9F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        'REFER-TO-CASH',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: AppConstants.primaryGreen.withValues(alpha: 0.5),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  // ① Instrucciones ─────────────────────────────────────────────────────────

  Widget _buildInstructions() {
    final isLarge = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 12,
        vertical: isLarge ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: AppConstants.darkCardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.borderDark),
      ),
      child: isLarge
          ? _buildInstructionsDesktop()
          : _buildInstructionsMobile(),
    );
  }

  Widget _buildInstructionsMobile() {
    return Row(
      children: const [
        _Step(icon: Icons.touch_app_rounded, label: 'Elegí\nun casino', step: 1),
        _StepConnector(),
        _Step(icon: Icons.qr_code_2_rounded, label: 'Se genera\ntu QR', step: 2),
        _StepConnector(),
        _Step(icon: Icons.share_rounded, label: 'Compartí\ny cobrá', step: 3),
      ],
    );
  }

  Widget _buildInstructionsDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _StepCompact(icon: Icons.touch_app_rounded, label: 'Elegí un casino', step: 1),
          SizedBox(width: 24),
          _StepConnectorVertical(),
          SizedBox(width: 24),
          _StepCompact(icon: Icons.qr_code_2_rounded, label: 'Se genera tu QR', step: 2),
          SizedBox(width: 24),
          _StepConnectorVertical(),
          SizedBox(width: 24),
          _StepCompact(icon: Icons.share_rounded, label: 'Compartí y cobrá', step: 3),
        ],
      ),
    );
  }

  // ② Casino selector ────────────────────────────────────────────────────────

  Widget _buildCasinoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedCasino == null ? 'Elegí dónde cobrar' : 'Casino de cobro',
              style: const TextStyle(
                fontSize: AppConstants.bodySmall,
                color: AppConstants.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            if (_selectedCasino != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedCasino!.nombreGral,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppConstants.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '· tocá para cambiar',
                style: TextStyle(fontSize: 10, color: Colors.white30),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildCasinoRow(),
      ],
    );
  }

  Widget _buildCasinoRow() {
    if (_loadingCasinos) {
      return const SizedBox(
        height: 78,
        child: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryGreen,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_casinos.isEmpty) {
      return Container(
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppConstants.darkCardBg,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppConstants.borderDark),
        ),
        child: const Text(
          'No hay casinos disponibles',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _casinos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _casinos[i];
          final selected = _selectedCasino?.nombreGral == c.nombreGral;
          return _CasinoChip(
            casino: c,
            selected: selected,
            loading: selected && _selectingCasino,
            onTap: () => _selectCasino(c),
          );
        },
      ),
    );
  }

  // ③ QR area ───────────────────────────────────────────────────────────────

  Widget _buildQRArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.darkCardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: _referCode != null
              ? AppConstants.primaryGreen.withValues(alpha: 0.35)
              : AppConstants.borderDark,
        ),
        boxShadow: _referCode != null
            ? [
                BoxShadow(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.07),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: _referCode != null
          ? _buildQRContent()
          : (_selectingCasino ? _buildQRLoading() : _buildQRPlaceholder()),
    );
  }

  Widget _buildQRLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryGreen,
            strokeWidth: 2.5,
          ),
          SizedBox(height: 14),
          Text(
            'Generando tu QR...',
            style: TextStyle(
              fontSize: AppConstants.bodyMedium,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 36,
              color: AppConstants.primaryGreen.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tu QR aparecerá aquí',
            style: TextStyle(
              fontSize: AppConstants.bodyMedium,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elegí un casino para generarlo',
            style: TextStyle(
              fontSize: AppConstants.bodyExtraSmall,
              color: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 600;
    // Restar: padding horizontal externo (16 o 24 c/lado) + padding QR area (20 c/lado) + padding container blanco (12 c/lado)
    final outerPad = (isLarge ? 24.0 : 16.0) * 2;
    final qrAreaPad = 20.0 * 2;
    final whitePad = 12.0 * 2;
    final availableWidth = screenWidth - outerPad - qrAreaPad - whitePad;
    const maxQrSize = 280.0;
    final size = availableWidth > 0
        ? (availableWidth > maxQrSize ? maxQrSize : availableWidth)
        : 220.0;

    return FadeTransition(
      opacity: _qrFade,
      child: ScaleTransition(
        scale: _qrScale,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _referUrl,
                version: QrVersions.auto,
                size: size,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ④ Stats ─────────────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryGreen.withValues(alpha: 0.1),
            AppConstants.darkCardBg,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppConstants.primaryGreen.withValues(alpha: 0.22),
        ),
      ),
      child: _loadingResumen
          ? const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          : _buildStatsContent(),
    );
  }

  Widget _buildStatsContent() {
    final total = (_resumen?['total'] as num?)?.toInt() ?? 0;
    final estaSemana = (_resumen?['estaSemana'] as num?)?.toInt() ?? 0;
    final pendientes = (_resumen?['pendientes'] as num?)?.toInt() ?? 0;
    final confirmados = (_resumen?['confirmados'] as num?)?.toInt() ?? 0;
    final acreditados = (_resumen?['acreditados'] as num?)?.toInt() ?? 0;
    final limSemRest = (_resumen?['limiteSemanRest'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppConstants.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total referidos totales',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppConstants.headingSmall,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryGreen,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    'Total acumulado',
                    style: TextStyle(
                      fontSize: AppConstants.captionSize,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '+$estaSemana',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryGreen,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'esta semana',
                    style: TextStyle(fontSize: 9, color: Colors.white38),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _StateBadge(
                    label: 'Pendientes',
                    count: pendientes,
                    color: Colors.orange,
                  ),
                  _StateBadge(
                    label: 'Confirmados',
                    count: confirmados,
                    color: AppConstants.primaryGreen,
                  ),
                  _StateBadge(
                    label: 'Acreditados',
                    count: acreditados,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$limSemRest / 20 disp.',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(
          color: AppConstants.primaryGreen.withValues(alpha: 0.12),
          height: 1,
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: _showReferidosSheet,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: const [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 13,
                  color: Colors.white38,
                ),
                SizedBox(width: 6),
                Text(
                  'Ver mis referidos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReferidosSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => const _ReferidosBottomSheet(),
    );
  }
}

// ─── Step widget ──────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final IconData icon;
  final String label;
  final int step;

  const _Step({
    required this.icon,
    required this.label,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: AppConstants.primaryGreen),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppConstants.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      child: Divider(
        color: AppConstants.primaryGreen.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}

class _StepConnectorVertical extends StatelessWidget {
  const _StepConnectorVertical();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Divider(
        color: AppConstants.primaryGreen.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}

class _StepCompact extends StatelessWidget {
  final IconData icon;
  final String label;
  final int step;

  const _StepCompact({
    required this.icon,
    required this.label,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: AppConstants.primaryGreen),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppConstants.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ─── Casino chip ──────────────────────────────────────────────────────────────

class _CasinoChip extends StatelessWidget {
  final _CasinoData casino;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  const _CasinoChip({
    required this.casino,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 76,
        decoration: BoxDecoration(
          color: selected
              ? AppConstants.primaryGreen.withValues(alpha: 0.1)
              : AppConstants.darkCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppConstants.primaryGreen : AppConstants.borderDark,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.18),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  casino.logoUrl.isNotEmpty
                      ? Image.network(
                          casino.logoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.casino_rounded,
                            color: selected
                                ? AppConstants.primaryGreen
                                : Colors.white38,
                            size: 26,
                          ),
                        )
                      : Icon(
                          Icons.casino_rounded,
                          color: selected
                              ? AppConstants.primaryGreen
                              : Colors.white38,
                          size: 26,
                        ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      casino.nombreGral,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: selected ? AppConstants.primaryGreen : Colors.white54,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── State badge ──────────────────────────────────────────────────────────────

class _StateBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StateBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Referidos bottom sheet ───────────────────────────────────────────────────

class _ReferidosBottomSheet extends StatefulWidget {
  const _ReferidosBottomSheet();

  @override
  State<_ReferidosBottomSheet> createState() => _ReferidosBottomSheetState();
}

class _ReferidosBottomSheetState extends State<_ReferidosBottomSheet> {
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 0;
  bool _isLast = false;
  int _total = 0;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (page == 0) {
      setState(() => _loading = true);
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final response = await HttpClient.get(
        '${ApiConfig.baseUrl}/referidos/mis-referidos?page=$page&size=$_pageSize',
        includeAuth: true,
      );
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['content'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        setState(() {
          if (page == 0) _items.clear();
          _items.addAll(content);
          _isLast = data['last'] as bool? ?? true;
          _total = (data['totalElements'] as num?)?.toInt() ?? 0;
          _page = page;
          _loading = false;
          _loadingMore = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'CONFIRMADO':
        return AppConstants.primaryGreen;
      case 'ACREDITADO':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      return '${dt.day} ${months[dt.month - 1]}. ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis referidos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!_loading)
                      Text(
                        '$_total en total',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                ),
              ],
            ),
          ),
          Divider(
            color: AppConstants.primaryGreen.withValues(alpha: 0.12),
            height: 1,
          ),
          // Body
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _items.length + (_isLast ? 0 : 1),
                        separatorBuilder: (_, __) => Divider(
                          color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        itemBuilder: (_, i) {
                          if (i == _items.length) return _buildLoadMore();
                          return _buildItem(_items[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final estado = item['estado']?.toString() ?? '';
    final username = item['usernameDestino']?.toString() ?? '-';
    final fecha = item['fechaAfiliacion']?.toString() ?? '';
    final color = _estadoColor(estado);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@$username',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fecha.isNotEmpty)
                Text(
                  _formatFecha(fecha),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  estado,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: Colors.white24,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Todavía no tenés referidos',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compartí tu QR para empezar',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryGreen,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _loadPage(_page + 1),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.darkCardBg,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppConstants.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: Text(
            'Cargar más',
            style: TextStyle(
              color: AppConstants.primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
