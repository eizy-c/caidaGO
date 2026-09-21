import 'package:flutter/material.dart';

enum BoosterType {
  xp,     // Racha Dorada: x2 XP
  coins,  // Lluvia de Monedas: +50% monedas si ganas (dura 3 partidas)
  shield, // Escudo de Trofeos: no pierdes trofeos si eres derrotado (dura 1 partida)
  lucky,  // Comodín: +10 trofeos extra al ganar (dura 2 partidas)
  regen,  // Recarga Express: regeneración de tickets x2 de velocidad (dura 60 min)
}

class BoosterDefinition {
  final BoosterType type;
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int defaultMatches; // Si es por partidas
  final int? durationMinutes; // Si es por tiempo
  final int coinCost;

  const BoosterDefinition({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.defaultMatches = 1,
    this.durationMinutes,
    required this.coinCost,
  });

  static const List<BoosterDefinition> catalog = [
    BoosterDefinition(
      type: BoosterType.xp,
      id: 'booster_xp',
      name: 'Racha Dorada',
      description: 'x2 de Experiencia (XP) en la próxima partida',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
      defaultMatches: 1,
      coinCost: 300,
    ),
    BoosterDefinition(
      type: BoosterType.coins,
      id: 'booster_coins',
      name: 'Lluvia de Monedas',
      description: '+50% de monedas en victorias durante 3 partidas',
      icon: Icons.monetization_on_rounded,
      color: Color(0xFFEAB308),
      defaultMatches: 3,
      coinCost: 350,
    ),
    BoosterDefinition(
      type: BoosterType.shield,
      id: 'booster_shield',
      name: 'Escudo de Trofeos',
      description: 'Si pierdes, tus trofeos no disminuyen (1 partida)',
      icon: Icons.shield_rounded,
      color: Color(0xFF38BDF8),
      defaultMatches: 1,
      coinCost: 400,
    ),
    BoosterDefinition(
      type: BoosterType.lucky,
      id: 'booster_lucky',
      name: 'Comodín de Mesa',
      description: '+10 trofeos adicionales al ganar durante 2 partidas',
      icon: Icons.stars_rounded,
      color: Color(0xFFA855F7),
      defaultMatches: 2,
      coinCost: 350,
    ),
    BoosterDefinition(
      type: BoosterType.regen,
      id: 'booster_regen',
      name: 'Recarga Express',
      description: 'Recupera tickets en la mitad de tiempo (60 min)',
      icon: Icons.timer_rounded,
      color: Color(0xFF10B981),
      defaultMatches: 0,
      durationMinutes: 60,
      coinCost: 280,
    ),
  ];

  static BoosterDefinition getByType(BoosterType type) {
    return catalog.firstWhere((b) => b.type == type, orElse: () => catalog.first);
  }

  static BoosterDefinition getById(String id) {
    return catalog.firstWhere((b) => b.id == id, orElse: () => catalog.first);
  }
}

/// Instancia de un potenciador activo o en inventario
class UserBooster {
  final String instanceId;
  final BoosterType type;
  int remainingMatches;
  DateTime? expiresAtUtc;

  UserBooster({
    required this.instanceId,
    required this.type,
    this.remainingMatches = 1,
    this.expiresAtUtc,
  });

  BoosterDefinition get definition => BoosterDefinition.getByType(type);

  bool get isExpired {
    if (expiresAtUtc != null) {
      return DateTime.now().toUtc().isAfter(expiresAtUtc!);
    }
    return remainingMatches <= 0;
  }

  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'type': type.name,
    'remainingMatches': remainingMatches,
    'expiresAtUtc': expiresAtUtc?.toIso8601String(),
  };

  factory UserBooster.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'xp';
    final type = BoosterType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => BoosterType.xp,
    );
    return UserBooster(
      instanceId: json['instanceId'] as String? ?? 'b_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      remainingMatches: json['remainingMatches'] as int? ?? 1,
      expiresAtUtc: json['expiresAtUtc'] != null
          ? DateTime.tryParse(json['expiresAtUtc'] as String)?.toUtc()
          : null,
    );
  }
}
