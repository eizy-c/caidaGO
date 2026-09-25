import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/player_session.dart';
import '../../economy/venezuela_room_tier.dart';
import '../domain/multiplayer_models.dart';
import '../network/local_game_client.dart';
import '../network/local_game_host.dart';
import '../network/local_network_utils.dart';
import '../network/local_room_beacon_service.dart';
import 'multiplayer_waiting_room_screen.dart';
import 'widgets/enter_pin_dialog.dart';

/// Pantalla Principal del Modo Multijugador (SALAS) con paleta Cartoon Azul/Púrpura
/// y distribución limpia según diseño de referencia.
class MultiplayerHubScreen extends StatefulWidget {
  const MultiplayerHubScreen({super.key});

  @override
  State<MultiplayerHubScreen> createState() => _MultiplayerHubScreenState();
}

class _MultiplayerHubScreenState extends State<MultiplayerHubScreen> {
  final LocalRoomBeaconService _beaconService = LocalRoomBeaconService();
  final PlayerSession _session = PlayerSession.shared;


  // Estado del formulario de creación de sala
  final TextEditingController _roomNameController =
      TextEditingController(text: 'Mesa Criolla');
  int _targetPlayers = 2; // 2, 3 o 4
  bool _isTeams = false;
  bool _isPrivate = false;
  final TextEditingController _pinController = TextEditingController(text: '1234');
  bool _fillWithBots = true;
  VenezuelaRoomTier? _selectedRegionalRoom;
  MultiplayerNetworkMode _networkMode = MultiplayerNetworkMode.online;
  final String _onlineServerUrl = 'wss://caidago-main.up.railway.app/ws';
  List<MultiplayerRoomInfo> _onlineRooms = [];
  bool _isLoadingOnlineRooms = false;
  String? _myLocalIp;

