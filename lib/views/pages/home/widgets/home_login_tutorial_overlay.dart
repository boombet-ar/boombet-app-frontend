import 'package:flutter/material.dart';

class HomeLoginTutorialOverlay extends StatefulWidget {
  const HomeLoginTutorialOverlay({
    super.key,
    required this.onClose,
    required this.inicioTargetKey,
    required this.descuentosTargetKey,
    required this.sorteosTargetKey,
    required this.foroTargetKey,
    required this.juegosTargetKey,
    required this.firstCouponTargetKey,
    required this.firstGameTargetKey,
    required this.faqTargetKey,
    required this.profileTargetKey,
    required this.settingsTargetKey,
    required this.logoutTargetKey,
    required this.claimedSwitchTargetKey,
    required this.forumBoomBetTargetKey,
    required this.forumAddPostTargetKey,
    required this.forumMyPostsTargetKey,
    required this.onRequestOpenDiscounts,
    required this.onRequestOpenRaffles,
    required this.onRequestOpenForum,
    required this.onRequestOpenGames,
    required this.onRequestOpenClaimedCoupons,
    this.onTutorialCompleted,
  });

  final VoidCallback onClose;
  final GlobalKey inicioTargetKey;
  final GlobalKey descuentosTargetKey;
  final GlobalKey sorteosTargetKey;
  final GlobalKey foroTargetKey;
  final GlobalKey juegosTargetKey;
  final GlobalKey firstCouponTargetKey;
  final GlobalKey firstGameTargetKey;
  final GlobalKey faqTargetKey;
  final GlobalKey profileTargetKey;
  final GlobalKey settingsTargetKey;
  final GlobalKey logoutTargetKey;
  final GlobalKey claimedSwitchTargetKey;
  final GlobalKey forumBoomBetTargetKey;
  final GlobalKey forumAddPostTargetKey;
  final GlobalKey forumMyPostsTargetKey;
  final VoidCallback onRequestOpenDiscounts;
  final VoidCallback onRequestOpenRaffles;
  final VoidCallback onRequestOpenForum;
  final VoidCallback onRequestOpenGames;
  final VoidCallback onRequestOpenClaimedCoupons;
  final Future<void> Function()? onTutorialCompleted;

  @override
  State<HomeLoginTutorialOverlay> createState() =>
      _HomeLoginTutorialOverlayState();
}

