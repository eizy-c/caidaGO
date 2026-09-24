import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../domain/models/caida_match_config.dart';
import '../../presentation/caida_screen.dart';
import '../../presentation/widgets/user_frame_view.dart';
import '../domain/multiplayer_models.dart';
import '../network/local_game_client.dart';
import '../network/local_game_host.dart';

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
    if (!mounted) return;
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
    final seats = _seatsNotifier.value;
    final botNames = seats
        .where((s) => s.isBot)
        .map((s) => s.name.replaceAll(' (Bot)', ''))
        .toList();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          config: CaidaMatchConfig(
            initialPlayers: widget.roomInfo.targetPlayers,
            initialTeams: widget.roomInfo.isTeams,
            autoStart: true,
            chooseMano: true,
            userName: widget.isHost
                ? widget.roomInfo.hostName
                : widget.client.seatsNotifier.value
                    .firstWhere((s) => s.seatIndex == widget.client.mySeatIndex,
                        orElse: () => const RoomSeat(seatIndex: 1, name: 'Tú'))
                    .name,
            botNames: botNames.isNotEmpty ? botNames : ['Alejandro', 'Carl', 'Jhonny'],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.isHost) {
      widget.host?.stopServer();
    } else {
      widget.client.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.roomInfo;

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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

            // Mesa visual de asientos
            Expanded(
              child: ValueListenableBuilder<List<RoomSeat>>(
                valueListenable: _seatsNotifier,
                builder: (context, seats, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: room.targetPlayers == 2 ? 2 : 2,
                        childAspectRatio: 0.95,
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
                color: Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Color(0xFF2E2E2E), width: 1)),
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
                        variant: App3dButtonVariant.gold,
                        icon: Icons.play_arrow_rounded,
                        iconSize: 22,
                        label: 'INICIAR PARTIDA',
                        textStyle: const TextStyle(
                          color: Color(0xFF713F12),
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

  Widget _buildSeatCard(RoomSeat? seat, int index) {
    final isOccupied = seat?.isOccupied == true;
    final isHostSeat = seat?.isHost == true;
    final isBot = seat?.isBot == true;
    final isReady = seat?.isReady == true;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOccupied
              ? (isReady ? const Color(0xFF22C55E) : const Color(0xFF38BDF8))
              : const Color(0xFF2E2E2E),
          width: isOccupied ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isOccupied) ...[
            Stack(
              alignment: Alignment.topRight,
              children: [
                UserFrameView(
                  avatarIndex: seat!.avatarId,
                  frameId: seat.frameId,
                  size: 60,
                  showLevelBadge: false,
                ),
                if (isHostSeat)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              seat.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.isHost && isBot) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => widget.host?.toggleBotInSeat(index),
                child: const Text(
                  'Quitar Bot',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 10.5, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ] else ...[
            // Asiento libre
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white30, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Puesto ${index + 1} Libre',
              style: const TextStyle(color: Colors.white38, fontSize: 11.5),
            ),
            if (widget.isHost) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => widget.host?.toggleBotInSeat(index),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy_rounded, color: Color(0xFF38BDF8), size: 12),
                      SizedBox(width: 4),
                      Text('+ Añadir Bot', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
