import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/user_progress.dart';
import '../../economy/rank_system.dart';
import '../../economy/achievement_catalog.dart';
import 'profile_and_level_modal.dart';
import 'user_frame_view.dart';
import 'rank_badge_widget.dart';
import 'game_toast_queue.dart';

/// Modal oficial "Perfil del Jugador" que unifica la vista de estadísticas de juego
/// detalladas (Generales, Jugadas de Caída y Cantos Tradicionales) y la pestaña de Logros.
/// Rediseñado con estética oscura, elegante y sobria con bordes neutros (#2E2E2E)
/// a juego completo con ProfileAndLevelModal e InventoryModal.
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

  /// Muestra el modal en pantalla de forma centrada.
  static Future<void> show(
    BuildContext context, {
    PlayerSession? session,
    PlayerStatsModel? stats,
    int initialTabIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
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

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
              maxHeight: 580,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
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
                  // 1. Cabecera integrada moderna con botón de cerrar
                  _buildHeader(),

                  // 2. Barra de Pestañas (Perfil | Logros)
                  _buildTabsRow(),

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
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              const Icon(Icons.query_stats_rounded, color: Colors.white70, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Perfil del jugador',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
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
                            alignment: Alignment.center,
                            children: [
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progressRatio.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              Text(
                                '$currentTierXp de $neededTierXp XP',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
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
                              backgroundColor: const Color(0xFF262626),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_stats.trophies} 🏆',
                          style: const TextStyle(
                            color: Colors.white70,
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
    final achievements = AchievementCatalog.allAchievements;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: achievements.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ach = achievements[index];
        final currentProgress = ach.getProgress(_stats);
        final isClaimed = _stats.claimedAchievementIds.contains(ach.id);
        final isUnlocked = AchievementCatalog.isUnlocked(ach, _stats);
        final reqItem = AchievementCatalog.getRequirement(ach);
        final isCompleted = isUnlocked && currentProgress >= ach.targetProgress;
        final progressRatio = isUnlocked
            ? (currentProgress / ach.targetProgress).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF2E2E2E),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Icono con indicador de candado si está bloqueado por nivel
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFF242424),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ach.icon,
                      color: isUnlocked ? Colors.white70 : Colors.white30,
                      size: 22,
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF333333),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white70,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 10),

              // Información del logro y progreso
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                color: isClaimed || !isUnlocked
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF262626),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                ach.levelBadge,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            Text(
                              '+${ach.coinReward}',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ach.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                      ),
                    ),
                    if (!isUnlocked && reqItem != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 11, color: Colors.white38),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Requiere completar nivel ${reqItem.levelBadge}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Barra de progreso
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: const Color(0xFF262626),
                              valueColor: AlwaysStoppedAnimation(
                                !isUnlocked
                                    ? Colors.white24
                                    : (isCompleted
                                        ? const Color(0xFF10B981)
                                        : Colors.white70),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isUnlocked
                              ? '${currentProgress.clamp(0, ach.targetProgress)} / ${ach.targetProgress}'
                              : '0 / ${ach.targetProgress}',
                          style: TextStyle(
                            color: isUnlocked ? Colors.white70 : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Botón o Etiqueta de Estado
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Reclamado',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!isUnlocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 11, color: Colors.white38),
                      SizedBox(width: 3),
                      Text(
                        'Bloqueado',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(60, 28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _stats.claimAchievement(ach.id);
                    _session.addCoins(ach.coinReward);
                    _session.addXp(ach.xpReward);
                    GameToastQueue.showAchievement(
                      context,
                      title: ach.title,
                      description: ach.description,
                      icon: ach.icon,
                      iconColor: ach.iconColor,
                      coinReward: ach.coinReward,
                      xpReward: ach.xpReward,
                    );
                    setState(() {});
                  },
                  child: const Text(
                    'Reclamar',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: const Text(
                    'En curso',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
