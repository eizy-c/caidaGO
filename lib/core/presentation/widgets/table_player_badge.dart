import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import '../../../features/la_caida/presentation/widgets/user_frame_view.dart';
import 'speech_bubble.dart';

enum PlayerPositionOnTable { bottom, top, left, right }

/// Badge visual unificado para representar a cualquier jugador o bot en la mesa.
/// Traduce el diseño técnico del boceto:
/// - Barra de tiempo curva en la esquina superior izquierda.
/// - Corona dorada flotante de "Mano" en la esquina superior derecha.
/// - Cápsulas gemelas de Puntos y Cartas recogidas en el borde inferior del avatar.
/// - Placa horizontal redondeada con el nombre del jugador.
/// - Mini-cartas boca abajo para rivales.
class TablePlayerBadge extends StatelessWidget {
  final String name;
  final int? scoreOrCards;
  final int? score;
  final int? cardsWon;
  final bool isBot;
  final bool isCurrentTurn;
  final double turnProgress; // 0.0 a 1.0 para la barra de tiempo
  final PlayerPositionOnTable position;
  final String? calloutMessage;
  final int cardsInHandCount;
  final Color avatarColor;
  final bool isMano;
  final int? avatarId;
  final String? frameId;
  final int? playerLevel;
  final VoidCallback? onTap;
  final bool isCompact;

  const TablePlayerBadge({
    super.key,
    required this.name,
    this.scoreOrCards,
    this.score,
    this.cardsWon,
    this.isBot = true,
    this.isCurrentTurn = false,
    this.turnProgress = 1.0,
    this.position = PlayerPositionOnTable.top,
    this.calloutMessage,
    this.cardsInHandCount = 3,
    this.avatarColor = const Color(0xFF6366F1),
    this.isMano = false,
    this.avatarId,
    this.frameId,
    this.playerLevel,
    this.onTap,
    this.isCompact = false,
  }) : assert(scoreOrCards != null || score != null, 'Debe especificarse score o scoreOrCards');

