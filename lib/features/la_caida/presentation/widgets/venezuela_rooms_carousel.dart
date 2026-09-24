import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/player_session.dart';
import '../../economy/trophy_session_manager.dart';
import '../../economy/venezuela_room_tier.dart';

/// Carrusel interactivo y responsivo de Salas VIP Regionales de Venezuela.
/// Implementa selector de modalidades (1 vs 1 y Parejas 2 vs 2),
/// carrusel horizontal con previsualización lateral y tarjetas naipe vertical
/// con marcos ilustrados oficiales y barras de progreso por trofeos.
class VenezuelaRoomsCarouselScreen extends StatefulWidget {
  final TrophySessionManager manager;
  final GameMode initialMode;
  final void Function(VenezuelaRoomTier room, GameMode mode)? onStartMatch;

  const VenezuelaRoomsCarouselScreen({
    super.key,
    required this.manager,
    this.initialMode = GameMode.duel1v1,
    this.onStartMatch,
  });

  /// Muestra el selector de salas en un modal de pantalla completa estilizado.
  static Future<void> show(
    BuildContext context, {
    TrophySessionManager? manager,
    GameMode initialMode = GameMode.duel1v1,
    void Function(VenezuelaRoomTier room, GameMode mode)? onStartMatch,
  }) {
    final activeManager = manager ?? TrophySessionManager.shared;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VenezuelaRoomsCarouselScreen(
        manager: activeManager,
        initialMode: initialMode,
        onStartMatch: onStartMatch,
      ),
    );
  }

  @override
  State<VenezuelaRoomsCarouselScreen> createState() => _VenezuelaRoomsCarouselScreenState();
}

class _VenezuelaRoomsCarouselScreenState extends State<VenezuelaRoomsCarouselScreen> {
  late GameMode _selectedMode;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _pageController = PageController(
      viewportFraction: 0.74,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPlayRoom(VenezuelaRoomTier room) {
    if (!widget.manager.isRoomUnlocked(room.id)) {
      HapticFeedback.lightImpact();
      return;
    }

    if (!widget.manager.canAfford(room.entryFee)) {
      HapticFeedback.lightImpact();
      return;
    }

    final success = widget.manager.deductEntryFee(room.entryFee);
    if (!success) return;

    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.onStartMatch?.call(room, _selectedMode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.manager,
      builder: (context, _) {
        final totalTrophies = widget.manager.getTotalTrophies();
        final currentCoins = PlayerSession.shared.coins;

        final screenHeight = MediaQuery.of(context).size.height;
        final carouselHeight = (screenHeight * 0.62).clamp(380.0, 460.0);

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.95),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF352B8C), AppPalette.cartoonBgDark, Color(0xFF1D1752)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: AppPalette.cartoonBorder, width: 2.2),
                left: BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                right: BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF130F3A),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tirador superior
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Cabecera Cartoon con balance de monedas y total de trofeos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Botón cerrar Cartoon
                        CartoonRoundButton(
                          width: 36,
                          height: 36,
                          backgroundColor: const Color(0xFF2E267D),
                          borderColor: const Color(0xFF4C3E9E),
                          shadowColor: const Color(0xFF1D1748),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),

