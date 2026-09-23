import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
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
        decoration: const BoxDecoration(
          color: AppPalette.cartoonBgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
            left: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
            right: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
          ),
          boxShadow: [
            BoxShadow(color: Color(0x60000000), blurRadius: 20, offset: Offset(0, -4)),
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
                    Icon(Icons.assignment_rounded, color: AppPalette.cartoonYellow, size: 22),
                    SizedBox(width: 8),
                    CartoonStrokeText(
                      'AUDITOR DE MESA',
                      fontSize: 16,
                      textColor: AppPalette.cartoonYellow,
                    ),
                  ],
                ),
                CartoonRoundButton(
                  width: 32,
                  height: 32,
                  borderRadius: 10,
                  depth: 2.0,
                  backgroundColor: const Color(0xFF352B6E),
                  borderColor: AppPalette.cartoonBorder,
                  shadowColor: const Color(0xFF151035),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 12),

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
      child: TactilePressable(
        onTap: () => setState(() => _selectedTab = index),
        depth: 2.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppPalette.cartoonCyan.withValues(alpha: 0.22)
                : AppPalette.cartoonCardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppPalette.cartoonCyan : AppPalette.cartoonBorder,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppPalette.cartoonCyan.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppPalette.cartoonCyan : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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
            color: AppPalette.cartoonCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x25000000),
                blurRadius: 4,
                offset: Offset(0, 1.5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Badge de ronda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCyan.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.cartoonCyan.withValues(alpha: 0.3), width: 1.0),
                ),
                child: Text(
                  item.round,
                  style: const TextStyle(
                    color: AppPalette.cartoonCyan,
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
