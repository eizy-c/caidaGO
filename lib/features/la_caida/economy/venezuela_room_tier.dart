import 'package:flutter/material.dart';

/// Modalidad de juego para las salas de apuestas de La Caída.
enum GameMode {
  duel1v1,
  teams2v2,
}

/// Alias descriptivo para compatibilidad de nomenclatura.
typedef VenezuelaGameMode = GameMode;

/// Modelo inmutable que representa una Sala VIP Regional de Venezuela.
/// Define las reglas financieras, requerimientos de trofeos y estética visual.
class VenezuelaRoomTier {
  final int id;
  final String name;
  final String region;
  final String subtitle;
  final int entryFee;
  final int basePrize;
  final int trophyCap;
  final int winTrophies;
  final int lossTrophies;
  final int requiredPrevTrophies;
  final String frameAsset;
  final Color primaryColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool isFrozenTheme;
  final int simulatedActivePlayers;

  const VenezuelaRoomTier({
    required this.id,
    required this.name,
    required this.region,
    required this.subtitle,
    required this.entryFee,
    required this.basePrize,
    required this.trophyCap,
    required this.winTrophies,
    required this.lossTrophies,
    required this.requiredPrevTrophies,
    required this.frameAsset,
    required this.primaryColor,
    required this.accentColor,
    required this.gradientColors,
    this.isFrozenTheme = false,
    this.simulatedActivePlayers = 120,
  });

  /// Pozo total acumulado en la mesa según la modalidad de juego.
  /// 1v1: Entrada * 2
  /// 2v2: Entrada * 4
  int getTotalPot(GameMode mode) {
    return mode == GameMode.teams2v2 ? entryFee * 4 : entryFee * 2;
  }

  /// Premio neto a recibir por cada jugador ganador según la modalidad de juego.
  /// En 1v1 el ganador se lleva el pozo completo (entryFee * 2).
  /// En 2v2 cada miembro del equipo ganador se lleva la mitad del pozo total (entryFee * 2).
  int getPrizePerWinner(GameMode mode) {
    return mode == GameMode.teams2v2 ? (entryFee * 4) ~/ 2 : entryFee * 2;
  }

  /// Determina si un saldo de monedas es suficiente para pagar la tarifa de entrada.
  bool canAfford(int playerCoins) => playerCoins >= entryFee;

  /// Cantidad de participantes requeridos por partida.
  int get playersCount => 4; // En 1v1 participan 2 humanos/bots, en 2v2 participan 4
}

