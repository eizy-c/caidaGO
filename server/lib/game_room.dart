import 'dart:async';
import 'models.dart';

/// Callback para notificar cuando la sala queda vacía y deba eliminarse.
typedef OnRoomEmptyCallback = void Function(String roomId);

/// Orquestador de una sala de juego online en el servidor.
class GameRoom {
  OnlineRoomInfo roomInfo;
  final List<RoomSeat> seats = [];
  final Map<String, dynamic> _clientSockets = {}; // playerId -> WebSocketChannel
  final OnRoomEmptyCallback? onRoomEmpty;

  bool isMatchStarted = false;
  DateTime lastActivity = DateTime.now();
  Timer? _emptyGraceTimer;

  GameRoom({
    required this.roomInfo,
    required String hostPlayerId,
    this.onRoomEmpty,
  }) {
    _initializeSeats(hostPlayerId);
  }

  void _initializeSeats(String hostPlayerId) {
    seats.clear();

    // Asiento 0: Anfitrión (con su marco y avatar personalizados)
    seats.add(RoomSeat(
      seatIndex: 0,
      playerId: hostPlayerId,
      name: roomInfo.hostName,
      avatarId: roomInfo.hostAvatarId,
      frameId: roomInfo.hostFrameId,
      isBot: false,
      isReady: true,
      isHost: true,
    ));

    // Asientos restantes según targetPlayers (2, 3 o 4)
    for (int i = 1; i < roomInfo.targetPlayers; i++) {
      seats.add(RoomSeat(
        seatIndex: i,
        playerId: null,
        name: 'Esperando...',
        isBot: false,
        isReady: false,
        isHost: false,
      ));
    }
  }

  int get humanPlayersCount =>
      seats.where((s) => s.playerId != null && !s.isBot).length;

  bool get isFull => seats.every((s) => s.isOccupied);

  /// Intenta unir a un nuevo jugador a la sala con sus marcos y avatares personalizados.
  bool addPlayer({
    required String playerId,
    required String playerName,
    required int avatarId,
    required String frameId,
    required dynamic socket,
    String? pinCode,
  }) {
    lastActivity = DateTime.now();

    final existingIndex = seats.indexWhere((s) => s.playerId == playerId);
    final isReconnecting = existingIndex != -1;
    final isReturningHost = roomInfo.hostName.trim().toLowerCase() == playerName.trim().toLowerCase();

    // 1. Validar PIN si la sala es privada (pero si está reconectando o es el anfitrión, no exigir PIN)
    if (roomInfo.isPrivate && !isReconnecting && !isReturningHost) {
      if (pinCode == null || pinCode.trim() != roomInfo.pinCode?.trim()) {
        _sendToSocket(
          socket,
          const NetworkGameMessage(
            type: 'JOIN_REJECTED',
            data: {
              'reason': 'PIN_INCORRECTO',
              'message': 'El PIN de 4 dígitos es incorrecto.',
            },
          ),
        );
        return false;
      }
    }

    // 2. Si el jugador ya estaba en la sala (reconectar)
    if (isReconnecting) {
      _emptyGraceTimer?.cancel();
      _emptyGraceTimer = null;
      _clientSockets[playerId] = socket;
      seats[existingIndex] = seats[existingIndex].copyWith(
        name: playerName,
        avatarId: avatarId,
        frameId: frameId,
        isConnected: true,
      );
      _sendJoinAccepted(socket, existingIndex, playerId);
      broadcastLobbyUpdate();
      print('[GameRoom] Jugador reconectado a sala ${roomInfo.roomId}: $playerName (asiento $existingIndex)');
      return true;
    }

    // Si es el anfitrión que regresa tras salir al menú/fondo
    if (isReturningHost && (seats.isEmpty || !seats[0].isOccupied || seats[0].isHost)) {
      _emptyGraceTimer?.cancel();
      _emptyGraceTimer = null;
      _clientSockets[playerId] = socket;
      seats[0] = seats[0].copyWith(
        playerId: playerId,
        name: playerName,
        avatarId: avatarId,
        frameId: frameId,
        isHost: true,
        isConnected: true,
      );
      _sendJoinAccepted(socket, 0, playerId);
      broadcastLobbyUpdate();
      print('[GameRoom] Anfitrión restablecido en sala ${roomInfo.roomId}: $playerName');
      return true;
    }

    // 3. Buscar asiento libre
    final freeSeatIndex = seats.indexWhere((s) => !s.isOccupied);
    if (freeSeatIndex == -1) {
      _sendToSocket(
        socket,
        const NetworkGameMessage(
          type: 'JOIN_REJECTED',
          data: {
            'reason': 'SALA_LLENA',
            'message': 'La sala ya está completa.',
          },
        ),
      );
      return false;
    }

    // 4. Asignar asiento con la personalización completa del jugador
    _emptyGraceTimer?.cancel();
    _emptyGraceTimer = null;
    seats[freeSeatIndex] = RoomSeat(
      seatIndex: freeSeatIndex,
      playerId: playerId,
      name: playerName,
      avatarId: avatarId,
      frameId: frameId,
      isBot: false,
      isReady: false,
      isHost: freeSeatIndex == 0,
      isConnected: true,
    );

    _clientSockets[playerId] = socket;
    roomInfo = roomInfo.copyWith(currentPlayers: humanPlayersCount);

    _sendJoinAccepted(socket, freeSeatIndex, playerId);
    broadcastLobbyUpdate();
    return true;
  }

