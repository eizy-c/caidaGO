import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/economy/rank_system.dart';

void main() {
  group('RankInfo', () {
    test('forTrophies retorna Novato para 0 trofeos', () {
      expect(RankInfo.forTrophies(0).tier, RankTier.novato);
    });
    test('forTrophies retorna Bronce para 150 trofeos', () {
      expect(RankInfo.forTrophies(150).tier, RankTier.bronce);
    });
    test('forTrophies retorna Leyenda para 4500 trofeos', () {
      expect(RankInfo.forTrophies(4500).tier, RankTier.leyenda);
    });
  });

  group('RankProgress', () {
    test('trophyDeltaForResult gana normal 1v1 = +25', () {
      expect(RankProgress.trophyDeltaForResult(
        won: true, trivolin: false, mesaLimpia: false,
        isTeams: false, currentTrophies: 200,
      ), 25);
    });
    test('trophyDeltaForResult pierde = -15', () {
      expect(RankProgress.trophyDeltaForResult(
        won: false, trivolin: false, mesaLimpia: false,
        isTeams: false, currentTrophies: 200,
      ), -15);
    });
    test('protección Novato: no pierde trofeos', () {
      expect(RankProgress.trophyDeltaForResult(
        won: false, trivolin: false, mesaLimpia: false,
        isTeams: false, currentTrophies: 50,
      ), 0);
    });
    test('victoria con Trivilín 1v1 = +35', () {
      expect(RankProgress.trophyDeltaForResult(
        won: true, trivolin: true, mesaLimpia: false,
        isTeams: false, currentTrophies: 200,
      ), 35);
    });
  });
}