                        // Título
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SALAS VIP REGIONALES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Venezuela • Progresión por Trofeos',
                                style: TextStyle(
                                  color: Color(0xFFDCE2FD),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Píldora de Trofeos Totales
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFB45309)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '$totalTrophies',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Píldora de Monedas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.cartoonCardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text(
                                '$currentCoins',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selector Segmentado de Modalidad (1v1 vs 2v2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: _buildModeSegmentedSelector(),
                  ),

                  const SizedBox(height: 6),

                  // Carrusel horizontal de tarjetas estilo naipe
                  SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: VenezuelaRoomCatalog.rooms.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final room = VenezuelaRoomCatalog.rooms[index];
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.16)).clamp(0.84, 1.0);
                            } else {
                              value = index == 0 ? 1.0 : 0.88;
                            }
                            return Center(
                              child: SizedBox(
                                height: Curves.easeOut.transform(value) * (carouselHeight - 5),
                                width: 265,
                                child: child,
                              ),
                            );
                          },
                          child: _buildRoomCard(room),
                        );
                      },
                    ),
                  ),

                  // Indicador de Puntos inferior (Paginador 1..7)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        VenezuelaRoomCatalog.rooms.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? const Color(0xFFF59E0B)
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
  }

  /// Selector de Modo Segmentado Cartoon [ Duelo 1 vs 1 ] y [ Parejas 2 vs 2 ]
  Widget _buildModeSegmentedSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeOptionButton(
              title: '⚔️ Duelo 1 vs 1',
              subtitle: 'Mano a Mano (2P)',
              mode: GameMode.duel1v1,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeOptionButton(
              title: '👥 Parejas 2 vs 2',
              subtitle: 'En Equipo (4P)',
              mode: GameMode.teams2v2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOptionButton({
    required String title,
    required String subtitle,
    required GameMode mode,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          setState(() => _selectedMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (mode == GameMode.teams2v2
                  ? AppGradients.greenAccept
                  : AppGradients.goldReward)
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
                  color: mode == GameMode.teams2v2
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (mode == GameMode.teams2v2
                            ? const Color(0xFF047857)
                            : const Color(0xFF92400E))
                        .withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white.withValues(alpha: 0.95) : Colors.white38,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de sala enmarcada con su marco oficial regional en el borde
  Widget _buildRoomCard(VenezuelaRoomTier room) {
    final isUnlocked = widget.manager.isRoomUnlocked(room.id);
    final trophies = widget.manager.getTrophies(room.id);
    final trophyProgress = widget.manager.getTrophyProgress(room.id);
    final isCompleted = widget.manager.isRoomCompleted(room.id);
    final canAfford = widget.manager.canAfford(room.entryFee);
    final prizePerWinner = room.getPrizePerWinner(_selectedMode);
    final totalPot = room.getTotalPot(_selectedMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final cardWidth = constraints.maxWidth;
        // La placa superior de madera ocupa ~21% de la altura total
        final topPadding = cardHeight * 0.215;
        // La viga inferior con ornamentos ocupa ~5.5% desde el borde inferior
        final bottomPadding = cardHeight * 0.055;
        // Los postes laterales y cañas de bambú ocupan ~9.5% a los lados
        final sidePadding = cardWidth * 0.095;

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. LA CARD (Fondo temático con bordes redondeados casi dentro del marco)
              Positioned(
                top: cardHeight * 0.025,
                left: cardWidth * 0.045,
                right: cardWidth * 0.045,
                bottom: cardHeight * 0.03,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? room.gradientColors
                          : [const Color(0xFF1D1752), const Color(0xFF130E38)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isUnlocked
                            ? room.primaryColor.withValues(alpha: 0.35)
                            : const Color(0xFF0F0B26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Scrim atenuado si la sala está bloqueada (solo sobre la card interna)
              if (!isUnlocked)
                Positioned(
                  top: cardHeight * 0.025,
                  left: cardWidth * 0.045,
                  right: cardWidth * 0.045,
                  bottom: cardHeight * 0.03,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

              // 3. Resplandor escarchado si aplica (Mérida)
              if (room.isFrozenTheme && isUnlocked)
                Positioned(
                  top: topPadding,
                  right: sidePadding,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                    ),
                  ),
                ),

              // 4. EL MARCO OFICIAL REGIONAL RECUBRIENDO LA CARD
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    room.frameAsset,
                    fit: BoxFit.fill,
                    errorBuilder: (ctx, err, stack) =>
                        _buildFallbackFrame(room, isUnlocked),
                  ),
                ),
              ),

              // 5. TODO EL CONTENIDO Y BOTONES EN FRENTE (Ajustado al cuadro interior)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sidePadding + 2,
                  topPadding,
                  sidePadding,
                  bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fila con subtítulo temático e indicador de jugadores en línea
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '"${room.subtitle}"',
                            style: TextStyle(
                              color: isUnlocked
                                  ? (room.isFrozenTheme
                                      ? const Color(0xFFBAE6FD)
                                      : room.accentColor)
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Indicador de jugadores en línea claro y descriptivo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${room.simulatedActivePlayers} en línea',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Centro / Espacio ilustrativo temático
                    Expanded(
                      child: Center(
                        child: isUnlocked
                            ? Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.3),
                                  border: Border.all(
                                    color: room.accentColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  room.isFrozenTheme
                                      ? Icons.ac_unit_rounded
                                      : (room.id == 1
                                          ? Icons.eco_rounded
                                          : (room.id == 2
                                              ? Icons.wb_sunny_rounded
                                              : (room.id == 3
                                                  ? Icons.waves_rounded
                                                  : (room.id == 4
                                                      ? Icons.bolt_rounded
                                                      : Icons.workspace_premium_rounded)))),
                                  color: room.accentColor,
                                  size: 30,
                                ),
                              )
                            : Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.8),
                                  border: Border.all(color: Colors.white24, width: 2),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFFFDE047),
                                  size: 22,
                                ),
                              ),
                      ),
                    ),

                    // 3. Caja de Entrada, Pozo Total y Premio (100% visible con cuánto se entra)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppPalette.cartoonCardDark.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUnlocked
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.85)
                              : Colors.white24,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ENTRADA
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'ENTRADA',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '🪙 ${room.entryFee}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // POZO TOTAL (4 Jugadores en 2v2, 2 Jugadores en 1v1)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedMode == GameMode.teams2v2 ? 'POZO (4J)' : 'POZO (2J)',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '🪙 $totalPot',
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PREMIO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedMode == GameMode.teams2v2 ? 'PREMIO C/U' : 'PREMIO GAN.',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '🪙 $prizePerWinner',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 4. Barra de Trofeos de la Sala
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Text('🏆', style: TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isCompleted ? 'SALA COMPLETADA' : 'TROFEOS DE SALA',
                                      style: TextStyle(
                                        color: isCompleted
                                            ? const Color(0xFFFDE047)
                                            : Colors.white70,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$trophies / ${room.trophyCap}',
                              style: TextStyle(
                                color: isCompleted
                                    ? const Color(0xFFFDE047)
                                    : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            height: 7,
                            color: const Color(0xFF0F172A),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: trophyProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isCompleted
                                        ? [const Color(0xFFFDE047), const Color(0xFFF59E0B)]
                                        : [const Color(0xFF38BDF8), const Color(0xFF0284C7)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Victoria: +${room.winTrophies} 🏆',
                                style: const TextStyle(
                                  color: Color(0xFF4ADE80),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                room.lossTrophies == 0
                                    ? 'Derrota: 0 🏆'
                                    : 'Derrota: ${room.lossTrophies} 🏆',
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 5. Botón Inferior de Acción (completamente al frente)
                    _buildActionButton(room, isUnlocked, canAfford),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Botón de acción según el estado de desbloqueo y balance
  Widget _buildActionButton(VenezuelaRoomTier room, bool isUnlocked, bool canAfford) {
    if (!isUnlocked) {
      final remaining = widget.manager.getRemainingTrophiesForUnlock(room.id);
      final prevRoom = VenezuelaRoomCatalog.getPreviousRoom(room.id);
      final prevName = prevRoom != null ? prevRoom.name : 'Sala anterior';

      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppPalette.cartoonCardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFFFBBF24), size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Faltan $remaining 🏆 en $prevName',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (!canAfford) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '🪙 FICHAS INSUFICIENTES (Entrada: ${room.entryFee})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isCurrentLobbyBg = PlayerSession.shared.selectedThemeId == 'room_fondo_${room.id}';
    final hasWonRoom = widget.manager.getTrophies(room.id) > 0 || isUnlocked;

    return Row(
      children: [
        if (hasWonRoom) ...[
          Tooltip(
            message: isCurrentLobbyBg
                ? 'Fondo activo en el Menú Principal'
                : 'Usar fondo de ${room.name} en el Menú Principal',
            child: CartoonRoundButton(
              width: 38,
              height: 38,
              borderRadius: 12,
              backgroundColor: isCurrentLobbyBg ? const Color(0xFF059669) : const Color(0xFF2E267D),
              borderColor: isCurrentLobbyBg ? const Color(0xFF34D399) : const Color(0xFF4C3E9E),
              onPressed: () {
                HapticFeedback.selectionClick();
                PlayerSession.shared.selectedThemeId = 'room_fondo_${room.id}';
                PlayerSession.shared.save();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡Fondo de ${room.name} aplicado al Menú Principal! 🎨'),
                    backgroundColor: room.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Icon(
                isCurrentLobbyBg ? Icons.wallpaper_rounded : Icons.palette_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: App3dButton(
            height: 40,
            borderRadius: 14,
            variant: App3dButtonVariant.emerald,
            onPressed: () => _onPlayRoom(room),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'JUGAR (🪙 ${room.entryFee})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback visual en caso de que el asset de marco no esté disponible
  Widget _buildFallbackFrame(VenezuelaRoomTier room, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: room.accentColor.withValues(alpha: 0.6),
          width: 3,
        ),
      ),
    );
  }
}
