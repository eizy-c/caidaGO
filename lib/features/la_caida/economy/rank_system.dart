import 'package:flutter/material.dart';

/// Tier de rango en el sistema competitivo por trofeos.
enum RankTier {
  novato,
  bronce,
  plata,
  oro,
  esmeralda,
  diamante,
  maestro1,
  maestro2,
  maestro3,
  leyenda,
}

/// Información estática de cada rango del sistema competitivo.
class RankInfo {
  final RankTier tier;
  final String name;
  final IconData icon;
  final String frameId;
  final int minTrophies;
  final int maxTrophies; // -1 para Leyenda (sin techo)
  final int divisions;   // número de divisiones (ej: 4, 3, 2, 1)
  final Color primaryColor;
  final Color secondaryColor;

  const RankInfo({
    required this.tier,
    required this.name,
    required this.icon,
    required this.frameId,
    required this.minTrophies,
    required this.maxTrophies,
    this.divisions = 3,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// Retorna el nivel de división actual (ej: 4, 3, 2, 1) según los trofeos del jugador
  /// División más alta dentro del rango es 1 (ej: Oro 3 -> Oro 2 -> Oro 1)
  int divisionFor(int trophies) {
    if (divisions <= 1 || maxTrophies < 0) return 1;
    final range = maxTrophies - minTrophies;
    final divSize = (range / divisions).ceil();
    if (divSize <= 0) return 1;
    final offset = trophies - minTrophies;
    final divIndex = (offset ~/ divSize).clamp(0, divisions - 1);
    final div = divisions - divIndex;
    return div.clamp(1, divisions);
  }

  /// Nombre completo con división (ej: "Novato 4", "Oro 3", "Plata 2")
  String fullNameFor(int trophies) {
    if (divisions <= 1) return name;
    final div = divisionFor(trophies);
    return '$name $div';
  }

  static const List<RankInfo> allRanks = [
    RankInfo(
      tier: RankTier.novato,
      name: 'Novato',
      icon: Icons.shield_outlined,
      frameId: 'rank_novato',
      minTrophies: 0,
      maxTrophies: 149,
      divisions: 4,
      primaryColor: Color(0xFF6B7280),
      secondaryColor: Color(0xFF9CA3AF),
    ),
    RankInfo(
      tier: RankTier.bronce,
      name: 'Bronce',
      icon: Icons.military_tech_rounded,
      frameId: 'rank_bronce',
      minTrophies: 150,
      maxTrophies: 449,
      divisions: 3,
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFF59E0B),
    ),
    RankInfo(
      tier: RankTier.plata,
      name: 'Plata',
      icon: Icons.workspace_premium_rounded,
      frameId: 'rank_plata',
      minTrophies: 450,
      maxTrophies: 899,
      divisions: 3,
      primaryColor: Color(0xFF94A3B8),
      secondaryColor: Color(0xFFCBD5E1),
    ),
    RankInfo(
      tier: RankTier.oro,
      name: 'Oro',
      icon: Icons.emoji_events_rounded,
      frameId: 'rank_oro',
      minTrophies: 900,
      maxTrophies: 1499,
      divisions: 3,
      primaryColor: Color(0xFFEAB308),
      secondaryColor: Color(0xFFFDE047),
    ),
    RankInfo(
      tier: RankTier.esmeralda,
      name: 'Esmeralda',
      icon: Icons.diamond_rounded,
      frameId: 'rank_esmeralda',
      minTrophies: 1500,
      maxTrophies: 2299,
      divisions: 3,
      primaryColor: Color(0xFF059669),
      secondaryColor: Color(0xFF10B981),
    ),
    RankInfo(
      tier: RankTier.diamante,
      name: 'Diamante',
      icon: Icons.auto_awesome_rounded,
      frameId: 'rank_diamante',
      minTrophies: 2300,
      maxTrophies: 3299,
      divisions: 3,
      primaryColor: Color(0xFF6366F1),
      secondaryColor: Color(0xFFA855F7),
    ),
    RankInfo(
      tier: RankTier.maestro1,
      name: 'Maestro I',
      icon: Icons.shield_rounded,
      frameId: 'rank_maestro',
      minTrophies: 3300,
      maxTrophies: 3699,
      divisions: 1,
      primaryColor: Color(0xFFDC2626),
      secondaryColor: Color(0xFFEF4444),
    ),
    RankInfo(
      tier: RankTier.maestro2,
      name: 'Maestro II',
      icon: Icons.star_rounded,
      frameId: 'rank_gran_maestro',
      minTrophies: 3700,
      maxTrophies: 4099,
      divisions: 1,
      primaryColor: Color(0xFFB45309),
      secondaryColor: Color(0xFFD97706),
    ),
    RankInfo(
      tier: RankTier.maestro3,
      name: 'Maestro III',
      icon: Icons.military_tech_rounded,
      frameId: 'rank_heroico',
      minTrophies: 4100,
      maxTrophies: 4499,
      divisions: 1,
      primaryColor: Color(0xFF4338CA),
      secondaryColor: Color(0xFF6366F1),
    ),
    RankInfo(
      tier: RankTier.leyenda,
      name: 'Leyenda',
      icon: Icons.stars_rounded,
      frameId: 'rank_leyenda',
      minTrophies: 4500,
      maxTrophies: -1,
      divisions: 1,
      primaryColor: Color(0xFFBE123C),
      secondaryColor: Color(0xFFE11D48),
    ),
  ];

  /// Obtiene el rango correspondiente a la cantidad de trofeos
  static RankInfo forTrophies(int trophies) {
    for (final rank in allRanks.reversed) {
      if (trophies >= rank.minTrophies) return rank;
    }
    return allRanks.first;
  }
}

/// Progreso del jugador en el sistema de rangos.
class RankProgress {
  final int trophies;

