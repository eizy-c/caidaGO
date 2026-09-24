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

  /// Siguiente rango (null si ya está en Leyenda)
  RankInfo? get nextRank {
    final idx = RankInfo.allRanks.indexOf(currentRank);
    if (idx >= 0 && idx < RankInfo.allRanks.length - 1) {
      return RankInfo.allRanks[idx + 1];
    }
    return null;
  }

  /// Trofeos mínimos del tier actual
  int get tierMinTrophies => currentRank.minTrophies;

  /// Trofeos meta para el siguiente tier (ej. 150 para Novato, 450 para Bronce)
  int get tierMaxTrophies => currentRank.maxTrophies >= 0 ? currentRank.maxTrophies + 1 : currentRank.minTrophies;

  /// Trofeos acumulados dentro del tier actual
  int get trophiesInTier => (trophies - tierMinTrophies).clamp(0, 999999);

  /// Amplitud de trofeos del tier actual
  int get tierSpan => (tierMaxTrophies - tierMinTrophies).clamp(1, 999999);

  /// Progreso normalizado (0.0 a 1.0) dentro de TODO el rango actual
  double get progressInTier {
    if (currentRank.maxTrophies < 0) return 1.0; // Leyenda: barra siempre llena
    final span = tierSpan;
    if (span <= 0) return 1.0;
    return (trophiesInTier / span).clamp(0.0, 1.0);
  }

  /// Trofeos restantes para el siguiente rango
  int get trophiesToNextRank {
    if (currentRank.maxTrophies < 0) return 0;
    return (tierMaxTrophies - trophies).clamp(0, 999999);
  }

  /// División actual (ej: 4, 3, 2, 1)
  int get currentDivision => currentRank.divisionFor(trophies);

  /// Trofeos base de la división actual
  int get divisionMinTrophies {
    if (currentRank.divisions <= 1 || currentRank.maxTrophies < 0) return currentRank.minTrophies;
    final totalRange = currentRank.maxTrophies - currentRank.minTrophies + 1;
    final divSize = totalRange / currentRank.divisions;
    final stepFromBottom = (currentRank.divisions - currentDivision).clamp(0, currentRank.divisions - 1);
    return (currentRank.minTrophies + (stepFromBottom * divSize)).round();
  }

  /// Trofeos objetivo de la división actual (o siguiente rango si es división 1)
  int get divisionMaxTrophies {
    if (currentRank.divisions <= 1 || currentRank.maxTrophies < 0) return tierMaxTrophies;
    final totalRange = currentRank.maxTrophies - currentRank.minTrophies + 1;
    final divSize = totalRange / currentRank.divisions;
    final stepFromBottom = (currentRank.divisions - currentDivision).clamp(0, currentRank.divisions - 1);
    if (stepFromBottom >= currentRank.divisions - 1) {
      return tierMaxTrophies;
    }
    return (currentRank.minTrophies + ((stepFromBottom + 1) * divSize)).round();
  }

  /// Progreso normalizado (0.0 a 1.0) dentro de la división actual
  double get progressInDivision {
    if (currentRank.maxTrophies < 0) return 1.0;
    final min = divisionMinTrophies;
    final max = divisionMaxTrophies;
    final span = max - min;
    if (span <= 0) return 1.0;
    return ((trophies - min) / span).clamp(0.0, 1.0);
  }

  /// Trofeos hasta la siguiente división (o rango si es división 1)
  int get trophiesToNextDivision {
    if (currentRank.maxTrophies < 0) return 0;
    return (divisionMaxTrophies - trophies).clamp(0, 999999);
  }

  /// Nombre del siguiente escalón (ej. "Novato 3" o "Bronce")
  String get nextMilestoneName {
    if (currentRank.maxTrophies < 0) return 'Leyenda';
    if (currentDivision > 1) {
      return '${currentRank.name} ${currentDivision - 1}';
    }
    return nextRank?.name ?? 'Siguiente Rango';
  }

  /// Nombre completo del rango y división actual (ej: "Novato 4", "Bronce 2")
  String get fullName => currentRank.fullNameFor(trophies);

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