  void _sendJoinAccepted(dynamic socket, int seatIndex, String playerId) {
    _sendToSocket(
      socket,
      NetworkGameMessage(
        type: 'JOIN_ACCEPTED',
        data: {
          'seatIndex': seatIndex,
          'playerId': playerId,
          'roomInfo': roomInfo.toJson(),
          'seats': seats.map((s) => s.toJson()).toList(),
        },
      ),
    );
  }

  /// Alterna el estado "Listo" de un jugador
  void togglePlayerReady(String playerId) {
    lastActivity = DateTime.now();
    final index = seats.indexWhere((s) => s.playerId == playerId);
    if (index == -1) return;

    final current = seats[index];
    seats[index] = current.copyWith(isReady: !current.isReady);
    broadcastLobbyUpdate();
  }

  /// Cambia al jugador a otro asiento disponible (útil en 2 vs 2 para elegir parejas)
  void switchPlayerSeat(String playerId, int targetSeatIndex) {
    lastActivity = DateTime.now();
    if (targetSeatIndex < 0 || targetSeatIndex >= seats.length) return;

    final currentIndex = seats.indexWhere((s) => s.playerId == playerId);
    if (currentIndex == -1 || currentIndex == targetSeatIndex) return;

    final targetSeat = seats[targetSeatIndex];
    if (targetSeat.isOccupied) return;

    final movingPlayer = seats[currentIndex];
    seats[targetSeatIndex] = movingPlayer.copyWith(
      seatIndex: targetSeatIndex,
      isReady: false,
    );

    seats[currentIndex] = RoomSeat(
      seatIndex: currentIndex,
      playerId: null,
      name: 'Esperando...',
      isBot: false,
      isReady: false,
      isHost: false,
    );

    broadcastLobbyUpdate();
  }

  /// Rellena los asientos restantes con Bots si está activado
  void fillEmptySeatsWithBots() {
    lastActivity = DateTime.now();
    final botNames = ['Pancho Bot', 'Lola Bot', 'Tito Bot'];
    final botAvatars = [1, 2, 4];
    final botFrames = ['rank_bronce', 'rank_plata', 'rank_oro'];

    int botCounter = 0;
    for (int i = 0; i < seats.length; i++) {
      if (!seats[i].isOccupied) {
        final bName = botNames[botCounter % botNames.length];
        final bAvatar = botAvatars[botCounter % botAvatars.length];
        final bFrame = botFrames[botCounter % botFrames.length];
        seats[i] = RoomSeat(
          seatIndex: i,
          playerId: 'bot_${i}_${DateTime.now().millisecondsSinceEpoch}',
          name: bName,
          avatarId: bAvatar,
          frameId: bFrame,
          isBot: true,
          isReady: true,
          isHost: false,
        );
        botCounter++;
      }
    }
    broadcastLobbyUpdate();
  }

  /// Inicia la partida formalmente y notifica a todos los clientes
  void startMatch({String? requestedByPlayerId}) {
    lastActivity = DateTime.now();

    // Rellenar con bots los asientos vacíos si la opción está activa
    if (roomInfo.fillWithBots && !seats.every((s) => s.isOccupied)) {
      fillEmptySeatsWithBots();
    }

    isMatchStarted = true;

    // Enviar START_MATCH con los asientos finales, marcos y avatares de todos
    broadcast(NetworkGameMessage(
      type: 'START_MATCH',
      data: {
        'roomId': roomInfo.roomId,
        'seats': seats.map((s) => s.toJson()).toList(),
        'isTeams': roomInfo.isTeams,
        'regionalRoomId': roomInfo.regionalRoomId,
        'entryFee': roomInfo.entryFee,
      },
    ));
  }

