import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/services/debug_logger.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/theme/app_palette.dart';
import '../economy/player_session.dart';
import 'caida_lobby_screen.dart';
import 'widgets/profile_options_dialog.dart';
import 'widgets/four_aces_display_view.dart';

/// Pantalla de bienvenida y portada estilizada para La Caída (CaidaGO),
/// con paleta Cartoon Indigo/Púrpura, abanico de cartas, logotipo 3D,
/// emblema central flotante y barra de carga reactiva con efectos de brillo.
class CaidaSplashScreen extends StatefulWidget {
  const CaidaSplashScreen({super.key});

  @override
  State<CaidaSplashScreen> createState() => _CaidaSplashScreenState();
}

class _CaidaSplashScreenState extends State<CaidaSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controlador de carga
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOutCubic,
    );

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onLoadingComplete();
      }
    });

    // 2. Controlador de flotación suave (respiración)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOutSine),
    );

    // 3. Controlador de resplandor / pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadingController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SpanishCardView.precacheAllCards(context);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onLoadingComplete() async {
    final profileService = UserProfileService();
    final session = PlayerSession.shared;
    final isFirst = profileService.isFirstTime && session.isFirstTime;

    DebugLogger.instance.log(
      'Carga al 100% completada. Es usuario nuevo: $isFirst',
      category: 'Navegación',
    );

    if (!mounted) return;

    if (isFirst) {
      await ProfileOptionsDialog.show(context);
      profileService.markNotFirstTime();
      session.markNotFirstTime();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const CaidaLobbyScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  String _getLoadingStatusText(double progress) {
    if (progress < 0.30) {
      return 'Cargando baraja española...';
    } else if (progress < 0.65) {
      return 'Sincronizando perfil de juego...';
    } else if (progress < 0.90) {
      return 'Preparando mesas regionales...';
    } else {
      return '¡Mesa lista!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo Chevron en Zigzag Cartoon Púrpura/Índigo
          Positioned.fill(
            child: CustomPaint(
              painter: _ChevronBackgroundPainter(),
            ),
          ),

          // 2. Resplandor radial central y partículas decorativas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                    const Color(0xFF4338CA).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Contenido Principal Flotante
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // A. Abanico de los 4 Ases con animación de flotación suave
                  AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value),
                        child: child,
                      );
                    },
                    child: const FourAcesDisplayView(cardWidth: 52),
                  ),
                  const SizedBox(height: 12),

                  // B. Logotipo 3D "CAIDAGO" + Badge "Tradicional"
                  _buildBrandLogo(),

                  const Spacer(flex: 3),

                  // C. 3 Tarjetas 3D Separadas: ESTRATEGIA, CONCENTRACIÓN y DIVERSIÓN
                  _buildThreeFeatureCardsRow(),

                  const Spacer(flex: 4),

                  // E. Barra de Carga Dinámica Inferior
                  _buildLoadingBar(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logotipo 3D "CAIDAGO" con sombra profunda y badge "Tradicional"
  Widget _buildBrandLogo() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Sombra 3D profunda inferior
        Transform.translate(
          offset: const Offset(0, 7),
          child: Text(
            'CAIDAGO',
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.5,
              foreground: Paint()
                ..style = PaintingStyle.fill
                ..color = const Color(0xFF0F0B38),
            ),
          ),
        ),

        // Trazo exterior cartoon
        Text(
          'CAIDAGO',
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF1E1763),
          ),
        ),

        // Relleno degradado cian/celeste brillante
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF67E8F9),
              Color(0xFF06B6D4),
              Color(0xFF0284C7),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ).createShader(bounds),
          child: const Text(
            'CAIDAGO',
            style: TextStyle(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.5,
              color: Colors.white,
            ),
          ),
        ),

        // Rótulo "Tradicional" estilo píldora neón
        Positioned(
          bottom: -10,
          right: -14,
          child: Transform.rotate(
            angle: -math.pi / 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA855F7), Color(0xFF7C3AED), Color(0xFF6D28D9)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.7),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: AppPalette.cartoonYellow, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Tradicional',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fila de las 3 Tarjetas 3D independientes: ESTRATEGIA, CONCENTRACIÓN y DIVERSIÓN
  Widget _buildThreeFeatureCardsRow() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Tarjeta Izquierda: ESTRATEGIA (Dorada)
              _buildFeatureCard(
                title: 'ESTRATEGIA',
                icon: Icons.psychology_rounded,
                gradientColors: [const Color(0xFFFBBF24), const Color(0xFFD97706), const Color(0xFFB45309)],
                edgeColor: const Color(0xFF78350F),
                width: 95,
                height: 116,
                rotationAngle: -0.06,
              ),

              const SizedBox(width: 8),

              // 2. Tarjeta Central: CONCENTRACIÓN / JUGAR (Cian Prominente con Aura)
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Aura brillante
                  Container(
                    width: 120 * _pulseAnimation.value,
                    height: 140 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  _buildFeatureCard(
                    title: 'CONCENTRACIÓN',
                    subtitle: 'JUGAR',
                    icon: Icons.sports_esports_rounded,
                    gradientColors: [const Color(0xFF38BDF8), const Color(0xFF0284C7), const Color(0xFF0369A1)],
                    edgeColor: const Color(0xFF0C4A6E),
                    width: 114,
                    height: 138,
                    isProminent: true,
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // 3. Tarjeta Derecha: DIVERSIÓN (Rubí / Fresa)
              _buildFeatureCard(
                title: 'DIVERSIÓN',
                icon: Icons.celebration_rounded,
                gradientColors: [const Color(0xFFFB7185), const Color(0xFFE11D48), const Color(0xFFBE123C)],
                edgeColor: const Color(0xFF881337),
                width: 95,
                height: 116,
                rotationAngle: 0.06,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color edgeColor,
    required double width,
    required double height,
    double rotationAngle = 0.0,
    bool isProminent = false,
  }) {
    final cardWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(isProminent ? 22 : 18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isProminent ? 0.9 : 0.65),
          width: isProminent ? 2.2 : 1.6,
        ),
        boxShadow: [
          // Base 3D
          BoxShadow(
            color: edgeColor,
            offset: Offset(0, isProminent ? 5.5 : 4.0),
            blurRadius: 0,
          ),
          // Sombra ambiental
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: Offset(0, isProminent ? 8 : 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono dentro de círculo translúcido
          Container(
            padding: EdgeInsets.all(isProminent ? 9 : 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isProminent ? 32 : 24,
              shadows: const [
                Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
          SizedBox(height: isProminent ? 6 : 4),

          if (subtitle != null) ...[
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],

          // Título del pilar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isProminent ? Colors.white.withValues(alpha: 0.9) : Colors.white,
                fontSize: isProminent ? 9.5 : 9.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                shadows: const [
                  Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (rotationAngle != 0.0) {
      return Transform.rotate(
        angle: rotationAngle,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// Barra de Carga Dinámica Inferior con brillo y porcentajes
  Widget _buildLoadingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, _) {
          final progress = _loadingAnimation.value.clamp(0.0, 1.0);
          final percentInt = (progress * 100).toInt();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1763).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0F0B38),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila de texto de estado y porcentaje
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        _getLoadingStatusText(progress),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$percentInt%',
                        style: const TextStyle(
                          color: AppPalette.cartoonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Riel de la barra con gradiente brillante
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12, width: 1.0),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fillWidth = constraints.maxWidth * progress;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: fillWidth,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0284C7),
                                Color(0xFF38BDF8),
                                Color(0xFF67E8F9),
                                Color(0xFFFFFFFF),
                              ],
                              stops: [0.0, 0.6, 0.9, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

/// CustomPainter para generar el patrón en zigzag / chevrons en tonos cartoon púrpuras
class _ChevronBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1065), Color(0xFF3B0764), Color(0xFF1E1763)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final chevronHeight = 56.0;
    final halfWidth = size.width / 2;
    final totalChevrons = (size.height / (chevronHeight * 0.75)).ceil() + 3;

    final paint1 = Paint()
      ..color = const Color(0xFF4C1D95).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF581C87).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    for (int i = -1; i < totalChevrons; i++) {
      final y = i * chevronHeight * 0.8;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(halfWidth, y - chevronHeight * 0.4)
        ..lineTo(size.width, y)
        ..lineTo(size.width, y + chevronHeight * 0.5)
        ..lineTo(halfWidth, y + chevronHeight * 0.1)
        ..lineTo(0, y + chevronHeight * 0.5)
        ..close();

      canvas.drawPath(path, i % 2 == 0 ? paint1 : paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

