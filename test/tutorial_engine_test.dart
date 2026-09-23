import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/services/audio_service.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/tutorial/tutorial_engine.dart';
import 'package:gme/features/la_caida/tutorial/tutorial_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialEngine - Tour de Inicio Maestro (4 Jugadores)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AudioService().isMuted = true;
      PlayerSession.setShared(PlayerSession.createDefault(coins: 0, hasCompletedTutorial: false));
    });

    test('Catálogo oficial contiene exactamente 10 etapas consecutivas y 4 jugadores', () {
      final engine = TutorialEngine();
      expect(engine.totalSteps, 10);
      expect(engine.currentStepIndex, 0);
      expect(engine.isCompleted, false);
      expect(engine.players.length, 4);
      expect(engine.userPlayer.name.isNotEmpty, true);
      expect(engine.carlosPlayer.name, 'Carlos');
      expect(engine.mariaPlayer.name, 'María');
      expect(engine.pedroPlayer.name, 'Pedro');
    });

    test('Etapa 1: Sorteo de Mano - Usuario elige carta y se corona como Mano', () async {
      final engine = TutorialEngine();
      expect(engine.currentStep.stepNumber, 1);
      expect(engine.currentStep.actionType, TutorialActionType.chooseManoCard);

      final candidate = engine.manoSession.candidates.first;
      await engine.pickManoCandidate(candidate);

      expect(engine.manoIndex, 0); // Usuario es la Mano
      expect(engine.manoSession.candidates.any((c) => c.isWinner && c.chosenByPlayerIndex == 0), true);
      expect(engine.showingFeedbackModal, true);
    });

    test('Etapa 2 a 4: Observación pedagógica (Reparto, Ronda y Patrulla)', () {
      final engine = TutorialEngine();
      engine.advanceToNextStep(); // Paso 2: Reparto
      expect(engine.currentStep.stepNumber, 2);
      expect(engine.currentStep.actionType, TutorialActionType.observeStage);
      expect(engine.pedroPlayer.callout != null, true);

      engine.triggerObservationCompletion();
      expect(engine.showingFeedbackModal, true);

      engine.advanceToNextStep(); // Paso 3: Ronda matada
      expect(engine.currentStep.stepNumber, 3);
      expect(engine.mariaPlayer.score, 2); // Ronda de Sotas cobrada por María

      engine.advanceToNextStep(); // Paso 4: Patrulla
      expect(engine.currentStep.stepNumber, 4);
      expect(engine.carlosPlayer.score, 6); // Patrulla de Carlos
    });

    test('Etapa 5: Canto de Vigía del usuario (+7 pts)', () {
      final engine = TutorialEngine();
      for (int i = 0; i < 4; i++) {
        engine.advanceToNextStep();
      }
      expect(engine.currentStep.stepNumber, 5);
      expect(engine.currentStep.actionType, TutorialActionType.callCanto);

      expect(engine.callUserCanto('PATRULLA'), false);
      expect(engine.callUserCanto('VIGÍA'), true);
      expect(engine.userScore, 7);
      expect(engine.userPlayer.callout, '¡VIGÍA! (+7 pts)');
    });

    test('Etapas 7, 8 y 9: Mecánicas de Mesa (Caída, Arrastre y Mesa Limpia)', () {
      final engine = TutorialEngine();

      // Avanzar a Etapa 7: Caída directa
      for (int i = 0; i < 6; i++) {
        engine.advanceToNextStep();
      }
      expect(engine.currentStep.stepNumber, 7);
      expect(engine.currentStep.actionType, TutorialActionType.playCard);

      // Carta incorrecta rechazada
      const wrongCard = SpanishCard(number: 2, suit: CardSuit.bastos);
      expect(engine.canPlayCard(wrongCard), false);
      expect(engine.playUserCard(wrongCard), false);

      // Jugar 6 de Copas sobre el 6 de Espadas de Carlos
      const caidaCard = SpanishCard(number: 6, suit: CardSuit.copas);
      expect(engine.canPlayCard(caidaCard), true);
      expect(engine.playUserCard(caidaCard), true);
      expect(engine.userScore, 1);
      expect(engine.tableCards.isEmpty, true);

      // Etapa 8: Arrastre
      engine.advanceToNextStep();
      expect(engine.currentStep.stepNumber, 8);
      const arrastreCard = SpanishCard(number: 7, suit: CardSuit.espadas);
      expect(engine.playUserCard(arrastreCard), true);
      expect(engine.userScore, 2);

      // Etapa 9: Mesa Limpia
      engine.advanceToNextStep();
      expect(engine.currentStep.stepNumber, 9);
      const limpiaCard = SpanishCard(number: 12, suit: CardSuit.copas);
      expect(engine.playUserCard(limpiaCard), true);
      expect(engine.userScore, 6); // 2 previos + 4 de limpia
    });

    test('Etapa 10: Clímax de Trivilín - Victoria fulminante, +1,000 monedas y graduación', () {
      final engine = TutorialEngine();
      final session = PlayerSession.shared;
      expect(session.coins, 0);
      expect(session.hasCompletedTutorial, false);

      for (int i = 0; i < 9; i++) {
        engine.advanceToNextStep();
      }
      expect(engine.currentStep.stepNumber, 10);
      expect(engine.currentStep.isTrivilinFinale, true);

      final success = engine.callUserCanto('¡TRIVILÍN!');
      expect(success, true);
      expect(engine.isCompleted, true);
      expect(engine.userScore, 24);

      // Validación económica de graduación
      expect(session.coins, 1000);
      expect(session.hasCompletedTutorial, true);
    });

    test('Flujo cinemático lineal: executeCurrentStepAction progresa paso a paso', () async {
      final engine = TutorialEngine();
      expect(engine.currentStepIndex, 0);

      // Paso 1: Sorteo
      await engine.pickManoCandidate(engine.manoSession.candidates.first);
      expect(engine.showingFeedbackModal, true);
      engine.executeCurrentStepAction(); // Avanza a paso 2

      expect(engine.currentStepIndex, 1);
      expect(engine.showingFeedbackModal, false);

      // Paso 2 a 10 usando executeCurrentStepAction
      while (!engine.isCompleted && engine.currentStepIndex < 9) {
        engine.executeCurrentStepAction(); // Ejecuta acción -> showingFeedbackModal = true
        expect(engine.showingFeedbackModal, true);
        engine.executeCurrentStepAction(); // Avanza al siguiente paso
      }

      // Etapa 10: Trivilín
      expect(engine.currentStepIndex, 9);
      engine.executeCurrentStepAction();
      expect(engine.isCompleted, true);
    });
  });
}
