import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../lib/game_room.dart';
import '../lib/models.dart';
import '../lib/room_manager.dart';

void main(List<String> args) async {
  final roomManager = RoomManager.instance;
  final startTime = DateTime.now();

  final app = Router();

  // 1. Endpoint HTTP Health Check (Requerido para Render, Railway, Fly.io)
  app.get('/health', (Request request) {
    final uptimeSeconds = DateTime.now().difference(startTime).inSeconds;
    final payload = {
      'status': 'online',
      'service': 'CaidaGO WebSocket Server',
      'activeRooms': roomManager.activeRoomsCount,
      'totalPlayers': roomManager.totalPlayersCount,
      'uptimeSeconds': uptimeSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json', 'access-control-allow-origin': '*'},
    );
  });

  // 2. Endpoint HTTP para listar todas las salas abiertas (públicas y privadas)
  app.get('/rooms', (Request request) {
    final openRooms = roomManager.listOpenRooms();
    final jsonList = openRooms.map((r) => r.toJson(includePin: false)).toList();
    return Response.ok(
      jsonEncode(jsonList),
      headers: {'content-type': 'application/json', 'access-control-allow-origin': '*'},
    );
  });

  // 3. Manejador de WebSocket para comunicación en tiempo real
  final wsHandler = webSocketHandler((WebSocketChannel channel) {
    String? assignedPlayerId;
    String? currentRoomId;

    channel.stream.listen(
      (data) {
        final message = NetworkGameMessage.deserialize(data.toString());
        if (message == null) return;

        // --- PING / PONG para medir latencia RTT ---
        if (message.type == 'PING') {
          channel.sink.add(NetworkGameMessage(
            type: 'PONG',
            data: {
              'clientTime': message.data['clientTime'],
              'serverTime': DateTime.now().millisecondsSinceEpoch,
            },
          ).serialize());
          return;
        }

        // --- CONSULTAR SALAS PÚBLICAS ---
        if (message.type == 'FETCH_ROOMS') {
          final rooms = roomManager.listPublicRooms();
          channel.sink.add(NetworkGameMessage(
            type: 'PUBLIC_ROOMS_UPDATE',
            data: {
              'rooms': rooms.map((r) => r.toJson(includePin: false)).toList(),
            },
          ).serialize());
          return;
        }

        // --- CREAR SALA ONLINE ---
        if (message.type == 'CREATE_ONLINE_ROOM') {
          final pId = message.data['hostPlayerId'] as String? ??
              message.data['playerId'] as String? ??
              'p_${DateTime.now().millisecondsSinceEpoch}';
          assignedPlayerId = pId;

          final roomName = message.data['roomName'] as String? ?? 'Mesa CaidaGO';
          final hostName = message.data['hostName'] as String? ?? 'Anfitrión';
          final avatarId = message.data['avatarId'] as int? ?? 0;
          final frameId = message.data['frameId'] as String? ?? 'rank_novato';
          final targetPlayers = message.data['targetPlayers'] as int? ?? 2;
          final isPrivate = message.data['isPrivate'] as bool? ?? false;
          final pinCode = message.data['pinCode'] as String?;
          final isTeams = message.data['isTeams'] as bool? ?? false;
          final fillWithBots = message.data['fillWithBots'] as bool? ?? true;
          final regionalRoomId = message.data['regionalRoomId'] as int?;
          final entryFee = message.data['entryFee'] as int? ?? 0;

          final newRoom = roomManager.createRoom(
            roomName: roomName,
            hostPlayerId: pId,
            hostName: hostName,
            hostAvatarId: avatarId,
            hostFrameId: frameId,
            targetPlayers: targetPlayers,
            isPrivate: isPrivate,
            pinCode: pinCode,
            isTeams: isTeams,
            fillWithBots: fillWithBots,
            regionalRoomId: regionalRoomId,
            entryFee: entryFee,
            hostSocket: channel,
          );

          currentRoomId = newRoom.roomInfo.roomId;
          return;
        }

        // --- UNIRSE A SALA ONLINE (POR ID O POR PIN) ---
        if (message.type == 'JOIN_ONLINE_ROOM') {
          final pId = message.data['playerId'] as String? ??
              'p_${DateTime.now().millisecondsSinceEpoch}';
          assignedPlayerId = pId;

          final playerName = message.data['name'] as String? ?? 'Jugador';
          final avatarId = message.data['avatarId'] as int? ?? 0;
          final frameId = message.data['frameId'] as String? ?? 'rank_novato';
          final targetRoomId = message.data['roomId'] as String?;
          final pinCode = message.data['pinCode'] as String?;

          GameRoom? room;
          if (targetRoomId != null && targetRoomId.isNotEmpty) {
            room = roomManager.getRoom(targetRoomId);
          } else if (pinCode != null && pinCode.isNotEmpty) {
            room = roomManager.findRoomByPin(pinCode);
          }

          if (room == null) {
            channel.sink.add(const NetworkGameMessage(
              type: 'JOIN_REJECTED',
              data: {
                'reason': 'SALA_NO_ENCONTRADA',
                'message': 'No se encontró ninguna sala con este PIN o ID.',
              },
            ).serialize());
            return;
          }

          final joined = room.addPlayer(
            playerId: pId,
            playerName: playerName,
            avatarId: avatarId,
            frameId: frameId,
            socket: channel,
            pinCode: pinCode,
          );

          if (joined) {
            currentRoomId = room.roomInfo.roomId;
            roomManager.registerPlayerInRoom(pId, currentRoomId!);
          }
          return;
        }

        // --- ⚡ PARTIDA RÁPIDA (EMPAREJAMIENTO AUTOMÁTICO) ---
        if (message.type == 'QUICK_MATCH') {
          final pId = message.data['playerId'] as String? ??
              'p_${DateTime.now().millisecondsSinceEpoch}';
          assignedPlayerId = pId;

          final playerName = message.data['name'] as String? ?? 'Jugador';
          final avatarId = message.data['avatarId'] as int? ?? 0;
          final frameId = message.data['frameId'] as String? ?? 'rank_novato';
          final targetPlayers = message.data['targetPlayers'] as int? ?? 2;
          final regionalRoomId = message.data['regionalRoomId'] as int?;
          final entryFee = message.data['entryFee'] as int? ?? 0;

          final room = roomManager.findOrCreateQuickMatch(
            playerId: pId,
            playerName: playerName,
            avatarId: avatarId,
            frameId: frameId,
            targetPlayers: targetPlayers,
            regionalRoomId: regionalRoomId,
            entryFee: entryFee,
            socket: channel,
          );

          currentRoomId = room.roomInfo.roomId;
          return;
        }

        // --- MENSAJES DENTRO DE LA SALA ---
        if (currentRoomId != null && assignedPlayerId != null) {
          final room = roomManager.getRoom(currentRoomId!);
          if (room != null) {
            if (message.type == 'TOGGLE_READY') {
              room.togglePlayerReady(assignedPlayerId!);
            } else if (message.type == 'SWITCH_SEAT') {
              final target = message.data['targetSeatIndex'] as int?;
              if (target != null) {
                room.switchPlayerSeat(assignedPlayerId!, target);
              }
            } else if (message.type == 'START_MATCH_REQUEST') {
              room.startMatch(requestedByPlayerId: assignedPlayerId);
            } else {
              room.handleGameMessage(message, assignedPlayerId!);
            }
          }
        }
      },
      onDone: () {
        if (assignedPlayerId != null) {
          roomManager.handlePlayerDisconnect(assignedPlayerId!);
        }
      },
      onError: (error) {
        if (assignedPlayerId != null) {
          roomManager.handlePlayerDisconnect(assignedPlayerId!);
        }
      },
    );
  });

  // Conectar la ruta /ws al webSocketHandler
  app.get('/ws', wsHandler);

  // Pipeline con CORS y logging básico
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app.call);

  // Leer puerto de variables de entorno (Render / Railway inyectan 'PORT')
  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('====================================================');
  print('  🚀 Servidor CaidaGO Online Iniciado');
  print('  • Puerto: ${server.port}');
  print('  • HTTP Health: http://0.0.0.0:${server.port}/health');
  print('  • WebSocket:   ws://0.0.0.0:${server.port}/ws');
  print('====================================================');

  // Cierre limpio al recibir señales del sistema (SIGINT / SIGTERM)
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n[Servidor] Cerrando servidor...');
    await server.close(force: true);
    exit(0);
  });
}