  @override
  void initState() {
    super.initState();
    _initNetworkAndScanning();
    _refreshOnlineRooms();
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

  Future<void> _refreshOnlineRooms() async {
    if (!mounted) return;
    setState(() => _isLoadingOnlineRooms = true);
    final rooms = await LocalGameClient.fetchOnlinePublicRoomsHttp(_onlineServerUrl);
    if (mounted) {
      setState(() {
        _onlineRooms = rooms;
        _isLoadingOnlineRooms = false;
      });
    }
  }

  @override
  void dispose() {
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
    final roomId = LocalNetworkUtils.generateRoomId();

    final entryFee = _selectedRegionalRoom?.entryFee ?? 0;
    if (entryFee > 0 && _session.coins < entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monedas insuficientes. Necesitas ${formatCoins(entryFee)} monedas para esta sala.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

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
      networkMode: _networkMode,
      regionalRoomId: _selectedRegionalRoom?.id,
      entryFee: entryFee,
    );

    if (_networkMode == MultiplayerNetworkMode.online) {
      final client = LocalGameClient();
      final created = await client.createOnlineRoom(
        serverUrl: _onlineServerUrl,
        roomName: roomName,
        hostName: _session.name.isNotEmpty ? _session.name : 'Anfitrión',
        hostAvatarId: _session.avatarIndex,
        hostFrameId: _session.selectedFrameId,
        targetPlayers: _targetPlayers,
        isPrivate: _isPrivate,
        pinCode: pin,
        isTeams: _isTeams && _targetPlayers == 4,
        fillWithBots: _fillWithBots,
        regionalRoomId: _selectedRegionalRoom?.id,
        entryFee: entryFee,
      );

      if (!created) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(client.errorMessageNotifier.value ?? 'No se pudo conectar al servidor online.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      final room = client.currentRoom ?? roomInfo;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiplayerWaitingRoomScreen(
            roomInfo: room,
            host: null,
            client: client,
            isHost: true,
          ),
        ),
      );
      return;
    }

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
    if (room.entryFee > 0 && _session.coins < room.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monedas insuficientes. Esta sala requiere ${formatCoins(room.entryFee)} monedas de entrada.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    String? pinToUse;
    if (room.isPrivate) {
      pinToUse = await EnterPinDialog.show(context, roomName: room.roomName);
      if (pinToUse == null) return; // Cancelado por el usuario
    }

    if (_networkMode == MultiplayerNetworkMode.online || room.networkMode == MultiplayerNetworkMode.online) {
      final client = LocalGameClient();
      final connected = await client.joinOnlineRoom(
        serverUrl: _onlineServerUrl,
        playerName: _session.name.isNotEmpty ? _session.name : 'Invitado',
        avatarId: _session.avatarIndex,
        frameId: _session.selectedFrameId,
        roomId: room.roomId,
        pinCode: pinToUse,
      );

      if (!connected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(client.errorMessageNotifier.value ?? 'No se pudo conectar a la sala online.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      final joinedRoom = client.currentRoom ?? room;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiplayerWaitingRoomScreen(
            roomInfo: joinedRoom,
            client: client,
            isHost: false,
          ),
        ),
      );
      return;
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

  // --- UNIRSE CON KEY / PIN O BÚSQUEDA ---
  Future<void> _showSearchOrJoinPinDialog() async {
    final idController = TextEditingController();
    final pinController = TextEditingController();
    final ipController = TextEditingController();
    bool showAdvancedIp = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppPalette.cartoonBgDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppPalette.cartoonBorder, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppPalette.cartoonYellow, size: 24),
              SizedBox(width: 8),
              CartoonStrokeText(
                'BUSCAR POR ID',
                fontSize: 17,
                textColor: AppPalette.cartoonYellow,
                strokeColor: AppPalette.cartoonCardText,
                strokeWidth: 2.5,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ID DE LA SALA (5 CARACTERES):',
                  style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: idController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 5,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppPalette.cartoonYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF262169),
                    hintText: 'EJ: 7K9BM',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'PIN DE ACCESO (SI LA SALA ES PRIVADA):',
                  style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF262169),
                    hintText: '•••• (opcional)',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Si la sala es pública, deja el PIN en blanco.',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setDlgState(() => showAdvancedIp = !showAdvancedIp),
                  child: Row(
                    children: [
                      Icon(
                        showAdvancedIp ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Opciones avanzadas (IP directa)',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (showAdvancedIp) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: ipController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'IP del Host (opcional)',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF262169),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            TactilePressable(
              depth: 3,
              onTap: () {
                final targetId = idController.text.trim().toUpperCase();
                final pin = pinController.text.trim();
                final customIp = ipController.text.trim();

                if (targetId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor escribe el ID de 5 caracteres de la sala.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                if (_networkMode == MultiplayerNetworkMode.online) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final client = LocalGameClient();
                  client.joinOnlineRoom(
                    serverUrl: customIp.isNotEmpty ? customIp : _onlineServerUrl,
                    playerName: _session.name.isNotEmpty ? _session.name : 'Invitado',
                    avatarId: _session.avatarIndex,
                    frameId: _session.selectedFrameId,
                    roomId: targetId,
                    pinCode: pin.isNotEmpty ? pin : null,
                  ).then((joined) async {
                    if (joined && mounted) {
                      await Future.delayed(const Duration(milliseconds: 250));
                      final r = client.currentRoom ??
                          MultiplayerRoomInfo(
                            roomId: targetId,
                            roomName: 'Sala Online #$targetId',
                            hostName: 'Anfitrión',
                            hostIp: _onlineServerUrl,
                            isPrivate: pin.isNotEmpty,
                            pinCode: pin,
                            networkMode: MultiplayerNetworkMode.online,
                          );
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => MultiplayerWaitingRoomScreen(
                            roomInfo: r,
                            client: client,
                            isHost: false,
                          ),
                        ),
                      );
                    } else if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(client.errorMessageNotifier.value ??
                              'No se encontró la sala #$targetId o el PIN es incorrecto.'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  });
                  return;
                }

                final discovered = _beaconService.discoveredRoomsNotifier.value;
                MultiplayerRoomInfo? matchedRoom;
                if (discovered.isNotEmpty) {
                  matchedRoom = discovered.where(
                    (r) => r.roomId.replaceAll('RM-', '').toUpperCase() == targetId,
                  ).firstOrNull;
                }

                final effectiveIp = customIp.isNotEmpty
                    ? customIp
                    : (matchedRoom?.hostIp ?? _myLocalIp ?? '127.0.0.1');

                _joinRoom(MultiplayerRoomInfo(
                  roomId: matchedRoom?.roomId ?? targetId,
                  roomName: matchedRoom?.roomName ?? 'Sala #$targetId',
                  hostName: matchedRoom?.hostName ?? 'Anfitrión',
                  hostIp: effectiveIp,
                  port: 45456,
                  isPrivate: pin.isNotEmpty,
                  pinCode: pin,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.greenAccept,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 2)),
                  ],
                ),
                child: const Text(
                  'ENTRAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGO PARA SELECCIONAR TIPO DE SALA (PÚBLICA O PRIVADA) ---
  void _showCreateRoomTypeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.cartoonBgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppPalette.cartoonBorder, width: 2.2),
        ),
        title: const Center(
          child: CartoonStrokeText(
            'TIPO DE SALA',
            fontSize: 20,
            textColor: AppPalette.cartoonYellow,
            strokeColor: AppPalette.cartoonCardText,
            strokeWidth: 3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Cómo deseas configurar el acceso a tu partida?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 18),

            // Opción 1: Sala Pública
            TactilePressable(
              depth: 3,
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isPrivate = false;
                });
                _openCreateRoomSheet();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanAccent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Color(0xFF1E1B4B),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SALA PÚBLICA',
                            style: TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sin contraseña. Visible para todos.',
                            style: TextStyle(
                              color: Color(0xFF1E1B4B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF1E1B4B),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Opción 2: Sala Privada
            TactilePressable(
              depth: 3,
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _isPrivate = true;
                });
                _openCreateRoomSheet();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldReward,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppPalette.cartoonCardText,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SALA PRIVADA',
                            style: TextStyle(
                              color: AppPalette.cartoonCardText,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Protegida con PIN de 4 dígitos.',
                            style: TextStyle(
                              color: AppPalette.cartoonCardText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppPalette.cartoonCardText,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL DE CONFIGURACIÓN Y CREACIÓN DE SALA ---
  void _openCreateRoomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.cartoonBgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppPalette.cartoonBorder, width: 2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de agarre
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Título del modal
                  Center(
                    child: CartoonStrokeText(
                      _isPrivate ? 'CREAR SALA PRIVADA' : 'CREAR SALA PÚBLICA',
                      fontSize: 22,
                      textColor: AppPalette.cartoonYellow,
                      strokeColor: AppPalette.cartoonCardText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre de la sala
                  const Text(
                    'NOMBRE DE LA SALA',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roomNameController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF262169),
                      hintText: 'Ej. Mesa Criolla',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Selector de Sala Regional de Venezuela / Apuesta
                  const Text(
                    'SALA REGIONAL / APUESTA',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Opción Mesa Libre
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TactilePressable(
                            depth: 2,
                            onTap: () {
                              setSheetState(() => _selectedRegionalRoom = null);
                              setState(() => _selectedRegionalRoom = null);
                            },
                            child: Container(
                              width: 110,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedRegionalRoom == null ? null : const Color(0xFF262169),
                                gradient: _selectedRegionalRoom == null ? AppGradients.cyanAccent : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedRegionalRoom == null ? AppPalette.cartoonBorder : AppPalette.cartoonBorder.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mesa Libre',
                                    style: TextStyle(
                                      color: _selectedRegionalRoom == null ? const Color(0xFF1E1B4B) : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Sin Apuesta',
                                    style: TextStyle(
                                      color: _selectedRegionalRoom == null ? const Color(0xFF1E1B4B).withValues(alpha: 0.8) : Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 7 Salas Regionales de Venezuela
                        ...VenezuelaRoomTier.catalog.map((tier) {
                          final isSel = _selectedRegionalRoom?.id == tier.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: TactilePressable(
                              depth: 2,
                              onTap: () {
                                setSheetState(() => _selectedRegionalRoom = tier);
                                setState(() => _selectedRegionalRoom = tier);
                              },
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel ? null : const Color(0xFF262169),
                                  gradient: isSel ? AppGradients.goldReward : null,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSel ? AppPalette.cartoonBorder : AppPalette.cartoonBorder.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tier.name,
                                      style: TextStyle(
                                        color: isSel ? const Color(0xFF1E1B4B) : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      formatCoins(tier.entryFee),
                                      style: TextStyle(
                                        color: isSel ? const Color(0xFF1E1B4B).withValues(alpha: 0.9) : const Color(0xFFFBBF24),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '+${tier.winTrophies}/-${tier.lossTrophies}',
                                      style: TextStyle(
                                        color: isSel ? const Color(0xFF1E1B4B).withValues(alpha: 0.75) : Colors.white54,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  if (_selectedRegionalRoom != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262169),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B3592)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pozo Total: ${formatCoins(_selectedRegionalRoom!.entryFee * (_isTeams && _targetPlayers == 4 ? 4 : _targetPlayers))}',
                            style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Premio Ganador: ${formatCoins(_isTeams && _targetPlayers == 4 ? (_selectedRegionalRoom!.entryFee * 4) ~/ 2 : _selectedRegionalRoom!.entryFee * _targetPlayers)}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Selector de jugadores: 2, 3 o 4
                  const Text(
                    'CANTIDAD DE JUGADORES',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [2, 3, 4].map((count) {
                      final isSel = _targetPlayers == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TactilePressable(
                            depth: 2,
                            onTap: () {
                              setSheetState(() {
                                _targetPlayers = count;
                                if (count != 4) _isTeams = false;
                              });
                              setState(() {
                                _targetPlayers = count;
                                if (count != 4) _isTeams = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? null : const Color(0xFF262169),
                                gradient: isSel ? AppGradients.cyanAccent : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? AppPalette.cartoonBorder : AppPalette.cartoonBorder.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B165E),
                                    offset: Offset(0, isSel ? 2 : 1),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      color: isSel ? const Color(0xFF1E1B4B) : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    count == 2 ? '1 vs 1' : (count == 3 ? 'Trío' : 'Mesa 4'),
                                    style: TextStyle(
                                      color: isSel ? const Color(0xFF1E1B4B).withValues(alpha: 0.8) : Colors.white60,
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

                  if (_targetPlayers == 4) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jugar en Parejas (2 vs 2)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Compañeros enfrentados', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        CartoonSwitch(
                          value: _isTeams,
                          onChanged: (val) {
                            setSheetState(() => _isTeams = val);
                            setState(() => _isTeams = val);
                          },
                        ),
                      ],
                    ),
                  ],

                  const Divider(color: Color(0xFF3B3592), height: 24),

                  // Sala Privada con PIN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sala Privada con PIN de 4 Números', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('Requiere clave para ingresar', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      CartoonSwitch(
                        value: _isPrivate,
                        onChanged: (val) {
                          setSheetState(() => _isPrivate = val);
                          setState(() => _isPrivate = val);
                        },
                      ),
                    ],
                  ),

                  if (_isPrivate) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(
                        color: AppPalette.cartoonYellow,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 6,
                      ),
                      decoration: InputDecoration(
                        labelText: 'PIN de la Sala (4 Números)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF262169),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Rellenar con Bots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rellenar puestos con Bots (IA)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('Completa la mesa automáticamente', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      CartoonSwitch(
                        value: _fillWithBots,
                        onChanged: (val) {
                          setSheetState(() => _fillWithBots = val);
                          setState(() => _fillWithBots = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón Confirmar Crear Sala (Verde Aceptar)
                  TactilePressable(
                    depth: 3.5,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _createRoom();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppGradients.greenAccept,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1B165E),
                            offset: Offset(0, 3.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: CartoonStrokeText(
                        _networkMode == MultiplayerNetworkMode.online
                            ? 'CREAR SALA ONLINE'
                            : 'ABRIR SALA (SIN INTERNET)',
                        fontSize: 15,
                        textColor: Colors.white,
                      ),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.cartoonBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header estilo cartoon: Botón <, Título SALAS y Botón Refrescar
            _buildHeader(context),

            if (_networkMode == MultiplayerNetworkMode.localWifi)
              _buildLocalWifiBanner(),

            const SizedBox(height: 4),

            // Lista de salas en vivo
            Expanded(
              child: _buildRoomList(),
            ),

            // Botonera inferior: [ UNIRSE POR ID ] [ RED LOCAL / INTERNET ] [ CREAR SALA ]
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppPalette.cartoonSurface,
        border: Border(
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CartoonRoundButton(
            onPressed: () => Navigator.of(context).pop(),
            width: 44,
            height: 44,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppPalette.cartoonCardText,
              size: 20,
            ),
          ),
          const CartoonStrokeText(
            'SALAS',
            fontSize: 26,
            textColor: AppPalette.cartoonYellow,
            strokeColor: AppPalette.cartoonCardText,
            strokeWidth: 4,
          ),
          Row(
            children: [
              CartoonRoundButton(
                onPressed: _startQuickMatch,
                width: 44,
                height: 44,
                backgroundColor: const Color(0xFFEAB308),
                borderColor: const Color(0xFFCA8A04),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              CartoonRoundButton(
                onPressed: () {
                  if (_networkMode == MultiplayerNetworkMode.online) {
                    _refreshOnlineRooms();
                  } else {
                    _beaconService.startListening();
                  }
                },
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppPalette.cartoonCardText,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalWifiBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E174D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF97316), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_rounded, color: Color(0xFFF97316), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modo Red Local (Sin Internet)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _networkMode = MultiplayerNetworkMode.online;
                _refreshOnlineRooms();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppGradients.cyanAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'VOLVER A INTERNET',
                style: TextStyle(
                  color: Color(0xFF1E1B4B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    if (_networkMode == MultiplayerNetworkMode.online) {
      if (_isLoadingOnlineRooms) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppPalette.cartoonCyan),
              SizedBox(height: 12),
              Text(
                'Consultando salas en el servidor online...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        );
      }

      if (_onlineRooms.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF332D8C),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  size: 42,
                  color: AppPalette.cartoonCyan,
                ),
              ),
              const SizedBox(height: 14),
              const CartoonStrokeText(
                'SIN SALAS ONLINE ACTIVAS',
                fontSize: 15,
                textColor: Colors.white,
                strokeColor: AppPalette.cartoonCardText,
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Sé el primero en abrir una mesa en Internet o únete con el ID de 5 dígitos de un amigo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _refreshOnlineRooms,
                icon: const Icon(Icons.refresh_rounded, color: AppPalette.cartoonCyan, size: 18),
                label: const Text('Actualizar salas online', style: TextStyle(color: AppPalette.cartoonCyan, fontSize: 12)),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _onlineRooms.length,
        itemBuilder: (context, index) {
          final room = _onlineRooms[index];
          return _buildRoomCard(room);
        },
      );
    }

    return ValueListenableBuilder<List<MultiplayerRoomInfo>>(
      valueListenable: _beaconService.discoveredRoomsNotifier,
      builder: (context, allRooms, _) {
        if (allRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF332D8C),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    size: 42,
                    color: AppPalette.cartoonCyan,
                  ),
                ),
                const SizedBox(height: 14),
                const CartoonStrokeText(
                  'BUSCANDO SALAS CERCANAS...',
                  fontSize: 15,
                  textColor: Colors.white,
                  strokeColor: AppPalette.cartoonCardText,
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'No necesitas internet. Conéctense al mismo Wi-Fi o punto de acceso y presiona "CREAR SALA".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11.5),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _beaconService.startListening(),
                  icon: const Icon(Icons.refresh_rounded, color: AppPalette.cartoonCyan, size: 18),
                  label: const Text('Actualizar búsqueda', style: TextStyle(color: AppPalette.cartoonCyan, fontSize: 12)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: allRooms.length,
          itemBuilder: (context, index) {
            final room = allRooms[index];
            return _buildRoomCard(room);
          },
        );
      },
    );
  }

  Widget _buildRoomCard(MultiplayerRoomInfo room) {
    // Formatear código de sala a 5 caracteres
    final rawCode = room.roomId.replaceAll('RM-', '');
    final displayCode = rawCode.length > 5 ? rawCode.substring(0, 5) : rawCode;
    final regionalRoom = room.regionalRoomId != null ? VenezuelaRoomTier.fromId(room.regionalRoomId!) : null;
    final roomTitle = regionalRoom?.name ?? room.roomName;
    final potAmount = room.entryFee > 0 ? room.totalPot : 0;

    return CartoonCard(
      onTap: () => _joinRoom(room),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila superior: #ID de 5 dígitos + Badge Pública/Privada + Contador de Jugadores
          Row(
            children: [
              Text(
                '#$displayCode',
                style: const TextStyle(
                  color: AppPalette.cartoonCardText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              // Badge diferenciador Pública / Privada (sin emojis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: room.isPrivate
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: room.isPrivate
                        ? const Color(0xFFD97706)
                        : const Color(0xFF059669),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      room.isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                      size: 11,
                      color: room.isPrivate
                          ? const Color(0xFFB45309)
                          : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      room.isPrivate ? 'PRIVADA' : 'PUBLICA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: room.isPrivate
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Contador de jugadores (icono de silueta, sin emojis)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFF4338CA),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.currentPlayers}/${room.targetPlayers}',
                    style: const TextStyle(
                      color: AppPalette.cartoonCardText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila media: Sala a jugar + Anfitrión + Chip de Premio/Monedas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roomTitle,
                      style: const TextStyle(
                        color: AppPalette.cartoonCardText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anfitrion: ${room.hostName}',
                      style: const TextStyle(
                        color: Color(0xFF4338CA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Chip Premio / Pozo (icono de moneda, sin emojis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldReward,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 13,
                      color: Color(0xFF1E1B4B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      potAmount > 0 ? '${formatCoins(potAmount)} Monedas' : 'Amistosa',
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Row(
        children: [
          // Botón 1: UNIRSE POR ID
          Expanded(
            child: TactilePressable(
              onTap: _showSearchOrJoinPinDialog,
              depth: 3.5,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.cyanAccent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tag_rounded, color: Color(0xFF1E1B4B), size: 18),
                    SizedBox(width: 5),
                    Text(
                      'UNIRSE POR ID',
                      style: TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón 2: RED LOCAL / INTERNET
          Expanded(
            child: TactilePressable(
              onTap: () {
                setState(() {
                  if (_networkMode == MultiplayerNetworkMode.online) {
                    _networkMode = MultiplayerNetworkMode.localWifi;
                    _beaconService.startListening();
                  } else {
                    _networkMode = MultiplayerNetworkMode.online;
                    _refreshOnlineRooms();
                  }
                });
              },
              depth: 3.5,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: _networkMode == MultiplayerNetworkMode.localWifi
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _networkMode == MultiplayerNetworkMode.localWifi
                          ? Icons.public_rounded
                          : Icons.wifi_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _networkMode == MultiplayerNetworkMode.localWifi
                          ? 'INTERNET'
                          : 'RED LOCAL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón 3: CREAR SALA
          Expanded(
            child: TactilePressable(
              onTap: _showCreateRoomTypeDialog,
              depth: 3.5,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.goldReward,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: AppPalette.cartoonCardText, size: 20),
                    SizedBox(width: 3),
                    Text(
                      'CREAR SALA',
                      style: TextStyle(
                        color: AppPalette.cartoonCardText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ⚡ PARTIDA RÁPIDA (EMPAREJAMIENTO DIRECTO) ---
  Future<void> _startQuickMatch() async {
    // Si estamos en modo Wi-Fi Local, buscar una sala abierta en la red local o crear una rápida
    if (_networkMode == MultiplayerNetworkMode.localWifi) {
      final availableRooms = _beaconService.discoveredRoomsNotifier.value
          .where((r) => !r.isPrivate && r.currentPlayers < r.targetPlayers)
          .toList();

      if (availableRooms.isNotEmpty) {
        _joinRoom(availableRooms.first);
        return;
      }

      // Si no hay salas LAN abiertas, crear una partida rápida LAN
      _roomNameController.text = 'Partida Rápida';
      _isPrivate = false;
      _targetPlayers = 2;
      _isTeams = false;
      _fillWithBots = true;
      _selectedRegionalRoom = null;
      _createRoom();
      return;
    }

    // Modo En Línea (Internet)
    // Diálogo animado de búsqueda de partida
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFF262169),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppGradients.cyanAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.cartoonBorder, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.flash_on_rounded, color: Color(0xFF1E1B4B), size: 36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CartoonStrokeText(
                    'BUSCANDO PARTIDA...',
                    fontSize: 18,
                    textColor: AppPalette.cartoonYellow,
                    strokeColor: AppPalette.cartoonCardText,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emparejando con un rival disponible o mesa abierta en segundos...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppPalette.cartoonCyan,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TactilePressable(
                    onTap: () => Navigator.of(dialogCtx).pop(),
                    depth: 2,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF332D8C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final client = LocalGameClient();
    final success = await client.requestQuickMatch(
      serverUrl: _onlineServerUrl,
      playerName: _session.name.isNotEmpty ? _session.name : 'Jugador Criollo',
      avatarId: _session.avatarIndex,
      frameId: _session.selectedFrameId,
      targetPlayers: 2,
    );

    // Esperar un momento a que llegue JOIN_ACCEPTED
    int retries = 0;
    while (client.currentRoom == null &&
        retries < 15 &&
        client.statusNotifier.value != ClientConnectionStatus.rejected &&
        client.statusNotifier.value != ClientConnectionStatus.error) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!success || client.currentRoom == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(client.errorMessageNotifier.value ?? 'No se pudo conectar a la partida rápida.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final room = client.currentRoom!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiplayerWaitingRoomScreen(
          roomInfo: room,
          host: null,
          client: client,
          isHost: client.mySeatIndex == 0,
        ),
      ),
    );
  }
}

