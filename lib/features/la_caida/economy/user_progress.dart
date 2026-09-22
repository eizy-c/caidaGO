import 'package:flutter/material.dart';

/// Cálculo matemático puro de nivel y progreso porcentual mediante curva exponencial.
/// Todos los jugadores inician formalmente en Nivel 0 (0 XP).
class UserProgress {
  final int totalXp;

  const UserProgress({required this.totalXp});

  /// XP total acumulada requerida para alcanzar un nivel dado.
  /// Nivel 0: 0 XP
  /// Nivel 1: 100 XP
  /// Nivel N: 100 * (N ^ 1.5)
  static const List<int> _levelThresholds = [
    0,       // Nivel 0: Pichón
    300,     // Nivel 1: Caimanero (~5 victorias)
    800,     // Nivel 2: El Avillao (~13 victorias)
    1800,    // Nivel 3: Arrastrador (~30 victorias)
    3500,    // Nivel 4: Gallo Fino (~58 victorias)
    6000,    // Nivel 5: El Tigre (~100 victorias)
    9500,    // Nivel 6: El Baquiano (~158 victorias)
    14000,   // Nivel 7: Pana Bravo (~233 victorias)
    19500,   // Nivel 8: El Caballo (~325 victorias)
    26000,   // Nivel 9: El Papá de los Helados (~433 victorias)
    34000,   // Nivel 10: Cacique del Trivilín (~566 victorias)
  ];

  /// XP total acumulada requerida para alcanzar un nivel dado.
  static int xpRequiredForLevel(int level) {
    if (level <= 0) return 0;
    if (level < _levelThresholds.length) {
      return _levelThresholds[level];
    }
    // Niveles de prestigio mayores a 10
    final extra = level - 10;
    return 34000 + (extra * 8000);
  }

  /// Nivel actual basado en la XP total acumulada (iniciando en 0).
  int get currentLevel {
    int level = 0;
    while (totalXp >= xpRequiredForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Base de XP al comenzar el nivel actual.
  int get currentLevelBaseXp => xpRequiredForLevel(currentLevel);

  /// Meta de XP para desbloquear el siguiente nivel.
  int get nextLevelTargetXp => xpRequiredForLevel(currentLevel + 1);

  /// XP ganada dentro del rango del nivel actual.
  int get currentTierXp => totalXp - currentLevelBaseXp;

  /// XP total necesaria dentro del rango para subir al siguiente nivel.
  int get neededInCurrentTier => nextLevelTargetXp - currentLevelBaseXp;

  /// XP exacta que le falta al jugador para subir al siguiente nivel.
  int get xpRemainingToNextLevel => (nextLevelTargetXp - totalXp).clamp(0, 9999999);

  /// Progreso porcentual normalizado (0.0 a 1.0) dentro del nivel actual.
  double get levelProgressPercentage {
    if (neededInCurrentTier <= 0) return 1.0;
    return (currentTierXp / neededInCurrentTier).clamp(0.0, 1.0);
  }

  /// Título de rango competitivo unificado según el nivel alcanzado.
  String get rankTitle {
    switch (currentLevel) {
      case 0:
        return 'Novato';
      case 1:
        return 'Bronce';
      case 2:
        return 'Plata';
      case 3:
        return 'Oro';
      case 4:
        return 'Esmeralda';
      case 5:
        return 'Diamante';
      case 6:
        return 'Maestro I';
      case 7:
        return 'Maestro II';
      case 8:
        return 'Maestro III';
      case 9:
        return 'Leyenda';
      default:
        return 'Leyenda Suprema';
    }
  }

  /// Color del badge de nivel según el nivel alcanzado (unificado con colores de rangos).
  static Color levelBadgeColor(int level) {
    if (level >= 10) return const Color(0xFFBE123C); // Leyenda Suprema
    if (level >= 9)  return const Color(0xFFBE123C); // Leyenda
    if (level >= 8)  return const Color(0xFF4338CA); // Maestro III
    if (level >= 7)  return const Color(0xFFB45309); // Maestro II
    if (level >= 6)  return const Color(0xFFDC2626); // Maestro I
    if (level >= 5)  return const Color(0xFF6366F1); // Diamante
    if (level >= 4)  return const Color(0xFF059669); // Esmeralda
    if (level >= 3)  return const Color(0xFFEAB308); // Oro
    if (level >= 2)  return const Color(0xFF94A3B8); // Plata
    if (level >= 1)  return const Color(0xFFD97706); // Bronce
    return const Color(0xFF6B7280);                   // Novato
  }
}

/// Representa una meta o hito de recompensa por alcanzar un nivel en La Caída.
class LevelMilestone {
  final int level;
  final String title;
  final String reward;

  const LevelMilestone({
    required this.level,
    required this.title,
    required this.reward,
  });

  bool isUnlocked(int playerLevel) => playerLevel >= level;

  /// Catálogo oficial de hitos de nivel para La Caída.
  /// NOTA: Los rangos competitivos y los marcos cosméticos se desbloquean con TROFEOS, NO por nivel.
  /// Los niveles de XP otorgan recompensas económicas (monedas, tickets y accesos a mesas).
  static const List<LevelMilestone> catalog = [
    LevelMilestone(level: 0, title: 'Nivel 0', reward: '10 Tickets de cortesía, Modo Normal'),
    LevelMilestone(level: 1, title: 'Nivel 1', reward: '+150 Monedas, Escuela de Novatos completada'),
    LevelMilestone(level: 2, title: 'Nivel 2', reward: '+200 Monedas, Acceso a Mesa VIP Taberna'),
    LevelMilestone(level: 3, title: 'Nivel 3', reward: '+300 Monedas, Acceso a Mesa VIP Club Privado'),
    LevelMilestone(level: 4, title: 'Nivel 4', reward: '+500 Monedas, Acceso a Mesa VIP Gran Casino'),
    LevelMilestone(level: 5, title: 'Nivel 5', reward: '+750 Monedas, Acceso a Mesa VIP High Roller'),
    LevelMilestone(level: 6, title: 'Nivel 6', reward: '+1,000 Monedas de bonificación'),
    LevelMilestone(level: 7, title: 'Nivel 7', reward: '+1,500 Monedas de bonificación'),
    LevelMilestone(level: 8, title: 'Nivel 8', reward: '+2,000 Monedas de bonificación'),
    LevelMilestone(level: 9, title: 'Nivel 9', reward: '+3,000 Monedas, Sala de Campeones'),
    LevelMilestone(level: 10, title: 'Nivel 10', reward: '+5,000 Monedas, Estatus de Gran Maestro'),
  ];
}
