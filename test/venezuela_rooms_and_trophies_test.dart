import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/match_history_model.dart';
import 'package:gme/features/la_caida/presentation/widgets/match_history_modal.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/economy/venezuela_room_tier.dart';
import 'package:gme/features/la_caida/economy/trophy_session_manager.dart';
import 'package:gme/features/la_caida/presentation/widgets/venezuela_rooms_carousel.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerSession.setShared(PlayerSession.createDefault(coins: 1000));
    final manager = TrophySessionManager();
    TrophySessionManager.setShared(manager);
  });

  group('Catálogo Oficial de 7 Salas VIP de Venezuela', () {
    test('Verifica la especificación exacta de las 7 salas', () {
      final rooms = VenezuelaRoomCatalog.rooms;
      expect(rooms.length, equals(7));

      // 1. Chivacoa (Yaracuy)
      final r1 = rooms[0];
      expect(r1.id, equals(1));
      expect(r1.name, equals('Chivacoa'));
      expect(r1.region, equals('Yaracuy'));
      expect(r1.subtitle, equals('Mesa del Alambique'));
      expect(r1.entryFee, equals(200));
      expect(r1.basePrize, equals(400));
      expect(r1.trophyCap, equals(15));
      expect(r1.winTrophies, equals(3));
      expect(r1.lossTrophies, equals(0));
      expect(r1.frameAsset, equals('assets/Tiers/box/1-SALAS.png'));

      // 2. Barquisimeto (Lara)
      final r2 = rooms[1];
      expect(r2.id, equals(2));
      expect(r2.name, equals('Barquisimeto'));
      expect(r2.region, equals('Lara'));
      expect(r2.subtitle, equals('Mesa Crepuscular'));
      expect(r2.entryFee, equals(100));
      expect(r2.basePrize, equals(200));
      expect(r2.trophyCap, equals(30));
      expect(r2.winTrophies, equals(4));
      expect(r2.lossTrophies, equals(-2));
      expect(r2.requiredPrevTrophies, equals(15));
      expect(r2.frameAsset, equals('assets/Tiers/box/2-SALAS.png'));

      // 3. Tucacas (Falcón)
      final r3 = rooms[2];
      expect(r3.id, equals(3));
      expect(r3.name, equals('Tucacas'));
      expect(r3.region, equals('Falcón'));
      expect(r3.subtitle, equals('Brisa Marina'));
      expect(r3.entryFee, equals(500));
      expect(r3.basePrize, equals(1000));
      expect(r3.trophyCap, equals(60));
      expect(r3.winTrophies, equals(6));
      expect(r3.lossTrophies, equals(-4));
      expect(r3.requiredPrevTrophies, equals(30));
      expect(r3.frameAsset, equals('assets/Tiers/box/3-SALAS.png'));

      // 4. Maracaibo (Zulia)
      final r4 = rooms[3];
      expect(r4.id, equals(4));
      expect(r4.name, equals('Maracaibo'));
      expect(r4.region, equals('Zulia'));
      expect(r4.subtitle, equals('Calor Zuliano'));
      expect(r4.entryFee, equals(2500));
      expect(r4.basePrize, equals(5000));
      expect(r4.trophyCap, equals(75));
      expect(r4.winTrophies, equals(8));
      expect(r4.lossTrophies, equals(-6));
      expect(r4.requiredPrevTrophies, equals(60));
      expect(r4.frameAsset, equals('assets/Tiers/box/4-SALAS.png'));

      // 5. Mérida (Páramo Helado ❄️)
      final r5 = rooms[4];
      expect(r5.id, equals(5));
      expect(r5.name, equals('Mérida'));
      expect(r5.subtitle, equals('Páramo y Baraja Helada'));
      expect(r5.isFrozenTheme, isTrue);
      expect(r5.entryFee, equals(10000));
      expect(r5.basePrize, equals(20000));
      expect(r5.trophyCap, equals(100));
      expect(r5.winTrophies, equals(10));
      expect(r5.lossTrophies, equals(-8));
      expect(r5.requiredPrevTrophies, equals(75));
      expect(r5.frameAsset, equals('assets/Tiers/box/5-SALAS.png'));

      // 6. Caracas (Distrito Capital)
      final r6 = rooms[5];
      expect(r6.id, equals(6));
      expect(r6.name, equals('Caracas'));
      expect(r6.region, equals('Distrito Capital'));
      expect(r6.subtitle, equals('La Gran Sultana'));
      expect(r6.entryFee, equals(50000));
      expect(r6.basePrize, equals(100000));
      expect(r6.trophyCap, equals(125));
      expect(r6.winTrophies, equals(12));
      expect(r6.lossTrophies, equals(-10));
      expect(r6.requiredPrevTrophies, equals(100));
      expect(r6.frameAsset, equals('assets/Tiers/box/6-SALAS.png'));

      // 7. Margarita VIP (Nueva Esparta)
      final r7 = rooms[6];
      expect(r7.id, equals(7));
      expect(r7.name, equals('Margarita VIP'));
      expect(r7.region, equals('Nueva Esparta'));
      expect(r7.subtitle, equals('Casino del Caribe'));
      expect(r7.entryFee, equals(250000));
      expect(r7.basePrize, equals(500000));
      expect(r7.trophyCap, equals(250));
      expect(r7.winTrophies, equals(15));
      expect(r7.lossTrophies, equals(-12));
      expect(r7.requiredPrevTrophies, equals(125));
      expect(r7.frameAsset, equals('assets/Tiers/box/7-SALAS.png'));
    });

    test('Cálculos de Pozos y Premios en 1v1 y 2v2', () {
      final chivacoa = VenezuelaRoomCatalog.getById(1);

      // 1v1 Duelo
      expect(chivacoa.getTotalPot(GameMode.duel1v1), equals(400));
      expect(chivacoa.getPrizePerWinner(GameMode.duel1v1), equals(400));

      // 2v2 Parejas
      expect(chivacoa.getTotalPot(GameMode.teams2v2), equals(800));
      expect(chivacoa.getPrizePerWinner(GameMode.teams2v2), equals(400));
    });
  });

  group('TrophySessionManager - Lógica de Progresión y Trofeos', () {
    test('Sala 1 está desbloqueada por defecto, Salas 2-7 bloqueadas inicialmente', () {
      final manager = TrophySessionManager.shared;

      expect(manager.isRoomUnlocked(1), isTrue);
      expect(manager.isRoomUnlocked(2), isFalse);
      expect(manager.isRoomUnlocked(3), isFalse);
      expect(manager.isRoomUnlocked(7), isFalse);

      expect(manager.getRemainingTrophiesForUnlock(2), equals(15));
    });

    test('Ganar partidas acumula trofeos y desbloquea la siguiente sala al 100%', () {
      final manager = TrophySessionManager.shared;

      // Ganar 5 partidas en Chivacoa (5 * 3 = 15 trofeos -> 100% de cap)
      for (int i = 0; i < 5; i++) {
        manager.processMatchResult(roomId: 1, isWinner: true, mode: GameMode.duel1v1);
      }

      expect(manager.getTrophies(1), equals(15));
      expect(manager.isRoomCompleted(1), isTrue);

      // Ahora Barquisimeto (Sala 2) debe estar desbloqueada
      expect(manager.isRoomUnlocked(2), isTrue);
      expect(manager.isRoomUnlocked(3), isFalse);
    });

    test('Trofeos se clapan al tope de la sala y no desbordan', () {
      final manager = TrophySessionManager.shared;

      // Ganar 10 partidas en Chivacoa (10 * 3 = 30 trofeos, pero cap es 15)
      for (int i = 0; i < 10; i++) {
        manager.processMatchResult(roomId: 1, isWinner: true, mode: GameMode.duel1v1);
      }

      expect(manager.getTrophies(1), equals(15));
      expect(manager.getTrophyProgress(1), equals(1.0));
    });

    test('Derrotas descuentan trofeos sin bajar de 0', () {
      final manager = TrophySessionManager.shared;

      // Barquisimeto: Win +4, Loss -2
      manager.setTrophiesForTesting(2, 6);
      expect(manager.getTrophies(2), equals(6));

      // 1 Derrota en Sala 2
      manager.processMatchResult(roomId: 2, isWinner: false, mode: GameMode.duel1v1);
      expect(manager.getTrophies(2), equals(4));

      // 3 Derrotas más (4 - 6 = -2 -> clamp a 0)
      manager.processMatchResult(roomId: 2, isWinner: false, mode: GameMode.duel1v1);
      manager.processMatchResult(roomId: 2, isWinner: false, mode: GameMode.duel1v1);
      manager.processMatchResult(roomId: 2, isWinner: false, mode: GameMode.duel1v1);
      expect(manager.getTrophies(2), equals(0));
    });

    test('Deducción de tarifa de entrada y premios de monedas', () {
      final manager = TrophySessionManager.shared;
      PlayerSession.shared.setCoins(200);

      expect(manager.canAfford(50), isTrue);
      expect(manager.canAfford(500), isFalse);

      // Deducir 50 de entrada
      final deducted = manager.deductEntryFee(50);
      expect(deducted, isTrue);
      expect(PlayerSession.shared.coins, equals(150));

      // Ganar en Sala 1 (Premio: 100)
      manager.processMatchResult(roomId: 1, isWinner: true, mode: GameMode.duel1v1);
      expect(PlayerSession.shared.coins, equals(250));
    });
  });

  group('VenezuelaRoomsCarouselScreen - UI Widget Tests', () {
    testWidgets('Renderiza carrusel de salas, selector 1v1 / 2v2 y tarjeta de Chivacoa', (tester) async {
      final manager = TrophySessionManager.shared;
      PlayerSession.shared.setCoins(1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenezuelaRoomsCarouselScreen(
              manager: manager,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SALAS VIP REGIONALES'), findsOneWidget);
      expect(find.text('⚔️ Duelo 1 vs 1'), findsOneWidget);
      expect(find.text('👥 Parejas 2 vs 2'), findsOneWidget);

      // Sala 1 (Chivacoa)
      expect(find.text('CHIVACOA'), findsOneWidget);
      expect(find.text('Yaracuy'), findsOneWidget);
      expect(find.text('"Mesa del Alambique"'), findsOneWidget);
      expect(find.text('JUGAR (🪙 50)'), findsOneWidget);
    });

    testWidgets('Alternar a modo 2v2 actualiza subtítulos y premios en vivo', (tester) async {
      final manager = TrophySessionManager.shared;
      PlayerSession.shared.setCoins(1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenezuelaRoomsCarouselScreen(
              manager: manager,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pulsar Parejas 2 vs 2
      await tester.tap(find.text('👥 Parejas 2 vs 2'));
      await tester.pumpAndSettle();

      expect(find.text('PREMIO C/U'), findsWidgets);
      expect(find.text('POZO TOTAL'), findsWidgets);
      expect(find.text('🪙 200'), findsWidgets); // Pozo 2v2 de Chivacoa: 50 * 4 = 200
    });

    testWidgets('Tocar JUGAR ejecuta callback con la sala y modalidad seleccionada', (tester) async {
      final manager = TrophySessionManager.shared;
      PlayerSession.shared.setCoins(1000);

      VenezuelaRoomTier? selectedRoom;
      GameMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenezuelaRoomsCarouselScreen(
              manager: manager,
              onStartMatch: (room, mode) {
                selectedRoom = room;
                selectedMode = mode;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('JUGAR (🪙 50)'));
      await tester.pumpAndSettle();

      expect(selectedRoom?.id, equals(1));
      expect(selectedMode, equals(GameMode.duel1v1));
    });
  });

  group('Historial de Partidas - Salas VIP y Multijugador', () {
    test('Persiste y deserializa salas regionales y partidas multijugador', () async {
      final storage = MatchHistoryStorage.instance;

      // 1. Partida en Chivacoa (Yaracuy)
      final vipEntry = MatchHistoryEntry(
        id: 'm_test_vip',
        playedAt: DateTime.now(),
        won: true,
        gameMode: '1 vs 1',
        userScore: 24,
        opponentScore: 18,
        coinsEarned: 100,
        xpEarned: 25,
        trophyDelta: 3,
        roomName: 'Chivacoa',
        roomRegion: 'Yaracuy',
        roomCategory: 'Sala VIP',
        isMultiplayer: false,
      );
      await storage.saveMatch(vipEntry);

      // 2. Partida en Multijugador Local
      final multiEntry = MatchHistoryEntry(
        id: 'm_test_multi',
        playedAt: DateTime.now(),
        won: false,
        gameMode: '2 vs 2',
        userScore: 20,
        opponentScore: 24,
        coinsEarned: 0,
        xpEarned: 15,
        trophyDelta: 0,
        roomName: 'Multijugador Local',
        roomCategory: 'Multijugador',
        isMultiplayer: true,
      );
      await storage.saveMatch(multiEntry);

      expect(storage.matches.length, greaterThanOrEqualTo(2));
      expect(storage.matches.first.roomName, equals('Multijugador Local'));
      expect(storage.matches.first.isMultiplayer, isTrue);

      final second = storage.matches[1];
      expect(second.roomName, equals('Chivacoa'));
      expect(second.roomRegion, equals('Yaracuy'));
      expect(second.trophyDelta, equals(3));
    });

    testWidgets('MatchHistoryModal renderiza badges de Sala Regional y Multijugador', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchHistoryModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HISTORIAL DE PARTIDAS'), findsOneWidget);
      expect(find.text('Chivacoa (Yaracuy)'), findsOneWidget);
      expect(find.text('Multijugador Local'), findsOneWidget);
      expect(find.text('+3 🏆'), findsOneWidget);
    });
  });
}