class _HomeLoginTutorialOverlayState extends State<HomeLoginTutorialOverlay> {
  int _step = 0;
  Rect? _inicioRect;
  Rect? _descuentosRect;
  Rect? _firstCouponRect;
  Rect? _claimedSwitchRect;
  Rect? _sorteosRect;
  Rect? _foroRect;
  Rect? _juegosRect;
  Rect? _forumBoomBetRect;
  Rect? _forumAddPostRect;
  Rect? _forumMyPostsRect;
  Rect? _firstGameRect;
  Rect? _faqRect;
  Rect? _profileRect;
  Rect? _settingsRect;
  Rect? _logoutRect;
  bool _finishingTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInicioTargetRect();
      _captureDescuentosTargetRect();
      _captureSorteosTargetRect();
      _captureForoTargetRect();
      _captureJuegosTargetRect();
    });
  }

  Rect? _readRectFromKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return null;
    final renderObject = targetContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  void _captureInicioTargetRect() {
    final rect = _readRectFromKey(widget.inicioTargetKey);
    if (rect != null && mounted) {
      setState(() => _inicioRect = rect);
    }
  }

  void _captureDescuentosTargetRect() {
    final rect = _readRectFromKey(widget.descuentosTargetKey);
    if (rect != null && mounted) {
      setState(() => _descuentosRect = rect);
    }
  }

  void _captureSorteosTargetRect() {
    final rect = _readRectFromKey(widget.sorteosTargetKey);
    if (rect != null && mounted) {
      setState(() => _sorteosRect = rect);
    }
  }

  void _captureForoTargetRect() {
    final rect = _readRectFromKey(widget.foroTargetKey);
    if (rect != null && mounted) {
      setState(() => _foroRect = rect);
    }
  }

  void _captureJuegosTargetRect() {
    final rect = _readRectFromKey(widget.juegosTargetKey);
    if (rect != null && mounted) {
      setState(() => _juegosRect = rect);
    }
  }

  void _pollRect({
    required GlobalKey key,
    required void Function(Rect rect) onCaptured,
    required bool Function() shouldContinue,
    int attempt = 0,
    int maxAttempts = 20,
  }) {
    if (!mounted || !shouldContinue()) return;

    final rect = _readRectFromKey(key);
    if (rect != null) {
      onCaptured(rect);
      return;
    }

    if (attempt >= maxAttempts) return;

    Future.delayed(const Duration(milliseconds: 180), () {
      _pollRect(
        key: key,
        onCaptured: onCaptured,
        shouldContinue: shouldContinue,
        attempt: attempt + 1,
        maxAttempts: maxAttempts,
      );
    });
  }

  void _goToDiscountsInfoStep() {
    widget.onRequestOpenDiscounts();
    setState(() {
      _step = 3;
    });
  }

  void _goToCouponStep() {
    setState(() {
      _step = 4;
      _firstCouponRect = null;
    });
    _pollRect(
      key: widget.firstCouponTargetKey,
      shouldContinue: () => _step == 4,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _firstCouponRect = rect);
      },
    );
  }

  void _goToClaimedSwitchStep() {
    setState(() {
      _step = 5;
      _claimedSwitchRect = null;
    });
    _pollRect(
      key: widget.claimedSwitchTargetKey,
      shouldContinue: () => _step == 5,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _claimedSwitchRect = rect);
      },
    );
  }

  void _goToSorteosFocusStep() {
    setState(() {
      _step = 7;
      _sorteosRect = null;
    });
    _pollRect(
      key: widget.sorteosTargetKey,
      shouldContinue: () => _step == 7,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _sorteosRect = rect);
      },
    );
  }

  void _goToSorteosInfoStep() {
    widget.onRequestOpenRaffles();
    setState(() {
      _step = 8;
    });
    _pollRect(
      key: widget.sorteosTargetKey,
      shouldContinue: () => _step == 8,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _sorteosRect = rect);
      },
    );
  }

  void _goToForoFocusStep() {
    setState(() {
      _step = 9;
      _foroRect = null;
    });
    _pollRect(
      key: widget.foroTargetKey,
      shouldContinue: () => _step == 9,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _foroRect = rect);
      },
    );
  }

  void _goToForoInfoStep() {
    widget.onRequestOpenForum();
    setState(() {
      _step = 10;
    });
    _pollRect(
      key: widget.foroTargetKey,
      shouldContinue: () => _step == 10,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _foroRect = rect);
      },
    );
  }

  void _goToForumSelectorStep() {
    setState(() {
      _step = 11;
      _forumBoomBetRect = null;
    });
    _pollRect(
      key: widget.forumBoomBetTargetKey,
      shouldContinue: () => _step == 11,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _forumBoomBetRect = rect);
      },
    );
  }

  void _goToForumHeaderButtonsStep() {
    setState(() {
      _step = 12;
      _forumAddPostRect = null;
      _forumMyPostsRect = null;
    });
    _pollRect(
      key: widget.forumAddPostTargetKey,
      shouldContinue: () => _step == 12,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _forumAddPostRect = rect);
      },
    );
    _pollRect(
      key: widget.forumMyPostsTargetKey,
      shouldContinue: () => _step == 12,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _forumMyPostsRect = rect);
      },
    );
  }

  void _goToJuegosFocusStep() {
    setState(() {
      _step = 13;
      _juegosRect = null;
    });
    _pollRect(
      key: widget.juegosTargetKey,
      shouldContinue: () => _step == 13,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _juegosRect = rect);
      },
    );
  }

  void _goToJuegosInfoStep() {
    widget.onRequestOpenGames();
    setState(() {
      _step = 14;
    });
    _pollRect(
      key: widget.juegosTargetKey,
      shouldContinue: () => _step == 14,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _juegosRect = rect);
      },
    );
  }

  void _goToFirstGameStep() {
    setState(() {
      _step = 15;
      _firstGameRect = null;
    });
    _pollRect(
      key: widget.firstGameTargetKey,
      shouldContinue: () => _step == 15,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _firstGameRect = rect);
      },
    );
  }

  void _goToFaqStep() {
    setState(() {
      _step = 16;
      _faqRect = null;
    });
    _pollRect(
      key: widget.faqTargetKey,
      shouldContinue: () => _step == 16,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _faqRect = rect);
      },
    );
  }

  void _goToProfileStep() {
    setState(() {
      _step = 17;
      _profileRect = null;
    });
    _pollRect(
      key: widget.profileTargetKey,
      shouldContinue: () => _step == 17,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _profileRect = rect);
      },
    );
  }

  void _goToSettingsStep() {
    setState(() {
      _step = 18;
      _settingsRect = null;
    });
    _pollRect(
      key: widget.settingsTargetKey,
      shouldContinue: () => _step == 18,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _settingsRect = rect);
      },
    );
  }

  void _goToLogoutStep() {
    setState(() {
      _step = 19;
      _logoutRect = null;
    });
    _pollRect(
      key: widget.logoutTargetKey,
      shouldContinue: () => _step == 19,
      onCaptured: (rect) {
        if (!mounted) return;
        setState(() => _logoutRect = rect);
      },
    );
  }

  Future<void> _goNext() async {
    if (_step == 0) {
      setState(() {
        _step = 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureInicioTargetRect();
      });
      return;
    }

    if (_step == 1) {
      setState(() {
        _step = 2;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureDescuentosTargetRect();
      });
      return;
    }

    if (_step == 2) {
      _goToDiscountsInfoStep();
      return;
    }

    if (_step == 3) {
      _goToCouponStep();
      return;
    }

    if (_step == 4) {
      _goToClaimedSwitchStep();
      return;
    }

    if (_step == 6) {
      _goToSorteosFocusStep();
      return;
    }

    if (_step == 8) {
      _goToForoFocusStep();
      return;
    }

    if (_step == 10) {
      _goToForumSelectorStep();
      return;
    }

    if (_step == 11) {
      _goToForumHeaderButtonsStep();
      return;
    }

    if (_step == 12) {
      _goToJuegosFocusStep();
      return;
    }

    if (_step == 14) {
      _goToFirstGameStep();
      return;
    }

    if (_step == 15) {
      _goToFaqStep();
      return;
    }

    if (_step == 16) {
      _goToProfileStep();
      return;
    }

    if (_step == 17) {
      _goToSettingsStep();
      return;
    }

    if (_step == 18) {
      _goToLogoutStep();
      return;
    }

    if (_step == 19) {
      setState(() {
        _step = 20;
      });
      return;
    }

    if (_step == 20) {
      if (!_finishingTutorial) {
        setState(() => _finishingTutorial = true);
        try {
          await widget.onTutorialCompleted?.call();
        } catch (_) {
          // No bloquear cierre del tutorial por fallo de red.
        } finally {
          if (mounted) {
            setState(() => _finishingTutorial = false);
          }
        }
      }
      widget.onClose();
      return;
    }

    widget.onClose();
  }

  bool _isInsideRect(Offset position, Rect rect) {
    return position.dx >= rect.left &&
        position.dx <= rect.right &&
        position.dy >= rect.top &&
        position.dy <= rect.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;

    if (_step == 0) {
      return Material(
        color: Colors.black.withValues(alpha: 0.94),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bienvenido a la app oficial de',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/boombetlogo.png',
                    width: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E15A),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Siguiente',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final focusRect = switch (_step) {
      1 => _inicioRect,
      2 => _descuentosRect,
      3 => _descuentosRect,
      4 => _firstCouponRect,
      5 => _claimedSwitchRect,
      7 => _sorteosRect,
      8 => _sorteosRect,
      9 => _foroRect,
      10 => _foroRect,
      11 => _forumBoomBetRect,
      12 => _forumAddPostRect,
      13 => _juegosRect,
      14 => _juegosRect,
      15 => _firstGameRect,
      16 => _faqRect,
      17 => _profileRect,
      18 => _settingsRect,
      19 => _logoutRect,
      _ => null,
    };
    final secondaryFocusRect = _step == 12 ? _forumMyPostsRect : null;
    final overlayAlpha = _step >= 2 ? 0.48 : 0.62;
    final showActionButton =
        _step == 1 ||
        _step == 3 ||
        _step == 4 ||
        _step == 6 ||
        _step == 8 ||
        _step == 10 ||
        _step == 11 ||
        _step == 12 ||
        _step == 14 ||
        _step == 15 ||
        _step == 16 ||
        _step == 17 ||
        _step == 18 ||
        _step == 19 ||
        _step == 20;
    final actionLabel = _step == 20
        ? 'Si, estoy listo!'
        : (_step == 1 ? 'Entendido' : 'Continuar');
    final message = _step == 1
        ? 'Esta es la pagina de inicio, aca podes encontrar las ultimas noticias relacionadas a Boombet y a tus casinos afiliados'
        : _step == 2
        ? 'Apreta aca para acceder a la pantalla de descuentos'
        : _step == 3
        ? 'Aca vas a poder acceder a descuentos exclusivos .'
        : _step == 4
        ? 'Apreta la imagen del cupon para saber mas sobre este y apreta el boton de "Reclamar" para reclamarlo'
        : _step == 5
        ? 'Apreta este boton para acceder a tus cupones reclamados'
        : _step == 6
        ? 'Aca vas a poder ver tus cupones reclamados con sus instrucciones sobre como usarlos.'
        : _step == 7
        ? 'Continuemos accediendo a los sorteos.'
        : _step == 8
        ? 'Aca podes anotarte a los mejores sorteos por parte de Boombet y participar por increibles premios.'
        : _step == 9
        ? 'Continuemos accediendo a nuestro foro.'
        : _step == 10
        ? 'Este es el foro de Boombet donde podes comunicarte con otros afiliados y formar parte de nuestra comunidad.'
        : _step == 11
        ? 'Aca podes cambiar entre nuestro foro general y los foros exclusivos de tus casinos afiliados.'
        : _step == 12
        ? 'Con el boton de "+" podes subir un nuevo posteo a nuestro foro y con el boton de "(icono de personita)" podes ver tus propios posteos'
        : _step == 13
        ? 'Terminemos accediendo a nuestros juegos.'
        : _step == 14
        ? 'Aca podes jugar a los minijuegos de Boombet y competir contra otros jugadores para subir de ranking'
        : _step == 15
        ? 'Apreta "Jugar ahora" en el juego que quieras y empeza a disfrutar.'
        : _step == 16
        ? 'Apretando aca podes acceder a la pagina de preguntas frecuentes para sacarte cualquier duda que tengas sobre nosotros.'
        : _step == 17
        ? 'Con este boton podes acceder a tu perfil donde podras ver tus datos personales y cambiarlos.'
        : _step == 18
        ? 'Aca podes acceder a la configuracion de nuestra aplicacion'
        : _step == 19
        ? 'Con este boton, podes cerrar sesion. En caso de que no quieras loguearte devuelta, con solo cerrar la aplicacion desde el sistema es suficiente.'
        : 'Estas preparado para acceder al mundo de Boombet?';

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (_step == 2 &&
              _descuentosRect != null &&
              _isInsideRect(details.globalPosition, _descuentosRect!)) {
            _goToDiscountsInfoStep();
            return;
          }

          if (_step == 5 &&
              _claimedSwitchRect != null &&
              _isInsideRect(details.globalPosition, _claimedSwitchRect!)) {
            widget.onRequestOpenClaimedCoupons();
            setState(() {
              _step = 6;
            });
            return;
          }

          if (_step == 7 &&
              _sorteosRect != null &&
              _isInsideRect(details.globalPosition, _sorteosRect!)) {
            _goToSorteosInfoStep();
            return;
          }

          if (_step == 9 &&
              _foroRect != null &&
              _isInsideRect(details.globalPosition, _foroRect!)) {
            _goToForoInfoStep();
            return;
          }

          if (_step == 13 &&
              _juegosRect != null &&
              _isInsideRect(details.globalPosition, _juegosRect!)) {
            _goToJuegosInfoStep();
            return;
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TutorialOverlayPainter(
                    focusRect: focusRect,
                    secondaryFocusRect: secondaryFocusRect,
                    overlayColor: Colors.black.withValues(alpha: overlayAlpha),
                  ),
                ),
              ),
            ),
            if (focusRect != null)
              Positioned(
                left: focusRect.left - 8,
                top: focusRect.top - 8,
                width: focusRect.width + 16,
                height: focusRect.height + 16,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00E15A),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00E15A,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (secondaryFocusRect != null)
              Positioned(
                left: secondaryFocusRect.left - 8,
                top: secondaryFocusRect.top - 8,
                width: secondaryFocusRect.width + 16,
                height: secondaryFocusRect.height + 16,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00E15A),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00E15A,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 96,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111).withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x3300E15A), width: 1),
                ),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_step == 12)
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'Con el boton de "+" podes subir un nuevo posteo a nuestro foro y con el boton de ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: textColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const TextSpan(
                                text: ' podes ver tus propios posteos',
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      if (showActionButton) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            onPressed: (_step == 20 && _finishingTutorial)
                                ? null
                                : _goNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E15A),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              actionLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _TutorialOverlayPainter extends CustomPainter {
  const _TutorialOverlayPainter({
    required this.focusRect,
    this.secondaryFocusRect,
    required this.overlayColor,
  });

  final Rect? focusRect;
  final Rect? secondaryFocusRect;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (focusRect != null) {
      final holeRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          focusRect!.left - 12,
          focusRect!.top - 12,
          focusRect!.right + 12,
          focusRect!.bottom + 12,
        ),
        const Radius.circular(26),
      );
      overlayPath.addRRect(holeRect);
      overlayPath.fillType = PathFillType.evenOdd;
    }

    if (secondaryFocusRect != null) {
      final secondHole = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          secondaryFocusRect!.left - 12,
          secondaryFocusRect!.top - 12,
          secondaryFocusRect!.right + 12,
          secondaryFocusRect!.bottom + 12,
        ),
        const Radius.circular(26),
      );
      overlayPath.addRRect(secondHole);
      overlayPath.fillType = PathFillType.evenOdd;
    }

    final paint = Paint()..color = overlayColor;
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TutorialOverlayPainter oldDelegate) {
    return oldDelegate.focusRect != focusRect ||
        oldDelegate.secondaryFocusRect != secondaryFocusRect ||
        oldDelegate.overlayColor != overlayColor;
  }
}
