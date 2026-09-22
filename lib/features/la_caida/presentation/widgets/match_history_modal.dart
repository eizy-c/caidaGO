import 'package:flutter/material.dart';
import '../../economy/match_history_model.dart';
import 'table_auditor_panel.dart';

/// Modal para consultar el historial de las últimas partidas jugadas
/// y abrir la auditoría completa de cantos y puntos de cada una.
class MatchHistoryModal extends StatelessWidget {
  const MatchHistoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MatchHistoryModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MatchHistoryStorage.instance,
      builder: (context, _) {
        final matches = MatchHistoryStorage.instance.matches;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_edu_rounded, color: Color(0xFFFDE047), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'HISTORIAL DE PARTIDAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: matches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sports_esports_rounded, size: 48, color: Colors.white24),
                              const SizedBox(height: 10),
                              Text(
                                'Aún no has jugado partidas registradas.\n¡Empieza a jugar para ver tu historial y auditoría!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: matches.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = matches[index];
                            final isWin = m.won;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF2E2E2E),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Fila superior: Victoria/Derrota, Modo y Fecha
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isWin
                                                  ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                                                  : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isWin ? 'VICTORIA' : 'DERROTA',
                                              style: TextStyle(
                                                color: isWin ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            m.gameMode,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${m.playedAt.day}/${m.playedAt.month} ${m.playedAt.hour.toString().padLeft(2, '0')}:${m.playedAt.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Marcador y Recompensas
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${m.userScore}  -  ${m.opponentScore}',
                                        style: TextStyle(
                                          color: isWin ? const Color(0xFFFDE047) : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (m.coinsEarned > 0) ...[
                                            const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFFFDE047)),
                                            const SizedBox(width: 3),
                                            Text(
                                              '+${m.coinsEarned}',
                                              style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (m.trophyDelta != 0) ...[
                                            Text(
                                              m.trophyDelta > 0 ? '+${m.trophyDelta} 🏆' : '${m.trophyDelta} 🏆',
                                              style: TextStyle(
                                                color: m.trophyDelta > 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Estadísticas y botón de Auditoría
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${m.caidasCount} Caídas • ${m.limpiasCount} Limpias • ${m.cantosCount} Cantos',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          TableAuditorPanel.show(context, auditLogs: m.auditLogs);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF242424),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'AUDITORÍA',
                                                style: TextStyle(
                                                  color: Color(0xFFE9D5FF),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFFE9D5FF)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
