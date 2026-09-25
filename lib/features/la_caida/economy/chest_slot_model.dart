import 'dart:math' as math;
import 'booster_model.dart';

enum ChestState {
  empty,
  unlocking,
  ready,
}

enum ChestRarity {
  madera,
  bronce,
  plata,
  oro,
  vip,
}

/// Resultado estructurado de abrir un cofre
class ChestRewardResult {
  final int coins;
  final int xp;
  final int trophies;
  final BoosterType? booster;
  final ChestRarity rarity;

  const ChestRewardResult({
    required this.coins,
    required this.xp,
    required this.trophies,
    this.booster,
    required this.rarity,
  });
}

/// Modelo de datos para un slot de cofre en el lobby principal.
/// Se desbloquea con temporizador de 2 minutos o instantáneamente por 2 tickets.
class ChestSlotModel {
  final int slotIndex; // 0, 1, 2, 3
  final String? id;
  final ChestRarity rarity;
  final DateTime? unlockStartedAtUtc;
  final int durationSeconds; // 120 s por defecto (2 minutos)
  final bool isOpened;

  static const int standardDurationSeconds = 120; // 2 minutos
  static const int instantTicketCost = 2; // 2 tickets para abrir de inmediato
  static const int minRewardCoins = 50;
  static const int maxRewardCoins = 5000;

  const ChestSlotModel({
    required this.slotIndex,
    this.id,
    this.rarity = ChestRarity.madera,
    this.unlockStartedAtUtc,
    this.durationSeconds = standardDurationSeconds,
    this.isOpened = false,
  });

  /// Crea un slot vacío por defecto
  factory ChestSlotModel.empty(int index) => ChestSlotModel(slotIndex: index);

  /// Crea un nuevo cofre asignado tras una victoria e inicia su cuenta regresiva de 2 min
  factory ChestSlotModel.newWonChest(int index, {ChestRarity rarity = ChestRarity.madera, DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return ChestSlotModel(
      slotIndex: index,
      id: 'chest_${now.millisecondsSinceEpoch}_$index',
      rarity: rarity,
      unlockStartedAtUtc: now,
      durationSeconds: standardDurationSeconds,
      isOpened: false,
    );
  }

  bool get isEmpty => id == null || isOpened;

  /// Retorna el estado actual del cofre evaluando el tiempo transcurrido
  ChestState getState({DateTime? nowUtc}) {
    if (isEmpty) return ChestState.empty;
    if (unlockStartedAtUtc == null) return ChestState.ready;

    final now = (nowUtc ?? DateTime.now()).toUtc();
    final elapsedSeconds = now.difference(unlockStartedAtUtc!).inSeconds;
    if (elapsedSeconds >= durationSeconds) {
      return ChestState.ready;
    }
    return ChestState.unlocking;
  }

  /// Retorna el tiempo restante para poder abrir el cofre
  Duration getRemainingDuration({DateTime? nowUtc}) {
    if (isEmpty || unlockStartedAtUtc == null) return Duration.zero;

    final now = (nowUtc ?? DateTime.now()).toUtc();
    final elapsed = now.difference(unlockStartedAtUtc!);
    final totalDuration = Duration(seconds: durationSeconds);
    final remaining = totalDuration - elapsed;
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  /// Formato legible del tiempo restante (ej. "01:45")
  String getFormattedRemainingTime({DateTime? nowUtc}) {
    final rem = getRemainingDuration(nowUtc: nowUtc);
    if (rem == Duration.zero) return '¡LISTO!';
    final minutes = rem.inMinutes.toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Genera una cantidad de monedas regulada según la rareza del cofre
  int generateRewardCoins({math.Random? random}) {
    final rng = random ?? math.Random();
    switch (rarity) {
      case ChestRarity.madera:
        return 30 + rng.nextInt(121); // 30 - 150
      case ChestRarity.bronce:
        return 100 + rng.nextInt(251); // 100 - 350
      case ChestRarity.plata:
        return 250 + rng.nextInt(551); // 250 - 800
      case ChestRarity.oro:
        return 600 + rng.nextInt(1401); // 600 - 2000
      case ChestRarity.vip:
        return 1500 + rng.nextInt(2501); // 1500 - 4000
    }
  }

  /// Genera XP de recompensa moderada según la rareza
  int generateRewardXp({math.Random? random}) {
    final rng = random ?? math.Random();
    switch (rarity) {
      case ChestRarity.madera:
        return 20 + rng.nextInt(25);
      case ChestRarity.bronce:
        return 40 + rng.nextInt(35);
      case ChestRarity.plata:
        return 75 + rng.nextInt(50);
      case ChestRarity.oro:
        return 120 + rng.nextInt(80);
      case ChestRarity.vip:
        return 250 + rng.nextInt(150);
    }
  }

  /// Genera trofeos de bonificación según la categoría de la sala
  int generateRewardTrophies({math.Random? random}) {
    final rng = random ?? math.Random();
    switch (rarity) {
      case ChestRarity.madera:
        return 1 + rng.nextInt(3); // 1 - 3
      case ChestRarity.bronce:
        return 3 + rng.nextInt(4); // 3 - 6
      case ChestRarity.plata:
        return 6 + rng.nextInt(7); // 6 - 12
      case ChestRarity.oro:
        return 12 + rng.nextInt(14); // 12 - 25
      case ChestRarity.vip:
        return 25 + rng.nextInt(26); // 25 - 50
    }
  }

  /// Genera un potenciador aleatorio escalado según la rareza
  BoosterType? generateRewardBooster({math.Random? random}) {
    final rng = random ?? math.Random();
    final double chance;
    switch (rarity) {
      case ChestRarity.madera:
        chance = 0.35;
        break;
      case ChestRarity.bronce:
        chance = 0.55;
        break;
      case ChestRarity.plata:
        chance = 0.75;
        break;
      case ChestRarity.oro:
      case ChestRarity.vip:
        chance = 1.0;
        break;
    }
    if (rng.nextDouble() < chance) {
      const types = BoosterType.values;
      return types[rng.nextInt(types.length)];
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'slotIndex': slotIndex,
        'id': id,
        'rarity': rarity.name,
        'unlockStartedAtUtc': unlockStartedAtUtc?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'isOpened': isOpened,
      };

  factory ChestSlotModel.fromJson(Map<String, dynamic> json) {
    final rarityStr = json['rarity'] as String? ?? 'madera';
    final rarity = ChestRarity.values.where((r) => r.name == rarityStr).firstOrNull ?? ChestRarity.madera;
    final timeStr = json['unlockStartedAtUtc'] as String?;

    return ChestSlotModel(
      slotIndex: json['slotIndex'] as int? ?? 0,
      id: json['id'] as String?,
      rarity: rarity,
      unlockStartedAtUtc: timeStr != null ? DateTime.tryParse(timeStr)?.toUtc() : null,
      durationSeconds: json['durationSeconds'] as int? ?? standardDurationSeconds,
      isOpened: json['isOpened'] as bool? ?? false,
    );
  }
}
