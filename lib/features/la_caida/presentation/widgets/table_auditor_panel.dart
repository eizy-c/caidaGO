import 'package:flutter/material.dart';
import '../../economy/match_history_model.dart';

/// Panel deslizante de Auditoría de Mesa en vivo durante la partida.
/// Permite consultar el historial cronológico de Cantos realizados,
/// la suma detallada de puntos y las jugadas clave.
class TableAuditorPanel extends StatefulWidget {
  final List<MatchAuditItem> auditLogs;

  const TableAuditorPanel({
    super.key,
    required this.auditLogs,
  });

  static Future<void> show(
    BuildContext context, {
    required List<MatchAuditItem> auditLogs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TableAuditorPanel(auditLogs: auditLogs),
    );
  }

  @override
  State<TableAuditorPanel> createState() => _TableAuditorPanelState();
}

class _TableAuditorPanelState extends State<TableAuditorPanel> {
  int _selectedTab = 0; // 0: Cantos, 1: Puntos, 2: Jugadas

  @override
  Widget build(BuildContext context) {
    final cantos = widget.auditLogs.where((l) => l.type == AuditEntryType.canto).toList();
    final puntos = widget.auditLogs.where((l) => l.type == AuditEntryType.puntos).toList();
    final jugadas = widget.auditLogs.where((l) => l.type == AuditEntryType.jugada).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1338), Color(0xFF0F071A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: const Color(0xFF9333EA), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          children: [
            // Tirador superior
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

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.assignment_rounded, color: Color(0xFFFDE047), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'AUDITOR DE MESA',
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

            // Selector de 3 pestañas: Cantos | Puntos | Jugadas
            Row(
              children: [
                _buildTabButton(0, 'Cantos (${cantos.length})'),
                const SizedBox(width: 6),
                _buildTabButton(1, 'Puntos (${puntos.length})'),
                const SizedBox(width: 6),
                _buildTabButton(2, 'Jugadas (${jugadas.length})'),
              ],
            ),

            const SizedBox(height: 12),

            // Lista con contenido según la pestaña seleccionada
            Expanded(
              child: _buildTabContent(
                _selectedTab == 0 ? cantos : (_selectedTab == 1 ? puntos : jugadas),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA855F7).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFA855F7) : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<MatchAuditItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No hay registros en esta sección aún.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isPositivePoints = item.points > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF160E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            children: [
              // Badge de ronda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.round,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Descripción y Jugador con equipo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item.isUserTeam
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.isUserTeam ? 'Tu equipo' : 'Rival',
                            style: TextStyle(
                              color: item.isUserTeam ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.playerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Puntos obtenidos
              if (item.points != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositivePoints
                        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                        : const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPositivePoints ? '+${item.points} pts' : '${item.points} pts',
                    style: TextStyle(
                      color: isPositivePoints ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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
