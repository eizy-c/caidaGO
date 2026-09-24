import 'dart:convert';
import '../network/multiplayer_security.dart';

/// Modo de red de la sala
enum MultiplayerNetworkMode {
  localWifi,
  online,
}

/// Estado de un asiento de jugador en la sala
class RoomSeat {
  final int seatIndex;
  final String? playerId;
  final String name;
  final int avatarId;
  final String frameId;
  final bool isBot;
  final bool isReady;
  final bool isHost;

  const RoomSeat({
    required this.seatIndex,
    this.playerId,
    required this.name,
    this.avatarId = 0,
    this.frameId = 'rank_novato',
    this.isBot = false,
    this.isReady = false,
    this.isHost = false,
  });

  bool get isOccupied => playerId != null || isBot;

  RoomSeat copyWith({
    int? seatIndex,
    String? playerId,
    String? name,
    int? avatarId,
    String? frameId,
    bool? isBot,
    bool? isReady,
    bool? isHost,
  }) {
    return RoomSeat(
      seatIndex: seatIndex ?? this.seatIndex,
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      frameId: frameId ?? this.frameId,
      isBot: isBot ?? this.isBot,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
    );
  }

  Map<String, dynamic> toJson() => {
        'seatIndex': seatIndex,
        'playerId': playerId,
        'name': name,
        'avatarId': avatarId,
        'frameId': frameId,
        'isBot': isBot,
        'isReady': isReady,
        'isHost': isHost,
      };

  factory RoomSeat.fromJson(Map<String, dynamic> json) => RoomSeat(
        seatIndex: json['seatIndex'] as int,
        playerId: json['playerId'] as String?,
        name: json['name'] as String? ?? 'Jugador',
        avatarId: json['avatarId'] as int? ?? 0,
        frameId: json['frameId'] as String? ?? 'rank_novato',
        isBot: json['isBot'] as bool? ?? false,
        isReady: json['isReady'] as bool? ?? false,
        isHost: json['isHost'] as bool? ?? false,
      );
}

/// Metadatos y configuración de una sala multijugador
class MultiplayerRoomInfo {
  final String roomId;
  final String roomName;
  final String hostName;
  final int hostAvatarId;
  final String hostFrameId;
  final String hostIp;
  final int port;
  final int targetPlayers; // 2, 3 o 4
  final int currentPlayers;
  final bool isPrivate;
  final String? pinCode; // 4 dígitos si es privada
  final bool isTeams; // Por parejas (solo válido para 4 jugadores)
  final bool fillWithBots;
  final MultiplayerNetworkMode networkMode;
  final int? regionalRoomId; // ID 1..7 de Sala de Venezuela (o null para Libre)
  final int entryFee; // Apuesta por jugador (0 para mesa libre)

  const MultiplayerRoomInfo({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    this.hostAvatarId = 0,
    this.hostFrameId = 'rank_novato',
    required this.hostIp,
    this.port = 45456,
    this.targetPlayers = 2,
    this.currentPlayers = 1,
    this.isPrivate = false,
    this.pinCode,
    this.isTeams = false,
    this.fillWithBots = true,
    this.networkMode = MultiplayerNetworkMode.localWifi,
    this.regionalRoomId,
    this.entryFee = 0,
  });

  bool get isFull => currentPlayers >= targetPlayers;

  int get totalPot => isTeams && targetPlayers == 4 ? entryFee * 4 : entryFee * targetPlayers;
  int get prizePerWinner => isTeams && targetPlayers == 4 ? (entryFee * 4) ~/ 2 : entryFee * targetPlayers;

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomName': roomName,
        'hostName': hostName,
        'hostAvatarId': hostAvatarId,
        'hostFrameId': hostFrameId,
        'hostIp': hostIp,
        'port': port,
        'targetPlayers': targetPlayers,
        'currentPlayers': currentPlayers,
        'isPrivate': isPrivate,
        'pinCode': pinCode,
        'isTeams': isTeams,
        'fillWithBots': fillWithBots,
        'networkMode': networkMode.name,
        'regionalRoomId': regionalRoomId,
        'entryFee': entryFee,
      };

  factory MultiplayerRoomInfo.fromJson(Map<String, dynamic> json) =>
      MultiplayerRoomInfo(
        roomId: json['roomId'] as String? ?? '',
        roomName: json['roomName'] as String? ?? 'Sala CaidaGO',
        hostName: json['hostName'] as String? ?? 'Anfitrión',
        hostAvatarId: json['hostAvatarId'] as int? ?? 0,
        hostFrameId: json['hostFrameId'] as String? ?? 'rank_novato',
        hostIp: json['hostIp'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 45456,
        targetPlayers: json['targetPlayers'] as int? ?? 2,
        currentPlayers: json['currentPlayers'] as int? ?? 1,
        isPrivate: json['isPrivate'] as bool? ?? false,
        pinCode: json['pinCode'] as String?,
        isTeams: json['isTeams'] as bool? ?? false,
        fillWithBots: json['fillWithBots'] as bool? ?? true,
        networkMode: json['networkMode'] == 'online'
            ? MultiplayerNetworkMode.online
            : MultiplayerNetworkMode.localWifi,
        regionalRoomId: json['regionalRoomId'] as int?,
        entryFee: json['entryFee'] as int? ?? 0,
      );

  String toBeaconPayload() => jsonEncode({
        'protocol': 'CAIDAGO_LOCAL_V1',
        ...toJson(),
        // No enviamos el PIN en el beacon broadcast por seguridad, solo que es privada
        'pinCode': null,
      });

  static MultiplayerRoomInfo? fromBeaconPayload(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['protocol'] != 'CAIDAGO_LOCAL_V1') return null;
      return MultiplayerRoomInfo.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

/// Mensaje que transita por WebSocket entre Host y Clientes
class NetworkGameMessage {
  final String type;
  final Map<String, dynamic> data;

  const NetworkGameMessage({
    required this.type,
    this.data = const {},
  });

  String serialize() => jsonEncode({
        'type': type,
        'data': data,
      });

  /// Serializa el mensaje y le aplica la capa de cifrado para red local
  String serializeSecure({String? pinCode, String? roomId}) {
    final plain = serialize();
    return MultiplayerSecurity.encryptPayload(plain, pinCode: pinCode, roomId: roomId);
  }

  static NetworkGameMessage? deserialize(String raw, {String? pinCode, String? roomId}) {
    try {
      final decrypted = MultiplayerSecurity.decryptPayload(raw, pinCode: pinCode, roomId: roomId);
      if (decrypted == null) return null;

      final map = jsonDecode(decrypted) as Map<String, dynamic>;
      return NetworkGameMessage(
        type: map['type'] as String? ?? 'UNKNOWN',
        data: (map['data'] as Map<String, dynamic>?) ?? {},
      );
    } catch (_) {
      return null;
    }
  }
}

