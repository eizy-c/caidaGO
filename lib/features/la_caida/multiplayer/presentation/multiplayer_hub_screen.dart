import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/player_session.dart';
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

  // Filtro de pestañas: 0 = TODAS, 1 = SIN CONTRASEÑA
  int _selectedFilterIndex = 0;

  // Estado del formulario de creación de sala
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
      if (pinToUse == null) return; // Cancelado por el usuario
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
                'BUSCAR / UNIRSE',
                fontSize: 17,
                textColor: AppPalette.cartoonYellow,
                strokeColor: AppPalette.cartoonCardText,
                strokeWidth: 2.5,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa la clave de 4 números de la sala privada para conectarte:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.cartoonYellow,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF262169),
                  hintText: '••••',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
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
                final pin = pinController.text.trim();
                final customIp = ipController.text.trim();
                Navigator.of(ctx).pop();

                final discovered = _beaconService.discoveredRoomsNotifier.value;
                MultiplayerRoomInfo? matchedRoom;
                if (discovered.isNotEmpty) {
                  matchedRoom = discovered.firstWhere(
                    (r) => r.isPrivate,
                    orElse: () => discovered.first,
                  );
                }

                final effectiveIp = customIp.isNotEmpty
                    ? customIp
                    : (matchedRoom?.hostIp ?? _myLocalIp ?? '127.0.0.1');

                _joinRoom(MultiplayerRoomInfo(
                  roomId: matchedRoom?.roomId ?? 'ROOM_KEY',
                  roomName: matchedRoom?.roomName ?? 'Sala Privada',
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
                      child: const CartoonStrokeText(
                        'ABRIR SALA (SIN INTERNET)',
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
            // Header estilo cartoon: Botón <, Título SALAS, Botón Buscar
            _buildHeader(context),

            // Pestañas cartoon: "PÚBLICAS" y "PRIVADAS" con indicador turquesa
            _buildFilterTabs(),

            const SizedBox(height: 6),

            // Lista de salas en vivo
            Expanded(
              child: _buildRoomList(),
            ),

            // Botón inferior flotante "CREAR SALA"
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
          CartoonRoundButton(
            onPressed: _showSearchOrJoinPinDialog,
            width: 44,
            height: 44,
            child: const Icon(
              Icons.search_rounded,
              color: AppPalette.cartoonCardText,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: CartoonStrokeText(
                      'PÚBLICAS',
                      fontSize: 15,
                      textColor: _selectedFilterIndex == 0
                          ? AppPalette.cartoonCyan
                          : const Color(0xFFA5B4FC),
                      strokeColor: AppPalette.cartoonCardText,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilterIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: CartoonStrokeText(
                      'PRIVADAS',
                      fontSize: 15,
                      textColor: _selectedFilterIndex == 1
                          ? AppPalette.cartoonCyan
                          : const Color(0xFFA5B4FC),
                      strokeColor: AppPalette.cartoonCardText,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Indicador de barra turquesa
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF262169),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final halfWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: _selectedFilterIndex == 0 ? 0 : halfWidth,
                      width: halfWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppPalette.cartoonCyan,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: AppPalette.cartoonCyan,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    return ValueListenableBuilder<List<MultiplayerRoomInfo>>(
      valueListenable: _beaconService.discoveredRoomsNotifier,
      builder: (context, allRooms, _) {
        // Filtrar según la pestaña activa (0 = Públicas, 1 = Privadas)
        final filteredRooms = _selectedFilterIndex == 1
            ? allRooms.where((r) => r.isPrivate).toList()
            : allRooms.where((r) => !r.isPrivate).toList();

        if (filteredRooms.isEmpty) {
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
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            return _buildRoomCard(room);
          },
        );
      },
    );
  }

  Widget _buildRoomCard(MultiplayerRoomInfo room) {
    // Formatear código de sala a 5 caracteres
    final rawCode = room.roomId.replaceAll('RM-', '');
    final displayCode = rawCode.padLeft(5, '0');

    return CartoonCard(
      onTap: () => _joinRoom(room),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Código de sala (5 dígitos)
          Text(
            displayCode,
            style: const TextStyle(
              color: AppPalette.cartoonCardText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),

          // Candado si es privada
          if (room.isPrivate) ...[
            const Icon(
              Icons.lock_rounded,
              color: AppPalette.cartoonCardText,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],

          const Spacer(),

          // Icono de refresh/estado
          const Icon(
            Icons.sync_rounded,
            color: Color(0xFF4338CA),
            size: 20,
          ),
          const SizedBox(width: 6),

          // Puntos / objetivo
          const Text(
            '0/24',
            style: TextStyle(
              color: AppPalette.cartoonCardText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(width: 14),

          // Icono silueta jugador
          const Icon(
            Icons.person_rounded,
            color: Color(0xFF4338CA),
            size: 20,
          ),
          const SizedBox(width: 4),

          // Contador de jugadores
          Text(
            '${room.currentPlayers}/${room.targetPlayers}',
            style: const TextStyle(
              color: AppPalette.cartoonCardText,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: TactilePressable(
        onTap: _showCreateRoomTypeDialog,
        depth: 4,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: AppGradients.goldReward,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppPalette.cartoonBorder, width: 2.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1B165E),
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono redondeado en rojo con tuerca/engranaje
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppGradients.redDanger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.8),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Texto CREAR SALA
              const Text(
                'CREAR SALA',
                style: TextStyle(
                  color: AppPalette.cartoonCardText,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
