import 'package:flutter/material.dart';
import '../../economy/rank_system.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/theme/app_palette.dart';

/// Modal animado que aparece cuando el jugador sube o baja de rango.
class RankUpModal extends StatefulWidget {
  final RankInfo previousRank;
  final RankInfo newRank;
  final bool isPromotion; // true = subió, false = bajó
  final int trophyDelta;
  final int coinReward; // recompensa inmediata si subió
  final VoidCallback? onClose;

  const RankUpModal({
    super.key,
    required this.previousRank,
    required this.newRank,
    required this.isPromotion,
    required this.trophyDelta,
    this.coinReward = 0,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required RankInfo previousRank,
    required RankInfo newRank,
    required bool isPromotion,
    required int trophyDelta,
    int coinReward = 0,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => RankUpModal(
        previousRank: previousRank,
        newRank: newRank,
        isPromotion: isPromotion,
        trophyDelta: trophyDelta,
        coinReward: coinReward,
        onClose: onClose,
      ),
    );
  }

  @override
  State<RankUpModal> createState() => _RankUpModalState();
}

class _RankUpModalState extends State<RankUpModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPromo = widget.isPromotion;
    final newRank = widget.newRank;
    final accentColor = isPromo ? newRank.primaryColor : const Color(0xFFEF4444);
    final title = isPromo ? '¡SUBISTE DE RANGO!' : 'Bajaste de rango';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: AppPalette.cartoonBgDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rango anterior -> Rango nuevo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _rankChip(widget.previousRank, dim: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          isPromo ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      _rankChip(newRank),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Trofeos ganados/perdidos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.trophyDelta >= 0
                          ? '+${widget.trophyDelta} 🏆'
                          : '${widget.trophyDelta} 🏆',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  // Recompensa inmediata si subió
                  if (isPromo && widget.coinReward > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFDE047), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '+${widget.coinReward} monedas',
                          style: const TextStyle(
                            color: Color(0xFFFDE047),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Marco desbloqueado ✔',
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],

                  const SizedBox(height: 24),

                  App3dButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                    label: '¡Entendido!',
                    height: 44,
                    depth: 5,
                    borderRadius: 14,
                    variant: isPromo ? App3dButtonVariant.gold : App3dButtonVariant.cyan,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rankChip(RankInfo rank, {bool dim = false}) {
    return Opacity(
      opacity: dim ? 0.5 : 1.0,
      child: Column(
        children: [
          Icon(rank.icon, size: 36, color: dim ? Colors.white38 : rank.primaryColor),
          const SizedBox(height: 6),
          Text(
            rank.name,
            style: TextStyle(
              color: dim ? Colors.white38 : rank.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