  const RankProgress({required this.trophies});

  /// Rango actual del jugador
  RankInfo get currentRank => RankInfo.forTrophies(trophies);

  /// Progreso normalizado (0.0 a 1.0) dentro del rango/división actual
  double get progressInTier {
    final rank = currentRank;
    if (rank.maxTrophies < 0) return 1.0; // Leyenda: barra siempre llena
    final range = rank.maxTrophies - rank.minTrophies + 1;
    if (range <= 0) return 1.0;
    // División actual
    final divSize = range ~/ rank.divisions.clamp(1, 3);
    final divIndex = (rank.divisionFor(trophies) - 1).clamp(0, rank.divisions - 1);
    final divStart = rank.minTrophies + (divIndex * divSize);
    final divEnd = (divIndex == rank.divisions - 1) ? rank.maxTrophies : divStart + divSize - 1;
    final inDiv = trophies - divStart;
    final divRange = divEnd - divStart + 1;
    return (inDiv / divRange).clamp(0.0, 1.0);
  }

  /// Trofeos hasta el siguiente rango (o división)
  int get trophiesToNextDivision {
    final rank = currentRank;
    if (rank.maxTrophies < 0) return 0;
    return (rank.maxTrophies + 1) - trophies;
  }

  /// Calcula el delta de trofeos según resultado de partida.
  /// Protección en Novato: nunca baja de 0.
  static int trophyDeltaForResult({
    required bool won,
    required bool trivolin,
    required bool mesaLimpia,
    required bool isTeams,
    required int currentTrophies,
  }) {
    int delta;
    if (won) {
      if (trivolin) {
        delta = isTeams ? 28 : 35;
      } else if (mesaLimpia) {
        delta = isTeams ? 24 : 30;
      } else {
        delta = isTeams ? 20 : 25;
      }
    } else {
      delta = isTeams ? -10 : -15;
      // Protección de Novato: no baja de 0
      final rank = RankInfo.forTrophies(currentTrophies);
      if (rank.tier == RankTier.novato) {
        delta = 0; // Sin penalización en Novato
      }
    }
    return delta;
  }

  /// Recompensa inmediata en monedas al alcanzar un rango por primera vez
  static int coinRewardForRank(RankTier tier) {
    switch (tier) {
      case RankTier.novato:    return 0;
      case RankTier.bronce:    return 500;
      case RankTier.plata:     return 800;
      case RankTier.oro:       return 1200;
      case RankTier.esmeralda: return 1800;
      case RankTier.diamante:  return 2500;
      case RankTier.maestro1:  return 3500;
      case RankTier.maestro2:  return 4500;
      case RankTier.maestro3:  return 5500;
      case RankTier.leyenda:   return 8000;
    }
  }

  /// Beneficio pasivo: capacidad extra de tickets para este rango
  static int bonusTicketCapacityForRank(RankTier tier) {
    switch (tier) {
      case RankTier.bronce:    return 2;
      case RankTier.oro:       return 4;
      case RankTier.diamante:  return 6;
      case RankTier.leyenda:   return 6;
      default: return 0;
    }
  }

  /// Beneficio pasivo: porcentaje extra de monedas en victorias
  static double bonusCoinMultiplierForRank(RankTier tier) {
    switch (tier) {
      case RankTier.plata:     return 0.05;
      case RankTier.maestro1:
      case RankTier.maestro2:
      case RankTier.maestro3: return 0.15;
      default: return 0.0;
    }
  }

  /// Beneficio pasivo: porcentaje extra de XP
  static double bonusXpMultiplierForRank(RankTier tier) {
    switch (tier) {
      case RankTier.esmeralda: return 0.10;
      default: return 0.0;
    }
  }
}
