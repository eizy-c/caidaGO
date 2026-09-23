import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/app_3d_button.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/services/user_profile_service.dart';
import '../domain/models/caida_match_config.dart';
import '../economy/daily_challenge_system.dart';
import '../economy/player_session.dart';
import '../economy/user_progress.dart';
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
import 'widgets/vip_tier_selector_modal.dart';
import '../multiplayer/presentation/multiplayer_hub_screen.dart';
import '../tutorial/presentation/tutorial_screen.dart';
import 'about_settings_screen.dart';



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
    VipTierSelectorModal.show(
      context,
      session: _session,
      initialIsTeams: initialIsTeams,
      onTierSelected: (tier, isTeams) {
        final matchConfig = CaidaMatchConfig.vipMatch(
          tier: tier,
          isTeams: isTeams,
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
            backgroundColor: const Color(0xFF161616),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF2E2E2E), width: 1.0),
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
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2E2E2E)),
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
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2E2E2E),
                        width: 1,
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
      MaterialPageRoute(
        builder: (_) => const AboutSettingsScreen(),
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
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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
                      color: const Color(0xFF181818),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
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
                                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
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
                                    color: const Color(0xFF252525),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
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
                                    color: const Color(0xFF252525),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
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
                    variant: _session.tickets >= 1 ? App3dButtonVariant.gold : App3dButtonVariant.crimson,
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

  // --- BARRA SUPERIOR SEGÚN REFERENCIA ---
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          // Botón de Ajustes (Engranaje)
          GestureDetector(
            onTap: _openSettingsDialog,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),

          // Chip de Tickets: 🎫 7/10 con temporizador mini ⏱ 08:02
          GestureDetector(
            onTap: _openBuyTicketsModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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

          // Chip de Monedas: 💰 2506 (+)
          GestureDetector(
            onTap: () => _openBuyTicketsModal(initialTab: 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFDE047), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${_session.coins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE047),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 10, color: Color(0xFF0F172A)),
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

  /// Tarjeta de Perfil y Nivel del Usuario (Horizontal superior)
  Widget _buildProfileLevelCard() {
    final userProg = UserProgress(totalXp: _session.xp);
    final xpCurrent = userProg.currentTierXp;
    final xpRequired = userProg.neededInCurrentTier;
    final progress = userProg.levelProgressPercentage;
    final level = userProg.currentLevel;

    return GestureDetector(
      onTap: () => _openProfileAndLevelModal(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Badge naranja CAIDAGO con icono de baraja
            Container(
              width: 58,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_rounded, color: Colors.white, size: 18),
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
            const SizedBox(width: 12),

            // Centro: Nivel y Barra de Progreso XP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nivel $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 8,
                      width: double.infinity,
                      color: const Color(0xFF0F172A),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text(
                      '$xpCurrent / $xpRequired XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Derecha: Avatar con marco y flecha >
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserFrameView(
                  avatarIndex: _session.avatarIndex,
                  frameId: _session.selectedFrameId,
                  level: _session.level,
                  size: 50,
                  showLevelBadge: true,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
              ],
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

        // Botón Gigante 3D Amarillo/Dorado: ▶ JUGAR (Demuestra tu habilidad)
        GestureDetector(
          onTap: () {
            setState(() => _currentView = LobbyViewMode.unJugador);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      'Demuestra tu habilidad',
                      style: TextStyle(
                        color: const Color(0xFF78350F).withValues(alpha: 0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
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
        // Botón TUTORIAL (Verde oliva / Caqui)
        Expanded(
          child: App3dButton.icon(
            onPressed: _openTutorial,
            height: 48,
            depth: 4,
            borderRadius: 16,
            variant: App3dButtonVariant.olive,
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

        // Botón MULTIJUGADOR (Coral / Rojo)
        Expanded(
          child: App3dButton.icon(
            onPressed: _openMultiplayerComingSoonDialog,
            height: 48,
            depth: 4,
            borderRadius: 16,
            variant: App3dButtonVariant.crimson,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                fontWeight: FontWeight.bold,
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
              GestureDetector(
                onTap: () => setState(() => _currentView = LobbyViewMode.main),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFFBBF24), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Volver al Menú',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showGamePreferencesDialog(
                players: _selectedTeams ? 2 : _selectedTotalPlayers.clamp(2, 4),
                teams: false,
                isVsBot: true,
              ),
              child: Container(
                width: 145,
                height: 155,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2E2E2E), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 52),
                    SizedBox(height: 8),
                    Text(
                      'Vs Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mano a Mano (1v1)',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            GestureDetector(
              onTap: () => _showGamePreferencesDialog(
                players: 4,
                teams: true,
                isVsBot: false,
              ),
              child: Container(
                width: 145,
                height: 155,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2E2E2E), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC2410C).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_rounded, color: Colors.white, size: 52),
                    SizedBox(height: 8),
                    Text(
                      '2 vs 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'En Parejas (4 Jug.)',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => _openVipModal(),
          child: Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESAS VIP • APUESTAS',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
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
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