  /// Retransmite un mensaje de juego (carta jugada, canto, chat, etc.) a los demás jugadores
  void handleGameMessage(NetworkGameMessage msg, String fromPlayerId) {
    lastActivity = DateTime.now();

    switch (msg.type) {
      case 'CHAT_MESSAGE':
      case 'VOICE_SOUND':
      case 'PLAY_CARD':
      case 'CALL_CANTO':
      case 'FALLEN_CARD':
      case 'EMOJI_REACTION':
        // Reenviar a todos (o a los demás) manteniendo al emisor identificado
        broadcast(
          NetworkGameMessage(
            type: msg.type,
            data: {
              ...msg.data,
              'senderPlayerId': fromPlayerId,
            },
          ),
          excludePlayerId: msg.type == 'PLAY_CARD' ? null : null,
        );
        break;

      case 'START_MATCH_REQUEST':
        startMatch(requestedByPlayerId: fromPlayerId);
        break;

      default:
        broadcast(msg);
        break;
    }
  }

  /// Se ejecuta cuando se cierra el WebSocket de un cliente (desconexión temporal o salida de pantalla)
  void handleSocketDisconnected(String playerId) {
    lastActivity = DateTime.now();
    _clientSockets.remove(playerId);

    final index = seats.indexWhere((s) => s.playerId == playerId);
    if (index != -1) {
      // Marcar como no conectado pero MANTENER el asiento y los datos del jugador
      seats[index] = seats[index].copyWith(isConnected: false);
      broadcastLobbyUpdate();
      print('[GameRoom] Socket desconectado para $playerId en sala ${roomInfo.roomId}. Asiento $index reservado.');
    }

    // Si ya no queda ningún socket activo conectado a la sala:
    // NO destruimos la sala inmediatamente. Damos un tiempo de gracia de 10 minutos
    // para permitir que el jugador vuelva a entrar normalmente.
    if (_clientSockets.isEmpty) {
      _emptyGraceTimer?.cancel();
      print('[GameRoom] Sala ${roomInfo.roomId} sin sockets activos. Iniciando tiempo de gracia de 10 minutos...');
      _emptyGraceTimer = Timer(const Duration(minutes: 10), () {
        if (_clientSockets.isEmpty) {
          print('[GameRoom] Tiempo de gracia expirado para sala ${roomInfo.roomId}. Eliminando por inactividad.');
          onRoomEmpty?.call(roomInfo.roomId);
        }
      });
    }
  }

  /// Remueve formalmente a un jugador cuando abandona explícitamente la sala
  void removePlayer(String playerId) {
    lastActivity = DateTime.now();
    _clientSockets.remove(playerId);

    final index = seats.indexWhere((s) => s.playerId == playerId);
    if (index != -1) {
      final wasHost = seats[index].isHost;
      seats[index] = RoomSeat(
        seatIndex: index,
        playerId: null,
        name: 'Esperando...',
        isBot: false,
        isReady: false,
        isHost: false,
        isConnected: false,
      );

      // Si el anfitrión se fue explícitamente, ceder el anfitrión al siguiente jugador humano
      if (wasHost) {
        final nextHumanIndex = seats.indexWhere((s) => s.playerId != null && !s.isBot);
        if (nextHumanIndex != -1) {
          seats[nextHumanIndex] = seats[nextHumanIndex].copyWith(isHost: true, isReady: true);
        }
      }

      roomInfo = roomInfo.copyWith(currentPlayers: humanPlayersCount);
      broadcastLobbyUpdate();
    }

    // Si ya no quedan jugadores humanos asignados a asientos:
    if (humanPlayersCount == 0) {
      _emptyGraceTimer?.cancel();
      _emptyGraceTimer = Timer(const Duration(minutes: 5), () {
        if (humanPlayersCount == 0) {
          onRoomEmpty?.call(roomInfo.roomId);
        }
      });
    }
  }

  /// Cierra la sala de inmediato y expulsa a todos los clientes (llamado por el anfitrión)
  void closeRoom() {
    _emptyGraceTimer?.cancel();
    broadcast(const NetworkGameMessage(
      type: 'ROOM_CLOSED',
      data: {'message': 'El anfitrión ha cerrado la sala.'},
    ));
    _clientSockets.clear();
    onRoomEmpty?.call(roomInfo.roomId);
  }

  /// Envía la lista de asientos actualizada a todos los clientes conectados
  void broadcastLobbyUpdate() {
    broadcast(NetworkGameMessage(
      type: 'LOBBY_UPDATE',
      data: {
        'roomInfo': roomInfo.toJson(),
        'seats': seats.map((s) => s.toJson()).toList(),
      },
    ));
  }

  /// Difunde un mensaje a los clientes conectados en la sala
  void broadcast(NetworkGameMessage msg, {String? excludePlayerId}) {
    final payload = msg.serialize();
    for (final entry in _clientSockets.entries) {
      if (excludePlayerId != null && entry.key == excludePlayerId) continue;
      try {
        entry.value.sink.add(payload);
      } catch (_) {}
    }
  }

  void _sendToSocket(dynamic socket, NetworkGameMessage msg) {
    try {
      socket.sink.add(msg.serialize());
    } catch (_) {}
  }
}
