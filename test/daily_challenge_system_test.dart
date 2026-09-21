import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/daily_challenge_system.dart';
import 'package:gme/features/la_caida/economy/achievement_catalog.dart';
import 'package:gme/features/la_caida/economy/player_stats_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyChallengeSystem tests', () {
    late DailyChallengeSystem system;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      system = DailyChallengeSystem();
    });

    test('pool contains 20 distinct challenge templates', () {
      expect(DailyChallengeSystem.pool.length, 20);
      final ids = DailyChallengeSystem.pool.map((t) => t.id).toSet();
      expect(ids.length, 20);
    });

    test('system initializes 3 challenges for today', () {
      expect(system.challenges.length, 3);
      for (final ch in system.challenges) {
        expect(ch.targetProgress, greaterThan(0));
        expect(ch.coinReward, greaterThan(0));
        expect(ch.xpReward, greaterThan(0));
        expect(ch.isCompleted, isFalse);
      }
    });

    test('timeUntilNextReset returns a positive duration less than 24h', () {
      final remaining = system.timeUntilNextReset();
      expect(remaining.isNegative, isFalse);
      expect(remaining.inHours, lessThanOrEqualTo(24));
    });
  });

  group('AchievementCatalog tests', () {
    test('catalog contains 25 achievements across 3 categories', () {
      expect(AchievementCatalog.allAchievements.length, 25);
      final partidas = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.partidas);
      final jugadas = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.jugadas);
      final economia = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.economia);

      expect(partidas.length, 9);
      expect(jugadas.length, 10);
      expect(economia.length, 6);
    });

    test('achievements getProgress properly evaluates stats', () {
      final stats = PlayerStatsModel(
        gamesPlayed: 15,
        gamesWon: 12,
        caidasMade: 30,
        mesasLimpias: 5,
        trivilines: 1,
        trophies: 500,
      );

      final achWins10 = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_wins_10');
      expect(achWins10.getProgress(stats), 12);
      expect(achWins10.getProgress(stats) >= achWins10.targetProgress, isTrue);

      final achTrivilin = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_trivilin_1');
      expect(achTrivilin.getProgress(stats), 1);
      expect(achTrivilin.getProgress(stats) >= achTrivilin.targetProgress, isTrue);

      final achRankBronce = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_rank_bronce');
      expect(achRankBronce.getProgress(stats), 500);
      expect(achRankBronce.getProgress(stats) >= achRankBronce.targetProgress, isTrue);
    });
  });
}
