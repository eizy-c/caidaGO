import 'dart:async';
import 'dart:convert';
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
  bool _isOnlineMode = false;

  final ValueNotifier<ClientConnectionStatus> statusNotifier =
      ValueNotifier<ClientConnectionStatus>(ClientConnectionStatus.disconnected);
  final ValueNotifier<List<RoomSeat>> seatsNotifier =
      ValueNotifier<List<RoomSeat>>([]);
  final ValueNotifier<List<MultiplayerRoomInfo>> onlineRoomsNotifier =
      ValueNotifier<List<MultiplayerRoomInfo>>([]);
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

  bool get isOnlineMode => _isOnlineMode;

  /// Conecta al WebSocket del Host e intenta unirse a la sala local con PIN opcional
  Future<bool> connectAndJoin({
    required String hostIp,
    required int port,
    required String playerName,
    required int avatarId,
    required String frameId,
    String? pinCode,
  }) async {
    await disconnect();

    _isOnlineMode = false;
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
      debugPrint('[LocalGameClient] Falló la conexión local: $e');
      _setStatus(ClientConnectionStatus.error);
      errorMessageNotifier.value = 'No se pudo conectar con la sala. Revisa que estén en el mismo Wi-Fi.';
      return false;
    }
  }

  /// Crea una sala en el servidor online remoto
  Future<bool> createOnlineRoom({
    required String serverUrl,
    required String roomName,
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
  }) async {
    await disconnect();

    _isOnlineMode = true;
    _setStatus(ClientConnectionStatus.connecting);
    errorMessageNotifier.value = null;
    _myPlayerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    _currentPinCode = pinCode?.trim();

    try {
      final wsUrl = _normalizeWsUrl(serverUrl);
      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('No se pudo conectar al servidor online en $wsUrl');
        },
      );

      _socket!.listen(
        _handleIncomingData,
        onDone: _handleConnectionClosed,
        onError: (err) {
          _setStatus(ClientConnectionStatus.error);
          errorMessageNotifier.value = 'Error en conexión con el servidor: $err';
        },
      );

      sendMessage(
        NetworkGameMessage(
          type: 'CREATE_ONLINE_ROOM',
          data: {
            'playerId': _myPlayerId,
            'roomName': roomName,
            'hostName': hostName,
            'avatarId': hostAvatarId,
            'frameId': hostFrameId,
            'targetPlayers': targetPlayers,
            'isPrivate': isPrivate,
            'pinCode': pinCode?.trim(),
            'isTeams': isTeams,
            'fillWithBots': fillWithBots,
            'regionalRoomId': regionalRoomId,
            'entryFee': entryFee,
          },
        ),
        isHandshake: true,
      );

      return true;
    } catch (e) {
      debugPrint('[LocalGameClient] Falló creación de sala online: $e');
      _setStatus(ClientConnectionStatus.error);
      errorMessageNotifier.value = 'No se pudo conectar con el servidor online. Revisa tu conexión a internet.';
      return false;
    }
  }

  /// Se une a una sala en el servidor online remoto (por roomId o por PIN)
  Future<bool> joinOnlineRoom({
    required String serverUrl,
    required String playerName,
    required int avatarId,
    required String frameId,
    String? roomId,
    String? pinCode,
  }) async {
    await disconnect();

    _isOnlineMode = true;
    _setStatus(ClientConnectionStatus.connecting);
    errorMessageNotifier.value = null;
    _myPlayerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    _currentPinCode = pinCode?.trim();
    _currentRoomId = roomId;

    try {
      final wsUrl = _normalizeWsUrl(serverUrl);
      _socket = await WebSocket.connect(wsUrl).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('No se pudo conectar al servidor online en $wsUrl');
        },
      );

      _socket!.listen(
        _handleIncomingData,
        onDone: _handleConnectionClosed,
        onError: (err) {
          _setStatus(ClientConnectionStatus.error);
          errorMessageNotifier.value = 'Error en conexión con el servidor: $err';
        },
      );

      sendMessage(
        NetworkGameMessage(
          type: 'JOIN_ONLINE_ROOM',
          data: {
            'playerId': _myPlayerId,
            'name': playerName,
            'avatarId': avatarId,
            'frameId': frameId,
            'roomId': roomId,
            'pinCode': pinCode?.trim(),
          },
        ),
        isHandshake: true,
      );

      return true;
    } catch (e) {
      debugPrint('[LocalGameClient] Falló unirse a sala online: $e');
      _setStatus(ClientConnectionStatus.error);
      errorMessageNotifier.value = 'No se pudo conectar con el servidor online. Revisa tu conexión a internet.';
      return false;
    }
  }

  static String _normalizeWsUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.startsWith('https://')) {
      trimmed = trimmed.replaceFirst('https://', 'wss://');
    } else if (trimmed.startsWith('http://')) {
      trimmed = trimmed.replaceFirst('http://', 'ws://');
    } else if (!trimmed.startsWith('ws://') && !trimmed.startsWith('wss://')) {
      trimmed = 'ws://$trimmed';
    }
    if (!trimmed.endsWith('/ws') && !trimmed.contains('/ws?')) {
      if (trimmed.endsWith('/')) {
        trimmed = '${trimmed}ws';
      } else {
        trimmed = '$trimmed/ws';
      }
    }
    return trimmed;
  }

  /// Consulta la lista de salas públicas disponibles en el servidor online vía HTTP
  static Future<List<MultiplayerRoomInfo>> fetchOnlinePublicRoomsHttp(String serverBaseUrl) async {
    try {
      var httpUrl = serverBaseUrl.trim();
      if (httpUrl.startsWith('wss://')) {
        httpUrl = httpUrl.replaceFirst('wss://', 'https://');
      } else if (httpUrl.startsWith('ws://')) {
        httpUrl = httpUrl.replaceFirst('ws://', 'http://');
      } else if (!httpUrl.startsWith('http://') && !httpUrl.startsWith('https://')) {
        httpUrl = 'http://$httpUrl';
      }
      if (httpUrl.endsWith('/ws')) {
        httpUrl = httpUrl.substring(0, httpUrl.length - 3);
      }
      if (httpUrl.endsWith('/')) {
        httpUrl = '${httpUrl}rooms';
      } else {
        httpUrl = '$httpUrl/rooms';
      }

      final uri = Uri.parse(httpUrl);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List;
        return list
            .map((json) => MultiplayerRoomInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[LocalGameClient] Error al consultar salas online HTTP: $e');
      return [];
    }
  }

  void _handleIncomingData(dynamic raw) {
    final msg = _isOnlineMode
        ? NetworkGameMessage.deserialize(raw.toString())
        : NetworkGameMessage.deserialize(
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
        if (msg.data['roomInfo'] != null) {
          _currentRoom = MultiplayerRoomInfo.fromJson(msg.data['roomInfo']);
          _currentRoomId = _currentRoom?.roomId;
        }
        if (msg.data['seats'] != null) {
          _updateSeatsFromJson(msg.data['seats'] as List);
          final mySeat = seatsNotifier.value.firstWhere(
            (s) => s.playerId == _myPlayerId,
            orElse: () => RoomSeat(seatIndex: _mySeatIndex, name: ''),
          );
          if (mySeat.playerId == _myPlayerId && mySeat.seatIndex != _mySeatIndex) {
            _mySeatIndex = mySeat.seatIndex;
          }
        }
        break;

      case 'PUBLIC_ROOMS_UPDATE':
        final list = msg.data['rooms'] as List?;
        if (list != null) {
          final rooms = list
              .map((r) => MultiplayerRoomInfo.fromJson(r as Map<String, dynamic>))
              .toList();
          onlineRoomsNotifier.value = List.unmodifiable(rooms);
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

  /// Solicitar inicio de partida en el servidor online (anfitrión)
  void requestStartOnlineMatch() {
    sendMessage(const NetworkGameMessage(
      type: 'START_MATCH_REQUEST',
      data: {},
    ));
  }

  void sendMessage(NetworkGameMessage message, {bool isHandshake = false}) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      try {
        if (_isOnlineMode) {
          _socket!.add(message.serialize());
        } else {
          _socket!.add(message.serializeSecure(
            pinCode: isHandshake ? null : _currentPinCode,
            roomId: isHandshake ? null : _currentRoomId,
          ));
        }
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
