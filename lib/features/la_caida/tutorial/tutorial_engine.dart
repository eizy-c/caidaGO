import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/cards/card_suit.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/user_profile_service.dart';
import '../domain/models/mano_draw_session.dart';
import '../economy/player_session.dart';
import 'tutorial_step.dart';

/// Representación simplificada de un participante en el tutorial guiado de 4 jugadores.
class TutorialPlayer {
  final int index;
  final String name;
  final Color color;
  final int avatarId;
  final bool isBot;
  int score;
  int cardsInHandCount;
  String? callout;

  TutorialPlayer({
    required this.index,
    required this.name,
    required this.color,
    required this.avatarId,
    required this.isBot,
    this.score = 0,
    this.cardsInHandCount = 3,
    this.callout,
  });
}

/// Motor controlador reactivo para el tour guiado de entrenamiento de La Caída (4 jugadores).
class TutorialEngine extends ChangeNotifier {
  final List<TutorialStep> _steps = TutorialStep.officialSteps;
  int _currentStepIndex = 0;
  bool _showingFeedbackModal = false;
  bool _isCompleted = false;
  bool _rewardAwarded = false;

  int _manoIndex = 0; // Índice de quién es la Mano (0: Usuario)
  late List<TutorialPlayer> _players;
  late List<SpanishCard> _currentUserHand;
  late List<SpanishCard> _currentTableCards;

  // Sesión de Sorteo de Mano para la Etapa 1
  late ManoDrawSession _manoSession;
  bool _isResolvingMano = false;

  TutorialEngine() {
    final session = PlayerSession.shared;
    _players = [
      TutorialPlayer(
        index: 0,
        name: session.name.isEmpty ? 'Tú' : session.name,
        color: const Color(0xFF10B981),
        avatarId: session.avatarIndex,
        isBot: false,
        score: 0,
        cardsInHandCount: 0,
      ),
      TutorialPlayer(
        index: 1,
        name: 'Carlos',
        color: const Color(0xFF3B82F6),
        avatarId: 3,
        isBot: true,
        score: 0,
        cardsInHandCount: 0,
      ),
      TutorialPlayer(
        index: 2,
        name: 'María',
        color: const Color(0xFF8B5CF6),
        avatarId: 4,
        isBot: true,
        score: 0,
        cardsInHandCount: 0,
      ),
      TutorialPlayer(
        index: 3,
        name: 'Pedro',
        color: const Color(0xFFEF4444),
        avatarId: 1,
        isBot: true,
        score: 0,
        cardsInHandCount: 0,
      ),
    ];

    _initManoSession();
    _loadStep(0);
  }

  void _initManoSession() {
    _manoSession = ManoDrawSession.startNew(
      initialAnnouncement: 'Sorteo de Mano: Toca una carta para ver quién sale',
    );
  }

  // Getters públicos
  List<TutorialStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  TutorialStep get currentStep => _steps[_currentStepIndex];
  int get totalSteps => _steps.length;
  bool get showingFeedbackModal => _showingFeedbackModal;
  bool get isCompleted => _isCompleted;
  int get manoIndex => _manoIndex;

  List<TutorialPlayer> get players => _players;
  TutorialPlayer get userPlayer => _players[0];
  TutorialPlayer get carlosPlayer => _players[1];
  TutorialPlayer get mariaPlayer => _players[2];
  TutorialPlayer get pedroPlayer => _players[3];

  int get userScore => _players[0].score;
  List<SpanishCard> get userHand => List.unmodifiable(_currentUserHand);
  List<SpanishCard> get tableCards => List.unmodifiable(_currentTableCards);

  ManoDrawSession get manoSession => _manoSession;
  bool get isResolvingMano => _isResolvingMano;

