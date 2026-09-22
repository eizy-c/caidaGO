import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/presentation/widgets/game_table_header.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../../core/presentation/widgets/table_player_badge.dart';
import '../../../../core/presentation/widgets/wood_table_background.dart';
import '../../../../core/services/audio_service.dart';
import '../../economy/player_session.dart';
import '../../presentation/widgets/deck_stack_view.dart';
import '../../domain/models/mano_draw_session.dart';
import '../tutorial_engine.dart';
import '../tutorial_step.dart';
import 'tutorial_completion_dialog.dart';

/// Pantalla interactiva guiada para el Tour de Inicio Maestro de La Caída.
/// Ambientada en una mesa real de 4 jugadores (Tú, Carlos, María y Pedro):
/// - Sorteo interactivo de Mano con abanico de naipes.
/// - Reparto reglamentario de 4 cartas a la mesa y 3 en mano.
/// - Demostración de todos los cantos (Ronda, Patrulla, Vigía, Registro, Trivilín).
/// - Caídas directas, arrastres por seguidilla y mesa limpia.
/// - Clímax de victoria instantánea por Trivilín (+24 pts y knock-out).
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late final TutorialEngine _engine;
  late AnimationController _targetPulse;
  late AnimationController _cantoPulse;

  String? _pointEventBanner;
  bool _hasShownGraduationDialog = false;

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
        Navigator.of(context).pop(); // Cierra el diálogo de graduación
        Navigator.of(context).pop(); // Retorna al Lobby
      },
    );
  }

  void _onCardTapped(SpanishCard card) {
    if (_engine.showingFeedbackModal) return;

    final step = _engine.currentStep;
    final isTarget = step.targetCard == card;

    if (!isTarget) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFFFDE047), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Toca la carta resaltada: ${step.targetCard?.displayName ?? "el naipe indicado"}!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E1B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
          ),
        ),
      );
      return;
    }

    if (step.stepNumber == 7) {
      _pointEventBanner = '¡CAÍDA! +1 pt';
    } else if (step.stepNumber == 8) {
      _pointEventBanner = '¡ARRASTRE EN SEGUIDILLA! +3 cartas';
    } else if (step.stepNumber == 9) {
      _pointEventBanner = '¡MESA LIMPIA! +4 pts';
    }

    _engine.playUserCard(card);
  }

  void _onCantoTapped(String cantoName) {
    if (_engine.showingFeedbackModal) return;

    final step = _engine.currentStep;
    if (step.stepNumber == 5) {
      _pointEventBanner = '¡VIGÍA! +7 pts (Mata a la Patrulla y Ronda)';
    } else if (step.stepNumber == 10) {
      _pointEventBanner = '¡¡¡TRIVILÍN VICTORIA POR NOCAUT!!! +24 pts';
    }

    _engine.callUserCanto(cantoName);
  }

  void _onAdvanceStep() {
    final step = _engine.currentStep;
    _pointEventBanner = null;

    if (step.isTrivilinFinale) {
      _showGraduationDialog();
    } else {
      _engine.advanceToNextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _engine.currentStep;
    final session = PlayerSession.shared;

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Tutorial: La Caída (4 Jugadores)',
        onBack: () => Navigator.of(context).pop(),
        trophies: _engine.userScore,
        playerLevel: session.level,
        isMuted: AudioService().isMuted,
        onToggleMute: () => setState(() => AudioService().toggleMute()),
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final isCompact = screenHeight < 420;

              return Stack(
                children: [
                  // 1. Mazo físico en esquina superior izquierda (salvo en sorteo)
                  if (step.actionType != TutorialActionType.chooseManoCard)
                    Positioned(
                      left: isCompact ? 8 : 14,
                      top: isCompact ? 6 : 10,
                      child: const DeckStackView(remainingCards: 28),
                    ),

                  // 2. Jugador 2: María (Norte / Frente)
                  Positioned(
                    top: isCompact ? 4 : 8,
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
                        isCompact: isCompact,
                      ),
                    ),
                  ),

                  // 3. Jugador 1: Carlos (Oeste / Izquierda)
                  Positioned(
                    left: isCompact ? 8 : 12,
                    top: isCompact ? 70 : 100,
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
                      isCompact: isCompact,
                    ),
                  ),

                  // 4. Jugador 3: Pedro (Este / Derecha - Repartidor / Postre inicial)
                  Positioned(
                    right: isCompact ? 8 : 12,
                    top: isCompact ? 70 : 100,
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
                      isCompact: isCompact,
                    ),
                  ),

                  // 5. Guía Pedagógica Flotante: "El Maestro" (ubicada entre el avatar norte y el centro)
                  Positioned(
                    top: isCompact ? 68 : 88,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: _buildTeacherBar(step),
                      ),
                    ),
                  ),

                  // 6. Área Central: Sorteo de Mano O Cartas de la Mesa
                  Positioned.fill(
                    top: isCompact ? 140 : 175,
                    bottom: isCompact ? 100 : 130,
                    child: Center(
                      child: step.actionType == TutorialActionType.chooseManoCard
                          ? _buildManoSelectionFan()
                          : _buildTableCardsArea(),
                    ),
                  ),

                  // 7. Banner de Evento / Jugada
                  if (_pointEventBanner != null)
                    Positioned(
                      top: isCompact ? 145 : 170,
                      left: 20,
                      right: 20,
                      child: Center(child: _buildPointEventBanner()),
                    ),

                  // 8. Jugador 0: Usuario (Sur / Abajo a la izquierda)
                  Positioned(
                    left: isCompact ? 8 : 14,
                    bottom: isCompact ? 6 : 10,
                    child: TablePlayerBadge(
                      name: _engine.userPlayer.name,
                      score: _engine.userPlayer.score,
                      cardsWon: 0,
                      isBot: false,
                      isCurrentTurn: !_engine.showingFeedbackModal,
                      position: PlayerPositionOnTable.bottom,
                      avatarId: _engine.userPlayer.avatarId,
                      avatarColor: _engine.userPlayer.color,
                      calloutMessage: _engine.userPlayer.callout,
                      cardsInHandCount: _engine.userHand.length,
                      isMano: _engine.manoIndex == 0,
                      isCompact: isCompact,
                    ),
                  ),

                  // 9. Botón de Canto destacado sobre la mano del usuario
                  if (step.actionType == TutorialActionType.callCanto && !_engine.showingFeedbackModal)
                    Positioned(
                      bottom: isCompact ? 95 : 120,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildCantoActionButton(step)),
                    ),

                  // 10. Mano interactiva de cartas del jugador (Abajo a la derecha)
                  if (_engine.userHand.isNotEmpty && step.actionType != TutorialActionType.chooseManoCard)
                    Positioned(
                      right: isCompact ? 8 : 14,
                      bottom: isCompact ? 6 : 10,
                      child: _buildUserHandFan(step),
                    ),

                  // 11. Lámina explicativa tras completar la acción didáctica
                  if (_engine.showingFeedbackModal)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: _buildFeedbackExplanationSheet(step),
                        ),
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

  /// Barra de guía didáctica del Maestro de Caída
  Widget _buildTeacherBar(TutorialStep step) {
    final isObservational = step.actionType == TutorialActionType.observeStage ||
        step.actionType == TutorialActionType.observeCantos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: Color(0xFF1E1B4B), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'LECCIÓN ${step.stepNumber} DE ${_engine.totalSteps}',
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            step.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          if (isObservational && !_engine.showingFeedbackModal) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF1E1B4B),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _engine.triggerObservationCompletion(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text(
                    'CONTINUAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Abanico interactivo del sorteo de Mano
  Widget _buildManoSelectionFan() {
    final session = _engine.manoSession;
    final candidates = session.candidates;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
            ),
            child: Text(
              session.announcement ?? '¡ELIGE UNA CARTA!',
              style: const TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 320,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: candidates.map((cand) {
                final isChosen = cand.chosenByPlayerIndex != null;
                final player = isChosen ? _engine.players[cand.chosenByPlayerIndex!] : null;
                final canTap = !_engine.isResolvingMano && !isChosen && !_engine.showingFeedbackModal;

                return Positioned(
                  key: ValueKey('mano_${cand.id}'),
                  top: 90 + cand.topOffset,
                  left: 135 + cand.leftOffset,
                  child: _TutorialManoFlickCard(
                    candidate: cand,
                    player: player,
                    onTap: canTap ? () => _engine.pickManoCandidate(cand) : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Tapete central con las cartas sobre la madera
  Widget _buildTableCardsArea() {
    final cards = _engine.tableCards;

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Mesa despejada',
          style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: cards.map((c) {
        return SpanishCardView(
          card: c,
          width: 70,
        );
      }).toList(),
    );
  }

  /// Banner animado de evento
  Widget _buildPointEventBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10),
        ],
      ),
      child: Text(
        _pointEventBanner!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFDE047),
          fontWeight: FontWeight.w900,
          fontSize: 13.5,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Botón de canto interactivo
  Widget _buildCantoActionButton(TutorialStep step) {
    final isTrivilin = step.isTrivilinFinale;
    final cantoName = step.targetCantoName ?? 'CANTAR';

    return AnimatedBuilder(
      animation: _cantoPulse,
      builder: (context, child) {
        final scale = 1.0 + (_cantoPulse.value * (isTrivilin ? 0.08 : 0.04));

        return Transform.scale(
          scale: scale,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTrivilin ? 26 : 20,
                vertical: isTrivilin ? 13 : 10,
              ),
              backgroundColor: isTrivilin ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isTrivilin ? const Color(0xFFFDE047) : Colors.white,
                  width: 2.0,
                ),
              ),
            ),
            onPressed: () => _onCantoTapped(cantoName),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTrivilin ? Icons.auto_awesome_rounded : Icons.campaign_rounded,
                  color: const Color(0xFFFDE047),
                  size: isTrivilin ? 22 : 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTrivilin ? '¡TRIVILÍN! (KNOCK-OUT)' : 'CANTAR $cantoName (+${step.pointsAwarded} pts)',
                  style: TextStyle(
                    fontSize: isTrivilin ? 14 : 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mano del usuario con efecto dorado sobre la carta objetivo
  Widget _buildUserHandFan(TutorialStep step) {
    final hand = _engine.userHand;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: hand.map((card) {
        final isTarget = step.actionType == TutorialActionType.playCard && step.targetCard == card;

        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: AnimatedBuilder(
            animation: _targetPulse,
            builder: (context, child) {
              final lift = isTarget ? -8.0 - (4.0 * _targetPulse.value) : 0.0;

              return Transform.translate(
                offset: Offset(0, lift),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTarget && !_engine.showingFeedbackModal)
                      Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOCA AQUÍ',
                              style: TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.touch_app_rounded, size: 11, color: Color(0xFF1E1B4B)),
                          ],
                        ),
                      ),
                    Container(
                      decoration: isTarget
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                  blurRadius: 14 + (6 * _targetPulse.value),
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                          : null,
                      child: SpanishCardView(
                        card: card,
                        width: 72,
                        onTap: () => _onCardTapped(card),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// Tarjeta de explicación y avance tras completar la lección
  Widget _buildFeedbackExplanationSheet(TutorialStep step) {
    final isLast = step.isTrivilinFinale;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLast ? const Color(0xFFFDE047) : const Color(0xFF2E2E2E),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 14),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isLast ? const Color(0xFF78350F) : const Color(0xFF065F46),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLast ? Icons.emoji_events_rounded : Icons.check_rounded,
                  color: isLast ? const Color(0xFFFDE047) : const Color(0xFF34D399),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.feedbackTitle,
                  style: TextStyle(
                    color: isLast ? const Color(0xFFFDE047) : const Color(0xFF34D399),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.feedbackDetail,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                foregroundColor: isLast ? const Color(0xFF1E1B4B) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _onAdvanceStep,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? '¡GRADUARME Y COBRAR 1,000 MONEDAS!' : 'SIGUIENTE LECCIÓN',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(isLast ? Icons.monetization_on_rounded : Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carta del sorteo de Mano con rotación y animación de volteo 3D
class _TutorialManoFlickCard extends StatelessWidget {
  final ManoCardCandidate candidate;
  final TutorialPlayer? player;
  final VoidCallback? onTap;

  const _TutorialManoFlickCard({
    required this.candidate,
    this.player,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRevealed = candidate.isRevealed;
    final isWinner = candidate.isWinner;

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isRevealed ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, flipVal, child) {
          final angle = flipVal * math.pi;
          final isFront = angle >= (math.pi / 2);
          final scale = 1.0 + (flipVal * (isWinner ? 0.20 : 0.10));

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateZ(candidate.rotation)
              ..scaleByDouble(scale, scale, 1.0, 1.0)
              ..rotateY(angle),
            child: isFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildFront(),
                  )
                : const SpanishCardView.back(width: 52),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (candidate.isWinner)
                const BoxShadow(
                  color: Color(0xFFFDE047),
                  blurRadius: 16,
                  spreadRadius: 2.5,
                )
              else if (player != null)
                BoxShadow(
                  color: player!.color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: SpanishCardView(
            card: candidate.card,
            width: 52,
            isSelected: candidate.chosenByPlayerIndex == 0 || candidate.isWinner,
          ),
        ),
        if (candidate.isWinner)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '¡ES MANO!',
              style: TextStyle(
                color: Color(0xFF713F12),
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        else if (player != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: player!.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              player!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}
