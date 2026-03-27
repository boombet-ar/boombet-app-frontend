import 'dart:convert';
import 'dart:math' as math;
import 'package:boombet_app/config/api_config.dart';
import 'package:boombet_app/config/app_constants.dart';
import 'package:boombet_app/core/notifiers.dart';
import 'package:boombet_app/models/player_model.dart';
import 'package:boombet_app/services/affiliation_service.dart';
import 'package:boombet_app/services/http_client.dart';
import 'package:boombet_app/services/player_service.dart';
import 'package:boombet_app/services/websocket_url_service.dart';
import 'package:boombet_app/views/pages/home/limited_home_page.dart';
import 'package:boombet_app/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';

class IsNotAffiliatedPage extends StatefulWidget {
  const IsNotAffiliatedPage({super.key});

  @override
  State<IsNotAffiliatedPage> createState() => _IsNotAffiliatedPageState();
}

class _IsNotAffiliatedPageState extends State<IsNotAffiliatedPage>
    with TickerProviderStateMixin {
  final AffiliationService _affiliationService = AffiliationService();
  final PlayerService _playerService = PlayerService();
  bool _isProcessing = false;
  final List<String> _logs = [];
  final ScrollController _logsScrollController = ScrollController();

  late final AnimationController _pulseController;
  late final AnimationController _entranceController;

  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    criticalFlowActive = true;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _buttonScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    criticalFlowActive = false;
    _pulseController.dispose();
    _entranceController.dispose();
    _logsScrollController.dispose();
    super.dispose();
  }

  void _log(String message) {
    if (!AppConstants.isNotAffiliatedDebugConsoleEnabled) return;
    setState(() => _logs.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logsScrollController.hasClients) {
        _logsScrollController.animateTo(
          _logsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _comenzarExperiencia() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    LoadingOverlay.show(context, message: 'Iniciando tu experiencia...');

    try {
      _log('Fetching player data...');
      PlayerData playerData;
      try {
        playerData = await _playerService.getCurrentUserPlayerData();
        _log('Player data OK: ${playerData.nombre} ${playerData.apellido}');
      } catch (e) {
        _log('❌ Error fetching player data: $e');
        if (!mounted) return;
        LoadingOverlay.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron obtener tus datos. Intentá de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final wsUrl = WebSocketUrlService.generateAffiliationUrl();
      _log('wsUrl: $wsUrl');
      await saveAffiliationWsUrl(wsUrl);

      final payload = {
        'websocketLink': wsUrl,
        'playerData': {
          'nombre': playerData.nombre,
          'apellido': playerData.apellido,
          'email': playerData.correoElectronico,
          'telefono': playerData.telefono,
          'genero': playerData.sexo,
          'dni': playerData.dni,
          'cuit': playerData.cuil,
          'calle': playerData.calle,
          'numCalle': playerData.numCalle,
          'provincia': playerData.provincia,
          'ciudad': playerData.localidad,
          'cp': playerData.cp?.toString() ?? '',
          'user': playerData.username,
          'password': affiliationPasswordNotifier.value,
          'fecha_nacimiento': playerData.fechaNacimiento,
          'est_civil': playerData.estadoCivil,
        },
      };

      final url = '${ApiConfig.baseUrl}/users/auth/affiliate';
      _log('POST $url');
      _log('payload: ${jsonEncode(payload)}');

      final response = await HttpClient.post(url, body: payload);

      if (!mounted) return;
      LoadingOverlay.hide(context);

      _log('status: ${response.statusCode}');
      _log('body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log('✅ Afiliación exitosa. Conectando WebSocket...');
        affiliationPasswordNotifier.value = '';
        _affiliationService
            .connectToWebSocket(wsUrl: wsUrl, token: '')
            .catchError((e) => _log('WS error: $e'));

        await saveAffiliationFlowRoute('/limited-home');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LimitedHomePage(
              affiliationService: _affiliationService,
              wsUrl: wsUrl,
            ),
          ),
        );
      } else {
        String errorMsg = 'Error al iniciar la afiliación';
        try {
          final decoded = jsonDecode(response.body);
          errorMsg = decoded['message'] ?? decoded['mensaje'] ?? errorMsg;
        } catch (_) {}

        _log('❌ Error: $errorMsg');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      _log('❌ Excepción: $e');
      if (!mounted) return;
      LoadingOverlay.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión. Intentá de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [
                    AppConstants.primaryGreen.withValues(alpha: 0.03),
                    AppConstants.darkBg,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 40),
                      _buildTitle(),
                      const SizedBox(height: 52),
                      _buildCTAButton(),
                    ],
                  ),
                ),
              ),),
            ),
          ),
          if (AppConstants.isNotAffiliatedDebugConsoleEnabled) _buildConsole(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (_, child) {
          final v = _pulseController.value;
          final v2 = (v + 0.5) % 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Transform.scale(
                scale: 1.0 + v * 0.55,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryGreen
                          .withValues(alpha: (1 - v) * 0.14),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Inner ring (offset phase)
              Transform.scale(
                scale: 1.0 + v2 * 0.38,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppConstants.primaryGreen
                          .withValues(alpha: (1 - v2) * 0.09),
                      width: 1,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppConstants.darkAccent,
            border: Border.all(
              color: AppConstants.primaryGreen.withValues(alpha: 0.28),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryGreen.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Image.asset(
            'assets/images/boombetlogo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            Text(
              'Activá tu cuenta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Un último paso para acceder a todo\nlo que BoomBet tiene para vos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppConstants.bodyMedium,
                color: AppConstants.textDark.withValues(alpha: 0.5),
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    return FadeTransition(
      opacity: _buttonFade,
      child: ScaleTransition(
        scale: _buttonScale,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            final pulse =
                (math.sin(_pulseController.value * math.pi * 2) + 1) / 2;
            return Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryGreen
                        .withValues(alpha: 0.12 + pulse * 0.10),
                    blurRadius: 14 + pulse * 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: SizedBox(
            width: double.infinity,
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _comenzarExperiencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    AppConstants.primaryGreen.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Comenzar mi experiencia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsole() {
    return Container(
      height: 200,
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text(
                  'DEBUG CONSOLE',
                  style: TextStyle(
                    color: AppConstants.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _logs.clear()),
                  child: const Text(
                    'limpiar',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _logsScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (_, i) => Text(
                _logs[i],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