  void _loadStep(int index) {
    final step = _steps[index];
    _currentUserHand = List.from(step.playerCards);
    _currentTableCards = List.from(step.initialTableCards);
    _showingFeedbackModal = false;

    // Actualizar estados visuales de los rivales según la etapa
    _players[0].callout = step.userCallout;
    _players[1].callout = step.carlosCallout;
    _players[2].callout = step.mariaCallout;
    _players[3].callout = step.pedroCallout;

    _players[1].cardsInHandCount = step.carlosCardsCount;
    _players[2].cardsInHandCount = step.mariaCardsCount;
    _players[3].cardsInHandCount = step.pedroCardsCount;

    // Aplicar deltas de puntuación de rivales si aplica
    if (step.carlosScoreDelta > 0) _players[1].score += step.carlosScoreDelta;
    if (step.mariaScoreDelta > 0) _players[2].score += step.mariaScoreDelta;
    if (step.pedroScoreDelta > 0) _players[3].score += step.pedroScoreDelta;
  }

  // ===========================================================================
  // INTERACCIÓN: SORTEO DE MANO (ETAPA 1)
  // ===========================================================================
  Future<void> pickManoCandidate(ManoCardCandidate userChoice) async {
    if (_isResolvingMano || userChoice.chosenByPlayerIndex != null) return;
    _isResolvingMano = true;
    notifyListeners();

    AudioService().playCardFlip();

    // 1. Asignar el 11 de Copas al usuario
    final userScriptedCard = const SpanishCard(number: 11, suit: CardSuit.copas);
    final userIdx = _manoSession.candidates.indexOf(userChoice);
    if (userIdx != -1) {
      _manoSession.candidates[userIdx] = ManoCardCandidate(
        id: userChoice.id,
        card: userScriptedCard,
        topOffset: userChoice.topOffset,
        leftOffset: userChoice.leftOffset,
        rotation: userChoice.rotation,
        chosenByPlayerIndex: 0,
        isRevealed: true,
      );
    }
    _manoSession.announcement = 'Tú sacas: 11 de Copas (Caballo)';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    // 2. Carlos (Oeste) saca 4 de Espadas
    final unchosen = _manoSession.unchosenCandidates;
    if (unchosen.isNotEmpty) {
      final bot1 = unchosen.removeAt(0);
      final idx1 = _manoSession.candidates.indexOf(bot1);
      _manoSession.candidates[idx1] = ManoCardCandidate(
        id: bot1.id,
        card: const SpanishCard(number: 4, suit: CardSuit.espadas),
        topOffset: bot1.topOffset,
        leftOffset: bot1.leftOffset,
        rotation: bot1.rotation,
        chosenByPlayerIndex: 1,
        isRevealed: true,
      );
      AudioService().playCardFlip();
      _manoSession.announcement = 'Carlos sacó: 4 de Espadas';
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 650));