/// Catálogo oficial inmutable con las 7 salas regionales venezolanas.
class VenezuelaRoomCatalog {
  static const List<VenezuelaRoomTier> rooms = [
    // 1. Chivacoa (Yaracuy)
    VenezuelaRoomTier(
      id: 1,
      name: 'Chivacoa',
      region: 'Yaracuy',
      subtitle: 'Mesa del Alambique',
      entryFee: 200,
      basePrize: 400,
      trophyCap: 15,
      winTrophies: 3,
      lossTrophies: 0,
      requiredPrevTrophies: 0,
      frameAsset: 'assets/Tiers/box/1-SALAS.png',
      primaryColor: Color(0xFF10B981), // Esmeralda / Selva
      accentColor: Color(0xFF34D399),
      gradientColors: [Color(0xFF064E3B), Color(0xFF022C22)],
      simulatedActivePlayers: 340,
    ),

    // 2. Barquisimeto (Lara)
    VenezuelaRoomTier(
      id: 2,
      name: 'Barquisimeto',
      region: 'Lara',
      subtitle: 'Mesa Crepuscular',
      entryFee: 100,
      basePrize: 200,
      trophyCap: 30,
      winTrophies: 4,
      lossTrophies: -2,
      requiredPrevTrophies: 15,
      frameAsset: 'assets/Tiers/box/2-SALAS.png',
      primaryColor: Color(0xFFF59E0B), // Atardecer crepuscular
      accentColor: Color(0xFFFBBF24),
      gradientColors: [Color(0xFF78350F), Color(0xFF451A03)],
      simulatedActivePlayers: 285,
    ),

    // 3. Tucacas (Falcón)
    VenezuelaRoomTier(
      id: 3,
      name: 'Tucacas',
      region: 'Falcón',
      subtitle: 'Brisa Marina',
      entryFee: 500,
      basePrize: 1000,
      trophyCap: 60,
      winTrophies: 6,
      lossTrophies: -4,
      requiredPrevTrophies: 30,
      frameAsset: 'assets/Tiers/box/3-SALAS.png',
      primaryColor: Color(0xFF06B6D4), // Turquesa costero
      accentColor: Color(0xFF22D3EE),
      gradientColors: [Color(0xFF164E63), Color(0xFF083344)],
      simulatedActivePlayers: 210,
    ),

    // 4. Maracaibo (Zulia)
    VenezuelaRoomTier(
      id: 4,
      name: 'Maracaibo',
      region: 'Zulia',
      subtitle: 'Calor Zuliano',
      entryFee: 2500,
      basePrize: 5000,
      trophyCap: 75,
      winTrophies: 8,
      lossTrophies: -6,
      requiredPrevTrophies: 60,
      frameAsset: 'assets/Tiers/box/4-SALAS.png',
      primaryColor: Color(0xFFEF4444), // Fuego / Relámpago
      accentColor: Color(0xFFF87171),
      gradientColors: [Color(0xFF7F1D1D), Color(0xFF450A0A)],
      simulatedActivePlayers: 180,
    ),

    // 5. Mérida (Mérida) ❄️
    VenezuelaRoomTier(
      id: 5,
      name: 'Mérida',
      region: 'Páramo Andino ❄️',
      subtitle: 'Páramo y Baraja Helada',
      entryFee: 10000,
      basePrize: 20000,
      trophyCap: 100,
      winTrophies: 10,
      lossTrophies: -8,
      requiredPrevTrophies: 75,
      frameAsset: 'assets/Tiers/box/5-SALAS.png',
      primaryColor: Color(0xFF38BDF8), // Azul escarcha
      accentColor: Color(0xFFBAE6FD),
      gradientColors: [Color(0xFF0C4A6E), Color(0xFF082F49)],
      isFrozenTheme: true,
      simulatedActivePlayers: 135,
    ),

    // 6. Caracas (Distrito Capital)
    VenezuelaRoomTier(
      id: 6,
      name: 'Caracas',
      region: 'Distrito Capital',
      subtitle: 'La Gran Sultana',
      entryFee: 50000,
      basePrize: 100000,
      trophyCap: 125,
      winTrophies: 12,
      lossTrophies: -10,
      requiredPrevTrophies: 100,
      frameAsset: 'assets/Tiers/box/6-SALAS.png',
      primaryColor: Color(0xFFA855F7), // Morado imperial
      accentColor: Color(0xFFC084FC),
      gradientColors: [Color(0xFF581C87), Color(0xFF3B0764)],
      simulatedActivePlayers: 95,
    ),

    // 7. Margarita VIP (Nueva Esparta)
    VenezuelaRoomTier(
      id: 7,
      name: 'Margarita VIP',
      region: 'Nueva Esparta',
      subtitle: 'Casino del Caribe',
      entryFee: 250000,
      basePrize: 500000,
      trophyCap: 250,
      winTrophies: 15,
      lossTrophies: -12,
      requiredPrevTrophies: 125,
      frameAsset: 'assets/Tiers/box/7-SALAS.png',
      primaryColor: Color(0xFFEAB308), // Oro Casino
      accentColor: Color(0xFFFDE047),
      gradientColors: [Color(0xFF713F12), Color(0xFF422006)],
      simulatedActivePlayers: 64,
    ),
  ];

  /// Obtiene una sala por su identificador numérico (1..7).
  static VenezuelaRoomTier getById(int id) {
    return rooms.firstWhere(
      (r) => r.id == id,
      orElse: () => rooms.first,
    );
  }

  /// Obtiene la sala previa en la cadena de progresión.
  static VenezuelaRoomTier? getPreviousRoom(int id) {
    final index = rooms.indexWhere((r) => r.id == id);
    if (index > 0) return rooms[index - 1];
    return null;
  }
}
