import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/rank_system.dart';
import 'player_profile_stats_modal.dart';
import 'user_frame_view.dart';

/// Modal rápido emergente de perfil para ver estadísticas de cualquier jugador
/// o bot al presionar su avatar en la mesa de juego.
class PlayerQuickProfileDialog extends StatelessWidget {
  final String playerName;
  final int avatarId;
  final String? avatarUrl;
  final String? frameId;
  final int level;
  final bool isLocalUser;
  final bool isBot;
  final bool isTeammate;
  final int trophies;
  final int gamesWon;
  final int gamesPlayed;
  final int caidasMade;
  final int matchScore;
  final int matchCardsWon;

  const PlayerQuickProfileDialog({
    super.key,
    required this.playerName,
    required this.avatarId,
    this.avatarUrl,
    this.frameId,
    required this.level,
    this.isLocalUser = false,
    this.isBot = false,
    this.isTeammate = false,
    required this.trophies,
    required this.gamesWon,
    required this.gamesPlayed,
    required this.caidasMade,
    required this.matchScore,
    required this.matchCardsWon,
  });

  static Future<void> show(
    BuildContext context, {
    required String playerName,
    required int avatarId,
    String? avatarUrl,
    String? frameId,
    required int level,
    bool isLocalUser = false,
    bool isBot = false,
    bool isTeammate = false,
    required int trophies,
    required int gamesWon,
    required int gamesPlayed,
    required int caidasMade,
    required int matchScore,
    required int matchCardsWon,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (_) => PlayerQuickProfileDialog(
        playerName: playerName,
        avatarId: avatarId,
        avatarUrl: avatarUrl,
        frameId: frameId,
        level: level,
        isLocalUser: isLocalUser,
        isBot: isBot,
        isTeammate: isTeammate,
        trophies: trophies,
        gamesWon: gamesWon,
        gamesPlayed: gamesPlayed,
        caidasMade: caidasMade,
        matchScore: matchScore,
        matchCardsWon: matchCardsWon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rank = RankInfo.forTrophies(trophies);
    final rankName = rank.fullNameFor(trophies);
    final winRate = gamesPlayed > 0 ? ((gamesWon / gamesPlayed) * 100).round() : 0;

    String roleLabel = 'RIVAL';
    Color roleColor = const Color(0xFFEF4444);
    if (isLocalUser) {
      roleLabel = 'TÚ';
      roleColor = AppPalette.cartoonCyan;
    } else if (isTeammate) {
      roleLabel = 'COMPAÑERO';
      roleColor = const Color(0xFF10B981);
    } else if (isBot) {
      roleLabel = 'BOT IA';
      roleColor = const Color(0xFF818CF8);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B4B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera superior con rol e icono cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: roleColor.withValues(alpha: 0.6), width: 1.2),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  TactilePressable(
                    depth: 2.0,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppPalette.cartoonBorder, width: 1.0),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar, Nombre y Nivel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  UserFrameView(
                    avatarIndex: avatarId,
                    avatarUrl: avatarUrl,
                    frameId: frameId ?? 'rank_novato',
                    size: 72,
                    level: level,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rango y trofeos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: rank.gradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rank.icon, color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          '$rankName • $trophies Trofeos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Fila de Estadísticas Generales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Victorias', '$gamesWon', Icons.emoji_events_rounded, const Color(0xFFFDE047)),
                    Container(width: 1, height: 28, color: Colors.white12),
                    _buildStatItem('% Victorias', '$winRate%', Icons.pie_chart_rounded, const Color(0xFF38BDF8)),
                    Container(width: 1, height: 28, color: Colors.white12),
                    _buildStatItem('Caídas', '$caidasMade', Icons.flash_on_rounded, const Color(0xFFF43F5E)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Fila de Estado en la Partida Actual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26206D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'En esta partida:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$matchScore pts • $matchCardsWon cartas',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Botones inferiores
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (isLocalUser) ...[
                    Expanded(
                      child: App3dButton(
                        label: 'VER PERFIL COMPLETO',
                        variant: App3dButtonVariant.cyan,
                        depth: 3.5,
                        height: 40,
                        borderRadius: 12,
                        onPressed: () {
                          Navigator.of(context).pop();
                          PlayerProfileStatsModal.show(context);
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: App3dButton(
                        label: 'CERRAR',
                        variant: App3dButtonVariant.dark,
                        depth: 3.5,
                        height: 40,
                        borderRadius: 12,
                        onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
