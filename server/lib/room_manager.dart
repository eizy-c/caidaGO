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
    // Generar un ID único de 5 caracteres alfanuméricos en mayúsculas (ej: K7X9B)
    String roomId;
    do {
      roomId = generateRoomId();
    } while (_rooms.containsKey(roomId));

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

  /// Genera un ID de sala de 5 caracteres alfanuméricos en mayúsculas (ej: K7X9B)
  static String generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = (now ^ (now >> 7));
    var n = rnd.abs();
    final buffer = StringBuffer();
    for (int i = 0; i < 5; i++) {
      buffer.write(chars[n % chars.length]);
      n = (n ~/ chars.length) ^ (DateTime.now().microsecond + i * 31);
    }
    return buffer.toString();
  }

  /// Busca una sala por su ID de 5 caracteres (insensible a mayúsculas/minúsculas)
  GameRoom? getRoom(String roomId) {
    final cleanId = roomId.trim().toUpperCase();
    return _rooms[cleanId];
  }

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

  /// Retorna la lista de todas las salas abiertas (públicas y privadas) disponibles para unirse
  List<OnlineRoomInfo> listOpenRooms() {
    return _rooms.values
        .where((r) =>
            !r.isFull &&
            !r.isMatchStarted &&
            r.humanPlayersCount > 0)
        .map((r) => r.roomInfo)
        .toList();
  }

  /// Retorna la lista de salas públicas disponibles para unirse
  List<OnlineRoomInfo> listPublicRooms() => listOpenRooms();

  /// Emparejamiento Rápido: Encuentra una sala pública abierta o crea una instantánea
  GameRoom findOrCreateQuickMatch({
    required String playerId,
    required String playerName,
    required int avatarId,
    required String frameId,
    int targetPlayers = 2,
    int? regionalRoomId,
    int entryFee = 0,
    required dynamic socket,
  }) {
    // 1. Buscar si hay una sala pública abierta que coincida
    for (final room in _rooms.values) {
      if (!room.roomInfo.isPrivate &&
          !room.isFull &&
          !room.isMatchStarted &&
          room.roomInfo.targetPlayers == targetPlayers &&
          (regionalRoomId == null || room.roomInfo.regionalRoomId == regionalRoomId)) {
        final success = room.addPlayer(
          playerId: playerId,
          playerName: playerName,
          avatarId: avatarId,
          frameId: frameId,
          socket: socket,
        );
        if (success) {
          registerPlayerInRoom(playerId, room.roomInfo.roomId);
          print('[RoomManager] ⚡ Emparejamiento Rápido: $playerName unido a ${room.roomInfo.roomId}');

          if (room.isFull) {
            room.startMatch();
          }
          return room;
        }
      }
    }

    // 2. Si no hay sala disponible, crear una automáticamente
    final newRoom = createRoom(
      roomName: 'Partida Rápida',
      hostPlayerId: playerId,
      hostName: playerName,
      hostAvatarId: avatarId,
      hostFrameId: frameId,
      targetPlayers: targetPlayers,
      isPrivate: false,
      isTeams: targetPlayers == 4,
      fillWithBots: true,
      regionalRoomId: regionalRoomId,
      entryFee: entryFee,
      hostSocket: socket,
    );

    // Temporizador de 7 segundos: si nadie más entra, autocompletar con bots y arrancar
    Timer(const Duration(seconds: 7), () {
      final currentRoom = _rooms[newRoom.roomInfo.roomId];
      if (currentRoom != null && !currentRoom.isMatchStarted && currentRoom.humanPlayersCount > 0) {
        print('[RoomManager] ⚡ Tiempo cumplido para ${newRoom.roomInfo.roomId}. Llenando con bots e iniciando.');
        currentRoom.fillEmptySeatsWithBots();
        currentRoom.startMatch();
      }
    });

    return newRoom;
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
