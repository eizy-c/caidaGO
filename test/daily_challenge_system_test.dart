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
    test('catalog contains 42 achievements across 3 categories with strict Bronce -> Plata -> Oro progression', () {
      expect(AchievementCatalog.allAchievements.length, 42);
      final partidas = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.partidas);
      final jugadas = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.jugadas);
      final economia = AchievementCatalog.allAchievements.where((a) => a.category == AchievementCategory.economia);

      expect(partidas.length, 9);
      expect(jugadas.length, 21);
      expect(economia.length, 12);

      // Cada logro debe ser de nivel 1, 2 o 3
      for (final ach in AchievementCatalog.allAchievements) {
        expect(ach.level, isIn([1, 2, 3]));
        if (ach.level == 1) {
          expect(ach.requiredAchievementId, isNull);
        } else {
          expect(ach.requiredAchievementId, isNotNull);
        }
      }
    });

    test('achievements getProgress properly evaluates stats', () {
      final stats = PlayerStatsModel(
        gamesPlayed: 15,
        gamesWon: 12,
        caidasMade: 30,
        mesasLimpias: 5,
        trivilines: 3,
        trophies: 500,
      );

      final achWins10 = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_wins_10');
      expect(achWins10.getProgress(stats), 12);
      expect(achWins10.getProgress(stats) >= achWins10.targetProgress, isTrue);

      final achTrivilin = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_trivilin_1');
      expect(achTrivilin.getProgress(stats), 3);
      expect(achTrivilin.getProgress(stats) >= achTrivilin.targetProgress, isTrue);

      final achRankBronce = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_rank_bronce');
      expect(achRankBronce.getProgress(stats), 500);
      expect(achRankBronce.getProgress(stats) >= achRankBronce.targetProgress, isTrue);
    });

    test('sequential unlock progression for Trivilín (Bronce -> Plata -> Oro)', () {
      final stats = PlayerStatsModel(trivilines: 10);
      final tBronce = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_trivilin_1');
      final tPlata = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_trivilin_2');
      final tOro = AchievementCatalog.allAchievements.firstWhere((a) => a.id == 'ach_trivilin_3');

      // Al inicio, solo Bronce está desbloqueado
      expect(AchievementCatalog.isUnlocked(tBronce, stats), isTrue);
      expect(AchievementCatalog.isUnlocked(tPlata, stats), isFalse);
      expect(AchievementCatalog.isUnlocked(tOro, stats), isFalse);

      // Tras reclamar Bronce, se desbloquea Plata
      stats.claimAchievement('ach_trivilin_1');
      expect(AchievementCatalog.isUnlocked(tBronce, stats), isTrue);
      expect(AchievementCatalog.isUnlocked(tPlata, stats), isTrue);
      expect(AchievementCatalog.isUnlocked(tOro, stats), isFalse);

      // Tras reclamar Plata, se desbloquea Oro
      stats.claimAchievement('ach_trivilin_2');
      expect(AchievementCatalog.isUnlocked(tOro, stats), isTrue);
    });
  });
}
