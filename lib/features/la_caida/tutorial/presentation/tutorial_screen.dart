import 'package:flutter/material.dart';
import '../../../../core/models/cards/card_suit.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/presentation/widgets/game_table_header.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../../core/presentation/widgets/table_player_badge.dart';
import '../../../../core/presentation/widgets/wood_table_background.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../presentation/widgets/deck_stack_view.dart';
import '../../presentation/widgets/card_flight_overlay.dart';
import '../../domain/models/spatial_card_state.dart';
import '../../domain/models/table_landing_zone.dart';
import '../../domain/models/mano_draw_session.dart';
import '../tutorial_engine.dart';
import '../tutorial_step.dart';
import 'tutorial_completion_dialog.dart';

/// Pantalla interactiva lineal y cinemática para el Tour de Inicio Maestro de La Caída.
/// Diseñada con una única tarjeta de historia y avance ("CONTINUAR ▶"), eliminando
/// la complejidad de botones múltiples y guiando al jugador paso a paso en una
/// experiencia fluida e inmersiva.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late final TutorialEngine _engine;
  late AnimationController _targetPulse;
  late AnimationController _cantoPulse;

  List<CardFlightTrajectory> _activeTrajectories = [];
  bool _isDealingAnimationRunning = false;
  String? _pointEventBanner;
  bool _hasShownGraduationDialog = false;

  final List<PlacedTableCard> _placedTableCards = [];
  int _tableCardZCounter = 0;

  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine();
    _engine.addListener(_onEngineChanged);

    _targetPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _cantoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _targetPulse.dispose();
    _cantoPulse.dispose();
    super.dispose();
  }

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showGraduationDialog() {
    if (_hasShownGraduationDialog || !mounted) return;
    _hasShownGraduationDialog = true;

    TutorialCompletionDialog.show(
      context,
      onGoToLobby: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
  }

  /// Animación visual fluida de reparto: 4 cartas a la mesa y naipes a las manos de los 4 jugadores
  Future<void> _animateCardDeal() async {
    if (_isDealingAnimationRunning) return;
    _isDealingAnimationRunning = true;

    final tableOffsets = [
      const Offset(-68, -80),
      const Offset(68, -80),
      const Offset(-68, 75),
      const Offset(68, 75),
    ];

    // 1. Repartir 4 cartas abiertas al centro de la mesa
    final step2 = _engine.steps[1];
    for (int i = 0; i < step2.initialTableCards.length; i++) {
      final card = step2.initialTableCards[i];
      AudioService().playCardDeal();
      HapticService.instance.onCardPlay();

      setState(() {
        _activeTrajectories = [
          CardFlightTrajectory(
            id: 'deal_table_${i}_${DateTime.now().millisecondsSinceEpoch}',
            card: card,
            startAnchor: SpatialCardAnchor.deckAnchor,
            targetAnchor: SpatialCardAnchor(
              card: card,
              offset: tableOffsets[i % tableOffsets.length],
              rotation: (i.isEven ? -0.04 : 0.04),
            ),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            isFaceUp: true,
          ),
        ];
      });

      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
    }

    // 2. Repartir 3 rondas a los 4 jugadores (Carlos, María, Pedro y Tú)
    for (int round = 0; round < 3; round++) {
      for (int p = 1; p <= 4; p++) {
        final pIdx = p % 4; // 1: Carlos, 2: María, 3: Pedro, 0: Tú
        AudioService().playCardDeal();

        final cardToDeal = (pIdx == 0 && round < step2.playerCards.length)
            ? step2.playerCards[round]
            : const SpanishCard(number: 1, suit: CardSuit.oros);

        setState(() {
          _activeTrajectories = [
            CardFlightTrajectory(
              id: 'deal_player_${round}_${pIdx}_${DateTime.now().millisecondsSinceEpoch}',
              card: cardToDeal,
              startAnchor: SpatialCardAnchor.deckAnchor,
              targetAnchor: SpatialCardAnchor.playerStationAnchor(playerIndex: pIdx, totalPlayers: 4),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              isFaceUp: pIdx == 0,
            ),
          ];
        });

        await Future.delayed(const Duration(milliseconds: 110));
        if (!mounted) return;
      }
    }

    if (mounted) {
      setState(() {
        _activeTrajectories.clear();
        _isDealingAnimationRunning = false;
      });
    }
  }

  /// Ejecuta la acción cinemática correspondiente a la etapa actual
  void _onPrimaryActionTapped(TutorialStep step) async {
    if (_isDealingAnimationRunning) return;

    if (_engine.showingFeedbackModal) {
      _onAdvanceStep();
      return;
    }

    switch (step.actionType) {
      case TutorialActionType.chooseManoCard:
        final session = _engine.manoSession;
        final unchosen = session.unchosenCandidates;
        if (unchosen.isNotEmpty) {
          _engine.pickManoCandidate(unchosen.first);
        }
        break;

      case TutorialActionType.observeStage:
      case TutorialActionType.observeCantos:
        _engine.triggerObservationCompletion();
        break;

      case TutorialActionType.playCard:
        if (step.targetCard != null) {
          final card = step.targetCard!;
          if (step.stepNumber == 7) {
            _pointEventBanner = '¡CAÍDA! +1 pt';
          } else if (step.stepNumber == 8) {
            _pointEventBanner = '¡ARRASTRE EN SEGUIDILLA! +3 cartas';
          } else if (step.stepNumber == 9) {
            _pointEventBanner = '¡MESA LIMPIA! +4 pts';
          }

          // 1. Cinemática de tiro: la carta vuela de la mano al centro de la mesa
          AudioService().playCardPlace();
          HapticService.instance.onCardPlay();

          setState(() {
            _activeTrajectories = [
              CardFlightTrajectory(
                id: 'user_play_${DateTime.now().millisecondsSinceEpoch}',
                card: card,
                startAnchor: const SpatialCardAnchor(offset: Offset(80, 200)),
                targetAnchor: const SpatialCardAnchor(offset: Offset(0, 0)),
                duration: const Duration(milliseconds: 270),
                curve: Curves.easeOutCubic,
                isFaceUp: true,
              ),
            ];
          });

          await Future.delayed(const Duration(milliseconds: 280));
          if (!mounted) return;

          // 2. Procesar jugada en el motor
          _engine.playUserCard(card);

          // 3. Cinemática de captura: las cartas ganadas vuelan al pozo del usuario
          await Future.delayed(const Duration(milliseconds: 180));
          if (!mounted) return;

          setState(() {
            _activeTrajectories = [
              CardFlightTrajectory(
                id: 'collect_user_${DateTime.now().millisecondsSinceEpoch}',
                card: card,
                startAnchor: const SpatialCardAnchor(offset: Offset(0, 0)),
                targetAnchor: SpatialCardAnchor.playerStationAnchor(playerIndex: 0, totalPlayers: 4),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                isFaceUp: false,
              ),
            ];
          });
        }
        break;

      case TutorialActionType.callCanto:
        if (step.targetCantoName != null) {
          if (step.stepNumber == 5) {
            _pointEventBanner = '¡VIGÍA! +7 pts (Mata a la Patrulla y Ronda)';
          } else if (step.stepNumber == 10) {
            _pointEventBanner = '¡¡¡TRIVILÍN VICTORIA POR NOCAUT!!! +24 pts';
          }
          _engine.callUserCanto(step.targetCantoName!);
        }
        break;
    }
  }

  void _onAdvanceStep() {
    final step = _engine.currentStep;
    _pointEventBanner = null;

    if (step.isTrivilinFinale) {
      _showGraduationDialog();
    } else {
      final nextIdx = _engine.currentStepIndex + 1;
      _engine.advanceToNextStep();

      // Si pasamos a la Etapa 2 (El Reparto), disparar la animación de reparto de naipes
      if (nextIdx == 1) {
        _animateCardDeal();
      }
    }
  }

  /// Sincroniza _placedTableCards con las cartas actuales del engine, manteniendo estabilidad
  void _syncTutorialPlacedCards() {
    final cards = _engine.tableCards;
    _placedTableCards.removeWhere((p) => !cards.contains(p.card));
    for (final card in cards) {
      final alreadyPlaced = _placedTableCards.any((p) => p.card == card);
      if (!alreadyPlaced) {
        _tableCardZCounter++;
        _placedTableCards.add(PlacedTableCard.computePlacementForCard(
          card: card,
          currentPlacedCards: _placedTableCards,
          zCounter: _tableCardZCounter,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _engine.currentStep;

    return Scaffold(
      // BARRA SUPERIOR IDÉNTICA A UNA PARTIDA REAL (Limpia y profesional)
      appBar: GameTableHeader(
        title: 'CaidaGO',
        titleWidget: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CaidaGO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.1),
                ),
                child: const Text(
                  'Tutorial • 4 Jugadores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        showTrophies: false,
        playerLevel: null,
        onBack: () => Navigator.of(context).pop(),
        isMuted: AudioService().isMuted,
        onToggleMute: () => setState(() => AudioService().toggleMute()),
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final isCompact = screenHeight < 560;

              return Stack(
                children: [
                  // 1. Mazo físico en esquina superior izquierda
                  if (step.actionType != TutorialActionType.chooseManoCard)
                    const Positioned(
                      left: 10,
                      top: 6,
                      child: DeckStackView(remainingCards: 28),
                    ),

                  // 2. Indicador oficial de mesa (igual a una partida real)
                  Positioned(
                    top: 6,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, color: Colors.white70, size: 12),
                          SizedBox(width: 4),
                          Text(
                            '4 Jug. • Mesa Oficial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Jugador 2: María (Norte / Frente - centrada arriba)
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TablePlayerBadge(
                        name: _engine.mariaPlayer.name,
                        score: _engine.mariaPlayer.score,
                        cardsWon: 0,
                        isBot: true,
                        isCurrentTurn: step.mariaCallout != null,
                        position: PlayerPositionOnTable.top,
                        avatarId: _engine.mariaPlayer.avatarId,
                        avatarColor: _engine.mariaPlayer.color,
                        calloutMessage: _engine.mariaPlayer.callout,
                        cardsInHandCount: _engine.mariaPlayer.cardsInHandCount,
                        isMano: _engine.manoIndex == 2,
                        isCompact: true,
                      ),
                    ),
                  ),

                  // 4. Panel Único de Historia y Acción Cinemática ("CONTINUAR ▶")
                  Positioned(
                    top: 58,
                    left: 10,
                    right: 10,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildMasterCinematicCard(step, isCompact),
                      ),
                    ),
                  ),

                  // 5. Jugador 1: Carlos (Oeste / Izquierda)
                  Positioned(
                    left: 6,
                    top: isCompact ? 175 : 190,
                    child: TablePlayerBadge(
                      name: _engine.carlosPlayer.name,
                      score: _engine.carlosPlayer.score,
                      cardsWon: 0,
                      isBot: true,
                      isCurrentTurn: step.carlosCallout != null,
                      position: PlayerPositionOnTable.left,
                      avatarId: _engine.carlosPlayer.avatarId,
                      avatarColor: _engine.carlosPlayer.color,
                      calloutMessage: _engine.carlosPlayer.callout,
                      cardsInHandCount: _engine.carlosPlayer.cardsInHandCount,
                      isMano: _engine.manoIndex == 1,
                      isCompact: true,
                    ),
                  ),

                  // 6. Jugador 3: Pedro (Este / Derecha - Repartidor / Postre inicial)
                  Positioned(
                    right: 6,
                    top: isCompact ? 175 : 190,
                    child: TablePlayerBadge(
                      name: _engine.pedroPlayer.name,
                      score: _engine.pedroPlayer.score,
                      cardsWon: 0,
                      isBot: true,
                      isCurrentTurn: step.pedroCallout != null,
                      position: PlayerPositionOnTable.right,
                      avatarId: _engine.pedroPlayer.avatarId,
                      avatarColor: _engine.pedroPlayer.color,
                      calloutMessage: _engine.pedroPlayer.callout,
                      cardsInHandCount: _engine.pedroPlayer.cardsInHandCount,
                      isMano: _engine.manoIndex == 3,
                      isCompact: true,
                    ),
                  ),

                  // 7. Área Central: Sorteo de Mano O Cartas de Mesa
                  Positioned.fill(
                    top: isCompact ? 170 : 185,
                    bottom: isCompact ? 105 : 120,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: step.actionType == TutorialActionType.chooseManoCard ? 50 : 16,
                        ),
                        child: step.actionType == TutorialActionType.chooseManoCard
                            ? _buildManoSelectionClean()
                            : _buildTableCardsArea(step),
                      ),
                    ),
                  ),

                  // 8. Banner de Evento / Jugada
                  if (_pointEventBanner != null)
                    Positioned(
                      top: isCompact ? 180 : 195,
                      left: 20,
                      right: 20,
                      child: Center(child: _buildPointEventBanner()),
                    ),

                  // 9. Jugador 0: Usuario (Sur / Abajo a la izquierda)
                  Positioned(
                    left: 8,
                    bottom: isCompact ? 10 : 16,
                    child: TablePlayerBadge(
                      name: _engine.userPlayer.name,
                      score: _engine.userPlayer.score,
                      cardsWon: 0,
                      isBot: false,
                      playerLevel: 1,
                      isCurrentTurn: true,
                      position: PlayerPositionOnTable.bottom,
                      avatarId: _engine.userPlayer.avatarId,
                      avatarColor: _engine.userPlayer.color,
                      calloutMessage: _engine.userPlayer.callout,
                      cardsInHandCount: _engine.userHand.length,
                      isMano: _engine.manoIndex == 0,
                      isCompact: true,
                    ),
                  ),

                  // 10. Mano interactiva de cartas del jugador (Abajo a la derecha)
                  if (_engine.userHand.isNotEmpty && step.actionType != TutorialActionType.chooseManoCard)
                    Positioned(
                      right: 8,
                      bottom: isCompact ? 10 : 16,
                      child: _buildUserHandFan(step),
                    ),

                  // 11. Capa superior de naipes en vuelo (CardFlightOverlay fluido)
                  Positioned.fill(
                    child: CardFlightOverlay(
                      activeTrajectories: _activeTrajectories,
                      onAllCompleted: () {
                        if (mounted) setState(() => _activeTrajectories.clear());
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Panel Único de Historia, Explicación Pedagógica y Botón Principal de Avance
  Widget _buildMasterCinematicCard(TutorialStep step, bool isCompact) {
    final isResult = _engine.showingFeedbackModal;
    final isLast = step.isTrivilinFinale;

    String actionButtonLabel;
    IconData actionButtonIcon;
    Color buttonColor;
    Color buttonTextColor;

    if (isResult) {
      if (isLast) {
        actionButtonLabel = '¡GRADUARME Y COBRAR 1,000 MONEDAS! 🏆';
        actionButtonIcon = Icons.monetization_on_rounded;
        buttonColor = const Color(0xFFF59E0B);
        buttonTextColor = const Color(0xFF1E1B4B);
      } else {
        actionButtonLabel = 'SIGUIENTE LECCIÓN ▶';
        actionButtonIcon = Icons.arrow_forward_rounded;
        buttonColor = const Color(0xFF10B981);
        buttonTextColor = Colors.white;
      }
    } else {
      buttonTextColor = const Color(0xFF1E1B4B);
      buttonColor = const Color(0xFFF59E0B);
      switch (step.actionType) {
        case TutorialActionType.chooseManoCard:
          actionButtonLabel = 'SORTEAR CARTA DE MANO ▶';
          actionButtonIcon = Icons.touch_app_rounded;
          break;
        case TutorialActionType.observeStage:
          actionButtonLabel = step.stepNumber == 2 ? 'VER REPARTO DE CARTAS ▶' : 'CONTINUAR ▶';
          actionButtonIcon = Icons.play_arrow_rounded;
          break;
        case TutorialActionType.observeCantos:
          actionButtonLabel = 'CONTINUAR ▶';
          actionButtonIcon = Icons.arrow_forward_rounded;
          break;
        case TutorialActionType.playCard:
          if (step.stepNumber == 7) {
            actionButtonLabel = 'JUGAR 6 Y HACER CAÍDA (+1 pt) ▶';
          } else if (step.stepNumber == 8) {
            actionButtonLabel = 'ARRASTRAR 7 ➔ 10 ➔ 11 ▶';
          } else if (step.stepNumber == 9) {
            actionButtonLabel = 'HACER MESA LIMPIA (+4 pts) ▶';
          } else {
            actionButtonLabel = 'JUGAR CARTA ▶';
          }
          actionButtonIcon = Icons.style_rounded;
          break;
        case TutorialActionType.callCanto:
          if (isLast) {
            actionButtonLabel = '¡¡CANTAR TRIVILÍN!! (VICTORIA) 👑 ▶';
            buttonColor = const Color(0xFFDC2626);
            buttonTextColor = Colors.white;
            actionButtonIcon = Icons.auto_awesome_rounded;
          } else {
            actionButtonLabel = '¡CANTAR ${step.targetCantoName ?? "CANTO"}! (+${step.pointsAwarded} pts) 📢';
            actionButtonIcon = Icons.campaign_rounded;
          }
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResult
              ? (isLast ? const Color(0xFFFDE047) : const Color(0xFF10B981))
              : const Color(0xFFF59E0B),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila 1: Placa de Lección + Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isResult ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isResult ? Icons.check_circle_rounded : Icons.school_rounded,
                      color: isResult ? Colors.white : const Color(0xFF1E1B4B),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isResult ? 'LOGRADO' : 'LECCIÓN ${step.stepNumber}/${_engine.totalSteps}',
                      style: TextStyle(
                        color: isResult ? Colors.white : const Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 9.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isResult ? step.feedbackTitle : step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isResult ? const Color(0xFFFDE68A) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Fila 2: Texto Explicativo o Feedback
          Text(
            isResult ? step.feedbackDetail : '${step.instruction} ${step.teacherExplanation}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),

          // Fila 3: Botón Único de Acción Lineal
          AnimatedBuilder(
            animation: _targetPulse,
            builder: (context, _) {
              final scale = 1.0 + (_targetPulse.value * (isLast ? 0.04 : 0.02));

              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: buttonTextColor,
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _onPrimaryActionTapped(step),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(actionButtonIcon, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            actionButtonLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Sorteo de Mano Limpio y Sin Desorden
  Widget _buildManoSelectionClean() {
    final session = _engine.manoSession;
    final candidates = session.candidates;
    final hasChosen = candidates.any((c) => c.chosenByPlayerIndex != null);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SI AÚN NO HA ELEGIDO: Mostrar abanico ordenado en 2 filas limpias
          if (!hasChosen)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: candidates.take(4).map((cand) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _engine.pickManoCandidate(cand),
                        child: AnimatedBuilder(
                          animation: _targetPulse,
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, -3.0 * _targetPulse.value),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const SpanishCardView.back(width: 54),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: candidates.skip(4).take(4).map((cand) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _engine.pickManoCandidate(cand),
                        child: AnimatedBuilder(
                          animation: _targetPulse,
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(0, -3.0 * _targetPulse.value),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const SpanishCardView.back(width: 54),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          else
            _buildRevealedManoCards(),
        ],
      ),
    );
  }

  /// Visualización cristalina de las 4 cartas sacadas por los 4 jugadores en el sorteo
  Widget _buildRevealedManoCards() {
    final session = _engine.manoSession;
    final chosen = session.candidates.where((c) => c.chosenByPlayerIndex != null).toList();

    final userChoice = chosen.cast<ManoCardCandidate?>().firstWhere((c) => c?.chosenByPlayerIndex == 0, orElse: () => null);
    final carlosChoice = chosen.cast<ManoCardCandidate?>().firstWhere((c) => c?.chosenByPlayerIndex == 1, orElse: () => null);
    final mariaChoice = chosen.cast<ManoCardCandidate?>().firstWhere((c) => c?.chosenByPlayerIndex == 2, orElse: () => null);
    final pedroChoice = chosen.cast<ManoCardCandidate?>().firstWhere((c) => c?.chosenByPlayerIndex == 3, orElse: () => null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fila 1: Los 3 Rivales (Carlos, María, Pedro)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (carlosChoice != null)
              _buildSingleManoCard(
                card: carlosChoice.card,
                player: _engine.carlosPlayer,
                isWinner: false,
                width: 52,
              ),
            const SizedBox(width: 8),
            if (mariaChoice != null)
              _buildSingleManoCard(
                card: mariaChoice.card,
                player: _engine.mariaPlayer,
                isWinner: false,
                width: 52,
              ),
            const SizedBox(width: 8),
            if (pedroChoice != null)
              _buildSingleManoCard(
                card: pedroChoice.card,
                player: _engine.pedroPlayer,
                isWinner: false,
                width: 52,
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Tu carta (Ganadora de Mano, resaltada y gloriosa)
        if (userChoice != null)
          _buildSingleManoCard(
            card: userChoice.card,
            player: _engine.userPlayer,
            isWinner: true,
            width: 66,
          ),
      ],
    );
  }

  Widget _buildSingleManoCard({
    required SpanishCard card,
    required TutorialPlayer player,
    required bool isWinner,
    required double width,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Placa del jugador
        Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isWinner ? const Color(0xFFD97706) : player.color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isWinner ? const Color(0xFFFDE047) : Colors.white24,
              width: isWinner ? 1.2 : 0.8,
            ),
          ),
          child: Text(
            player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        // Carta física
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (isWinner)
                const BoxShadow(
                  color: Color(0xFFFDE047),
                  blurRadius: 16,
                  spreadRadius: 2.5,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: SpanishCardView(
            card: card,
            width: width,
            isSelected: isWinner,
          ),
        ),

        // Plaqueta de Ganador
        if (isWinner)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFF713F12), size: 12),
                SizedBox(width: 3),
                Text(
                  '¡ES LA MANO!',
                  style: TextStyle(
                    color: Color(0xFF713F12),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tapete central con cartas esparcidas orgánicamente (idéntico a caida_screen.dart)
  Widget _buildTableCardsArea(TutorialStep step) {
    final cards = _engine.tableCards;

    if (cards.isEmpty) {
      _placedTableCards.clear();
      return Center(
        child: Text(
          'Mesa Limpia',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      );
    }

    // Sincronizar colocaciones estables
    if (_placedTableCards.length != cards.length) {
      _syncTutorialPlacedCards();
    }

    // Ordenar por zIndex para solapamiento natural
    final visiblePlaced = _placedTableCards
        .where((p) => cards.contains(p.card))
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Etiqueta contextual sobre la mesa
        if (step.stepNumber == 7)
          Positioned(
            top: -18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Lanzada por Carlos (Oeste)',
                style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else if (step.stepNumber == 8)
          Positioned(
            top: -18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE047), width: 0.8),
              ),
              child: const Text(
                'Mesa: 7 ➔ 10 ➔ 11 (Seguidilla consecutiva)',
                style: TextStyle(color: Color(0xFFFDE047), fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Cartas esparcidas orgánicamente con rotación y jitter natural
        ...visiblePlaced.map((placed) {
          return Transform.translate(
            key: ValueKey('tut_table_${placed.card.suit.index}_${placed.card.number}'),
            offset: placed.offset,
            child: Transform.rotate(
              angle: placed.rotation,
              child: SpanishCardView(
                card: placed.card,
                width: 58,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Banner animado de evento
  Widget _buildPointEventBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8),
        ],
      ),
      child: Text(
        _pointEventBanner!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFDE047),
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Mano del usuario en abanico real (fan layout) idéntico a caida_screen.dart
  Widget _buildUserHandFan(TutorialStep step) {
    final hand = _engine.userHand;
    if (hand.isEmpty) return const SizedBox.shrink();

    final cardCount = hand.length;
    final fanAngles = cardCount == 3
        ? [-0.08, 0.0, 0.08]
        : (cardCount == 2 ? [-0.05, 0.05] : [0.0]);
    final fanYOffsets = cardCount == 3
        ? [6.0, 0.0, 6.0]
        : (cardCount == 2 ? [3.0, 3.0] : [0.0]);

    const cardWidth = 64.0;
    const fanHeight = 112.0;

    return SizedBox(
      height: fanHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(cardCount, (index) {
          final card = hand[index];
          final isTarget = step.actionType == TutorialActionType.playCard && step.targetCard == card;
          final angle = isTarget ? 0.0 : fanAngles[index % fanAngles.length];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _targetPulse,
              builder: (context, child) {
                final yOffset = isTarget
                    ? -12.0 - (4.0 * _targetPulse.value)
                    : fanYOffsets[index % fanYOffsets.length];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, yOffset, 0),
                  child: Transform.rotate(
                    angle: angle,
                    child: AnimatedScale(
                      scale: isTarget ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: isTarget
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                                    blurRadius: 12 + (5 * _targetPulse.value),
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                            : null,
                        child: SpanishCardView(
                          key: ValueKey('tut_hand_$index'),
                          card: card,
                          width: cardWidth,
                          isSelected: isTarget,
                          onTap: () => _onPrimaryActionTapped(step),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
