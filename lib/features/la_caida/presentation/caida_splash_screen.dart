import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/services/debug_logger.dart';
import '../../../core/services/user_profile_service.dart';
import '../economy/player_session.dart';
import 'caida_lobby_screen.dart';
import 'widgets/profile_options_dialog.dart';
import 'widgets/four_aces_display_view.dart';

/// Pantalla de bienvenida y portada estilizada para La Caída,
/// inspirada en la captura con fondo chevron púrpura y tipografía 3D abombada.
class CaidaSplashScreen extends StatefulWidget {
  const CaidaSplashScreen({super.key});

  @override
  State<CaidaSplashScreen> createState() => _CaidaSplashScreenState();
}

class _CaidaSplashScreenState extends State<CaidaSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  String _getLoadingStatusText(double progress) {
    if (progress < 0.35) {
      return 'Cargando baraja española...';
    } else if (progress < 0.70) {
      return 'Sincronizando perfil de juego...';
    } else if (progress < 0.95) {
      return 'Preparando la mesa de Caída...';
    } else {
      return '¡Mesa lista!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo de Chevrons en zigzag Púrpura / Azul Rey
          Positioned.fill(
            child: CustomPaint(
              painter: _ChevronBackgroundPainter(),
            ),
          ),

          // 2. Resplandor radial central
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.85,
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.28),
                    const Color(0xFF6B21A8).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Contenido Central (Abanico de 4 Ases + Logo 3D + 3 Tarjetas Flotantes + Lema)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // A. Abanico de los 4 Ases (Oros, Copas, Espadas, Bastos)
                      const FourAcesDisplayView(cardWidth: 54),
                      const SizedBox(height: 6),

                      // B. Logotipo 3D CAIDAGO + Rótulo "Tradicional"
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Sombra 3D profunda
                          Transform.translate(
                            offset: const Offset(3, 7),
                            child: Text(
                              'CAIDAGO',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                foreground: Paint()
                                  ..style = PaintingStyle.fill
                                  ..color = const Color(0xFF0F172A).withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          // Borde exterior 3D
                          Text(
                            'CAIDAGO',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 6.5
                                ..color = const Color(0xFF0284C7),
                            ),
                          ),
                          // Gradiente interior celeste brillante
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)],
                            ).createShader(bounds),
                            child: const Text(
                              'CAIDAGO',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Rótulo "Tradicional"
                          Positioned(
                            bottom: -10,
                            right: -10,
                            child: Transform.rotate(
                              angle: -math.pi / 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white38, width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9333EA).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Tradicional',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 38),

                      // C. 3 Tarjetas Flotantes 3D (Desafíos, JUGAR, Historial) con Chispas
                      _buildFloatingCardsRow(),
                      const SizedBox(height: 24),

                      // D. Lema / Tagline
                      Text(
                        'ESTRATEGIA  •  CONCENTRACIÓN  •  DIVERSIÓN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Barra de Carga Dinámica Inferior (0% al 100%)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, _) {
                final progress = _loadingAnimation.value.clamp(0.0, 1.0);
                final percentInt = (progress * 100).toInt();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fila de estado y porcentaje
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _getLoadingStatusText(progress),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percentInt%',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Riel de la barra de progreso
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                                width: 1.0,
                              ),
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
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF38BDF8).withValues(alpha: 0.7),
                                          blurRadius: 8,
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
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Fila de las 3 Tarjetas Flotantes 3D en el centro de la pantalla
  Widget _buildFloatingCardsRow() {
    return SizedBox(
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Tarjeta Izquierda (Amarilla - DESAFÍOS)
          Positioned(
            left: 10,
            child: Transform.rotate(
              angle: -0.12,
              child: _buildFloatingCard(
                label: 'DESAFÍOS',
                icon: Icons.military_tech_rounded,
                gradientColors: [const Color(0xFFFBBF24), const Color(0xFFD97706)],
                shadowColor: const Color(0xFFF59E0B),
                width: 90,
                height: 115,
              ),
            ),
          ),

          // Tarjeta Derecha (Roja - HISTORIAL)
          Positioned(
            right: 10,
            child: Transform.rotate(
              angle: 0.12,
              child: _buildFloatingCard(
                label: 'HISTORIAL',
                icon: Icons.emoji_events_rounded,
                gradientColors: [const Color(0xFFFB7185), const Color(0xFFE11D48)],
                shadowColor: const Color(0xFFF43F5E),
                width: 90,
                height: 115,
              ),
            ),
          ),

          // Tarjeta Central Elevada (Celeste - JUGAR)
          Positioned(
            child: _buildFloatingCard(
              label: 'JUGAR',
              icon: Icons.sports_esports_rounded,
              gradientColors: [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
              shadowColor: const Color(0xFF38BDF8),
              width: 102,
              height: 130,
              isProminent: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required Color shadowColor,
    required double width,
    required double height,
    bool isProminent = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: isProminent ? 0.6 : 0.35),
          width: isProminent ? 2.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: isProminent ? 0.6 : 0.4),
            blurRadius: isProminent ? 20 : 12,
            spreadRadius: isProminent ? 2 : 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isProminent ? 42 : 34,
            shadows: const [
              Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: isProminent ? 13 : 11,
              letterSpacing: 0.8,
              shadows: const [
                Shadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para generar el patrón en zigzag / chevrons en tonos púrpuras
class _ChevronBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1065), Color(0xFF3B0764), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Dibujar chevrons repetitivos con bandas alternas
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
