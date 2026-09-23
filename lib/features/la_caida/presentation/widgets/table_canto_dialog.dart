import 'package:flutter/material.dart';
import '../../domain/caida_models.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';

/// Diálogo modal estilizado e intuitivo para que el jugador Mano elija
/// si cantará la mesa comenzando desde el 1 (1->2->3->4) o desde el 4 (4->3->2->1).
class TableCantoDialog extends StatelessWidget {
  const TableCantoDialog({super.key});

  static Future<DealDirection?> show(BuildContext context) {
    return showDialog<DealDirection>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const TableCantoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de repartidor / mano con gradiente dorado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppGradients.goldReward,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(
                Icons.front_hand_rounded,
                color: Color(0xFF1E1B4B),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            // Título principal limpio
            const Text(
              '¡ERES LA MANO!',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¿Cómo quieres comenzar a contar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Explicación pedagógica clara
            Text(
              'Al colocar cada una de las 4 cartas en la mesa se cantará su número. '
              'Elige si prefieres comenzar el canto desde el 1 o desde el 4.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),

            // Opciones 1 y 4 lado a lado con botones táctiles
            Row(
              children: [
                // OPCIÓN 1: Gradiente verde (Aceptar conteo normal)
                Expanded(
                  child: _buildBigChoiceCard(
                    context: context,
                    direction: DealDirection.ascending,
                    number: '1',
                    actionLabel: 'Cantar 1',
                    sequence: '1 → 2 → 3 → 4',
                    gradient: AppGradients.greenAccept,
                  ),
                ),
                const SizedBox(width: 14),

                // OPCIÓN 4: Gradiente dorado (Conteo invertido)
                Expanded(
                  child: _buildBigChoiceCard(
                    context: context,
                    direction: DealDirection.descending,
                    number: '4',
                    actionLabel: 'Cantar 4',
                    sequence: '4 → 3 → 2 → 1',
                    gradient: AppGradients.goldReward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigChoiceCard({
    required BuildContext context,
    required DealDirection direction,
    required String number,
    required String actionLabel,
    required String sequence,
    required Gradient gradient,
  }) {
    return TactilePressable(
      depth: 4,
      onTap: () {
        Navigator.of(context).pop(direction);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Número gigante protagonista limpio
            Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.w900,
                height: 1.0,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Botón o etiqueta de acción
            Text(
              actionLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),

            // Secuencia de conteo
            Text(
              sequence,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
