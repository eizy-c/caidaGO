import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/multiplayer_models.dart';

/// Estado de la conexión del cliente con el host
enum ClientConnectionStatus {
  disconnected,
  connecting,
  connected,
  rejected,
  error,
}

/// Cliente WebSocket para unirse a salas locales u online y comunicarse con el Host.
class LocalGameClient {
  WebSocket? _socket;
  ClientConnectionStatus _status = ClientConnectionStatus.disconnected;

  MultiplayerRoomInfo? _currentRoom;
  int _mySeatIndex = -1;
  String _myPlayerId = '';

  final ValueNotifier<ClientConnectionStatus> statusNotifier =
      ValueNotifier<ClientConnectionStatus>(ClientConnectionStatus.disconnected);
  final ValueNotifier<List<RoomSeat>> seatsNotifier =
      ValueNotifier<List<RoomSeat>>([]);
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<int> pingMsNotifier = ValueNotifier<int>(25);

  Timer? _pingTimer;
  int _smoothedPing = 25;

  // Callbacks para la partida
  void Function(NetworkGameMessage msg)? onMessageReceived;
  void Function()? onMatchStarted;
  void Function()? onDisconnected;

  String? _currentPinCode;
  String? _currentRoomId;

  ClientConnectionStatus get status => _status;
  MultiplayerRoomInfo? get currentRoom => _currentRoom;
  int get mySeatIndex => _mySeatIndex;
  String get myPlayerId => _myPlayerId;
  bool get isConnected => _status == ClientConnectionStatus.connected;

  /// Conecta al WebSocket del Host e intenta unirse a la sala con PIN opcional
  Future<bool> connectAndJoin({
    required String hostIp,
    required int port,
    required String playerName,
    required int avatarId,
    required String frameId,
    String? pinCode,
  }) async {
    await disconnect();

    _setStatus(ClientConnectionStatus.connecting);
    errorMessageNotifier.value = null;
    _myPlayerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    _currentPinCode = pinCode?.trim();

    try {
      final wsUrl = 'ws://$hostIp:$port';
      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          throw TimeoutException('No se pudo contactar al anfitrión en $wsUrl');
        },
      );

      _socket!.listen(
        _handleIncomingData,
        onDone: _handleConnectionClosed,
        onError: (err) {
          _setStatus(ClientConnectionStatus.error);
          errorMessageNotifier.value = 'Error en conexión: $err';
        },
      );

      // Enviar solicitud de unión inmediata (usando clave de handshake común)
      sendMessage(
        NetworkGameMessage(
          type: 'JOIN_ROOM',
          data: {
            'playerId': _myPlayerId,
            'name': playerName,
            'avatarId': avatarId,
            'frameId': frameId,
            'pinCode': pinCode?.trim(),
          },
        ),
        isHandshake: true,
      );

      return true;
    } catch (e) {
      debugPrint('[LocalGameClient] Falló la conexión: $e');
      _setStatus(ClientConnectionStatus.error);
      errorMessageNotifier.value = 'No se pudo conectar con la sala. Revisa que estén en el mismo Wi-Fi.';
      return false;
    }
  }

  void _handleIncomingData(dynamic raw) {
    final msg = NetworkGameMessage.deserialize(
      raw.toString(),
      pinCode: _currentPinCode,
      roomId: _currentRoomId,
    );
    if (msg == null) return;

    switch (msg.type) {
      case 'JOIN_ACCEPTED':
        _setStatus(ClientConnectionStatus.connected);
        _mySeatIndex = msg.data['seatIndex'] as int? ?? -1;
        if (msg.data['roomInfo'] != null) {
          _currentRoom = MultiplayerRoomInfo.fromJson(msg.data['roomInfo']);
          _currentRoomId = _currentRoom?.roomId;
        }
        if (msg.data['seats'] != null) {
          _updateSeatsFromJson(msg.data['seats'] as List);
        }
        _startPingLoop();
        break;

      case 'PONG':
        final clientTime = msg.data['clientTime'] as int?;
        if (clientTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final rtt = (now - clientTime).clamp(2, 999);
          _smoothedPing = (_smoothedPing * 0.65 + rtt * 0.35).round().clamp(2, 999);
          pingMsNotifier.value = _smoothedPing;
        }
        break;

      case 'JOIN_REJECTED':
        _setStatus(ClientConnectionStatus.rejected);
        final reason = msg.data['message'] as String? ?? 'No se pudo unir a la sala.';
        errorMessageNotifier.value = reason;
        disconnect();
        break;

      case 'LOBBY_UPDATE':
        if (msg.data['seats'] != null) {
          _updateSeatsFromJson(msg.data['seats'] as List);
          // Actualizar mi índice de asiento si cambié de lugar/equipo
          final mySeat = seatsNotifier.value.firstWhere(
            (s) => s.playerId == _myPlayerId,
            orElse: () => RoomSeat(seatIndex: _mySeatIndex, name: ''),
          );
          if (mySeat.playerId == _myPlayerId && mySeat.seatIndex != _mySeatIndex) {
            _mySeatIndex = mySeat.seatIndex;
          }
        }
        break;

      case 'START_MATCH':
        onMatchStarted?.call();
        onMessageReceived?.call(msg);
        break;

      default:
        onMessageReceived?.call(msg);
        break;
    }
  }

  void _updateSeatsFromJson(List rawSeats) {
    final list = rawSeats
        .map((s) => RoomSeat.fromJson(s as Map<String, dynamic>))
        .toList();
    seatsNotifier.value = List.unmodifiable(list);
  }

  void toggleReady() {
    sendMessage(NetworkGameMessage(
      type: 'TOGGLE_READY',
      data: {'playerId': _myPlayerId},
    ));
  }

  /// Solicitar cambio de asiento o equipo
  void requestSwitchSeat(int targetSeatIndex) {
    sendMessage(NetworkGameMessage(
      type: 'SWITCH_SEAT',
      data: {'targetSeatIndex': targetSeatIndex, 'playerId': _myPlayerId},
    ));
  }

  void sendMessage(NetworkGameMessage message, {bool isHandshake = false}) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        _socket!.add(message.serializeSecure(
          pinCode: isHandshake ? null : _currentPinCode,
          roomId: isHandshake ? null : _currentRoomId,
        ));
      } catch (_) {}
    }
  }



  void _startPingLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (isConnected) {
        sendMessage(NetworkGameMessage(
          type: 'PING',
          data: {'clientTime': DateTime.now().millisecondsSinceEpoch},
        ));
      }
    });
  }

  void _handleConnectionClosed() {
    debugPrint('[LocalGameClient] Conexión cerrada por el Host');
    if (_status == ClientConnectionStatus.connected) {
      _setStatus(ClientConnectionStatus.disconnected);
      errorMessageNotifier.value = 'Se perdió la conexión con la sala del anfitrión.';
      onDisconnected?.call();
    }
  }

  void _setStatus(ClientConnectionStatus newStatus) {
    _status = newStatus;
    statusNotifier.value = newStatus;
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (_) {}
      _socket = null;
    }
    _currentRoom = null;
    _mySeatIndex = -1;
    if (_status != ClientConnectionStatus.rejected) {
      _setStatus(ClientConnectionStatus.disconnected);
    }
  }

  void dispose() {
    disconnect();
    pingMsNotifier.dispose();
    statusNotifier.dispose();
    seatsNotifier.dispose();
    errorMessageNotifier.dispose();
  }
}
