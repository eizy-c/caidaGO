import 'package:flutter/material.dart';
import '../../economy/achievement_catalog.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptic_service.dart';

/// Tarjeta de logro estilo cartoon basada fielmente en la interfaz de referencia:
/// - Fila de 3 medallas secuenciales a la izquierda (Bronce, Plata, Oro).
/// - Título temático y descripción del nivel activo a la derecha.
/// - Barra de progreso tipo cápsula azul con texto centrado 'X / Y'.
/// - Franja inferior de recompensas con XP, Monedas y botón interactivo 'RECLAMAR'.
class AchievementCardWidget extends StatelessWidget {
  final AchievementFamilyGroup family;
  final PlayerStatsModel stats;
  final PlayerSession session;
  final VoidCallback onClaimed;

  const AchievementCardWidget({
    super.key,
    required this.family,
    required this.stats,
    required this.session,
    required this.onClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final active = family.activeLevel(stats);
    final claimedCount = family.claimedMedalsCount(stats);
    final isFullyClaimed = family.isFullyClaimed(stats);
    final currentProgress = active.getProgress(stats);
    final isClaimable = !isFullyClaimed && currentProgress >= active.targetProgress;
    final progressRatio = isFullyClaimed
        ? 1.0
        : (currentProgress / active.targetProgress).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimable ? const Color(0xFFF59E0B) : const Color(0xFFE5D5B5),
          width: isClaimable ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isClaimable
                ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isClaimable ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Parte superior: Medallas + Información
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Medallas horizontales a la izquierda
                _buildMedalsRow(claimedCount),
                const SizedBox(width: 12),

                // Título y Descripción de la meta actual
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.title,
                        style: const TextStyle(
                          color: Color(0xFF451A03),
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isFullyClaimed
                            ? '¡Has completado todos los niveles de esta serie!'
                            : active.description,
                        style: const TextStyle(
                          color: Color(0xFF78350F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Barra de Progreso Cápsula Azul
                      _buildPillProgressBar(
                        progressRatio: progressRatio,
                        current: isFullyClaimed
                            ? active.targetProgress
                            : currentProgress.clamp(0, active.targetProgress),
                        target: active.targetProgress,
                        isComplete: isFullyClaimed || isClaimable,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Franja inferior de Recompensas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: const BoxDecoration(
              color: Color(0xFFF8EFE0),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(
                top: BorderSide(color: Color(0xFFEADBBE), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Etiqueta Recompensas + XP + Monedas
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recompensas:',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Estrella de XP
                    _buildRewardPill(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      label: 'XP ${active.xpReward}',
                      textColor: const Color(0xFF92400E),
                    ),
                    const SizedBox(width: 8),

                    // Monedas
                    _buildRewardPill(
                      icon: Icons.monetization_on_rounded,
                      iconColor: const Color(0xFFEAB308),
                      label: _formatRewardNumber(active.coinReward),
                      textColor: const Color(0xFF92400E),
                    ),
                  ],
                ),

                // Botón Reclamar o Estado
                if (isClaimable)
                  GestureDetector(
                    onTap: () {
                      HapticService.instance.onSelection();
                      AudioService().playCanto('ronda');
                      stats.claimAchievement(active.id);
                      session.rewardCoins(active.coinReward, xpGain: active.xpReward);
                      onClaimed();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.redeem_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'RECLAMAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isFullyClaimed)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEADBBE).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Nivel ${claimedCount + 1}/3',
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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

  /// Construye las 3 medallas secuenciales idénticas a la imagen de referencia:
  /// Las medallas reclamadas tienen su cinta roja y medalla dorada/metálica brillante.
  /// Las pendientes se muestran en silueta beige con bajo relieve.
  Widget _buildMedalsRow(int claimedCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isClaimed = index < claimedCount;
        return Padding(
          padding: EdgeInsets.only(right: index < 2 ? 4.0 : 0.0),
          child: _buildSingleMedal(index: index, isClaimed: isClaimed),
        );
      }),
    );
  }

  Widget _buildSingleMedal({required int index, required bool isClaimed}) {
    if (isClaimed) {
      // Medalla ganada con cinta roja y medalla dorada/metálica brillante
      final List<Color> medalGradient = index == 0
          ? const [Color(0xFFD97706), Color(0xFFB45309)] // Bronce
          : (index == 1
              ? const [Color(0xFFE2E8F0), Color(0xFF94A3B8)] // Plata
              : const [Color(0xFFFDE047), Color(0xFFEAB308)]); // Oro

      final Color borderColor = index == 1 ? Colors.white : const Color(0xFFCA8A04);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cinta roja superior con pliegue
          Container(
            width: 14,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              border: Border.all(color: const Color(0xFF991B1B), width: 0.6),
            ),
          ),
          // Medallón circular metálico con estrella
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: medalGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else {
      // Silueta en bajo relieve beige (como se aprecia en la imagen de referencia)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cinta en silueta
          Container(
            width: 14,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFEADBBE),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              border: Border.all(color: const Color(0xFFD8C7A5), width: 0.6),
            ),
          ),
          // Medalla en silueta beige
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEADBBE),
              border: Border.all(color: const Color(0xFFD8C7A5), width: 1.2),
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded,
                size: 13,
                color: Color(0xFFD8C7A5),
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Barra de progreso estilo cápsula redondeada con degradado azul celeste y texto centrado
  Widget _buildPillProgressBar({
    required double progressRatio,
    required int current,
    required int target,
    required bool isComplete,
  }) {
    return Container(
      height: 19,
      decoration: BoxDecoration(
        color: const Color(0xFFEADBBE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8C7A5), width: 1.0),
      ),
      child: Stack(
        children: [
          // Relleno de progreso azul celeste con brillo
          FractionallySizedBox(
            widthFactor: progressRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF0284C7),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Texto centrado X / Y
          Center(
            child: Text(
              '$current / $target',
              style: TextStyle(
                color: progressRatio > 0.4 ? Colors.white : const Color(0xFF451A03),
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                letterSpacing: 0.4,
                shadows: progressRatio > 0.4
                    ? const [
                        Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatRewardNumber(int number) {
    if (number >= 1000) {
      final k = (number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1);
      return '$k K';
    }
    return '$number';
  }
}
