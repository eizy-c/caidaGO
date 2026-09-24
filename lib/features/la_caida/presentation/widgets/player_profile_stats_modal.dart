import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/user_progress.dart';
import '../../economy/rank_system.dart';
import '../../economy/achievement_catalog.dart';
import '../../economy/trophy_session_manager.dart';
import '../../../../core/theme/app_palette.dart';
import 'profile_and_level_modal.dart';
import 'user_frame_view.dart';
import 'rank_badge_widget.dart';
import 'game_toast_queue.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';

/// Modal oficial "Perfil del Jugador" que unifica la vista de estadísticas de juego
/// detalladas (Generales, Jugadas de Caída y Cantos Tradicionales) y la pestaña de Logros.
/// Rediseñado con estética Cartoon Indigo a juego con el Lobby y demás módulos.

class PlayerProfileStatsModal extends StatefulWidget {
  final PlayerSession? session;
  final PlayerStatsModel? stats;
  final int initialTabIndex;

  const PlayerProfileStatsModal({
    super.key,
    this.session,
    this.stats,
    this.initialTabIndex = 0,
  });

  /// Muestra el modal en pantalla como un bottom sheet deslizable desde abajo.
  static Future<void> show(
    BuildContext context, {
    PlayerSession? session,
    PlayerStatsModel? stats,
    int initialTabIndex = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => PlayerProfileStatsModal(
        session: session,
        stats: stats,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<PlayerProfileStatsModal> createState() => _PlayerProfileStatsModalState();
}

class _PlayerProfileStatsModalState extends State<PlayerProfileStatsModal> {
  late int _selectedTabIndex;
  late PlayerSession _session;
  late PlayerStatsModel _stats;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _session = widget.session ?? PlayerSession.shared;
    _stats = widget.stats ?? PlayerStatsModel.shared;
  }

  void _openProfileEditor() async {
    await ProfileAndLevelModal.show(context, session: _session);
    if (mounted) setState(() {});
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_session, _stats, TrophySessionManager.shared]),
      builder: (context, _) {
        final progress = UserProgress(totalXp: _session.xp);
        final level = progress.currentLevel;
        final currentTierXp = progress.currentTierXp;
        final neededTierXp = progress.neededInCurrentTier;
        final progressRatio = progress.levelProgressPercentage;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E267D), Color(0xFF26206D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Cabecera estilo cartoon con cápsula naranja y botón (X)
                  _buildHeader(),

                  // 2. Barra de Pestañas (Perfil | Logros)
                  _buildTabsRow(),

                  const SizedBox(height: 6),

                  // 3. Contenido interior de las pestañas
                  Expanded(
                    child: _selectedTabIndex == 0
                        ? _buildProfileTab(progress, level, currentTierXp, neededTierXp, progressRatio)
                        : _buildAchievementsTab(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Cabecera moderna integrada en la ventana modal
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7A3D), Color(0xFFF95B16)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEA580C), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Perfil del jugador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
TactilePressable(
            depth: 2.5,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.redDanger,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),

          ),
        ],
      ),
    );
  }

  /// Barra de Pestañas integrada y sobria
  Widget _buildTabsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppPalette.cartoonBgDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TactilePressable(
              depth: 1.5,
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 0 ? AppGradients.cyanAccent : null,
                  color: _selectedTabIndex == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Perfil',
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TactilePressable(
              depth: 1.5,
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 1 ? AppGradients.cyanAccent : null,
                  color: _selectedTabIndex == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Logros',
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pestaña 1: Perfil de Jugador con Estadísticas Completas
  Widget _buildProfileTab(
    UserProgress progress,
    int level,
    int currentTierXp,
    int neededTierXp,
    double progressRatio,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tarjeta Superior de Identidad del Jugador
          _buildPlayerHeaderCard(progress, level, currentTierXp, neededTierXp, progressRatio),

          const SizedBox(height: 12),

          // 2. Tarjeta de Rango Competitivo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.cartoonCardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    const Text(
                      'Rango Competitivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    RankBadgeWidget(trophies: _stats.trophies),
                  ],
                ),
                const SizedBox(height: 10),
                RankProgressBar(trophies: _stats.trophies, height: 8),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Columnas de Estadísticas (Layout Responsivo)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 460;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna Izquierda: Estadísticas Generales
                    Expanded(
                      flex: 5,
                      child: _buildGeneralStatsSection(),
                    ),
                    const SizedBox(width: 14),
                    // Columna Derecha: Jugadas de Caída y Cantos Tradicionales
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaidaPlaysSection(),
                          const SizedBox(height: 12),
                          _buildTraditionalCantosSection(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralStatsSection(),
                    const SizedBox(height: 14),
                    _buildCaidaPlaysSection(),
                    const SizedBox(height: 14),
                    _buildTraditionalCantosSection(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Cabecera de Identidad del Jugador (Avatar + Marco + Nombre + Nivel/XP + Barra de Rango + Título)
  Widget _buildPlayerHeaderCard(
    UserProgress progress,
    int level,
    int currentTierXp,
    int neededTierXp,
    double progressRatio,
  ) {
    final playerName = _session.name.trim().isNotEmpty ? _session.name : 'Yoangel Eizaga';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar con Marco y Etiqueta de Nivel integrada
          UserFrameView(
            frameId: _session.selectedFrameId,
            avatarIndex: _session.avatarIndex,
            level: level,
            size: 64,
            showLevelBadge: true,
            onTap: _openProfileEditor,
          ),

          const SizedBox(width: 14),

          // Nombre, Barra de XP, Barra de Rango y Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: Nombre + Botón [ EDITAR ]
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openProfileEditor,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppPalette.cartoonBgDark,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppPalette.cartoonBorder, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: Colors.white70, size: 12),
                            SizedBox(width: 3),
                            Text(
                              'EDITAR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Fila 2: Nivel X [====...] XX de YY XP
                Row(
                  children: [
                    Text(
                      'Nivel $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppPalette.cartoonBgDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppPalette.cartoonBorder, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progressRatio.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: AppGradients.greenAccept,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '$currentTierXp de $neededTierXp XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Fila 3: Barra de rango abajo del nivel
                Builder(
                  builder: (context) {
                    final rankProg = RankProgress(trophies: _stats.trophies);
                    final rank = rankProg.currentRank;
                    final fullName = rank.fullNameFor(_stats.trophies);
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.cartoonBgDark,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppPalette.cartoonBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(rank.icon, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: rankProg.progressInTier,
                              minHeight: 7,
backgroundColor: AppPalette.cartoonBgDark,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),

                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_stats.trophies}',
                              style: TextStyle(
                                color: rank.secondaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.emoji_events_rounded, size: 10, color: rank.secondaryColor),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 6),

                // Fila 4: Píldora de Título de Nivel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppPalette.cartoonBgDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1),
                  ),
                  child: Text(
                    'Título: "${progress.rankTitle}"',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sección: Estadísticas Generales
  Widget _buildGeneralStatsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADÍSTICAS GENERALES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          _buildStatItem('Ganancias totales', _formatNumber(_stats.totalEarnings), hasCoinIcon: true),
          _buildStatItem('Partidas jugadas / Ganadas', '${_stats.gamesPlayed} (${_stats.gamesWon} ganadas)'),
          _buildStatItem('Efectividad de victoria', '${_stats.winRatePercentage}%'),
          _buildStatItem('Racha actual / Máxima', '${_stats.currentStreak} / ${_stats.maxStreak}'),
          _buildStatItem('Mano a mano (1 vs 1)', '${_stats.soloWins} ganada${_stats.soloWins == 1 ? '' : 's'}'),
          _buildStatItem('Partidas en equipo (2 vs 2)', '${_stats.teamWins} ganada${_stats.teamWins == 1 ? '' : 's'}'),
        ],
      ),
    );
  }

  /// Sección: Jugadas y Mesa (Caída)
  Widget _buildCaidaPlaysSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JUGADAS Y MESA (CAÍDA)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          _buildStatItem('Caídas cantadas (rival cazado)', '${_stats.caidasMade}'),
          _buildStatItem('Caídas recibidas', '${_stats.caidasReceived}'),
          _buildStatItem('Mesas limpias', '${_stats.mesasLimpias}'),
          _buildStatItem('Caídas con mesa limpia', '${_stats.caidasWithLimpia}'),
          _buildStatItem('Registros / Registrícos', '${_stats.registros}'),
          _buildStatItem('Total cartas acumuladas', _formatNumber(_stats.totalCardsWon)),
        ],
      ),
    );
  }

  /// Sección: Cantos Tradicionales
  Widget _buildTraditionalCantosSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CANTOS TRADICIONALES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          _buildStatItem('Rondas', '${_stats.rondas}'),
          _buildStatItem('Patrullas', '${_stats.patrullas}'),
          _buildStatItem('Vigías', '${_stats.vigias}'),
          _buildStatItem('Trivilines cantados', '${_stats.trivilines}'),
        ],
      ),
    );
  }

  /// Fila individual de estadística con etiqueta a la izquierda y valor a la derecha
  Widget _buildStatItem(String label, String value, {Color? valueColor, bool hasCoinIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCoinIcon) ...[
                const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFFF59E0B)),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Medalla cartoon con listón superior y medalla circular con estrella dorada/metálica.
  Widget _buildCartoonMedal({
    required int level,
    required bool isEarned,
    required bool isCurrent,
  }) {
    final ribbonColors = isEarned
        ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
        : [const Color(0xFF1E174D), const Color(0xFF17113E)];

    final ribbonBorder = isEarned ? const Color(0xFF991B1B) : const Color(0xFF2A2066);

    List<Color> medalColors;
    Color medalBorder;
    Color starColor;

    if (isEarned) {
      switch (level) {
        case 1:
          medalColors = const [Color(0xFFF59E0B), Color(0xFFD97706)];
          medalBorder = const Color(0xFFB45309);
          starColor = Colors.white;
          break;
        case 2:
          medalColors = const [Color(0xFFF1F5F9), Color(0xFF94A3B8)];
          medalBorder = const Color(0xFF64748B);
          starColor = Colors.white;
          break;
        case 3:
        default:
          medalColors = const [Color(0xFFFEF08A), Color(0xFFEAB308)];
          medalBorder = const Color(0xFFCA8A04);
          starColor = const Color(0xFF78350F);
          break;
      }
    } else {
      medalColors = [const Color(0xFF221A5C), const Color(0xFF1A1349)];
      medalBorder = const Color(0xFF33277A);
      starColor = Colors.white12;
    }

    return SizedBox(
      width: 25,
      height: 35,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Listón / Cinta superior
          Container(
            width: 14,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ribbonColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
              border: Border.all(color: ribbonBorder, width: 0.8),
            ),
          ),
          // Medalla circular inferior
          Positioned(
            top: 11,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: medalColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: medalBorder, width: 1.2),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: medalColors.first.withValues(alpha: 0.45),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: starColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Medalla o escudo exclusivo para conquistas de Sala Regional (1 solo nivel).
  Widget _buildSingleRegionalMedal({
    required bool isEarned,
    required IconData icon,
    required Color iconColor,
  }) {
    final ribbonColors = isEarned
        ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
        : [const Color(0xFF1E174D), const Color(0xFF17113E)];
    final ribbonBorder = isEarned ? const Color(0xFFB45309) : const Color(0xFF2A2066);

    final medalColors = isEarned
        ? const [Color(0xFFFEF08A), Color(0xFFEAB308), Color(0xFFCA8A04)]
        : const [Color(0xFF221A5C), Color(0xFF1A1349)];
    final medalBorder = isEarned ? const Color(0xFFCA8A04) : const Color(0xFF33277A);

    return SizedBox(
      width: 38,
      height: 44,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Listón / Cinta superior
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ribbonColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border.all(color: ribbonBorder, width: 0.9),
            ),
          ),
          // Medalla circular destacada inferior
          Positioned(
            top: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: medalColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: medalBorder, width: 1.5),
                boxShadow: isEarned
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  isEarned ? icon : Icons.lock_outline_rounded,
                  size: 16,
                  color: isEarned ? const Color(0xFF78350F) : Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pestaña 2: Logros y Misiones de La Caída (Agrupados en series de 3 Medallas)
  Widget _buildAchievementsTab() {
    final groups = AchievementCatalog.familyGroups;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final activeItem = group.activeLevel(_stats);
        final claimedCount = group.claimedMedalsCount(_stats);
        final isFullyClaimed = group.isFullyClaimed(_stats);
        final currentProgress = activeItem.getProgress(_stats);
        final isClaimable = group.isClaimable(_stats);
        final progressRatio = isFullyClaimed
            ? 1.0
            : (activeItem.targetProgress > 0
                ? (currentProgress / activeItem.targetProgress).clamp(0.0, 1.0)
                : 0.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppPalette.cartoonCardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isClaimable
                  ? const Color(0xFF10B981)
                  : (isFullyClaimed
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                      : AppPalette.cartoonBorder),
              width: isClaimable ? 2.0 : 1.6,
            ),
            boxShadow: isClaimable
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0xFF151042),
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cuerpo Principal: Medallas + Título, Descripción y Barra
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Medallas (1 única para salas regionales, o 3 para misiones multi-nivel)
                      SizedBox(
                        width: 84,
                        child: group.isSingleTier
                            ? Center(
                                child: _buildSingleRegionalMedal(
                                  isEarned: claimedCount > 0,
                                  icon: activeItem.icon,
                                  iconColor: activeItem.iconColor,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) {
                                  final isEarned = i < claimedCount;
                                  final isCurrent = i == claimedCount;
                                  return Padding(
                                    padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
                                    child: _buildCartoonMedal(
                                      level: i + 1,
                                      isEarned: isEarned,
                                      isCurrent: isCurrent,
                                    ),
                                  );
                                }),
                              ),
                      ),

                      const SizedBox(width: 10),

                      // Título, Descripción y Barra de Progreso
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFullyClaimed
                                  ? (group.isSingleTier
                                      ? '¡Sala completada y trofeo conquistado!'
                                      : '¡Todos los niveles completados con éxito!')
                                  : activeItem.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isFullyClaimed ? const Color(0xFFFDE047) : Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 7),

                            // Barra de Progreso Estilo Cartoon con texto centrado
                            Container(
                              height: 18,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF15103E),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final totalWidth = constraints.maxWidth;
                                  final fillWidth = (totalWidth * progressRatio).clamp(0.0, totalWidth);
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Relleno de la barra proporcional al avance real
                                      if (fillWidth > 0)
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: fillWidth,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isFullyClaimed
                                                    ? const [Color(0xFF10B981), Color(0xFF34D399)]
                                                    : (isClaimable
                                                        ? const [Color(0xFF059669), Color(0xFF10B981)]
                                                        : const [Color(0xFF0284C7), Color(0xFF38BDF8)]),
                                              ),
                                              borderRadius: BorderRadius.horizontal(
                                                left: const Radius.circular(8),
                                                right: Radius.circular(progressRatio >= 0.98 ? 8 : 2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Texto de progreso centrado
                                      Center(
                                        child: Text(
                                          isFullyClaimed
                                              ? 'COMPLETADO'
                                              : '${currentProgress.clamp(0, activeItem.targetProgress)} / ${activeItem.targetProgress}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                            shadows: [
                                              Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(0, 1)),
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
                      ),

                      // Botón Reclamar (si está listo para cobrar)
                      if (isClaimable) ...[
                        const SizedBox(width: 8),
                        App3dButton(
                          label: 'Reclamar',
                          variant: App3dButtonVariant.emerald,
                          depth: 2.5,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          onPressed: () {
                            _stats.claimAchievement(activeItem.id);
                            _session.addCoins(activeItem.coinReward);
                            _session.addXp(activeItem.xpReward);
                            GameToastQueue.showAchievement(
                              context,
                              title: activeItem.title,
                              description: activeItem.description,
                              icon: activeItem.icon,
                              iconColor: activeItem.iconColor,
                              coinReward: activeItem.coinReward,
                              xpReward: activeItem.xpReward,
                            );
                            setState(() {});
                          },
                          child: const Text(
                            'Reclamar',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. Franja Inferior: Recompensas Oficiales (XP y Monedas) con fondo contrastante
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D1754),
                    border: Border(
                      top: BorderSide(color: Color(0xFF2E2578), width: 1.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Recompensas:',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Recompensa XP
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star_rounded, size: 11, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFullyClaimed ? 'Max XP' : '${activeItem.xpReward} XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 16),

                      // Recompensa Monedas
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            isFullyClaimed ? 'Completado' : '${activeItem.coinReward}',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Indicador de Nivel / Medalla actual
                      Text(
                        group.isSingleTier
                            ? (isFullyClaimed ? '¡Conquistada!' : 'Sala Regional')
                            : (isFullyClaimed
                                ? '3 / 3'
                                : '${claimedCount + 1} / 3 Medallas'),
                        style: TextStyle(
                          color: isFullyClaimed
                              ? const Color(0xFF34D399)
                              : (group.isSingleTier
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white54),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
