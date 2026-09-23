import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
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
                colors: [Color(0xFF0F172A), Color(0xFF020617)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black87,
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
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Cabecera con balance de monedas y total de trofeos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Botón cerrar
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          ),
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
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Venezuela • Progresión por Trofeos',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Píldora de Trofeos Totales
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFB45309)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE047), width: 1),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
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

  /// Selector de Modo Segmentado [ Duelo 1 vs 1 ] y [ Parejas 2 vs 2 ]
  Widget _buildModeSegmentedSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
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
              ? const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
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
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.white38,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta naipe vertical (~260x370 dp) de una sala
  Widget _buildRoomCard(VenezuelaRoomTier room) {
    final isUnlocked = widget.manager.isRoomUnlocked(room.id);
    final trophies = widget.manager.getTrophies(room.id);
    final trophyProgress = widget.manager.getTrophyProgress(room.id);
    final isCompleted = widget.manager.isRoomCompleted(room.id);
    final canAfford = widget.manager.canAfford(room.entryFee);
    final prizePerWinner = room.getPrizePerWinner(_selectedMode);
    final totalPot = room.getTotalPot(_selectedMode);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked ? room.gradientColors : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked
              ? (room.isFrozenTheme ? const Color(0xFF7DD3FC) : room.accentColor)
              : Colors.white12,
          width: isUnlocked ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? room.primaryColor.withValues(alpha: 0.35)
                : Colors.black54,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Resplandor de fondo escarchado o luminoso
            if (room.isFrozenTheme && isUnlocked)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                  ),
                ),
              ),

            // Contenido principal de la tarjeta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabecera: Nombre de la Sala, Región y Subtítulo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    room.name.toUpperCase(),
                                    style: TextStyle(
                                      color: isUnlocked ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (room.isFrozenTheme) ...[
                                  const SizedBox(width: 4),
                                  const Text('❄️', style: TextStyle(fontSize: 13)),
                                ],
                              ],
                            ),
                            Text(
                              room.region,
                              style: TextStyle(
                                color: isUnlocked ? room.accentColor : Colors.white38,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contador de Jugadores Activos
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
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
                              '${room.simulatedActivePlayers}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Subtítulo temático
                  const SizedBox(height: 3),
                  Text(
                    '"${room.subtitle}"',
                    style: TextStyle(
                      color: isUnlocked ? Colors.white60 : Colors.white24,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 2. Ilustración Central / Anillo con Marco de Mesa
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120, maxWidth: 120),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Imagen del Marco Oficial
                            Image.asset(
                              room.frameAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => _buildFallbackFrame(room, isUnlocked),
                            ),

                            // Icono de Candado si está bloqueada
                            if (!isUnlocked)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.75),
                                  border: Border.all(color: Colors.white24, width: 2),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Color(0xFFFDE047),
                                  size: 28,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Caja de Premio y Pozo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Premio por Ganador
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedMode == GameMode.teams2v2 ? 'PREMIO C/U' : 'PREMIO GANADOR',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '$prizePerWinner',
                                      style: const TextStyle(
                                        color: Color(0xFFFDE047),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Pozo Total
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'POZO TOTAL',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '🪙 $totalPot',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'SALA COMPLETADA' : 'TROFEOS DE SALA',
                                style: TextStyle(
                                  color: isCompleted ? const Color(0xFFFDE047) : Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$trophies / ${room.trophyCap}',
                            style: TextStyle(
                              color: isCompleted ? const Color(0xFFFDE047) : Colors.white,
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
                              style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 8.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              room.lossTrophies == 0 ? 'Derrota: 0 🏆' : 'Derrota: ${room.lossTrophies} 🏆',
                              style: const TextStyle(color: Color(0xFFF87171), fontSize: 8.5, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 5. Botón Inferior de Acción
                  _buildActionButton(room, isUnlocked, canAfford),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de acción según el estado de desbloqueo y balance
  Widget _buildActionButton(VenezuelaRoomTier room, bool isUnlocked, bool canAfford) {
    if (!isUnlocked) {
      final remaining = widget.manager.getRemainingTrophiesForUnlock(room.id);
      final prevRoom = VenezuelaRoomCatalog.getPreviousRoom(room.id);
      final prevName = prevRoom != null ? prevRoom.name : 'Sala anterior';

      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
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
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: const Center(
          child: Text(
            '🪙 FICHAS INSUFICIENTES',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return App3dButton(
      height: 44,
      borderRadius: 14,
      variant: App3dButtonVariant.emerald,
      onPressed: () => _onPlayRoom(room),
      child: Center(
        child: Row(
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
    );
  }

  /// Fallback visual en caso de que el asset de marco no esté disponible
  Widget _buildFallbackFrame(VenezuelaRoomTier room, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            room.accentColor.withValues(alpha: 0.5),
            room.primaryColor,
          ],
        ),
        border: Border.all(
          color: room.accentColor,
          width: 3,
        ),
      ),
      child: Center(
        child: Icon(
          room.isFrozenTheme ? Icons.ac_unit_rounded : Icons.casino_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}
