import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/features/la_caida/domain/caida_ai_engine.dart';

void main() {
  group('CaidaAiEngine - Heurística e Inteligencia de Juego', () {
    test('Prioriza ¡Caída! inmediata sobre carta del rival antes que cualquier descarte', () {
      final hand = [
        const SpanishCard(number: 1, suit: CardSuit.oros),
        const SpanishCard(number: 7, suit: CardSuit.copas),
        const SpanishCard(number: 12, suit: CardSuit.espadas),
      ];

      final tableCards = [
        const SpanishCard(number: 3, suit: CardSuit.bastos),
      ];

      // El rival anterior jugó un 7
      final previousCard = const SpanishCard(number: 7, suit: CardSuit.bastos);

      final chosen = CaidaAiEngine.chooseBestCard(
        hand: hand,
        tableCards: tableCards,
        previousCard: previousCard,
        isPreviousPlayerTeammate: false,
      );

      expect(chosen.number, equals(7), reason: 'El bot debe cantar ¡Caída! con el 7');
    });

    test('Prioriza ¡Mesa Limpia! cuando una carta limpia la mesa por completo', () {
      final hand = [
        const SpanishCard(number: 2, suit: CardSuit.oros),
        const SpanishCard(number: 4, suit: CardSuit.copas),
      ];

      // Mesa con solo un 4
      final tableCards = [
        const SpanishCard(number: 4, suit: CardSuit.espadas),
      ];

      final chosen = CaidaAiEngine.chooseBestCard(
        hand: hand,
        tableCards: tableCards,
      );

      expect(chosen.number, equals(4), reason: 'El 4 captura y hace Mesa Limpia');
    });

    test('Maximiza Arrastre levantando secuencia de cartas', () {
      // Mano con un 3 y un 10
      final hand = [
        const SpanishCard(number: 3, suit: CardSuit.oros),
        const SpanishCard(number: 10, suit: CardSuit.copas),
      ];

      // Mesa con 3, 4, 5 y un 10 aislado
      final tableCards = [
        const SpanishCard(number: 3, suit: CardSuit.copas),
        const SpanishCard(number: 4, suit: CardSuit.espadas),
        const SpanishCard(number: 5, suit: CardSuit.bastos),
        const SpanishCard(number: 10, suit: CardSuit.oros),
      ];

      final chosen = CaidaAiEngine.chooseBestCard(
        hand: hand,
        tableCards: tableCards,
      );

      expect(chosen.number, equals(3),
          reason: 'El 3 arrastra 3-4-5 (3 cartas) superando la captura simple del 10');
    });

    test('Protege figuras al descartar (prefiere tirar carta baja antes que Rey o Caballo)', () {
      // Mano sin capturas sobre la mesa
      final hand = [
        const SpanishCard(number: 12, suit: CardSuit.oros), // Rey
        const SpanishCard(number: 11, suit: CardSuit.copas), // Caballo
        const SpanishCard(number: 2, suit: CardSuit.espadas),  // Carta baja segura
      ];

      final tableCards = [
        const SpanishCard(number: 5, suit: CardSuit.bastos),
      ];

      final chosen = CaidaAiEngine.chooseBestCard(
        hand: hand,
        tableCards: tableCards,
      );

      expect(chosen.number, equals(2),
          reason: 'Debe proteger el 11 y 12 y descartar el 2');
    });

    test('Táctica de Pesca/Trampa: Prefiere descartar carta con duplicado en mano', () {
      final hand = [
        const SpanishCard(number: 4, suit: CardSuit.oros),
        const SpanishCard(number: 4, suit: CardSuit.copas),
        const SpanishCard(number: 6, suit: CardSuit.espadas),
      ];

      final tableCards = [
        const SpanishCard(number: 1, suit: CardSuit.bastos),
      ];

      final chosen = CaidaAiEngine.chooseBestCard(
        hand: hand,
        tableCards: tableCards,
      );

      expect(chosen.number, equals(4),
          reason: 'Tirar uno de los dos 4 prepara la pesca/trampa para el siguiente turno');
    });
  });
}
