import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/economy/booster_model.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';

void main() {
  group('BoosterDefinition tests', () {
    test('catalog contains all 5 booster types', () {
      expect(BoosterDefinition.catalog.length, 5);
      expect(BoosterDefinition.getByType(BoosterType.xp).name, 'Racha Dorada');
      expect(BoosterDefinition.getByType(BoosterType.shield).name, 'Escudo de Trofeos');
      expect(BoosterDefinition.getByType(BoosterType.coins).name, 'Lluvia de Monedas');
      expect(BoosterDefinition.getByType(BoosterType.lucky).name, 'Comodín de Mesa');
      expect(BoosterDefinition.getByType(BoosterType.regen).name, 'Recarga Express');
    });

    test('getById returns matching definition', () {
      final def = BoosterDefinition.getById('booster_shield');
      expect(def.type, BoosterType.shield);
      expect(def.coinCost, 400);
    });
  });

  group('PlayerSession Booster management', () {
    late PlayerSession session;

    setUp(() {
      session = PlayerSession.createDefault(coins: 2000);
    });

    test('addBooster increases inventory', () {
      expect(session.getBoosterCount(BoosterType.shield), 0);
      session.addBooster(BoosterType.shield, 2);
      expect(session.getBoosterCount(BoosterType.shield), 2);
    });

    test('activateBooster stacks up to 3 and deducts from inventory', () {
      session.addBooster(BoosterType.xp, 2);
      session.addBooster(BoosterType.coins, 2);

      expect(session.activateBooster(BoosterType.xp), isTrue);
      expect(session.activateBooster(BoosterType.xp), isTrue);
      expect(session.activateBooster(BoosterType.coins), isTrue);
      expect(session.activeBoosters.length, 3);

      // 4th activation must fail
      expect(session.activateBooster(BoosterType.coins), isFalse);

      // Inventory should have decreased
      expect(session.getBoosterCount(BoosterType.xp), 1); // 1 default + 2 added - 2 activated = 1
      expect(session.getBoosterCount(BoosterType.coins), 1);
    });

    test('deactivateBooster returns to inventory', () {
      session.addBooster(BoosterType.shield, 1);
      expect(session.activateBooster(BoosterType.shield), isTrue);
      expect(session.activeBoosters.contains(BoosterType.shield), isTrue);
      expect(session.getBoosterCount(BoosterType.shield), 0);

      expect(session.deactivateBooster(BoosterType.shield), isTrue);
      expect(session.activeBoosters.contains(BoosterType.shield), isFalse);
      expect(session.getBoosterCount(BoosterType.shield), 1);
    });

    test('consumeActiveBoostersForMatch clears active list and returns consumed', () {
      session.addBooster(BoosterType.shield, 1);
      session.activateBooster(BoosterType.shield);

      final consumed = session.consumeActiveBoostersForMatch();
      expect(consumed.length, 1);
      expect(consumed.first, BoosterType.shield);
      expect(session.activeBoosters.isEmpty, isTrue);
    });

    test('buyBooster deducts coins and adds to inventory', () {
      final initialCoins = session.coins;
      final success = session.buyBooster(BoosterType.xp);
      expect(success, isTrue);
      expect(session.coins, initialCoins - 300);
      expect(session.getBoosterCount(BoosterType.xp), 2); // 1 initial + 1 bought
    });

    test('buyBoosterBundle adds 3 boosters and deducts 900 coins', () {
      final initialCoins = session.coins;
      final success = session.buyBoosterBundle(
        cost: 900,
        boosters: [BoosterType.xp, BoosterType.shield, BoosterType.coins],
      );
      expect(success, isTrue);
      expect(session.coins, initialCoins - 900);
      expect(session.getBoosterCount(BoosterType.shield), 1);
      expect(session.getBoosterCount(BoosterType.coins), 1);
    });
  });
}
