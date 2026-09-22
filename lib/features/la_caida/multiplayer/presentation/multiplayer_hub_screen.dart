import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../economy/player_session.dart';
import '../domain/multiplayer_models.dart';
import '../network/local_game_client.dart';
import '../network/local_game_host.dart';
import '../network/local_network_utils.dart';
import '../network/local_room_beacon_service.dart';
import 'multiplayer_waiting_room_screen.dart';
import 'widgets/enter_pin_dialog.dart';

/// Pantalla Principal del Modo Multijugador.
/// Permite:
/// - Ver salas locales Wi-Fi en vivo (sin internet).
/// - Crear sala (2, 3 o 4 jugadores, clave de 4 dígitos opcional, con o sin bots).
/// - Unirse directamente ingresando el Key único o IP.
class MultiplayerHubScreen extends StatefulWidget {
  const MultiplayerHubScreen({super.key});

  @override
  State<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends State<MultiplayerHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalRoomBeaconService _beaconService = LocalRoomBeaconService();
  final PlayerSession _session = PlayerSession.shared;

  // Estado del formulario de creación
  final TextEditingController _roomNameController =
      TextEditingController(text: 'Mesa Criolla');
  int _targetPlayers = 2; // 2, 3 o 4
  bool _isTeams = false;
  bool _isPrivate = false;
  final TextEditingController _pinController = TextEditingController(text: '1234');
  bool _fillWithBots = true;
  final MultiplayerNetworkMode _createNetworkMode = MultiplayerNetworkMode.localWifi;
  String? _myLocalIp;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initNetworkAndScanning();
  }

  Future<void> _initNetworkAndScanning() async {
    final ip = await LocalNetworkUtils.getLocalIpAddress();
    if (mounted) {
      setState(() {
        _myLocalIp = ip;
      });
    }
    await _beaconService.startListening();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomNameController.dispose();
    _pinController.dispose();
    _beaconService.dispose();
    super.dispose();
  }

  // --- CREAR SALA (HOST) ---
  Future<void> _createRoom() async {
    final roomName = _roomNameController.text.trim().isNotEmpty
        ? _roomNameController.text.trim()
        : 'Mesa de ${_session.name}';
    final hostIp = _myLocalIp ?? '127.0.0.1';
    final roomId = 'RM-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final pin = _isPrivate ? _pinController.text.trim() : null;
    if (_isPrivate && (pin == null || !LocalNetworkUtils.isValidPin(pin))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El Key privado debe ser de exactamente 4 números.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final roomInfo = MultiplayerRoomInfo(
      roomId: roomId,
      roomName: roomName,
      hostName: _session.name.isNotEmpty ? _session.name : 'Anfitrión',
      hostAvatarId: _session.avatarIndex,
      hostFrameId: _session.selectedFrameId,
      hostIp: hostIp,
      port: 45456,
      targetPlayers: _targetPlayers,
      currentPlayers: 1,
      isPrivate: _isPrivate,
      pinCode: pin,
      isTeams: _isTeams && _targetPlayers == 4,
      fillWithBots: _fillWithBots,
      networkMode: _createNetworkMode,
    );

    final host = LocalGameHost();
    final started = await host.startServer(
      room: roomInfo,
      hostPlayerId: 'host_${_session.name}',
    );

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la sala. Revisa permisos de red.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final dummyClient = LocalGameClient();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiplayerWaitingRoomScreen(
          roomInfo: roomInfo,
          host: host,
          client: dummyClient,
          isHost: true,
        ),
      ),
    );
  }

  // --- UNIRSE A UNA SALA (CLIENTE) ---
  Future<void> _joinRoom(MultiplayerRoomInfo room) async {
    String? pinToUse;
    if (room.isPrivate) {
      pinToUse = await EnterPinDialog.show(context, roomName: room.roomName);
      if (pinToUse == null) return; // Cancelado
    }

    final client = LocalGameClient();
    final connected = await client.connectAndJoin(
      hostIp: room.hostIp,
      port: room.port,
      playerName: _session.name.isNotEmpty ? _session.name : 'Invitado',
      avatarId: _session.avatarIndex,
      frameId: _session.selectedFrameId,
      pinCode: pinToUse,
    );

    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(client.errorMessageNotifier.value ?? 'No se pudo conectar.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiplayerWaitingRoomScreen(
          roomInfo: room,
          client: client,
          isHost: false,
        ),
      ),
    );
  }

  // --- UNIRSE CON CÓDIGO O IP MANUAL ---
  Future<void> _joinWithManualCodeOrIp() async {
    final textController = TextEditingController();
    final pinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF38BDF8), size: 20),
            SizedBox(width: 8),
            Text('Unirse con Key o IP', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Dirección IP del Anfitrión (ej. 192.168.1.50)',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                prefixIcon: Icon(Icons.router_rounded, color: Colors.white54, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Key / PIN de 4 dígitos (si es privada)',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                prefixIcon: Icon(Icons.pin_rounded, color: Colors.white54, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            onPressed: () {
              Navigator.of(ctx).pop();
              final targetIp = textController.text.trim();
              if (targetIp.isNotEmpty) {
                _joinRoom(MultiplayerRoomInfo(
                  roomId: 'MANUAL',
                  roomName: 'Sala Directa',
                  hostName: 'Anfitrión',
                  hostIp: targetIp,
                  port: 45456,
                  isPrivate: pinController.text.trim().isNotEmpty,
                  pinCode: pinController.text.trim(),
                ));
              }
            },
            child: const Text('CONECTAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'ARENA MULTIJUGADOR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.radar_rounded, size: 18), text: 'SALAS EN VIVO'),
            Tab(icon: Icon(Icons.add_circle_outline_rounded, size: 18), text: 'CREAR SALA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveRoomsTab(),
          _buildCreateRoomTab(),
        ],
      ),
    );
  }

  // --- PESTAÑA 1: SALAS EN VIVO ---
  Widget _buildLiveRoomsTab() {
    return Column(
      children: [
        // Barra de estado de escaneo Wi-Fi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF181818),
          child: Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF22C55E), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscando salas en tu red local (IP: ${_myLocalIp ?? "Detectando..."})',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const Text(
                      'No necesitas internet. Conéctense al mismo Wi-Fi o Hotspot.',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                onPressed: () => _beaconService.startListening(),
              ),
            ],
          ),
        ),

        // Botón directo "Unirse con Key / IP"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: InkWell(
            onTap: _joinWithManualCodeOrIp,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 8),
                  Text(
                    '¿TIENES UN KEY O IP DIRECTA? TOCA AQUÍ',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista en tiempo real
        Expanded(
          child: ValueListenableBuilder<List<MultiplayerRoomInfo>>(
            valueListenable: _beaconService.discoveredRoomsNotifier,
            builder: (context, rooms, _) {
              if (rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi_find_rounded, size: 48, color: Colors.white24),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Escaneando salas locales...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Pídele a un amigo que cree una sala desde la pestaña "CREAR SALA" o conéctate compartiendo zona Wi-Fi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _buildRoomCard(room);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(MultiplayerRoomInfo room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              room.targetPlayers == 2
                  ? Icons.people_outline_rounded
                  : (room.targetPlayers == 3
                      ? Icons.groups_outlined
                      : Icons.groups_rounded),
              color: const Color(0xFF38BDF8),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      room.roomName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (room.isPrivate) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Host: ${room.hostName} • ${room.targetPlayers} Jugadores ${room.isTeams ? "(Parejas)" : ""}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  'IP: ${room.hostIp}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          App3dButton(
            onPressed: () => _joinRoom(room),
            height: 38,
            depth: 3,
            borderRadius: 12,
            variant: App3dButtonVariant.cyan,
            label: 'UNIRSE',
            textStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 2: CREAR SALA ---
  Widget _buildCreateRoomTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la sala
          const Text('NOMBRE DE LA SALA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _roomNameController,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              hintText: 'Ej. Mesa Criolla',
              hintStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
            ),
          ),

          const SizedBox(height: 18),

          // Selector de Jugadores: 2, 3 o 4
          const Text('CANTIDAD DE JUGADORES', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [2, 3, 4].map((count) {
              final isSel = _targetPlayers == count;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _targetPlayers = count;
                        if (count != 4) _isTeams = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            count == 2 ? '1 vs 1' : (count == 3 ? 'Trío' : 'Mesa 4'),
                            style: TextStyle(
                              color: isSel ? Colors.black87 : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Opción Parejas (solo si son 4)
          if (_targetPlayers == 4) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jugar en Parejas (2 vs 2)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Los puntos se suman entre compañeros enfrentados', style: TextStyle(color: Colors.white54, fontSize: 11)),
              value: _isTeams,
              activeThumbColor: const Color(0xFF38BDF8),
              onChanged: (val) => setState(() => _isTeams = val),
            ),
          ],

          const Divider(color: Color(0xFF2E2E2E), height: 28),

          // Switch: Sala Privada con Key de 4 dígitos
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sala Privada con Key de 4 Dígitos', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Solo podrán unirse quienes tengan el PIN', style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: _isPrivate,
            activeThumbColor: const Color(0xFFF59E0B),
            onChanged: (val) => setState(() => _isPrivate = val),
          ),

          if (_isPrivate) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 4),
              decoration: InputDecoration(
                labelText: 'Key de la Sala (4 Números)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E2E2E))),
              ),
            ),
          ],

          // Switch: Rellenar puestos vacíos con Bots
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rellenar puestos vacíos con Bots (IA)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Si no se llenan los puestos, se completan con la máquina', style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: _fillWithBots,
            activeThumbColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _fillWithBots = val),
          ),

          const SizedBox(height: 24),

          // Botón Crear Sala
          App3dButton.icon(
            onPressed: _createRoom,
            expand: true,
            height: 50,
            depth: 4.5,
            borderRadius: 16,
            variant: App3dButtonVariant.gold,
            icon: Icons.meeting_room_rounded,
            iconSize: 22,
            label: 'CREAR SALA (SIN INTERNET)',
            textStyle: const TextStyle(
              color: Color(0xFF713F12),
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
