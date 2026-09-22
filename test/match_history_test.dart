import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/match_history_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MatchAuditItem serialization', () {
    test('serializes and deserializes correctly', () {
      final now = DateTime.now();
      final item = MatchAuditItem(
        round: 'Ronda 2',
        playerName: 'Diego',
        type: AuditEntryType.canto,
        description: 'Cantó Trivilín de Reyes',
        points: 5,
        timestamp: now,
      );

      final json = item.toJson();
      expect(json['round'], 'Ronda 2');
      expect(json['playerName'], 'Diego');
      expect(json['type'], 'canto');
      expect(json['description'], 'Cantó Trivilín de Reyes');
      expect(json['points'], 5);

      final parsed = MatchAuditItem.fromJson(json);
      expect(parsed.round, 'Ronda 2');
      expect(parsed.playerName, 'Diego');
      expect(parsed.type, AuditEntryType.canto);
      expect(parsed.description, 'Cantó Trivilín de Reyes');
      expect(parsed.points, 5);
      expect(parsed.isUserTeam, true);
      expect(parsed.timestamp.toIso8601String(), now.toIso8601String());
    });
  });

  group('MatchHistoryEntry serialization', () {
    test('serializes and deserializes correctly with audit logs', () {
      final now = DateTime.now();
      final log = MatchAuditItem(
        round: 'Ronda 1',
        playerName: 'user',
        type: AuditEntryType.puntos,
        description: 'Caída con 7 de Espadas (+1 pt)',
        points: 1,
        timestamp: now,
      );

      final entry = MatchHistoryEntry(
        id: 'test_m_1',
        playedAt: now,
        won: true,
        gameMode: '1 vs 1',
        userScore: 24,
        opponentScore: 18,
        coinsEarned: 150,
        xpEarned: 95,
        trophyDelta: 25,
        caidasCount: 3,
        limpiasCount: 1,
        cantosCount: 2,
        auditLogs: [log],
      );

      final json = entry.toJson();
      expect(json['id'], 'test_m_1');
      expect(json['won'], true);
      expect(json['gameMode'], '1 vs 1');
      expect(json['userScore'], 24);
      expect(json['opponentScore'], 18);
      expect(json['coinsEarned'], 150);
      expect(json['xpEarned'], 95);
      expect(json['trophyDelta'], 25);
      expect(json['caidasCount'], 3);
      expect(json['limpiasCount'], 1);
      expect(json['cantosCount'], 2);
      expect((json['auditLogs'] as List).length, 1);

      final parsed = MatchHistoryEntry.fromJson(json);
      expect(parsed.id, 'test_m_1');
      expect(parsed.won, true);
      expect(parsed.gameMode, '1 vs 1');
      expect(parsed.userScore, 24);
      expect(parsed.opponentScore, 18);
      expect(parsed.coinsEarned, 150);
      expect(parsed.xpEarned, 95);
      expect(parsed.trophyDelta, 25);
      expect(parsed.caidasCount, 3);
      expect(parsed.limpiasCount, 1);
      expect(parsed.cantosCount, 2);
      expect(parsed.auditLogs.length, 1);
      expect(parsed.auditLogs.first.description, 'Caída con 7 de Espadas (+1 pt)');
    });
  });

  group('MatchHistoryStorage capping and insertion', () {
    test('caps storage at maxMatches (20)', () async {
      final storage = MatchHistoryStorage.instance;

      for (int i = 0; i < 25; i++) {
        await storage.saveMatch(
          MatchHistoryEntry(
            id: 'match_$i',
            playedAt: DateTime.now(),
            won: i % 2 == 0,
            gameMode: '1 vs 1',
            userScore: 24,
            opponentScore: 20,
            coinsEarned: 50,
            xpEarned: 40,
          ),
        );
      }

      expect(storage.matches.length, MatchHistoryStorage.maxMatches);
      expect(storage.matches.first.id, 'match_24');
    });
  });
}
