import 'package:flutter/material.dart';
import '../../economy/rank_system.dart';

/// Emblema visual del rango del jugador.
/// Muestra el emoji del rango + nombre de división.
/// Tamaño: 'small' para lobby, 'medium' para perfil.
class RankBadgeWidget extends StatelessWidget {
  final int trophies;
  final bool showDivision;
  final double fontSize;
  final bool compact;

  const RankBadgeWidget({
    super.key,
    required this.trophies,
    this.showDivision = true,
    this.fontSize = 11,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = RankProgress(trophies: trophies);
    final rank = progress.currentRank;
    final fullName = showDivision ? rank.fullNameFor(trophies) : rank.name;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: rank.primaryColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank.primaryColor.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: rank.primaryColor.withValues(alpha: 0.25),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rank.icon,
            size: compact ? fontSize + 1 : fontSize + 3,
            color: rank.secondaryColor,
          ),
          if (!compact) const SizedBox(width: 4),
          if (!compact)
            Text(
              fullName,
              style: TextStyle(
                color: rank.secondaryColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
        ],
      ),
    );
  }
}

/// Barra de progreso de trofeos con marcador dinámico interactivo ("marca por donde va").
class RankProgressBar extends StatelessWidget {
  final int trophies;
  final double height;
  final bool showMarker;
  final bool showLabels;
  final bool animate;

  const RankProgressBar({
    super.key,
    required this.trophies,
    this.height = 10,
    this.showMarker = true,
    this.showLabels = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = RankProgress(trophies: trophies);
    final rank = progress.currentRank;
    final targetRatio = progress.progressInTier;
    final nextMilestone = progress.nextMilestoneName;
    final needed = progress.trophiesToNextDivision;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabels) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rango + división actual con icono
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(rank.icon, size: 14, color: rank.secondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    progress.fullName,
                    style: TextStyle(
                      color: rank.secondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              // Trofeos y meta
              if (rank.maxTrophies >= 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    RichText(
                      text: TextSpan(
                        text: '$trophies',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          TextSpan(
                            text: ' / ${progress.tierMaxTrophies}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFFFDE047)),
                    SizedBox(width: 4),
                    Text(
                      '¡Rango Leyenda Máximo!',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Barra con marcador de posición ("marca por donde va")
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final barHeight = height;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetRatio),
              duration: animate ? const Duration(milliseconds: 650) : Duration.zero,
              curve: Curves.easeOutCubic,
              builder: (context, animRatio, child) {
                final markerSize = (barHeight * 1.5).clamp(14.0, 22.0);
                final markerCenter = (animRatio * trackWidth).clamp(markerSize / 2, trackWidth - markerSize / 2);

                return SizedBox(
                  height: showMarker ? (barHeight > markerSize ? barHeight : markerSize + 2) : barHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track de fondo con borde biselado
                      Container(
                        height: barHeight,
                        width: trackWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(barHeight),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),

                      // Marcadores de división (checkpoints) en la pista
                      if (rank.divisions > 1 && rank.maxTrophies >= 0)
                        for (int i = 1; i < rank.divisions; i++)
                          Positioned(
                            left: (trackWidth * (i / rank.divisions)) - 1,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 2,
                                height: barHeight * 0.7,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),

                      // Relleno de progreso con degradado del rango
                      ClipRRect(
                        borderRadius: BorderRadius.circular(barHeight),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: barHeight,
                            width: (trackWidth * animRatio).clamp(0.0, trackWidth),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  rank.primaryColor,
                                  rank.secondaryColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rank.secondaryColor.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Marcador destacado que "marca por donde va" (Pin / Indicador)
                      if (showMarker && animRatio > 0.0)
                        Positioned(
                          left: markerCenter - (markerSize / 2),
                          child: Container(
                            width: markerSize,
                            height: markerSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B)],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.emoji_events_rounded,
                                size: 9,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        // Subtítulo con información de avance
        if (showLabels) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 10, color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 2),
                  Text(
                    '${progress.tierMinTrophies}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (rank.maxTrophies >= 0)
                Text(
                  '$needed para $nextMilestone',
                  style: TextStyle(
                    color: rank.secondaryColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'Corona de Campeón',
                  style: TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 10, color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 2),
                  Text(
                    '${progress.tierMaxTrophies}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
