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
          Text(
            rank.emoji,
            style: TextStyle(fontSize: compact ? fontSize - 1 : fontSize + 1),
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

/// Barra de progreso de trofeos dentro del rango actual.
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
                fontWeight: FontWeight.w800,
              ),
            ),
            if (rank.maxTrophies >= 0)
              Text(
                '${progress.trophiesToNextDivision} para subir',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              )
            else
              const Text(
                'Rango máximo',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: height,
            backgroundColor: rank.primaryColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(rank.primaryColor),
          ),
        ),
      ],
    );
  }
}
