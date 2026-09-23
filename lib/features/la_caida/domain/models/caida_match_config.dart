import '../../economy/venezuela_room_tier.dart';
import '../../economy/vip_tier.dart';

/// Configuración inmutable para inicializar y parametrizar una partida de La Caída.
/// Reemplaza la proliferación de parámetros individuales dispersos en constructores.
class CaidaMatchConfig {
  final int initialPlayers;
  final bool autoStart;
  final bool animateDealing;
  final bool initialTeams;
  final bool chooseMano;
  final String? userName;
  final List<String> botNames;
  final VipTierOffer? vipTier;
  final VenezuelaRoomTier? venezuelaRoom;
  final int? vipPrizePool;
  final int? vipWinnerReward;
  final bool isMatandoCantos;
  final bool isMultiplayer;
  final List<String>? playerNames;
  final List<int>? playerAvatarIds;
  final List<String>? playerFrameIds;

  const CaidaMatchConfig({
    this.initialPlayers = 2,
    this.autoStart = false,
    this.animateDealing = true,
    this.initialTeams = false,
    this.chooseMano = false,
    this.userName,
    this.botNames = const ['Alejandro', 'Carl', 'Jhonny'],
    this.vipTier,
    this.venezuelaRoom,
    this.vipPrizePool,
    this.vipWinnerReward,
    this.isMatandoCantos = true,
    this.isMultiplayer = false,
    this.playerNames,
    this.playerAvatarIds,
    this.playerFrameIds,
  });

  /// Crea una configuración para partida individual rápida
  factory CaidaMatchConfig.quickMatch({
    required String userName,
    int players = 2,
    bool teams = false,
    bool? isTeams,
    bool chooseMano = true,
    List<String> botNames = const ['Alejandro', 'Carl', 'Jhonny'],
    bool isMatandoCantos = true,
  }) {
    final effectiveTeams = isTeams ?? teams;
    return CaidaMatchConfig(
      initialPlayers: players,
      initialTeams: effectiveTeams,
      autoStart: true,
      chooseMano: chooseMano,
      userName: userName,
      botNames: botNames,
      isMatandoCantos: isMatandoCantos,
    );
  }

  /// Crea una configuración para mesa VIP con apuesta
  factory CaidaMatchConfig.vipMatch({
    required String userName,
    required VipTierOffer tier,
    required bool isTeams,
    List<String> botNames = const ['Alejandro', 'Carl', 'Jhonny'],
    bool isMatandoCantos = true,
  }) {
    return CaidaMatchConfig(
      initialPlayers: isTeams ? 4 : 2,
      initialTeams: isTeams,
      autoStart: true,
      chooseMano: true,
      userName: userName,
      botNames: botNames,
      vipTier: tier,
      vipPrizePool: tier.calculatePrizePool(isTeams: isTeams),
      vipWinnerReward: tier.calculateNetPrizePerWinner(isTeams: isTeams),
      isMatandoCantos: isMatandoCantos,
    );
  }

  /// Crea una configuración para sala VIP Regional de Venezuela
  factory CaidaMatchConfig.venezuelaRoomMatch({
    required String userName,
    required VenezuelaRoomTier room,
    required GameMode mode,
    List<String> botNames = const ['Alejandro', 'Carl', 'Jhonny'],
    bool isMatandoCantos = true,
  }) {
    final isTeams = mode == GameMode.teams2v2;
    return CaidaMatchConfig(
      initialPlayers: isTeams ? 4 : 2,
      initialTeams: isTeams,
      autoStart: true,
      chooseMano: true,
      userName: userName,
      botNames: botNames,
      venezuelaRoom: room,
      vipPrizePool: room.getTotalPot(mode),
      vipWinnerReward: room.getPrizePerWinner(mode),
      isMatandoCantos: isMatandoCantos,
    );
  }

  int get botCount => (initialPlayers - 1).clamp(1, 3);
  bool get isVip => vipTier != null || venezuelaRoom != null;

  CaidaMatchConfig copyWith({
    int? initialPlayers,
    bool? autoStart,
    bool? animateDealing,
    bool? initialTeams,
    bool? chooseMano,
    String? userName,
    List<String>? botNames,
    VipTierOffer? vipTier,
    VenezuelaRoomTier? venezuelaRoom,
    int? vipPrizePool,
    int? vipWinnerReward,
    bool? isMatandoCantos,
  }) {
    return CaidaMatchConfig(
      initialPlayers: initialPlayers ?? this.initialPlayers,
      autoStart: autoStart ?? this.autoStart,
      animateDealing: animateDealing ?? this.animateDealing,
      initialTeams: initialTeams ?? this.initialTeams,
      chooseMano: chooseMano ?? this.chooseMano,
      userName: userName ?? this.userName,
      botNames: botNames ?? this.botNames,
      vipTier: vipTier ?? this.vipTier,
      venezuelaRoom: venezuelaRoom ?? this.venezuelaRoom,
      vipPrizePool: vipPrizePool ?? this.vipPrizePool,
      vipWinnerReward: vipWinnerReward ?? this.vipWinnerReward,
      isMatandoCantos: isMatandoCantos ?? this.isMatandoCantos,
    );
  }
}
