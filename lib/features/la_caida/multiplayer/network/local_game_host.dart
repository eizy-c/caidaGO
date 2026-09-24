import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/multiplayer_models.dart';
import 'local_room_beacon_service.dart';

/// Servidor local WebSocket autoritativo que orquesta la partida en el dispositivo Host.
class LocalGameHost {
  HttpServer? _server;
  final LocalRoomBeaconService _beaconService = LocalRoomBeaconService();

  MultiplayerRoomInfo? _roomInfo;
  final List<RoomSeat> _seats = [];
  final Map<String, WebSocket> _clientSockets = {}; // playerId -> WebSocket

  final ValueNotifier<List<RoomSeat>> seatsNotifier =
      ValueNotifier<List<RoomSeat>>([]);
  final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> pingMsNotifier = ValueNotifier<int>(5);

  // Callbacks para eventos del juego
  void Function(NetworkGameMessage msg, String fromPlayerId)? onClientMessageReceived;
  void Function(String playerId)? onPlayerDisconnected;

  MultiplayerRoomInfo? get roomInfo => _roomInfo;
  bool get isRunning => _server != null;

  /// Inicia el servidor de la sala en el puerto especificado
  Future<bool> startServer({
    required MultiplayerRoomInfo room,
    required String hostPlayerId,
  }) async {
    await stopServer();

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        room.port,
        shared: true,
      );

      _roomInfo = room;
      _initializeSeats(room, hostPlayerId);

      _server!.listen(_handleHttpRequest);

      // Iniciar el broadcast UDP en la red local
      await _beaconService.startBroadcasting(room);

