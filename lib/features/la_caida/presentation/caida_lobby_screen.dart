import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/presentation/widgets/app_3d_button.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/services/user_profile_service.dart';
import '../domain/models/caida_match_config.dart';
import '../economy/daily_challenge_system.dart';
import '../economy/player_session.dart';
import 'widgets/game_toast_queue.dart';
import 'caida_screen.dart';
import 'widgets/booster_selector_widget.dart';
import 'widgets/bot_customization_modal.dart';
import 'widgets/buy_tickets_modal.dart';
import 'widgets/chest_slots_view.dart';
import 'widgets/four_aces_display_view.dart';
import 'widgets/inventory_modal.dart';
import 'widgets/match_history_modal.dart';
import 'widgets/player_profile_stats_modal.dart';
import 'widgets/profile_and_level_modal.dart';
import 'widgets/user_frame_view.dart';
import 'widgets/venezuela_rooms_carousel.dart';
import '../economy/venezuela_room_tier.dart';
import '../economy/trophy_session_manager.dart';
import '../multiplayer/presentation/multiplayer_hub_screen.dart';
import '../tutorial/presentation/tutorial_screen.dart';
import '../economy/player_stats_model.dart';
import 'widgets/rank_badge_widget.dart';
import 'about_settings_screen.dart';
import '../../../core/presentation/widgets/cartoon_widgets.dart';
import '../economy/rank_system.dart';
import '../economy/player_stats_model.dart';



/// Modo de visualización de navegación del lobby
enum LobbyViewMode { main, unJugador }

/// Lobby principal de La Caída inspirado en el boceto de referencia:
/// Barra superior con ajustes, tickets y monedas;
/// Sub-cabecera con Logo del juego, botones de Estadística y Desafíos, y Perfil con Marco y Nivel 0;
/// Centro con abanico de los 4 Ases de la baraja y botones grandes de JUGAR y TUTORIAL;
/// Barra inferior con los 4 slots de cofres de recompensa (2 min de apertura).
class CaidaLobbyScreen extends StatefulWidget {
  const CaidaLobbyScreen({super.key});

  @override
  State<CaidaLobbyScreen> createState() => _CaidaLobbyScreenState();
}

class _CaidaLobbyScreenState extends State<CaidaLobbyScreen> {
  final _profileService = UserProfileService();
  late PlayerSession _session;
  Timer? _ticketRegenTimer;

  // Estado del flujo del lobby
  LobbyViewMode _currentView = LobbyViewMode.main;

  // Opciones seleccionadas para la partida
  bool _isMatandoCantos = true;
  int _selectedTotalPlayers = 2;
  bool _selectedTeams = false;


