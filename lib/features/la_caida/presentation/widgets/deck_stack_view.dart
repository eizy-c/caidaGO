import 'package:flutter/material.dart';
import '../../domain/models/card_back_option.dart';
import '../../economy/player_session.dart';

/// Componente visual que representa el mazo de cartas físicas sobre la mesa.
/// Muestra un efecto apilado tridimensional en capas, el diseño del reverso activo
/// (o personalizado) y el contador numérico dinámico de cartas restantes.
class DeckStackView extends StatelessWidget {
  final int remainingCards;
  final VoidCallback? onTap;
  final String? customBackAssetPath;

  const DeckStackView({
    super.key,
    required this.remainingCards,
    this.onTap,
    this.customBackAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerSession.shared,
      builder: (context, _) {
        final session = PlayerSession.shared;
        final effectiveAsset = customBackAssetPath ?? session.activeCardBackAssetPath;
        final cardBackOpt = CardBackOption.allCardBacks.firstWhere(
          (b) => b.assetPath == effectiveAsset || b.id == session.selectedCardBackId,
          orElse: () => CardBackOption.allCardBacks.first,
        );

        final hasCards = remainingCards > 0;
        // La altura del apilado es proporcional a las cartas restantes (hasta 4 capas)
        final stackLayers = hasCards ? (remainingCards / 10).ceil().clamp(1, 4) : 0;

        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!hasCards)
                      // Huella o silueta del mazo vacío sobre el tapete
                      Container(
                        width: 52,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.layers_clear_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      // Capas apiladas tridimensionales
                      ...List.generate(stackLayers, (index) {
                        final offset = (stackLayers - 1 - index) * 2.2;
                        return Positioned(
                          top: offset,
                          left: offset * 0.8,
                          child: _buildCardBack(
                            isTop: index == stackLayers - 1,
                            assetPath: effectiveAsset,
                            primaryColor: cardBackOpt.primaryColor,
                            accentColor: cardBackOpt.accentColor,
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Píldora con el contador de cartas en el mazo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: hasCards ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasCards ? cardBackOpt.accentColor.withValues(alpha: 0.7) : Colors.white24,
                    width: 1,
                  ),
                  boxShadow: hasCards
                      ? [
                          BoxShadow(
                            color: cardBackOpt.accentColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 10,
                      color: hasCards ? cardBackOpt.accentColor : Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasCards ? '$remainingCards' : 'Agotado',
                      style: TextStyle(
                        color: hasCards ? Colors.white : Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardBack({
    required bool isTop,
    required String assetPath,
    required Color primaryColor,
    required Color accentColor,
  }) {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isTop ? accentColor : const Color(0xFF1E293B),
          width: isTop ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(
          assetPath,
          width: 52,
          height: 74,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => _buildFallbackVectorBack(isTop, primaryColor, accentColor),
        ),
      ),
    );
  }

  Widget _buildFallbackVectorBack(bool isTop, Color primaryColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border.all(color: const Color(0xFF2E2E2E), width: 1.5),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Center(
            child: Icon(Icons.style_rounded, size: 18, color: accentColor),
          ),
        ),
      ),
    );
  }
}
