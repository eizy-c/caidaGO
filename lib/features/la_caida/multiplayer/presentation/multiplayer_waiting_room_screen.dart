import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/caida_match_config.dart';
import '../../economy/player_session.dart';
import '../../presentation/caida_screen.dart';
import '../../presentation/widgets/user_frame_view.dart';
import '../domain/multiplayer_models.dart';
import '../network/local_game_client.dart';
import '../network/local_game_host.dart';
import '../../economy/venezuela_room_tier.dart';

/// Sala de espera interactiva (Lobby de partida) para 2, 3 o 4 jugadores.
/// Muestra los asientos en tiempo real, permite añadir bots, alternar "Listo" y arrancar la partida.
class MultiplayerWaitingRoomScreen extends StatefulWidget {
  final MultiplayerRoomInfo roomInfo;
  final LocalGameHost? host;
  final LocalGameClient client;
  final bool isHost;

  const MultiplayerWaitingRoomScreen({
    super.key,
    required this.roomInfo,
    this.host,
    required this.client,
    required this.isHost,
  });

  @override
  State<MultiplayerWaitingRoomScreen> createState() =>
      _MultiplayerWaitingRoomScreenState();
}

class _MultiplayerWaitingRoomScreenState
    extends State<MultiplayerWaitingRoomScreen> {
  late ValueNotifier<List<RoomSeat>> _seatsNotifier;
  bool _isNavigatingToGame = false;

  @override
  void initState() {
    super.initState();
    _seatsNotifier = widget.isHost && widget.host != null
        ? widget.host!.seatsNotifier
        : widget.client.seatsNotifier;

    widget.client.onMatchStarted = _onMatchStartedByHost;
    widget.client.onDisconnected = _onHostDisconnected;
  }

  void _onMatchStartedByHost() {
    if (!mounted) return;
    _navigateToMatchScreen();
  }

  void _onHostDisconnected() {
    if (!mounted || _isNavigatingToGame) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El anfitrión cerró la sala o se perdió la conexión.'),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
    Navigator.of(context).pop();
  }

  void _startMatchAsHost() {
    if (widget.host == null) return;

    // Rellenar automáticamente con Bots si faltan puestos
    widget.host!.fillEmptySeatsWithBots();

    // Notificar a todos los clientes que la partida comienza
    widget.host!.broadcastMessage(const NetworkGameMessage(
      type: 'START_MATCH',
      data: {'status': 'STARTING'},
    ));

    _navigateToMatchScreen();
  }

  void _navigateToMatchScreen() {
    _isNavigatingToGame = true;
    final seats = _seatsNotifier.value;
    final botNames = seats
        .where((s) => s.isBot)
        .map((s) => s.name.replaceAll(' (Bot)', ''))
        .toList();

    final mySeatIndex = widget.isHost ? 0 : widget.client.mySeatIndex;
    final sortedSeats = <RoomSeat>[];

    // Asiento 0: Jugador local
    final mySeat = seats.firstWhere(
      (s) => s.seatIndex == mySeatIndex,
      orElse: () => RoomSeat(
        seatIndex: 0,
        name: widget.isHost ? widget.roomInfo.hostName : 'Tú',
        avatarId: PlayerSession.shared.avatarIndex,
        frameId: PlayerSession.shared.selectedFrameId,
      ),
    );
    sortedSeats.add(mySeat);

    // Asientos de los otros rivales / compañeros en la mesa
    for (int i = 1; i < widget.roomInfo.targetPlayers; i++) {
      final seatIdx = (mySeatIndex + i) % widget.roomInfo.targetPlayers;
      final seat = seats.firstWhere(
        (s) => s.seatIndex == seatIdx,
        orElse: () => RoomSeat(
          seatIndex: seatIdx,
          name: 'Jugador ${i + 1}',
          avatarId: (i % 14) + 1,
          frameId: 'rank_novato',
          isBot: true,
        ),
      );
      sortedSeats.add(seat);
    }

    final regionalRoom = widget.roomInfo.regionalRoomId != null
        ? VenezuelaRoomTier.fromId(widget.roomInfo.regionalRoomId!)
        : null;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          config: CaidaMatchConfig(
            initialPlayers: widget.roomInfo.targetPlayers,
            initialTeams: widget.roomInfo.isTeams,
            autoStart: true,
            chooseMano: true,
            userName: mySeat.name,
            botNames: botNames.isNotEmpty ? botNames : ['Alejandro', 'Carl', 'Jhonny'],
            isMultiplayer: true,
            playerNames: sortedSeats.map((s) => s.name).toList(),
            playerAvatarIds: sortedSeats.map((s) => s.avatarId).toList(),
            playerFrameIds: sortedSeats.map((s) => s.frameId).toList(),
            playerIsBots: sortedSeats.map((s) => s.isBot).toList(),
            host: widget.isHost ? widget.host : null,
            client: widget.client,
            localSeatIndex: mySeatIndex,
            multiplayerRoom: widget.roomInfo,
            venezuelaRoom: regionalRoom,
            vipPrizePool: widget.roomInfo.totalPot,
            vipWinnerReward: widget.roomInfo.prizePerWinner,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!_isNavigatingToGame) {
      if (widget.isHost) {
        widget.host?.stopServer();
      } else {
        widget.client.disconnect();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.roomInfo;

    return Scaffold(
      backgroundColor: const Color(0xFF26206D),
      appBar: AppBar(
        backgroundColor: AppPalette.cartoonBgDark,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CartoonRoundButton(
            width: 38,
            height: 38,
            backgroundColor: const Color(0xFFDCE2FD),
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E1763), size: 20),
          ),
        ),
        title: Column(
          children: [
            Text(
              room.roomName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  room.networkMode == MultiplayerNetworkMode.localWifi
                      ? Icons.wifi_rounded
                      : Icons.public_rounded,
                  size: 12,
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 4),
                Text(
                  room.networkMode == MultiplayerNetworkMode.localWifi
                      ? 'Red Local Wi-Fi'
                      : 'En Línea',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (room.isPrivate && room.pinCode != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key_rounded, size: 11, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          'PIN: ${room.pinCode}',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner informativo superior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFF181818),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modo: ${room.targetPlayers} Jugadores ${room.isTeams ? "(Parejas)" : "(Individual)"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.isHost ? 'Eres el Anfitrión' : 'Esperando al Anfitrión...',
                    style: TextStyle(
                      color: widget.isHost ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Selector de Equipos para partidas en Parejas (2 vs 2)
            if (room.isTeams && room.targetPlayers == 4) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.8),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    const CartoonStrokeText(
                      'ELIGE TU EQUIPO Y COMPAÑERO',
                      fontSize: 13,
                      textColor: AppPalette.cartoonYellow,
                      strokeColor: AppPalette.cartoonCardText,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Botón Unirse a Equipo A
                        Expanded(
                          child: TactilePressable(
                            depth: 2.0,
                            onTap: () => _joinTeam(0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.cyanAccent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_rounded, color: Color(0xFF1E1B4B), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'EQUIPO A',
                                    style: TextStyle(
                                      color: Color(0xFF1E1B4B),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Botón Unirse a Equipo B
                        Expanded(
                          child: TactilePressable(
                            depth: 2.0,
                            onTap: () => _joinTeam(1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.redDanger,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 2)),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'EQUIPO B',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Mesa visual de asientos
            Expanded(
              child: ValueListenableBuilder<List<RoomSeat>>(
                valueListenable: _seatsNotifier,
                builder: (context, seats, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.88,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: room.targetPlayers,
                      itemBuilder: (context, index) {
                        final seat = index < seats.length ? seats[index] : null;
                        return _buildSeatCard(seat, index);
                      },
                    ),
                  );
                },
              ),
            ),

            // Barra inferior de acciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppPalette.cartoonBgDark,
                border: Border(top: BorderSide(color: AppPalette.cartoonBorder, width: 2.0)),
              ),
              child: Row(
                children: [
                  if (!widget.isHost) ...[
                    Expanded(
                      child: App3dButton(
                        onPressed: () {
                          widget.client.toggleReady();
                        },
                        height: 48,
                        depth: 4,
                        borderRadius: 16,
                        variant: App3dButtonVariant.cyan,
                        label: 'ESTOY LISTO',
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: App3dButton.icon(
                        onPressed: _startMatchAsHost,
                        height: 48,
                        depth: 4.5,
                        borderRadius: 16,
                        variant: App3dButtonVariant.emerald,
                        icon: Icons.play_arrow_rounded,
                        iconSize: 22,
                        label: 'INICIAR PARTIDA',
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _joinTeam(int targetTeam) {
    // Equipo A: Asientos 0 y 2
    // Equipo B: Asientos 1 y 3
    final candidateSeats = targetTeam == 0 ? [0, 2] : [1, 3];
    final seats = _seatsNotifier.value;

    int? freeSeat;
    for (final s in candidateSeats) {
      if (s < seats.length) {
        final seat = seats[s];
        if (!seat.isOccupied || seat.isBot) {
          freeSeat = s;
          break;
        }
      }
    }

    freeSeat ??= candidateSeats.first;
    _switchSeat(freeSeat);
  }

  void _switchSeat(int targetSeatIndex) {
    if (widget.isHost) {
      widget.host?.switchPlayerSeat('host_${widget.roomInfo.hostName}', targetSeatIndex);
    } else {
      widget.client.requestSwitchSeat(targetSeatIndex);
    }
  }

  Widget _buildSeatCard(RoomSeat? seat, int index) {
    final isOccupied = seat?.isOccupied == true;
    final isHostSeat = seat?.isHost == true;
    final isBot = seat?.isBot == true;
    final isReady = seat?.isReady == true;

    // Equipo A: Asientos 0 y 2 (Azul) / Equipo B: Asientos 1 y 3 (Rojo)
    final isTeamA = index % 2 == 0;
    final isTeamsMode = widget.roomInfo.isTeams && widget.roomInfo.targetPlayers == 4;

    return TactilePressable(
      depth: 2.5,
      onTap: () => _switchSeat(index),
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.cartoonCardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isTeamsMode
                ? (isTeamA ? AppPalette.cartoonCyan : AppPalette.cartoonRed)
                : (isOccupied
                    ? (isReady ? const Color(0xFF10B981) : const Color(0xFF22D3EE))
                    : AppPalette.cartoonBorder),
            width: isOccupied ? 2.2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rótulo del Equipo (si es 2 vs 2)
            if (isTeamsMode) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  gradient: isTeamA ? AppGradients.cyanAccent : AppGradients.redDanger,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.0),
                ),
                child: Text(
                  isTeamA ? '🔵 EQUIPO A' : '🔴 EQUIPO B',
                  style: TextStyle(
                    color: isTeamA ? const Color(0xFF1E1B4B) : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            if (isOccupied) ...[
              Stack(
                alignment: Alignment.topRight,
                children: [
                  UserFrameView(
                    avatarIndex: seat!.avatarId,
                    frameId: seat.frameId,
                    size: 54,
                    showLevelBadge: false,
                  ),
                  if (isHostSeat)
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seat.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isReady
                      ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isReady ? const Color(0xFF22C55E) : Colors.white24,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isReady ? 'LISTO' : 'ESPERANDO',
                  style: TextStyle(
                    color: isReady ? const Color(0xFF22C55E) : Colors.white60,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.isHost && isBot) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => widget.host?.toggleBotInSeat(index),
                  child: const Text(
                    'Quitar Bot',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ] else ...[
              // Asiento libre
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.cartoonBgDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white30, size: 22),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toca para sentarte',
                style: TextStyle(color: AppPalette.cartoonCyan, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              if (widget.isHost) ...[
                const SizedBox(height: 6),
                TactilePressable(
                  depth: 2.0,
                  onTap: () => widget.host?.toggleBotInSeat(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppPalette.cartoonBgDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_rounded, size: 11, color: Color(0xFF38BDF8)),
                        SizedBox(width: 3),
                        Text(
                          '+ Bot',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