  @override
  Widget build(BuildContext context) {
    final avatarSize = isCompact ? 44.0 : 56.0;
    final frame = frameId != null ? UserFrameItem.getById(frameId!) : null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenedor del Avatar con decoraciones flotantes
              SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1. Barra de tiempo curva en la esquina superior izquierda
                    if (isCurrentTurn)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedCornerTimerPainter(
                            progress: turnProgress,
                            isCurrentTurn: isCurrentTurn,
                          ),
                        ),
                      ),

                    // 2. Cuadro del Avatar con Marco Oficial (UserFrameView)
                    if (avatarId != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: avatarSize + 6,
                        height: avatarSize + 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isCurrentTurn)
                              BoxShadow(
                                color: AppPalette.cartoonCyan.withValues(alpha: 0.65),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                          ],
                        ),
                        child: UserFrameView(
                          avatarIndex: avatarId!,
                          frameId: frameId ?? 'rank_novato',
                          size: avatarSize,
                          showLevelBadge: false,
                        ),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          color: AppPalette.cartoonCardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrentTurn
                                ? AppPalette.cartoonCyan
                                : const Color(0xFF4C3E9E),
                            width: isCurrentTurn ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            if (isCurrentTurn)
                              BoxShadow(
                                color: AppPalette.cartoonCyan.withValues(alpha: 0.45),
                                blurRadius: 10,
                                spreadRadius: 1.5,
                              )
                            else
                              const BoxShadow(
                                color: Color(0x35000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                color: avatarColor.withValues(alpha: 0.35),
                              ),
                              Icon(
                                isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Corona/Joya superior del Marco si no se renderiza UserFrameView
                    if (avatarId == null && frame?.crownIcon != null)
                      Positioned(
                        top: -8,
                        child: Icon(
                          frame!.crownIcon,
                          size: 15,
                          color: const Color(0xFFFDE047),
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),

                    // 3. Insignia flotante de Mano Dorada en la esquina superior derecha (sin palabra MANO)
                    if (isMano)
                      Positioned(
                        top: -7,
                        right: -7,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                            ),
                            border: Border.all(color: Colors.white, width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEAB308).withValues(alpha: 0.65),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.front_hand_rounded,
                              size: 13,
                              color: Color(0xFF713F12),
                            ),
                          ),
                        ),
                      ),

                    // 4. Cápsulas gemelas: Puntos y Cartas recogidas en el borde inferior
                    Positioned(
                      bottom: -9,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPointsPill(),
                          if (cardsWon != null) ...[
                            const SizedBox(width: 3),
                            _buildCardsWonPill(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Separación para librar las cápsulas que sobresalen hacia abajo
              const SizedBox(height: 12),

              // 5. Placa horizontal del Nombre del Jugador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrentTurn
                        ? AppPalette.cartoonCyan
                        : AppPalette.cartoonBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isCurrentTurn)
                      BoxShadow(
                        color: AppPalette.cartoonCyan.withValues(alpha: 0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    else
                      const BoxShadow(
                        color: Color(0x35000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBot) ...[
                      const Icon(Icons.smart_toy_rounded, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                    ] else if (playerLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: AppPalette.cartoonBgDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppPalette.cartoonBorder, width: 1.0),
                        ),
                        child: Text(
                          'Nv. $playerLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTurn ? Colors.white : Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Mini-cartas en mano para rivales
              if (position != PlayerPositionOnTable.bottom && cardsInHandCount > 0) ...[
                const SizedBox(height: 3),
                _buildMiniFacedownCards(),
              ],
            ],
          ),
        ),

        // Bocadillo flotante de cantos / pensamientos que emerge de la foto del avatar
        if (calloutMessage != null && calloutMessage!.isNotEmpty)
          _buildCalloutBubble(),
      ],
    );
  }

  Widget _buildCalloutBubble() {
    final horizontalOffset = isCompact ? 46.0 : 58.0;
    final verticalOffset = isCompact ? 60.0 : 76.0;

    switch (position) {
      case PlayerPositionOnTable.left:
        return Positioned(
          left: horizontalOffset,
          top: 6,
          child: SpeechBubble.directional(
            text: calloutMessage!,
            arrowDirection: BubbleArrowDirection.left,
            maxWidth: isCompact ? 130 : 155,
          ),
        );
      case PlayerPositionOnTable.right:
        return Positioned(
          right: horizontalOffset,
          top: 6,
          child: SpeechBubble.directional(
            text: calloutMessage!,
            arrowDirection: BubbleArrowDirection.right,
            maxWidth: isCompact ? 130 : 155,
          ),
        );
      case PlayerPositionOnTable.top:
        return Positioned(
          top: verticalOffset,
          child: SpeechBubble.directional(
            text: calloutMessage!,
            arrowDirection: BubbleArrowDirection.up,
            maxWidth: isCompact ? 130 : 155,
          ),
        );
      case PlayerPositionOnTable.bottom:
        return Positioned(
          bottom: verticalOffset,
          left: 0,
          child: SpeechBubble.directional(
            text: calloutMessage!,
            arrowDirection: BubbleArrowDirection.down,
            maxWidth: isCompact ? 130 : 155,
          ),
        );
    }
  }

  /// Cápsula izquierda: Puntos
  Widget _buildPointsPill() {
    final displayValue = score ?? scoreOrCards ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppPalette.cartoonBgDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppPalette.cartoonBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFDE047)),
          const SizedBox(width: 2),
          Text(
            '$displayValue',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Cápsula derecha: Cartas recogidas
  Widget _buildCardsWonPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppPalette.cartoonBgDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppPalette.cartoonBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_rounded, size: 9.5, color: Colors.white70),
          const SizedBox(width: 2),
          Text(
            '$cardsWon',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFacedownCards() {
    final count = cardsInHandCount.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Transform.translate(
          offset: Offset(index * -4.0, 0),
          child: Container(
            width: 14,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white70, width: 0.8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFBBF24), width: 0.5),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Painter para la barra de tiempo en L / curva en la esquina superior izquierda del avatar
class _CurvedCornerTimerPainter extends CustomPainter {
  final double progress;
  final bool isCurrentTurn;

  _CurvedCornerTimerPainter({
    required this.progress,
    required this.isCurrentTurn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isCurrentTurn) return;

    const strokeWidth = 3.8;
    const padding = 2.5;
    const cornerRadius = 16.0;

    // Ruta en L curvada que abraza la esquina superior izquierda del avatar:
    // Empieza a 65% de altura en el lateral izquierdo, sube por la esquina redondeada
    // y termina a 65% de ancho en el borde superior.
    final path = Path();
    final startY = size.height * 0.65;
    final endX = size.width * 0.65;

    path.moveTo(-padding, startY);
    path.lineTo(-padding, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, -padding),
      radius: const Radius.circular(cornerRadius + padding),
      clockwise: true,
    );
    path.lineTo(endX, -padding);

    // 1. Trazado sutil de fondo
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, trackPaint);

    // 2. Trazo de progreso activo
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress <= 0.001) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractLength = metric.length * clampedProgress;
    final progressPath = metric.extractPath(0, extractLength);

    final isWarning = clampedProgress <= 0.25;
    final activeColor = isWarning
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);

    // Resplandor exterior
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawPath(progressPath, glowPaint);

    // Trazo principal nítido
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(progressPath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedCornerTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isCurrentTurn != isCurrentTurn;
  }
}
