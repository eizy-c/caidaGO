import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/caida_models.dart';

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
            // Icono de repartidor / mano
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
              ),
              child: const Icon(
                Icons.front_hand_rounded,
                color: Color(0xFFF59E0B),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),

            // Título principal
            const Text(
              '¡ERES LA MANO!',
              style: TextStyle(
                color: Color(0xFFF59E0B),
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

            // Opciones 1 y 4 lado a lado (Grandes y protagonistas)
            Row(
              children: [
                // OPCIÓN 1
                Expanded(
                  child: _buildBigChoiceCard(
                    context: context,
                    direction: DealDirection.ascending,
                    number: '1',
                    actionLabel: 'Cantar 1',
                    sequence: '1 → 2 → 3 → 4',
                    accentColor: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 14),

                // OPCIÓN 4
                Expanded(
                  child: _buildBigChoiceCard(
                    context: context,
                    direction: DealDirection.descending,
                    number: '4',
                    actionLabel: 'Cantar 4',
                    sequence: '4 → 3 → 2 → 1',
                    accentColor: const Color(0xFFF59E0B),
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
    required Color accentColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(direction);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Número gigante protagonista
              Text(
                number,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Botón o etiqueta de acción
              Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),

              // Secuencia de conteo
              Text(
                sequence,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
