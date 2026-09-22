import 'package:flutter/material.dart';
import 'player_stats_model.dart';

enum AchievementCategory {
  partidas,
  jugadas,
  economia,
}

class AchievementItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final AchievementCategory category;
  final int targetProgress;
  final int coinReward;
  final int xpReward;
  final int Function(PlayerStatsModel stats) getProgress;
  final int level;
  final String? familyId;
  final String? requiredAchievementId;

  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.category,
    required this.targetProgress,
    required this.coinReward,
    required this.xpReward,
    required this.getProgress,
    this.level = 1,
    this.familyId,
    this.requiredAchievementId,
  });

  String get levelBadge {
    switch (level) {
      case 1:
        return 'Bronce';
      case 2:
        return 'Plata';
      case 3:
        return 'Oro';
      default:
        return 'Nivel $level';
    }
  }

  Color get levelColor {
    switch (level) {
      case 1:
        return const Color(0xFFD97706); // Bronce / Ámbar vivo
      case 2:
        return const Color(0xFF94A3B8); // Plata nítida
      case 3:
        return const Color(0xFFF59E0B); // Oro brillante
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get levelBgColor {
    switch (level) {
      case 1:
        return const Color(0xFF78350F).withValues(alpha: 0.35); // Bronce profundo
      case 2:
        return const Color(0xFF334155).withValues(alpha: 0.50); // Plata pizarra
      case 3:
        return const Color(0xFF854D0E).withValues(alpha: 0.40); // Oro rico
      default:
        return const Color(0xFF1E293B).withValues(alpha: 0.50);
    }
  }

  Color get levelTextColor {
    switch (level) {
      case 1:
        return const Color(0xFFFDE68A); // Ámbar claro legible
      case 2:
        return const Color(0xFFF8FAFC); // Blanco perla reluciente
      case 3:
        return const Color(0xFFFEF08A); // Oro brillante
      default:
        return Colors.white;
    }
  }
}

class AchievementCatalog {
  /// Verifica si un logro está desbloqueado para progresar o reclamar.
  /// Si depende de un logro previo, este debe haber sido reclamado.
  static bool isUnlocked(AchievementItem item, PlayerStatsModel stats) {
    if (item.requiredAchievementId == null) return true;
    return stats.claimedAchievementIds.contains(item.requiredAchievementId);
  }

  /// Retorna el logro requisito previo si existe.
  static AchievementItem? getRequirement(AchievementItem item) {
    if (item.requiredAchievementId == null) return null;
    try {
      return allAchievements.firstWhere((a) => a.id == item.requiredAchievementId);
    } catch (_) {
      return null;
    }
  }

  /// Catálogo de logros organizado en series estrictas de 3 niveles:
  /// Nivel 1: Bronce (desbloqueado desde el inicio)
  /// Nivel 2: Plata (requiere reclamar el nivel Bronce)
  /// Nivel 3: Oro (requiere reclamar el nivel Plata)
  static final List<AchievementItem> allAchievements = [
    // =========================================================================
    // SERIE 1: MAESTRO DEL TRIVILÍN (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_trivilin_1',
      title: 'Maestro del Trivilín',
      description: 'Cantar 3 Trivilines en partida oficial.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF9333EA),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 3,
      coinReward: 350,
      xpReward: 70,
      getProgress: (s) => s.trivilines,
      familyId: 'trivilin',
    ),
    AchievementItem(
      id: 'ach_trivilin_2',
      title: 'Maestro del Trivilín',
      description: 'Cantar 6 Trivilines en partida oficial.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF9333EA),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 6,
      coinReward: 700,
      xpReward: 140,
      getProgress: (s) => s.trivilines,
      familyId: 'trivilin',
      requiredAchievementId: 'ach_trivilin_1',
    ),
    AchievementItem(
      id: 'ach_trivilin_3',
      title: 'Maestro del Trivilín',
      description: 'Cantar 10 Trivilines en partida oficial.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF9333EA),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 10,
      coinReward: 1500,
      xpReward: 300,
      getProgress: (s) => s.trivilines,
      familyId: 'trivilin',
      requiredAchievementId: 'ach_trivilin_2',
    ),

    // =========================================================================
    // SERIE 2: GALLO DE ORO (MESAS VIP) (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_vip_1',
      title: 'Gallo de Oro',
      description: 'Ganar 1 partida en Mesas VIP.',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFFEAB308),
      category: AchievementCategory.economia,
      level: 1,
      targetProgress: 1,
      coinReward: 300,
      xpReward: 60,
      getProgress: (s) => s.gamesWon,
      familyId: 'vip',
    ),
    AchievementItem(
      id: 'ach_vip_3',
      title: 'Gallo de Oro',
      description: 'Ganar 3 partidas en Mesas VIP.',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFFEAB308),
      category: AchievementCategory.economia,
      level: 2,
      targetProgress: 3,
      coinReward: 600,
      xpReward: 120,
      getProgress: (s) => s.gamesWon,
      familyId: 'vip',
      requiredAchievementId: 'ach_vip_1',
    ),
    AchievementItem(
      id: 'ach_vip_5',
      title: 'Gallo de Oro',
      description: 'Ganar 5 partidas en Mesas VIP.',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFFEAB308),
      category: AchievementCategory.economia,
      level: 3,
      targetProgress: 5,
      coinReward: 1200,
      xpReward: 250,
      getProgress: (s) => s.gamesWon,
      familyId: 'vip',
      requiredAchievementId: 'ach_vip_3',
    ),

    // =========================================================================
    // SERIE 3: INVICTO EN PAREJAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_teams_1',
      title: 'Invicto en Parejas',
      description: 'Ganar 1 partida en modo 2 vs 2.',
      icon: Icons.groups_rounded,
      iconColor: const Color(0xFF3B82F6),
      category: AchievementCategory.economia,
      level: 1,
      targetProgress: 1,
      coinReward: 200,
      xpReward: 40,
      getProgress: (s) => s.teamWins,
      familyId: 'teams',
    ),
    AchievementItem(
      id: 'ach_teams_3',
      title: 'Invicto en Parejas',
      description: 'Ganar 3 partidas en modo 2 vs 2.',
      icon: Icons.groups_rounded,
      iconColor: const Color(0xFF3B82F6),
      category: AchievementCategory.economia,
      level: 2,
      targetProgress: 3,
      coinReward: 500,
      xpReward: 100,
      getProgress: (s) => s.teamWins,
      familyId: 'teams',
      requiredAchievementId: 'ach_teams_1',
    ),
    AchievementItem(
      id: 'ach_teams_10',
      title: 'Invicto en Parejas',
      description: 'Ganar 10 partidas en modo 2 vs 2.',
      icon: Icons.groups_rounded,
      iconColor: const Color(0xFF3B82F6),
      category: AchievementCategory.economia,
      level: 3,
      targetProgress: 10,
      coinReward: 1200,
      xpReward: 250,
      getProgress: (s) => s.teamWins,
      familyId: 'teams',
      requiredAchievementId: 'ach_teams_3',
    ),

    // =========================================================================
    // SERIE 4: COLECCIONISTA DE ASES (CARTAS) (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_cards_50',
      title: 'Coleccionista de Ases',
      description: 'Acumular 50 cartas ganadas en mesa.',
      icon: Icons.style_rounded,
      iconColor: const Color(0xFF10B981),
      category: AchievementCategory.economia,
      level: 1,
      targetProgress: 50,
      coinReward: 300,
      xpReward: 60,
      getProgress: (s) => s.totalCardsWon,
      familyId: 'cards',
    ),
    AchievementItem(
      id: 'ach_cards_200',
      title: 'Coleccionista de Ases',
      description: 'Acumular 200 cartas ganadas en mesa.',
      icon: Icons.inventory_2_rounded,
      iconColor: const Color(0xFF047857),
      category: AchievementCategory.economia,
      level: 2,
      targetProgress: 200,
      coinReward: 800,
      xpReward: 150,
      getProgress: (s) => s.totalCardsWon,
      familyId: 'cards',
      requiredAchievementId: 'ach_cards_50',
    ),
    AchievementItem(
      id: 'ach_cards_500',
      title: 'Coleccionista de Ases',
      description: 'Acumular 500 cartas ganadas en mesa.',
      icon: Icons.auto_awesome_motion_rounded,
      iconColor: const Color(0xFF059669),
      category: AchievementCategory.economia,
      level: 3,
      targetProgress: 500,
      coinReward: 1600,
      xpReward: 300,
      getProgress: (s) => s.totalCardsWon,
      familyId: 'cards',
      requiredAchievementId: 'ach_cards_200',
    ),

    // =========================================================================
    // SERIE 5: RANGO COMPETITIVO (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_rank_bronce',
      title: 'Ascenso a la Gloria',
      description: 'Alcanzar el rango Bronce (150+ trofeos).',
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFD97706),
      category: AchievementCategory.economia,
      level: 1,
      targetProgress: 150,
      coinReward: 300,
      xpReward: 60,
      getProgress: (s) => s.trophies,
      familyId: 'rank',
    ),
    AchievementItem(
      id: 'ach_rank_plata',
      title: 'Ascenso a la Gloria',
      description: 'Alcanzar el rango Plata (450+ trofeos).',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFF94A3B8),
      category: AchievementCategory.economia,
      level: 2,
      targetProgress: 450,
      coinReward: 600,
      xpReward: 120,
      getProgress: (s) => s.trophies,
      familyId: 'rank',
      requiredAchievementId: 'ach_rank_bronce',
    ),
    AchievementItem(
      id: 'ach_rank_oro',
      title: 'Ascenso a la Gloria',
      description: 'Alcanzar el rango Oro (900+ trofeos).',
      icon: Icons.star_rounded,
      iconColor: const Color(0xFFFDE047),
      category: AchievementCategory.economia,
      level: 3,
      targetProgress: 900,
      coinReward: 1200,
      xpReward: 250,
      getProgress: (s) => s.trophies,
      familyId: 'rank',
      requiredAchievementId: 'ach_rank_plata',
    ),

    // =========================================================================
    // SERIE 6: PARTIDAS JUGADAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_games_1',
      title: 'Veterano de la Mesa',
      description: 'Jugar 1 partida oficial de La Caída.',
      icon: Icons.play_arrow_rounded,
      iconColor: const Color(0xFF38BDF8),
      category: AchievementCategory.partidas,
      level: 1,
      targetProgress: 1,
      coinReward: 100,
      xpReward: 20,
      getProgress: (s) => s.gamesPlayed,
      familyId: 'games',
    ),
    AchievementItem(
      id: 'ach_games_10',
      title: 'Veterano de la Mesa',
      description: 'Jugar 10 partidas oficiales.',
      icon: Icons.history_edu_rounded,
      iconColor: const Color(0xFF60A5FA),
      category: AchievementCategory.partidas,
      level: 2,
      targetProgress: 10,
      coinReward: 300,
      xpReward: 60,
      getProgress: (s) => s.gamesPlayed,
      familyId: 'games',
      requiredAchievementId: 'ach_games_1',
    ),
    AchievementItem(
      id: 'ach_games_50',
      title: 'Veterano de la Mesa',
      description: 'Jugar 50 partidas oficiales.',
      icon: Icons.workspace_premium_rounded,
      iconColor: const Color(0xFF818CF8),
      category: AchievementCategory.partidas,
      level: 3,
      targetProgress: 50,
      coinReward: 800,
      xpReward: 150,
      getProgress: (s) => s.gamesPlayed,
      familyId: 'games',
      requiredAchievementId: 'ach_games_10',
    ),

    // =========================================================================
    // SERIE 7: VICTORIAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_wins_1',
      title: 'Dominador',
      description: 'Ganar tu primera partida.',
      icon: Icons.emoji_events_rounded,
      iconColor: const Color(0xFFFBBF24),
      category: AchievementCategory.partidas,
      level: 1,
      targetProgress: 1,
      coinReward: 150,
      xpReward: 30,
      getProgress: (s) => s.gamesWon,
      familyId: 'wins',
    ),
    AchievementItem(
      id: 'ach_wins_10',
      title: 'Dominador',
      description: 'Ganar 10 partidas oficiales.',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFFF59E0B),
      category: AchievementCategory.partidas,
      level: 2,
      targetProgress: 10,
      coinReward: 500,
      xpReward: 100,
      getProgress: (s) => s.gamesWon,
      familyId: 'wins',
      requiredAchievementId: 'ach_wins_1',
    ),
    AchievementItem(
      id: 'ach_wins_50',
      title: 'Dominador',
      description: 'Ganar 50 partidas oficiales.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFFEAB308),
      category: AchievementCategory.partidas,
      level: 3,
      targetProgress: 50,
      coinReward: 1500,
      xpReward: 300,
      getProgress: (s) => s.gamesWon,
      familyId: 'wins',
      requiredAchievementId: 'ach_wins_10',
    ),

    // =========================================================================
    // SERIE 8: RACHAS DE VICTORIAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_streak_3',
      title: 'Racha Imparable',
      description: 'Alcanzar una racha de 3 victorias consecutivas.',
      icon: Icons.local_fire_department_rounded,
      iconColor: const Color(0xFFEA580C),
      category: AchievementCategory.partidas,
      level: 1,
      targetProgress: 3,
      coinReward: 400,
      xpReward: 80,
      getProgress: (s) => s.winStreak,
      familyId: 'streak',
    ),
    AchievementItem(
      id: 'ach_streak_5',
      title: 'Racha Imparable',
      description: 'Alcanzar una racha de 5 victorias consecutivas.',
      icon: Icons.whatshot_rounded,
      iconColor: const Color(0xFFDC2626),
      category: AchievementCategory.partidas,
      level: 2,
      targetProgress: 5,
      coinReward: 1000,
      xpReward: 200,
      getProgress: (s) => s.winStreak,
      familyId: 'streak',
      requiredAchievementId: 'ach_streak_3',
    ),
    AchievementItem(
      id: 'ach_streak_8',
      title: 'Racha Imparable',
      description: 'Alcanzar una racha de 8 victorias consecutivas.',
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFEF4444),
      category: AchievementCategory.partidas,
      level: 3,
      targetProgress: 8,
      coinReward: 2000,
      xpReward: 400,
      getProgress: (s) => s.winStreak,
      familyId: 'streak',
      requiredAchievementId: 'ach_streak_5',
    ),

    // =========================================================================
    // SERIE 9: CAÍDAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_caida_1',
      title: 'Cazador de Caídas',
      description: 'Cantar tu primera Caída a un rival.',
      icon: Icons.flash_on_rounded,
      iconColor: const Color(0xFFE11D48),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 1,
      coinReward: 100,
      xpReward: 20,
      getProgress: (s) => s.caidasMade,
      familyId: 'caidas',
    ),
    AchievementItem(
      id: 'ach_caidas_25',
      title: 'Cazador de Caídas',
      description: 'Cantar 25 Caídas a tus rivales.',
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFBE123C),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 25,
      coinReward: 600,
      xpReward: 120,
      getProgress: (s) => s.caidasMade,
      familyId: 'caidas',
      requiredAchievementId: 'ach_caida_1',
    ),
    AchievementItem(
      id: 'ach_caidas_100',
      title: 'Cazador de Caídas',
      description: 'Cantar 100 Caídas a tus rivales.',
      icon: Icons.dangerous_rounded,
      iconColor: const Color(0xFF881337),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 100,
      coinReward: 2000,
      xpReward: 400,
      getProgress: (s) => s.caidasMade,
      familyId: 'caidas',
      requiredAchievementId: 'ach_caidas_25',
    ),

    // =========================================================================
    // SERIE 10: MESAS LIMPIAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_limpia_1',
      title: 'Limpieza Total',
      description: 'Realizar 1 Mesa Limpia.',
      icon: Icons.cleaning_services_rounded,
      iconColor: const Color(0xFF0D9488),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 1,
      coinReward: 150,
      xpReward: 30,
      getProgress: (s) => s.mesasLimpias,
      familyId: 'limpias',
    ),
    AchievementItem(
      id: 'ach_limpia_10',
      title: 'Limpieza Total',
      description: 'Realizar 10 Mesas Limpias en partidas.',
      icon: Icons.waves_rounded,
      iconColor: const Color(0xFF059669),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 10,
      coinReward: 700,
      xpReward: 140,
      getProgress: (s) => s.mesasLimpias,
      familyId: 'limpias',
      requiredAchievementId: 'ach_limpia_1',
    ),
    AchievementItem(
      id: 'ach_limpia_25',
      title: 'Limpieza Total',
      description: 'Realizar 25 Mesas Limpias en partidas.',
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF10B981),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 25,
      coinReward: 1500,
      xpReward: 300,
      getProgress: (s) => s.mesasLimpias,
      familyId: 'limpias',
      requiredAchievementId: 'ach_limpia_10',
    ),

    // =========================================================================
    // SERIE 11: RONDAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_rondas_3',
      title: 'Canta que Canta',
      description: 'Cantar 3 Rondas.',
      icon: Icons.music_note_rounded,
      iconColor: const Color(0xFF10B981),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 3,
      coinReward: 200,
      xpReward: 40,
      getProgress: (s) => s.rondas,
      familyId: 'rondas',
    ),
    AchievementItem(
      id: 'ach_rondas_10',
      title: 'Canta que Canta',
      description: 'Cantar 10 Rondas.',
      icon: Icons.music_note_rounded,
      iconColor: const Color(0xFF10B981),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 10,
      coinReward: 500,
      xpReward: 100,
      getProgress: (s) => s.rondas,
      familyId: 'rondas',
      requiredAchievementId: 'ach_rondas_3',
    ),
    AchievementItem(
      id: 'ach_rondas_25',
      title: 'Canta que Canta',
      description: 'Cantar 25 Rondas.',
      icon: Icons.music_note_rounded,
      iconColor: const Color(0xFF10B981),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 25,
      coinReward: 1200,
      xpReward: 250,
      getProgress: (s) => s.rondas,
      familyId: 'rondas',
      requiredAchievementId: 'ach_rondas_10',
    ),

    // =========================================================================
    // SERIE 12: PATRULLAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_patrulla_2',
      title: 'El Guardián',
      description: 'Cantar 2 Patrullas.',
      icon: Icons.shield_moon_rounded,
      iconColor: const Color(0xFF2563EB),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 2,
      coinReward: 250,
      xpReward: 50,
      getProgress: (s) => s.patrullas,
      familyId: 'patrullas',
    ),
    AchievementItem(
      id: 'ach_patrulla_5',
      title: 'El Guardián',
      description: 'Cantar 5 Patrullas.',
      icon: Icons.shield_moon_rounded,
      iconColor: const Color(0xFF2563EB),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 5,
      coinReward: 600,
      xpReward: 120,
      getProgress: (s) => s.patrullas,
      familyId: 'patrullas',
      requiredAchievementId: 'ach_patrulla_2',
    ),
    AchievementItem(
      id: 'ach_patrulla_12',
      title: 'El Guardián',
      description: 'Cantar 12 Patrullas.',
      icon: Icons.security_rounded,
      iconColor: const Color(0xFF2563EB),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 12,
      coinReward: 1400,
      xpReward: 280,
      getProgress: (s) => s.patrullas,
      familyId: 'patrullas',
      requiredAchievementId: 'ach_patrulla_5',
    ),

    // =========================================================================
    // SERIE 13: VIGÍAS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_vigia_1',
      title: 'Ojos de Águila',
      description: 'Cantar 1 Vigía.',
      icon: Icons.visibility_rounded,
      iconColor: const Color(0xFF7C3AED),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 1,
      coinReward: 250,
      xpReward: 50,
      getProgress: (s) => s.vigias,
      familyId: 'vigias',
    ),
    AchievementItem(
      id: 'ach_vigia_3',
      title: 'Ojos de Águila',
      description: 'Cantar 3 Vigías.',
      icon: Icons.visibility_rounded,
      iconColor: const Color(0xFF7C3AED),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 3,
      coinReward: 600,
      xpReward: 120,
      getProgress: (s) => s.vigias,
      familyId: 'vigias',
      requiredAchievementId: 'ach_vigia_1',
    ),
    AchievementItem(
      id: 'ach_vigia_8',
      title: 'Ojos de Águila',
      description: 'Cantar 8 Vigías.',
      icon: Icons.remove_red_eye_rounded,
      iconColor: const Color(0xFF7C3AED),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 8,
      coinReward: 1500,
      xpReward: 300,
      getProgress: (s) => s.vigias,
      familyId: 'vigias',
      requiredAchievementId: 'ach_vigia_3',
    ),

    // =========================================================================
    // SERIE 14: REGISTROS (BRONCE -> PLATA -> ORO)
    // =========================================================================
    AchievementItem(
      id: 'ach_registro_1',
      title: 'Canto de Gala',
      description: 'Cantar 1 Registro en partida oficial.',
      icon: Icons.workspace_premium_rounded,
      iconColor: const Color(0xFFD97706),
      category: AchievementCategory.jugadas,
      level: 1,
      targetProgress: 1,
      coinReward: 300,
      xpReward: 60,
      getProgress: (s) => s.registros,
      familyId: 'registros',
    ),
    AchievementItem(
      id: 'ach_registro_3',
      title: 'Canto de Gala',
      description: 'Cantar 3 Registros en partida oficial.',
      icon: Icons.workspace_premium_rounded,
      iconColor: const Color(0xFFD97706),
      category: AchievementCategory.jugadas,
      level: 2,
      targetProgress: 3,
      coinReward: 700,
      xpReward: 140,
      getProgress: (s) => s.registros,
      familyId: 'registros',
      requiredAchievementId: 'ach_registro_1',
    ),
    AchievementItem(
      id: 'ach_registro_6',
      title: 'Canto de Gala',
      description: 'Cantar 6 Registros en partida oficial.',
      icon: Icons.military_tech_rounded,
      iconColor: const Color(0xFFD97706),
      category: AchievementCategory.jugadas,
      level: 3,
      targetProgress: 6,
      coinReward: 1800,
      xpReward: 360,
      getProgress: (s) => s.registros,
      familyId: 'registros',
      requiredAchievementId: 'ach_registro_3',
    ),
  ];
}
