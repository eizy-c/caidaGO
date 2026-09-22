import 'package:flutter/material.dart';

class GameResultEntry {
  final String name;
  final int scoreChange; // Ej. +2000, -1000
  final bool isWinner;
  final bool isUser;

  const GameResultEntry({
    required this.name,
    required this.scoreChange,
    this.isWinner = false,
    this.isUser = false,
  });
}

/// Modal emergente de fin de partida (¡HAS GANADO! o ¡HAS PERDIDO!).
/// Incluye banner estilizado, podio con corona dorada, puntuaciones de cada jugador
/// y botones de acción: Atrás, Lobby y Revancha con paleta unificada.
class GameResultDialog extends StatelessWidget {
  final bool userWon;
  final String? subtitle;
  final List<GameResultEntry> entries;
  final VoidCallback onRematch;
  final VoidCallback onBackToMenu;

  const GameResultDialog({
    super.key,
    required this.userWon,
    this.subtitle,
    required this.entries,
    required this.onRematch,
    required this.onBackToMenu,
  });

  static Future<void> show(
    BuildContext context, {
    required bool userWon,
    String? subtitle,
    required List<GameResultEntry> entries,
    required VoidCallback onRematch,
    required VoidCallback onBackToMenu,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameResultDialog(
        userWon: userWon,
        subtitle: subtitle,
        entries: entries,
        onRematch: onRematch,
        onBackToMenu: onBackToMenu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Caja principal oscura neutra con podio de resultados
          Container(
            margin: const EdgeInsets.only(top: 26),
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Lista de resultados por jugador
                ...entries.map((entry) => _buildPlayerResultTile(entry)),

                const SizedBox(height: 20),

                // Fila de dos botones: Lobby y Revancha
                Row(
                  children: [
                    // Botón Lobby
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onBackToMenu,
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text(
                          'Lobby',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Botón Revancha
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRematch,
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text(
                          'Revancha',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B), // Naranja dorado vibrante
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Banner superior con sombra
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: userWon
                      ? const [Color(0xFF10B981), Color(0xFF059669)]
                      : const [Color(0xFFEA580C), Color(0xFFC2410C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (userWon ? const Color(0xFF10B981) : const Color(0xFFEA580C))
                        .withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                userWon ? '¡HAS GANADO!' : '¡HAS PERDIDO!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResultTile(GameResultEntry entry) {
    final isPositive = entry.scoreChange >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
      ),
      child: Row(
        children: [
          // Corona si es ganador
          if (entry.isWinner) ...[
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 24),
            const SizedBox(width: 8),
          ] else ...[
            const SizedBox(width: 6),
          ],

          // Avatar
          CircleAvatar(
            radius: 17,
            backgroundColor: entry.isUser ? const Color(0xFF0284C7) : const Color(0xFF333333),
            child: Icon(
              entry.isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
              size: 19,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),

          // Nombre
          Expanded(
            child: Text(
              entry.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Puntaje / Recompensa (+2,000 / -1,000)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isPositive ? '+' : ''}${entry.scoreChange}',
                style: TextStyle(
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
