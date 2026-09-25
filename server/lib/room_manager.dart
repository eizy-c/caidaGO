import 'dart:async';
import 'game_room.dart';
import 'models.dart';

/// Gestor global de salas activas en memoria para el servidor online de CaidaGO.
class RoomManager {
  static final RoomManager instance = RoomManager._internal();
  RoomManager._internal() {
    // Limpieza periódica de salas zombies o inactivas cada 10 minutos
    Timer.periodic(const Duration(minutes: 10), (_) => _cleanupInactiveRooms());
  }

  final Map<String, GameRoom> _rooms = {}; // roomId -> GameRoom
  final Map<String, String> _playerRoomMap = {}; // playerId -> roomId

  int get activeRoomsCount => _rooms.length;

  int get totalPlayersCount =>
      _rooms.values.fold(0, (sum, r) => sum + r.humanPlayersCount);

  /// Crea una nueva sala online en el servidor
  GameRoom createRoom({
    required String roomName,
    required String hostPlayerId,
    required String hostName,
    required int hostAvatarId,
    required String hostFrameId,
    int targetPlayers = 2,
    bool isPrivate = false,
    String? pinCode,
    bool isTeams = false,
    bool fillWithBots = true,
    int? regionalRoomId,
    int entryFee = 0,
    required dynamic hostSocket,
  }) {
    // Generar un ID único corto y limpio
    final roomId = 'ON-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final info = OnlineRoomInfo(
      roomId: roomId,
      roomName: roomName.isNotEmpty ? roomName : 'Sala de $hostName',
      hostName: hostName,
      hostAvatarId: hostAvatarId,
      hostFrameId: hostFrameId,
      targetPlayers: targetPlayers,
      currentPlayers: 1,
      isPrivate: isPrivate,
      pinCode: isPrivate ? pinCode?.trim() : null,
      isTeams: isTeams,
      fillWithBots: fillWithBots,
      regionalRoomId: regionalRoomId,
      entryFee: entryFee,
    );

    final room = GameRoom(
      roomInfo: info,
      hostPlayerId: hostPlayerId,
      onRoomEmpty: (id) => _removeRoom(id),
    );

    // Conectar el socket del host al asiento 0
    room.addPlayer(
      playerId: hostPlayerId,
      playerName: hostName,
      avatarId: hostAvatarId,
      frameId: hostFrameId,
      socket: hostSocket,
      pinCode: pinCode,
    );

    _rooms[roomId] = room;
    _playerRoomMap[hostPlayerId] = roomId;

    print('[RoomManager] Sala creada: $roomId ("${info.roomName}") por $hostName');
    return room;
  }

  /// Busca una sala por su ID
  GameRoom? getRoom(String roomId) => _rooms[roomId];

  /// Busca una sala privada por su PIN de 4 dígitos
  GameRoom? findRoomByPin(String pin) {
    final cleanPin = pin.trim();
    for (final room in _rooms.values) {
      if (room.roomInfo.isPrivate && room.roomInfo.pinCode == cleanPin) {
        if (!room.isFull && !room.isMatchStarted) {
          return room;
        }
      }
    }
    return null;
  }

  /// Retorna la lista de salas públicas disponibles para unirse desde el Lobby
  List<OnlineRoomInfo> listPublicRooms() {
    return _rooms.values
        .where((r) =>
            !r.roomInfo.isPrivate &&
            !r.isFull &&
            !r.isMatchStarted &&
            r.humanPlayersCount > 0)
        .map((r) => r.roomInfo)
        .toList();
  }

  /// Registra que un jugador se unió a una sala
  void registerPlayerInRoom(String playerId, String roomId) {
    _playerRoomMap[playerId] = roomId;
  }

  /// Obtiene la sala donde está jugando actualmente un jugador
  GameRoom? getRoomForPlayer(String playerId) {
    final roomId = _playerRoomMap[playerId];
    if (roomId == null) return null;
    return _rooms[roomId];
  }

  /// Desconecta y remueve a un jugador de su sala actual
  void handlePlayerDisconnect(String playerId) {
    final roomId = _playerRoomMap.remove(playerId);
    if (roomId != null) {
      final room = _rooms[roomId];
      room?.removePlayer(playerId);
    }
  }

  void _removeRoom(String roomId) {
    final room = _rooms.remove(roomId);
    if (room != null) {
      print('[RoomManager] Sala $roomId eliminada por inactividad/vacía.');
    }
  }

  void _cleanupInactiveRooms() {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _rooms.entries) {
      final room = entry.value;
      // Salas vacías o inactivas por más de 3 horas
      final isStale = now.difference(room.lastActivity).inHours >= 3;
      if (room.humanPlayersCount == 0 || isStale) {
        toRemove.add(entry.key);
      }
    }

    for (final id in toRemove) {
      _removeRoom(id);
    }
  }
}
