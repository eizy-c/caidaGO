import '../../../core/models/cards/spanish_card.dart';
import 'caida_rules_engine.dart';

/// Motor de Inteligencia Artificial para La Caída Venezolana.
///
/// Evalúa estratégicamente la mejor carta a jugar basada en los principios
/// tradicionales:
/// 1. ¡Caída! inmediata sobre el rival (máxima prioridad y puntos directos).
/// 2. ¡Mesa Limpia! (vaciar la mesa otorgando 4 pts).
/// 3. Arrastre de cartas (seguidilla de cartas consecutivas para acumular volumen).
/// 4. Descarte defensivo y táctico cuando no hay captura:
///    - Protección de Figuras (10, 11, 12): evitar dejarlas expuestas a caídas rivales.
///    - Pesca / Trampa: jugar cartas duplicadas en mano para recogerlas el siguiente turno.
///    - Prevención de escalera: evitar colocar cartas que faciliten arrastre al siguiente jugador.
///    - Preferencia por cartas bajas (As, 2, 3...) seguras de menor riesgo.
class CaidaAiEngine {
  /// Selecciona la mejor carta de la mano del bot.
  static SpanishCard chooseBestCard({
    required List<SpanishCard> hand,
    required List<SpanishCard> tableCards,
    SpanishCard? previousCard,
    bool isDeckEmpty = false,
    bool isPreviousPlayerTeammate = false,
  }) {
    if (hand.isEmpty) {
      throw ArgumentError('La mano no puede estar vacía');
    }
    if (hand.length == 1) {
      return hand.first;
    }

    SpanishCard bestCard = hand.first;
    double bestScore = -double.infinity;

    for (final card in hand) {
      final score = evaluateCardScore(
        candidate: card,
        hand: hand,
        tableCards: tableCards,
        previousCard: previousCard,
        isDeckEmpty: isDeckEmpty,
        isPreviousPlayerTeammate: isPreviousPlayerTeammate,
      );

      if (score > bestScore) {
        bestScore = score;
        bestCard = card;
      }
    }

    return bestCard;
  }

  /// Evalúa numéricamente el valor estratégico de jugar una carta específica.
  static double evaluateCardScore({
    required SpanishCard candidate,
    required List<SpanishCard> hand,
    required List<SpanishCard> tableCards,
    SpanishCard? previousCard,
    bool isDeckEmpty = false,
    bool isPreviousPlayerTeammate = false,
  }) {
    double score = 0.0;

    final eval = CaidaRulesEngine.evaluatePlay(
      playedCard: candidate,
      tableCards: tableCards,
      previousCard: previousCard,
      isDeckEmpty: isDeckEmpty,
    );

    // 1. ¡CAÍDA! (Evaluada con máxima prioridad al coincidir con la carta del jugador previo)
    if (eval.isCaida) {
      if (!isPreviousPlayerTeammate) {
        // Caída a un rival: máxima prioridad
        score += 10000.0 + (eval.caidaPoints * 500.0);
      } else {
        // Caída accidental a un compañero: puntuación moderada
        score += 600.0 + (eval.caidaPoints * 50.0);
      }
    }

    // 2. CAPTURA Y MESA LIMPIA
    if (eval.didCapture) {
      // 2.1. ¡Mesa Limpia!
      if (eval.isLimpia) {
        score += 5000.0 + (eval.limpiaPoints * 400.0);
      }

      // 2.2. Volumen de cartas capturadas (acumular para las 20+ cartas)
      score += 1000.0 + (eval.capturedCards.length * 150.0);

      // Bonificación extra por arrastre masivo (3 o más cartas recogidas)
      if (eval.capturedCards.length >= 3) {
        score += 350.0;
      }

      return score;
    }

    if (eval.isCaida) {
      return score;
    }

    // 2. DESCARTE SIN CAPTURA (Juego defensivo y colocación táctica)
    // 2.1. Protección estricta de figuras: Rey (12), Caballo (11), Sota (10)
    switch (candidate.number) {
      case 12: // Rey: Caída rival valdría 4 pts
        score -= 600.0;
        break;
      case 11: // Caballo: Caída rival valdría 3 pts
        score -= 450.0;
        break;
      case 10: // Sota: Caída rival valdría 2 pts
        score -= 300.0;
        break;
      default: // Cartas 1 a 7: Menor riesgo
        score += (7 - candidate.number) * 20.0;
        break;
    }

    // 2.2. Pesca / Trampa (Tener duplicado en mano)
    final duplicatesInHand = hand.where((c) => c.number == candidate.number).length;
    if (duplicatesInHand > 1) {
      // Se descarta sabiendo que se tiene el duplicado para recoger en el próximo turno
      score += 350.0;
    }

    // 2.3. Prevención de escalera / arrastre para rivales
    // Si la mesa ya tiene una carta N y candidate es N+1 (según secuencia),
    // facilitamos que un rival con N se lleve ambas en arrastre
    final createsLadderRisk = tableCards.any((tc) =>
        CaidaRulesEngine.getNextInSequence(tc.number) == candidate.number);
    if (createsLadderRisk) {
      score -= 200.0;
    }

    return score;
  }
}
