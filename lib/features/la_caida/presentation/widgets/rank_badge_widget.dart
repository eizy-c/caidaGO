import 'package:flutter/material.dart';
import '../../economy/rank_system.dart';

/// Emblema visual del rango del jugador con gradiente semántico según trofeos.
/// Muestra el icono del rango + nombre y división con tipografía limpia sin bordes oscuros.
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
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rank.primaryColor.withValues(alpha: 0.35),
            rank.secondaryColor.withValues(alpha: 0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: rank.secondaryColor.withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: rank.primaryColor.withValues(alpha: 0.30),
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
          if (!compact) const SizedBox(width: 5),
          if (!compact)
            Text(
              fullName,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
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

/// Barra de progreso de trofeos con gradiente del rango actual.
class RankProgressBar extends StatelessWidget {
  final int trophies;
  final double height;

  const RankProgressBar({
    super.key,
    required this.trophies,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final progress = RankProgress(trophies: trophies);
    final rank = progress.currentRank;
    final ratio = progress.progressInTier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$trophies 🏆',
              style: TextStyle(
                color: rank.secondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (rank.maxTrophies >= 0)
              Text(
                '${progress.trophiesToNextDivision} para subir',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              const Text(
                'Rango máximo',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Container(
            height: height,
            width: double.infinity,
            color: rank.primaryColor.withValues(alpha: 0.22),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: rank.gradient,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
