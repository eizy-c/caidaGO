import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/multiplayer/domain/multiplayer_models.dart';
import 'package:gme/features/la_caida/multiplayer/network/local_game_client.dart';
import 'package:gme/features/la_caida/multiplayer/network/local_game_host.dart';
import 'package:gme/features/la_caida/multiplayer/network/local_network_utils.dart';

void main() {
  group('Multiplayer Network Core - Pruebas de Modelos y Red Local', () {
    test('Validación de PIN de 4 dígitos', () {
      expect(LocalNetworkUtils.isValidPin('1234'), isTrue);
      expect(LocalNetworkUtils.isValidPin('0000'), isTrue);
      expect(LocalNetworkUtils.isValidPin('9999'), isTrue);
      expect(LocalNetworkUtils.isValidPin('123'), isFalse);
      expect(LocalNetworkUtils.isValidPin('12345'), isFalse);
      expect(LocalNetworkUtils.isValidPin('abcd'), isFalse);
    });

    test('Serialización y deserialización de MultiplayerRoomInfo Beacon', () {
      const original = MultiplayerRoomInfo(
        roomId: 'RM-7777',
        roomName: 'Mesa Criolla',
        hostName: 'Yoangel',
        hostAvatarId: 2,
        hostFrameId: 'rank_oro',
        hostIp: '192.168.1.10',
        port: 45456,
        targetPlayers: 3,
        currentPlayers: 1,
        isPrivate: true,
        pinCode: '7777',
        isTeams: false,
        fillWithBots: true,
      );

      final beacon = original.toBeaconPayload();
      final parsed = MultiplayerRoomInfo.fromBeaconPayload(beacon);

      expect(parsed, isNotNull);
      expect(parsed!.roomId, 'RM-7777');
      expect(parsed.roomName, 'Mesa Criolla');
      expect(parsed.targetPlayers, 3);
      expect(parsed.isPrivate, isTrue);
      expect(parsed.pinCode, isNull); // El PIN no se filtra en el broadcast UDP
    });

    test('Host inicializa asientos correctamente para 2, 3 y 4 jugadores', () async {
      final host = LocalGameHost();

      // Sala de 3
      const room3 = MultiplayerRoomInfo(
        roomId: 'R3',
        roomName: 'Trío',
        hostName: 'Carlos',
        hostIp: '127.0.0.1',
        port: 46124,
        targetPlayers: 3,
      );
      await host.startServer(room: room3, hostPlayerId: 'host_carlos');

      expect(host.seatsNotifier.value.length, 3);
      expect(host.seatsNotifier.value[0].isHost, isTrue);
      expect(host.seatsNotifier.value[0].name, 'Carlos');
      expect(host.seatsNotifier.value[1].isOccupied, isFalse);
      expect(host.seatsNotifier.value[2].isOccupied, isFalse);

      // Alternar bot en asiento 1
      host.toggleBotInSeat(1);
      expect(host.seatsNotifier.value[1].isBot, isTrue);
      expect(host.seatsNotifier.value[1].isReady, isTrue);

      // Rellenar restantes con bots
      host.fillEmptySeatsWithBots();
      expect(host.seatsNotifier.value[2].isBot, isTrue);

      host.stopServer();
    });

    test('Conexión Local Host-Cliente en localhost con rechazo de PIN incorrecto y aceptación con PIN correcto',
        () async {
      final host = LocalGameHost();
      const testPort = 46123;

      const privateRoom = MultiplayerRoomInfo(
        roomId: 'R-PRIV',
        roomName: 'Sala Privada',
        hostName: 'Yoangel',
        hostIp: '127.0.0.1',
        port: testPort,
        targetPlayers: 2,
        isPrivate: true,
        pinCode: '4321',
      );

      final started = await host.startServer(room: privateRoom, hostPlayerId: 'host_1');
      expect(started, isTrue);

      // 1. Cliente intenta con PIN incorrecto
      final badClient = LocalGameClient();
      await badClient.connectAndJoin(
        hostIp: '127.0.0.1',
        port: testPort,
        playerName: 'Intruso',
        avatarId: 1,
        frameId: 'rank_novato',
        pinCode: '9999', // PIN incorrecto
      );

      // Dar tiempo para el rechazo
      await Future.delayed(const Duration(milliseconds: 150));
      expect(badClient.status, ClientConnectionStatus.rejected);
      await badClient.disconnect();

      // 2. Cliente intenta con PIN correcto
      final goodClient = LocalGameClient();
      final joined = await goodClient.connectAndJoin(
        hostIp: '127.0.0.1',
        port: testPort,
        playerName: 'Amigo',
        avatarId: 3,
        frameId: 'rank_plata',
        pinCode: '4321', // PIN correcto
      );
      expect(joined, isTrue);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(goodClient.status, ClientConnectionStatus.connected);
      expect(goodClient.mySeatIndex, 1);

      // Verificar que el host registró al cliente en el asiento 1
      expect(host.seatsNotifier.value[1].name, 'Amigo');
      expect(host.seatsNotifier.value[1].playerId, goodClient.myPlayerId);

      // Cliente marca Listo
      goodClient.toggleReady();
      await Future.delayed(const Duration(milliseconds: 150));
      expect(host.seatsNotifier.value[1].isReady, isTrue);

      await goodClient.disconnect();
      await host.stopServer();
    });
  });
}
