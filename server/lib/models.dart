import 'dart:convert';

/// Estado de un asiento en una sala online.
/// Incluye los elementos de personalización del jugador: avatar, marco (frameId), nombre.
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

/// Metadatos y configuración de una sala multijugador online.
class OnlineRoomInfo {
  final String roomId;
  final String roomName;
  final String hostName;
  final int hostAvatarId;
  final String hostFrameId;
  final int targetPlayers; // 2, 3 o 4
  final int currentPlayers;
  final bool isPrivate;
  final String? pinCode; // 4 dígitos si es privada
  final bool isTeams; // Por parejas (2 vs 2)
  final bool fillWithBots;
  final int? regionalRoomId; // ID 1..7 de Sala de Venezuela (o null para Libre)
  final int entryFee; // Apuesta por jugador

  const OnlineRoomInfo({
    required this.roomId,
    required this.roomName,
    required this.hostName,
    this.hostAvatarId = 0,
    this.hostFrameId = 'rank_novato',
    this.targetPlayers = 2,
    this.currentPlayers = 1,
    this.isPrivate = false,
    this.pinCode,
    this.isTeams = false,
    this.fillWithBots = true,
    this.regionalRoomId,
    this.entryFee = 0,
  });

  bool get isFull => currentPlayers >= targetPlayers;

  int get totalPot =>
      isTeams && targetPlayers == 4 ? entryFee * 4 : entryFee * targetPlayers;

  OnlineRoomInfo copyWith({
    String? roomId,
    String? roomName,
    String? hostName,
    int? hostAvatarId,
    String? hostFrameId,
    int? targetPlayers,
    int? currentPlayers,
    bool? isPrivate,
    String? pinCode,
    bool? isTeams,
    bool? fillWithBots,
    int? regionalRoomId,
    int? entryFee,
  }) {
    return OnlineRoomInfo(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      hostName: hostName ?? this.hostName,
      hostAvatarId: hostAvatarId ?? this.hostAvatarId,
      hostFrameId: hostFrameId ?? this.hostFrameId,
      targetPlayers: targetPlayers ?? this.targetPlayers,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      isPrivate: isPrivate ?? this.isPrivate,
      pinCode: pinCode ?? this.pinCode,
      isTeams: isTeams ?? this.isTeams,
      fillWithBots: fillWithBots ?? this.fillWithBots,
      regionalRoomId: regionalRoomId ?? this.regionalRoomId,
      entryFee: entryFee ?? this.entryFee,
    );
  }

  Map<String, dynamic> toJson({bool includePin = true}) => {
        'roomId': roomId,
        'roomName': roomName,
        'hostName': hostName,
        'hostAvatarId': hostAvatarId,
        'hostFrameId': hostFrameId,
        'targetPlayers': targetPlayers,
        'currentPlayers': currentPlayers,
        'isPrivate': isPrivate,
        if (includePin) 'pinCode': pinCode,
        'isTeams': isTeams,
        'fillWithBots': fillWithBots,
        'regionalRoomId': regionalRoomId,
        'entryFee': entryFee,
        'networkMode': 'online',
      };

  factory OnlineRoomInfo.fromJson(Map<String, dynamic> json) => OnlineRoomInfo(
        roomId: json['roomId'] as String? ?? '',
        roomName: json['roomName'] as String? ?? 'Sala Online',
        hostName: json['hostName'] as String? ?? 'Anfitrión',
        hostAvatarId: json['hostAvatarId'] as int? ?? 0,
        hostFrameId: json['hostFrameId'] as String? ?? 'rank_novato',
        targetPlayers: json['targetPlayers'] as int? ?? 2,
        currentPlayers: json['currentPlayers'] as int? ?? 1,
        isPrivate: json['isPrivate'] as bool? ?? false,
        pinCode: json['pinCode'] as String?,
        isTeams: json['isTeams'] as bool? ?? false,
        fillWithBots: json['fillWithBots'] as bool? ?? true,
        regionalRoomId: json['regionalRoomId'] as int?,
        entryFee: json['entryFee'] as int? ?? 0,
      );
}

/// Mensaje estándar JSON que viaja por WebSocket
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

  static NetworkGameMessage? deserialize(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NetworkGameMessage(
        type: map['type'] as String? ?? 'UNKNOWN',
        data: (map['data'] as Map<String, dynamic>?) ?? {},
      );
    } catch (_) {
      return null;
    }
  }
}