  @override
  void initState() {
    super.initState();
    _session = PlayerSession.shared;
    _session.addListener(_onProfileChanged);
    _profileService.addListener(_onProfileChanged);
    PlayerStatsModel.shared.addListener(_onProfileChanged);
    _loadSessionAsync();

    _ticketRegenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _session.regenerateTicketsPassive();
        });
      }
    });
  }

  Future<void> _loadSessionAsync() async {
    final loaded = await PlayerSession.load();
    if (mounted) {
      setState(() {
        _session.removeListener(_onProfileChanged);
        _session = loaded;
        _session.addListener(_onProfileChanged);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SpanishCardView.precacheAllCards(context);
    UserFrameView.precacheAllAssets(context);
  }

  @override
  void dispose() {
    _ticketRegenTimer?.cancel();
    _session.removeListener(_onProfileChanged);
    _profileService.removeListener(_onProfileChanged);
    PlayerStatsModel.shared.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _openProfileAndLevelModal({int initialTabIndex = 0}) {
    ProfileAndLevelModal.show(context, session: _session, initialTabIndex: initialTabIndex);
  }

  void _openBotCustomization() {
    BotCustomizationModal.show(
      context,
      session: _session,
      onSaved: (names) {
        setState(() {});
      },
    );
  }

  void _openVipModal({bool initialIsTeams = false}) {
    VenezuelaRoomsCarouselScreen.show(
      context,
      manager: TrophySessionManager.shared,
      initialMode: initialIsTeams ? GameMode.teams2v2 : GameMode.duel1v1,
      onStartMatch: (room, mode) {
        final matchConfig = CaidaMatchConfig.venezuelaRoomMatch(
          room: room,
          mode: mode,
          userName: _session.name,
          botNames: _session.botNames,
          isMatandoCantos: _isMatandoCantos,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaidaScreen(
              config: matchConfig,
            ),
          ),
        );
      },
    );
  }

  void _openBuyTicketsModal({int initialTab = 0}) {
    BuyTicketsModal.show(context, session: _session, initialTab: initialTab);
  }

  void _openTutorial() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const TutorialScreen(),
      ),
    )
        .then((_) {
      setState(() {
        _session = PlayerSession.shared;
      });
    });
  }

  void _openStatisticsDialog() {
    PlayerProfileStatsModal.show(context, session: _session);
  }

  void _openHistoryDialog() {
    MatchHistoryModal.show(context);
  }

  void _openInventoryModal() {
    InventoryModal.show(context);
  }

  void _openChallengesDialog() {
    final system = DailyChallengeSystem.instance;
    Timer? liveTimer;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          liveTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (context.mounted) {
              setDialogState(() {});
            }
          });

          final challenges = system.challenges;
          final remaining = system.timeUntilNextReset();
          final hours = remaining.inHours.toString().padLeft(2, '0');
          final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

          return AlertDialog(
            backgroundColor: AppPalette.cartoonBgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFFFDE047), size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Retos Diarios',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.cartoonCardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_rounded, size: 12, color: Color(0xFFFDE047)),
                      const SizedBox(width: 4),
                      Text(
                        '$hours:$minutes:$seconds',
                        style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: challenges.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPalette.cartoonCardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppPalette.cartoonBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          c.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: c.isCompleted ? const Color(0xFF22C55E) : const Color(0xFFFDE047),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(c.rewardText, style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (c.isClaimed)
                          const Text('Reclamado', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold))
                        else if (c.isCompleted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(60, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final claimed = system.claimReward(c.id);
                              if (claimed != null) {
                                _session.addCoins(claimed.coinReward);
                                _session.addXp(claimed.xpReward);
                                GameToastQueue.showChallenge(
                                  context,
                                  title: claimed.title,
                                  coinReward: claimed.coinReward,
                                  xpReward: claimed.xpReward,
                                );
                                setDialogState(() {});
                                setState(() {});
                              }
                            },
                            child: const Text('Reclamar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                          )
                        else
                          Text(c.progressText, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              App3dButton(
                label: 'Cerrar',
                variant: App3dButtonVariant.gold,
                depth: 3.5,
                borderRadius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onPressed: () {
                  liveTimer?.cancel();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    ).then((_) => liveTimer?.cancel());
  }

  void _openSettingsDialog() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AboutSettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }


  void _openMultiplayerComingSoonDialog() {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MultiplayerHubScreen(),
      ),
    );
  }


  void _showGamePreferencesDialog({
    required int players,
    required bool teams,
    bool isVsBot = false,
  }) {
    setState(() {
      _selectedTotalPlayers = players;
      _selectedTeams = teams;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPalette.cartoonBgDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppPalette.cartoonCardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                    child: Text(
                      isVsBot
                          ? 'Preferencias de juego\nVs Bot'
                          : 'Preferencias de juego\n2 vs 2 (Parejas)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.cartoonCardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Entrada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppPalette.cartoonBorder, width: 1),
                                  ),
                                  child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFF38BDF8), size: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '1  (${_session.tickets} disp.)',
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Matando cantos',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Switch(
                              value: _isMatandoCantos,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFFF59E0B),
                              onChanged: (val) {
                                setDialogState(() => _isMatandoCantos = val);
                                setState(() => _isMatandoCantos = val);
                              },
                            ),
                          ],
                        ),

                        if (isVsBot) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Modo de juego',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    if (_selectedTotalPlayers == 2) {
                                      _selectedTotalPlayers = 3;
                                    } else if (_selectedTotalPlayers == 3) {
                                      _selectedTotalPlayers = 4;
                                    } else {
                                      _selectedTotalPlayers = 2;
                                    }
                                    _selectedTeams = false;
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppPalette.cartoonBgDark,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                                  ),
                                  child: Text(
                                    '$_selectedTotalPlayers Jugadores',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rivales Bots (IA)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _openBotCustomization();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppPalette.cartoonBgDark,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.smart_toy_rounded, color: Color(0xFF60A5FA), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _session.botNames.isNotEmpty ? _session.botNames[0] : 'Editar',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  App3dButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (_session.tickets < 1) {
                        _openBuyTicketsModal();
                      } else {
                        _startMatch();
                      }
                    },
                    expand: true,
                    height: 48,
                    depth: 5,
                    borderRadius: 16,
                    variant: _session.tickets >= 1 ? App3dButtonVariant.emerald : App3dButtonVariant.crimson,
                    label: _session.tickets >= 1 ? '¡Empezar!' : '¡SIN TICKETS! - RECARGAR',
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startMatch() {
    if (!_session.consumeTicketForNormalMatch()) {
      _openBuyTicketsModal();
      return;
    }
    _profileService.useTicket();
    final matchConfig = CaidaMatchConfig.quickMatch(
      players: _selectedTotalPlayers,
      isTeams: _selectedTeams,
      userName: _session.name,
      botNames: _session.botNames,
      isMatandoCantos: _isMatandoCantos,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          config: matchConfig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LobbyThemeOption.getById(_session.selectedThemeId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Barra Superior idéntica al boceto (Ajustes | Tickets | Monedas)
              _buildTopBar(),

              // 2. Contenido dinámico del lobby
              Expanded(
                child: _currentView == LobbyViewMode.main ? _buildMainSketchLobbyView() : _buildUnJugadorView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BARRA SUPERIOR SEGÚN REFERENCIA UNIFICADA ---
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.cartoonBgDark.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2)),
      ),
      child: Row(
        children: [
          // Botón de Ajustes (Engranaje) con efecto táctil cartoon
          CartoonRoundButton(
            width: 40,
            height: 40,
            borderRadius: 12,
            depth: 2.5,
            onPressed: _openSettingsDialog,
            child: const Icon(Icons.settings_rounded, color: AppPalette.cartoonCardText, size: 22),
          ),
          const Spacer(),

// Chip de Tickets con gradiente Cyan y efecto táctil
          TactilePressable(
            depth: 2,

            onTap: _openBuyTicketsModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppGradients.cyanAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1B165E),
                    blurRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    '${_session.tickets}/${_session.maxTickets}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  if (_session.tickets < _session.maxTickets) ...[
                    const SizedBox(width: 6),
                    _buildTicketRegenBadge(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

// Chip de Monedas con gradiente Dorado y efecto táctil
          TactilePressable(
            depth: 2,

            onTap: () => _openBuyTicketsModal(initialTab: 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppGradients.goldReward,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1B165E),
                    blurRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFF1E1B4B), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${_session.coins}',
                    style: const TextStyle(
                      color: Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1B4B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pequeña cápsula con el tiempo hasta el próximo ticket
  Widget _buildTicketRegenBadge() {
    final remaining = _session.timeUntilNextTicket();
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, size: 9, color: Color(0xFF38BDF8)),
          const SizedBox(width: 2),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA PRINCIPAL SEGÚN LA REFERENCIA ---
  Widget _buildMainSketchLobbyView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          // 1. Tarjeta de Perfil y Nivel
          _buildProfileLevelCard(),
          const SizedBox(height: 12),

          // 2. Área Hero con 4 Ases y Botón JUGAR
          _buildHeroPlaySection(),
          const SizedBox(height: 12),

          // 3. Modos Secundarios (TUTORIAL y MULTIJUGADOR)
          _buildSecondaryModesRow(),
          const SizedBox(height: 12),

          // 4. Fila de 4 Tarjetas (Estadística, Historial, Desafíos, Inventario)
          _buildNavigationCardsRow(),
          const SizedBox(height: 12),

          // 5. Barra de Potenciadores
          BoosterSelectorWidget(
            session: _session,
            onOpenShop: () => _openBuyTicketsModal(initialTab: 1),
          ),
          const SizedBox(height: 12),

          // 6. Fila de 4 Ranuras de Cofres de Recompensa
          ChestSlotsView(
            session: _session,
            onChestClaimed: (coins) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  /// Tarjeta de Perfil del Usuario en el Menú (Avatar, Nombre y Rango)
  Widget _buildProfileLevelCard() {
    final trophies = PlayerStatsModel.shared.trophies;
    final rank = RankInfo.forTrophies(trophies);

    return TactilePressable(
      depth: 3,
      onTap: () => _openProfileAndLevelModal(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.cartoonCardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.cartoonBorder, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3.5), blurRadius: 0),
          ],
        ),
        child: Row(
          children: [
            // Badge con gradiente del Rango actual (CAIDAGO)
            Container(
              width: 52,
              height: 48,
              decoration: BoxDecoration(
                gradient: rank.gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_rounded, color: Colors.white, size: 17),
                  SizedBox(height: 2),
                  Text(
                    'CAIDAGO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 8.5,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Avatar con Marco cosmético (sin indicador numérico de nivel)
            UserFrameView(
              avatarIndex: _session.avatarIndex,
              frameId: _session.selectedFrameId,
              size: 46,
              showLevelBadge: false,
            ),
            const SizedBox(width: 10),

            // Centro: Nombre de Jugador y Rango Oficial con Trofeos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
Text(
                    _session.name.isNotEmpty ? _session.name : 'Jugador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: rank.gradient,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Text(
                          rank.fullNameFor(trophies),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$trophies 🏆',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Derecha: Botón de personalización / perfil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppPalette.cartoonBgDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette_rounded, color: AppPalette.cartoonCyan, size: 14),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Área Hero Central con 4 Ases y Gran Botón 3D de JUGAR
  Widget _buildHeroPlaySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Resplandor de rayos y Abanico de los 4 Ases
        Stack(
          alignment: Alignment.center,
          children: [
            // Resplandor azul detrás de las cartas
            Container(
              width: 220,
              height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    const Color(0xFF0284C7).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const FourAcesDisplayView(cardWidth: 62),
          ],
        ),
        const SizedBox(height: 12),

        // Botón Gigante 3D Amarillo/Dorado: ▶ JUGAR con efecto de presión táctil
        TactilePressable(
          depth: 5,
          onTap: () {
            setState(() => _currentView = LobbyViewMode.unJugador);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppGradients.goldReward,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                const BoxShadow(
                  color: Colors.black45,
                  blurRadius: 8,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                const SizedBox(width: 8),
                const Text(
                  'JUGAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Fila de Modos Secundarios (TUTORIAL y MULTIJUGADOR)
  Widget _buildSecondaryModesRow() {
    return Row(
      children: [
        // Botón TUTORIAL (Verde esmeralda con gradiente)
        Expanded(
          child: App3dButton.icon(
            onPressed: _openTutorial,
            height: 48,
            depth: 4,
            borderRadius: 16,
            variant: App3dButtonVariant.emerald,
            icon: Icons.school_rounded,
            iconSize: 18,
            label: 'TUTORIAL',
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Botón MULTIJUGADOR (Turquesa / Cyan con gradiente)
        Expanded(
          child: App3dButton.icon(
            onPressed: _openMultiplayerComingSoonDialog,
            height: 48,
            depth: 4,
            borderRadius: 16,
            variant: App3dButtonVariant.cyan,
            icon: Icons.wifi_rounded,
            iconSize: 18,
            label: 'MULTIJUGADOR',
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  /// Fila de 4 Tarjetas de Navegación (Estadística, Historial, Desafíos, Inventario)
  Widget _buildNavigationCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSquareFeatureCard(
            title: 'Estadística',
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFF0284C7),
            onTap: _openStatisticsDialog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSquareFeatureCard(
            title: 'Historial',
            icon: Icons.history_rounded,
            color: const Color(0xFFA855F7),
            onTap: _openHistoryDialog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSquareFeatureCard(
            title: 'Desafíos',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            onTap: _openChallengesDialog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSquareFeatureCard(
            title: 'Inventario',
            icon: Icons.backpack_rounded,
            color: const Color(0xFF14B8A6),
            onTap: _openInventoryModal,
          ),
        ),
      ],
    );
  }

  Widget _buildSquareFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TactilePressable(
      depth: 3,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppPalette.cartoonCardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPalette.cartoonBorder, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1B165E),
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB-VISTA DE SELECCIÓN DE MODOS DE JUEGO ---
  Widget _buildUnJugadorView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CartoonRoundButton(
                width: 42,
                height: 42,
                backgroundColor: const Color(0xFF2E267D),
                borderColor: const Color(0xFF4C3E9E),
                shadowColor: const Color(0xFF1D1748),
                onPressed: () => setState(() => _currentView = LobbyViewMode.main),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'MODOS DE JUEGO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TactilePressable(
              depth: 4.0,
              onTap: () => _showGamePreferencesDialog(
                players: _selectedTeams ? 2 : _selectedTotalPlayers.clamp(2, 4),
                teams: false,
                isVsBot: true,
              ),
              child: Container(
                width: 150,
                height: 165,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldReward,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD97706), width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF92400E),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 54),
                    SizedBox(height: 8),
                    Text(
                      'Vs Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Mano a Mano (1v1)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 18),

            TactilePressable(
              depth: 4.0,
              onTap: () => _showGamePreferencesDialog(
                players: 4,
                teams: true,
                isVsBot: false,
              ),
              child: Container(
                width: 150,
                height: 165,
                decoration: BoxDecoration(
                  gradient: AppGradients.greenAccept,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF059669), width: 2.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF047857),
                      offset: Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_rounded, color: Colors.white, size: 54),
                    SizedBox(height: 8),
                    Text(
                      '2 vs 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'En Parejas (4 Jug.)',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        TactilePressable(
          depth: 4.0,
          onTap: () => _openVipModal(),
          child: Container(
            width: 318,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppGradients.cyanAccent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0284C7), width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF0369A1),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESAS VIP • APUESTAS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pozos y Premios en Monedas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