    // 3. María (Norte) saca 7 de Oros
    final unchosen2 = _manoSession.unchosenCandidates;
    if (unchosen2.isNotEmpty) {
      final bot2 = unchosen2.removeAt(0);
      final idx2 = _manoSession.candidates.indexOf(bot2);
      _manoSession.candidates[idx2] = ManoCardCandidate(
        id: bot2.id,
        card: const SpanishCard(number: 7, suit: CardSuit.oros),
        topOffset: bot2.topOffset,
        leftOffset: bot2.leftOffset,
        rotation: bot2.rotation,
        chosenByPlayerIndex: 2,
        isRevealed: true,
      );
      AudioService().playCardFlip();
      _manoSession.announcement = 'María sacó: 7 de Oros';
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 650));

    // 4. Pedro (Este) saca Sota 10 de Bastos
    final unchosen3 = _manoSession.unchosenCandidates;
    if (unchosen3.isNotEmpty) {
      final bot3 = unchosen3.removeAt(0);
      final idx3 = _manoSession.candidates.indexOf(bot3);
      _manoSession.candidates[idx3] = ManoCardCandidate(
        id: bot3.id,
        card: const SpanishCard(number: 10, suit: CardSuit.bastos),
        topOffset: bot3.topOffset,
        leftOffset: bot3.leftOffset,
        rotation: bot3.rotation,
        chosenByPlayerIndex: 3,
        isRevealed: true,
      );
      AudioService().playCardFlip();
      _manoSession.announcement = 'Pedro sacó: 10 de Bastos';
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 800));

    // 5. Declarar al usuario ganador del sorteo
    if (userIdx != -1) {
      _manoSession.candidates[userIdx].isWinner = true;
    }
    _manoIndex = 0;
    _manoSession.announcement = '¡Sacaste el 11 de Copas y eres MANO!';
    AudioService().playCaida();
    _isResolvingMano = false;

    await Future.delayed(const Duration(milliseconds: 900));
    _showingFeedbackModal = true;
    notifyListeners();
  }

  // ===========================================================================
  // INTERACCIÓN: AVANZAR ETAPAS OBSERVACIONALES (ETAPAS 2, 3, 4, 6)
  // ===========================================================================
  void triggerObservationCompletion() {
    _showingFeedbackModal = true;
    notifyListeners();
  }

  // ===========================================================================
  // INTERACCIÓN: JUGAR CARTA (ETAPAS 7, 8, 9)
  // ===========================================================================
  bool canPlayCard(SpanishCard card) {
    if (currentStep.actionType != TutorialActionType.playCard) return false;
    final target = currentStep.targetCard;
    if (target == null) return false;
    return card.number == target.number && card.suit == target.suit;
  }

  bool playUserCard(SpanishCard card) {
    if (!canPlayCard(card)) return false;

    _currentUserHand.removeWhere((c) => c.number == card.number && c.suit == card.suit);

    if (currentStep.stepNumber == 7) {
      // Caída directa sobre el 6 de Espadas de Carlos
      _currentTableCards.clear();
      AudioService().playCaida();
    } else if (currentStep.stepNumber == 8) {
      // Arrastre y seguidilla: levanta 7, 10 y 11
      _currentTableCards.clear();
      AudioService().playCaida();
    } else if (currentStep.stepNumber == 9) {
      // Mesa Limpia: levanta el Rey y deja el tapete en blanco
      _currentTableCards.clear();
      AudioService().playCaida();
      Future.delayed(const Duration(milliseconds: 600), () {
        AudioService().playMesaLimpia();
      });
    }

    _players[0].score += currentStep.pointsAwarded;
    _players[0].callout = currentStep.userCallout;
    _showingFeedbackModal = true;
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // INTERACCIÓN: CANTOS (ETAPA 5 VIGÍA Y ETAPA 10 TRIVILÍN)
  // ===========================================================================
  bool canCallCanto(String cantoName) {
    if (currentStep.actionType != TutorialActionType.callCanto) return false;
    final target = currentStep.targetCantoName;
    if (target == null) return false;
    return target.toUpperCase().contains(cantoName.toUpperCase()) ||
        cantoName.toUpperCase().contains(target.toUpperCase());
  }

  bool callUserCanto(String cantoName) {
    if (!canCallCanto(cantoName)) return false;

    if (currentStep.stepNumber == 5) {
      AudioService().playVigia();
    } else if (currentStep.stepNumber == 10) {
      AudioService().playCanto('trivilin');
      _isCompleted = true;
      if (!_rewardAwarded) {
        _rewardAwarded = true;
        PlayerSession.shared.completeTutorialReward(coinReward: 1000);
        UserProfileService().markNotFirstTime();
      }
    }

    _players[0].score += currentStep.pointsAwarded;
    _players[0].callout = currentStep.userCallout;
    _showingFeedbackModal = true;
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // NAVEGACIÓN Y AVANCE DE PASOS
  // ===========================================================================
  void advanceToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _loadStep(_currentStepIndex);
    } else {
      _isCompleted = true;
      _showingFeedbackModal = false;
    }
    notifyListeners();
  }

  void dismissFeedback() {
    _showingFeedbackModal = false;
    notifyListeners();
  }

  void reset() {
    _currentStepIndex = 0;
    _isCompleted = false;
    _isResolvingMano = false;
    for (final p in _players) {
      p.score = 0;
      p.callout = null;
    }
    _initManoSession();
    _loadStep(0);
    notifyListeners();
  }
}
