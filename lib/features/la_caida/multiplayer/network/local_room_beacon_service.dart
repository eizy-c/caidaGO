import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../domain/multiplayer_models.dart';

/// Servicio de descubrimiento de salas en la red local Wi-Fi vía UDP Broadcast.
class LocalRoomBeaconService {
  static const int broadcastPort = 45455;

  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _listenSocket;
  Timer? _broadcastTimer;

  MultiplayerRoomInfo? _hostingRoom;
  final ValueNotifier<List<MultiplayerRoomInfo>> discoveredRoomsNotifier =
      ValueNotifier<List<MultiplayerRoomInfo>>([]);

  final Map<String, ({MultiplayerRoomInfo room, DateTime lastSeen})> _roomsCache =
      {};
  Timer? _cleanupTimer;

  bool get isBroadcasting => _broadcastTimer != null;

  // ===========================================================================
  // 1. EMISOR (HOST): Transmite la existencia de la sala periódicamente
  // ===========================================================================
  Future<void> startBroadcasting(MultiplayerRoomInfo room) async {
    stopBroadcasting();
    _hostingRoom = room;

    try {
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _broadcastSocket?.broadcastEnabled = true;

      _broadcastTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        _sendBeacon();
      });
      _sendBeacon();
    } catch (e) {
      debugPrint('[LocalRoomBeacon] Error al iniciar broadcasting UDP: $e');
    }
  }

  void _sendBeacon() {
    if (_broadcastSocket == null || _hostingRoom == null) return;
    try {
      final payload = _hostingRoom!.toBeaconPayload();
      final bytes = utf8.encode(payload);
      _broadcastSocket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        broadcastPort,
      );
    } catch (_) {}
  }

  void updateBroadcastingRoom(MultiplayerRoomInfo updatedRoom) {
    _hostingRoom = updatedRoom;
    _sendBeacon();
  }

  void stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _broadcastSocket?.close();
    _broadcastSocket = null;
    _hostingRoom = null;
  }

  // ===========================================================================
  // 2. RECEPTOR (CLIENTES): Escucha en la red y mantiene la lista en vivo
  // ===========================================================================
  Future<void> startListening() async {
    stopListening();
    _roomsCache.clear();
    discoveredRoomsNotifier.value = [];

    try {
      try {
        _listenSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          broadcastPort,
          reuseAddress: true,
          reusePort: true,
        );
      } catch (_) {
        // Fallback para dispositivos donde reusePort arroja excepción del SO
        _listenSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          broadcastPort,
          reuseAddress: true,
        );
      }

      _listenSocket?.broadcastEnabled = true;

      _listenSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _listenSocket?.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final room = MultiplayerRoomInfo.fromBeaconPayload(message);
              if (room != null) {
                // Actualizar la IP real del emisor si en el payload venía genérica
                final effectiveRoom = MultiplayerRoomInfo(
                  roomId: room.roomId,
                  roomName: room.roomName,
                  hostName: room.hostName,
                  hostAvatarId: room.hostAvatarId,
                  hostFrameId: room.hostFrameId,
                  hostIp: datagram.address.address,
                  port: room.port,
                  targetPlayers: room.targetPlayers,
                  currentPlayers: room.currentPlayers,
                  isPrivate: room.isPrivate,
                  isTeams: room.isTeams,
                  fillWithBots: room.fillWithBots,
                  networkMode: room.networkMode,
                );

                _roomsCache[effectiveRoom.roomId] = (
                  room: effectiveRoom,
                  lastSeen: DateTime.now(),
                );
                _notifyRoomsChanged();
              }
            } catch (_) {}
          }
        }
      });

      // Limpieza periódica de salas que dejaron de transmitir hace > 4 segundos
      _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        final now = DateTime.now();
        bool changed = false;
        _roomsCache.removeWhere((id, item) {
          final expired = now.difference(item.lastSeen).inSeconds > 4;
          if (expired) changed = true;
          return expired;
        });
        if (changed) _notifyRoomsChanged();
      });
    } catch (e) {
      debugPrint('[LocalRoomBeacon] Error escuchando beacons UDP: $e');
    }
  }

  void _notifyRoomsChanged() {
    discoveredRoomsNotifier.value =
        _roomsCache.values.map((v) => v.room).toList();
  }

  void stopListening() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _listenSocket?.close();
    _listenSocket = null;
    _roomsCache.clear();
    discoveredRoomsNotifier.value = [];
  }

  void dispose() {
    stopBroadcasting();
    stopListening();
    discoveredRoomsNotifier.dispose();
  }
}