      isRunningNotifier.value = true;
      _notifySeats();
      return true;
    } catch (e) {
      debugPrint('[LocalGameHost] Error iniciando servidor en puerto ${room.port}: $e');
      await stopServer();
      return false;
    }
  }

  void _initializeSeats(MultiplayerRoomInfo room, String hostPlayerId) {
    _seats.clear();

    // Asiento 0: Host
    _seats.add(RoomSeat(
      seatIndex: 0,
      playerId: hostPlayerId,
      name: room.hostName,
      avatarId: room.hostAvatarId,
      frameId: room.hostFrameId,
      isBot: false,
      isReady: true,
      isHost: true,
    ));

    // Asientos restantes según targetPlayers (2, 3 o 4)
    for (int i = 1; i < room.targetPlayers; i++) {
      _seats.add(RoomSeat(
        seatIndex: i,
        playerId: null,
        name: 'Esperando...',
        isBot: false,
        isReady: false,
        isHost: false,
      ));
    }
  }

  void _handleHttpRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then((socket) {
        _handleNewClient(socket);
      });
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('CaidaGO WebSocket Server Only')
        ..close();
    }
  }

  void _handleNewClient(WebSocket socket) {
    String? assignedPlayerId;

    socket.listen(
      (data) {
        final message = NetworkGameMessage.deserialize(
          data.toString(),
          pinCode: _roomInfo?.pinCode,
          roomId: _roomInfo?.roomId,
        );
        if (message == null) return;

        if (message.type == 'PING') {
          _sendMessageToSocket(
            socket,
            NetworkGameMessage(
              type: 'PONG',
              data: {
                'clientTime': message.data['clientTime'],
                'serverTime': DateTime.now().millisecondsSinceEpoch,
              },
            ),
          );
        } else if (message.type == 'JOIN_ROOM') {
          assignedPlayerId = _processJoinRequest(socket, message.data);
        } else if (message.type == 'TOGGLE_READY') {
          if (assignedPlayerId != null) {
            _togglePlayerReady(assignedPlayerId!);
          }
        } else if (message.type == 'SWITCH_SEAT') {
          final target = message.data['targetSeatIndex'] as int?;
          if (assignedPlayerId != null && target != null) {
            switchPlayerSeat(assignedPlayerId!, target);
          }
        } else {
          // Reenviar al callback de la lógica de partida
          if (assignedPlayerId != null) {
            onClientMessageReceived?.call(message, assignedPlayerId!);
          }
        }
      },
      onDone: () {
        if (assignedPlayerId != null) {
          _handleClientDisconnect(assignedPlayerId!);
        }
      },
      onError: (err) {
        if (assignedPlayerId != null) {
          _handleClientDisconnect(assignedPlayerId!);
        }
      },
    );
  }

  String? _processJoinRequest(WebSocket socket, Map<String, dynamic> data) {
    final playerName = data['name'] as String? ?? 'Invitado';
    final avatarId = data['avatarId'] as int? ?? 0;
    final frameId = data['frameId'] as String? ?? 'rank_novato';
    final clientPin = data['pinCode'] as String?;
    final clientPlayerId =
        data['playerId'] as String? ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Validar PIN si la sala es privada
    if (_roomInfo?.isPrivate == true) {
      if (clientPin == null || clientPin.trim() != _roomInfo?.pinCode?.trim()) {
        _sendMessageToSocket(
          socket,
          const NetworkGameMessage(
            type: 'JOIN_REJECTED',
            data: {'reason': 'PIN_INCORRECTO', 'message': 'El PIN de 4 dígitos es incorrecto.'},
          ),
          isHandshake: true,
        );
        socket.close();
        return null;
      }
    }

    // 2. Buscar un asiento libre
    final freeSeatIndex = _seats.indexWhere((s) => !s.isOccupied);
    if (freeSeatIndex == -1) {
      _sendMessageToSocket(
        socket,
        const NetworkGameMessage(
          type: 'JOIN_REJECTED',
          data: {'reason': 'SALA_LLENA', 'message': 'La sala ya está completa.'},
        ),
        isHandshake: true,
      );
      socket.close();
      return null;
    }


    // 3. Asignar asiento
    _seats[freeSeatIndex] = RoomSeat(
      seatIndex: freeSeatIndex,
      playerId: clientPlayerId,
      name: playerName,
      avatarId: avatarId,
      frameId: frameId,
      isBot: false,
      isReady: false,
      isHost: false,
    );

    _clientSockets[clientPlayerId] = socket;

    // 4. Responder con éxito y enviar estado de sala
    _sendMessageToSocket(
      socket,
      NetworkGameMessage(
        type: 'JOIN_ACCEPTED',
        data: {
          'seatIndex': freeSeatIndex,
          'playerId': clientPlayerId,
          'roomInfo': _roomInfo?.toJson(),
          'seats': _seats.map((s) => s.toJson()).toList(),
        },
      ),
      isHandshake: true,
    );


    _updateBroadcastRoomCount();
    _broadcastLobbyUpdate();
    _notifySeats();
    return clientPlayerId;
  }

  void _togglePlayerReady(String playerId) {
    final idx = _seats.indexWhere((s) => s.playerId == playerId);
    if (idx != -1) {
      _seats[idx] = _seats[idx].copyWith(isReady: !_seats[idx].isReady);
      _broadcastLobbyUpdate();
      _notifySeats();
    }
  }

  /// Cambiar de asiento / equipo a un jugador
  void switchPlayerSeat(String playerId, int targetSeatIndex) {
    if (targetSeatIndex < 0 || targetSeatIndex >= _seats.length) return;
    final currentIdx = _seats.indexWhere((s) => s.playerId == playerId);
    if (currentIdx == -1 || currentIdx == targetSeatIndex) return;

    final currentSeat = _seats[currentIdx];
    final targetSeat = _seats[targetSeatIndex];

    if (!targetSeat.isOccupied) {
      // Mover al asiento vacío
      _seats[targetSeatIndex] = currentSeat.copyWith(seatIndex: targetSeatIndex);
      _seats[currentIdx] = RoomSeat(
        seatIndex: currentIdx,
        playerId: null,
        name: 'Esperando...',
        isBot: false,
        isReady: false,
        isHost: false,
      );
    } else if (targetSeat.isBot) {
      // Reemplazar al Bot
      _seats[targetSeatIndex] = currentSeat.copyWith(seatIndex: targetSeatIndex);
      _seats[currentIdx] = targetSeat.copyWith(
        seatIndex: currentIdx,
        playerId: 'bot_$currentIdx',
      );
    } else {
      // Intercambiar asientos entre dos jugadores humanos
      _seats[targetSeatIndex] = currentSeat.copyWith(seatIndex: targetSeatIndex);
      _seats[currentIdx] = targetSeat.copyWith(seatIndex: currentIdx);
    }

    _updateBroadcastRoomCount();
    _broadcastLobbyUpdate();
    _notifySeats();
  }

  /// Añadir o alternar un Bot en un asiento libre
  void toggleBotInSeat(int seatIndex) {
    if (seatIndex <= 0 || seatIndex >= _seats.length) return;
    final current = _seats[seatIndex];

    if (!current.isOccupied) {
      // Poner Bot
      final botNames = ['Alejandro', 'Carl', 'Jhonny', 'Simón'];
      final botAvatars = [20, 21, 22, 1];
      _seats[seatIndex] = RoomSeat(
        seatIndex: seatIndex,
        playerId: 'bot_$seatIndex',
        name: '${botNames[(seatIndex - 1) % botNames.length]} (Bot)',
        avatarId: botAvatars[(seatIndex - 1) % botAvatars.length],
        frameId: 'rank_bronce',
        isBot: true,
        isReady: true,
        isHost: false,
      );
    } else if (current.isBot) {
      // Quitar Bot
      _seats[seatIndex] = RoomSeat(
        seatIndex: seatIndex,
        playerId: null,
        name: 'Esperando...',
        isBot: false,
        isReady: false,
        isHost: false,
      );
    }

    _updateBroadcastRoomCount();
    _broadcastLobbyUpdate();
    _notifySeats();
  }

  /// Rellenar todos los puestos vacíos restantes con Bots si el Host inicia
  void fillEmptySeatsWithBots() {
    for (int i = 1; i < _seats.length; i++) {
      if (!_seats[i].isOccupied) {
        toggleBotInSeat(i);
      }
    }
  }

  void _handleClientDisconnect(String playerId) {
    _clientSockets.remove(playerId);
    final idx = _seats.indexWhere((s) => s.playerId == playerId);

    if (idx != -1) {
      debugPrint('[LocalGameHost] Jugador desconectado: ${_seats[idx].name}');
      if (_roomInfo?.fillWithBots == true) {
        // Sustituir automáticamente por Bot para no frenar la partida
        _seats[idx] = RoomSeat(
          seatIndex: idx,
          playerId: 'bot_$idx',
          name: '${_seats[idx].name} (Bot)',
          avatarId: _seats[idx].avatarId,
          frameId: _seats[idx].frameId,
          isBot: true,
          isReady: true,
          isHost: false,
        );
      } else {
        _seats[idx] = RoomSeat(
          seatIndex: idx,
          playerId: null,
          name: 'Esperando...',
          isBot: false,
          isReady: false,
          isHost: false,
        );
      }
      _updateBroadcastRoomCount();
      _broadcastLobbyUpdate();
      _notifySeats();
      onPlayerDisconnected?.call(playerId);
    }
  }

  void _updateBroadcastRoomCount() {
    if (_roomInfo == null) return;
    final occupied = _seats.where((s) => s.isOccupied).length;
    _roomInfo = MultiplayerRoomInfo(
      roomId: _roomInfo!.roomId,
      roomName: _roomInfo!.roomName,
      hostName: _roomInfo!.hostName,
      hostAvatarId: _roomInfo!.hostAvatarId,
      hostFrameId: _roomInfo!.hostFrameId,
      hostIp: _roomInfo!.hostIp,
      port: _roomInfo!.port,
      targetPlayers: _roomInfo!.targetPlayers,
      currentPlayers: occupied,
      isPrivate: _roomInfo!.isPrivate,
      pinCode: _roomInfo!.pinCode,
      isTeams: _roomInfo!.isTeams,
      fillWithBots: _roomInfo!.fillWithBots,
      networkMode: _roomInfo!.networkMode,
    );
    _beaconService.updateBroadcastingRoom(_roomInfo!);
  }

  void _broadcastLobbyUpdate() {
    broadcastMessage(NetworkGameMessage(
      type: 'LOBBY_UPDATE',
      data: {
        'seats': _seats.map((s) => s.toJson()).toList(),
      },
    ));
  }

  void broadcastMessage(NetworkGameMessage message) {
    final raw = message.serializeSecure(
      pinCode: _roomInfo?.pinCode,
      roomId: _roomInfo?.roomId,
    );
    for (final socket in _clientSockets.values) {
      try {
        socket.add(raw);
      } catch (_) {}
    }
  }

  void sendMessageToPlayer(String playerId, NetworkGameMessage message) {
    final socket = _clientSockets[playerId];
    if (socket != null) {
      _sendMessageToSocket(socket, message);
    }
  }

  void _sendMessageToSocket(WebSocket socket, NetworkGameMessage message, {bool isHandshake = false}) {
    try {
      socket.add(message.serializeSecure(
        pinCode: isHandshake ? null : _roomInfo?.pinCode,
        roomId: isHandshake ? null : _roomInfo?.roomId,
      ));
    } catch (_) {}
  }



  void _notifySeats() {
    seatsNotifier.value = List.unmodifiable(_seats);
  }

  Future<void> stopServer() async {
    _beaconService.stopBroadcasting();

    for (final socket in _clientSockets.values) {
      try {
        socket.close();
      } catch (_) {}
    }
    _clientSockets.clear();

    await _server?.close(force: true);
    _server = null;
    _roomInfo = null;
    _seats.clear();
    isRunningNotifier.value = false;
    _notifySeats();
  }

  void dispose() {
    stopServer();
    seatsNotifier.dispose();
    isRunningNotifier.dispose();
    _beaconService.dispose();
  }
}
