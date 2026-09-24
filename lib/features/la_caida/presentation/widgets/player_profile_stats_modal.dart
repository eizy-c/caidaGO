import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/user_progress.dart';
import '../../economy/rank_system.dart';
import '../../economy/achievement_catalog.dart';
import 'achievement_card_widget.dart';
import 'profile_and_level_modal.dart';
import 'user_frame_view.dart';
import 'rank_badge_widget.dart';

/// Modal oficial "Perfil del Jugador" que unifica la vista de estadísticas de juego
/// detalladas (Generales, Jugadas de Caída y Cantos Tradicionales) y la pestaña de Logros.
/// Rediseñado con estética de panel inferior deslizable (Bottom Sheet) y tarjetas estilo cartoon.
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
      animation: Listenable.merge([_session, _stats]),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: Color(0xFF2E2E2E), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 24,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle superior para deslizar hacia abajo
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? const Color(0xFF2E2E2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Perfil',
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? const Color(0xFF2E2E2E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Logros',
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF333333), width: 1),
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
                          color: const Color(0xFF262626),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF333333), width: 0.8),
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
                                      color: const Color(0xFF22C55E),
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
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF333333), width: 0.8),
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
                              backgroundColor: rank.primaryColor.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(rank.secondaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_stats.trophies} 🏆',
                          style: TextStyle(
                            color: rank.secondaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E2E2E), width: 0.8),
                  ),
                  child: Text(
                    'Título: "${progress.rankTitle}"',
                    style: const TextStyle(
                      color: Colors.white60,
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
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

  /// Pestaña 2: Logros y Misiones de La Caída (Categorías y niveles progresivos)
  Widget _buildAchievementsTab() {
    final families = AchievementCatalog.familyGroups;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      itemCount: families.length,
      itemBuilder: (context, index) {
        final family = families[index];
        return AchievementCardWidget(
          family: family,
          stats: _stats,
          session: _session,
          onClaimed: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }
}
