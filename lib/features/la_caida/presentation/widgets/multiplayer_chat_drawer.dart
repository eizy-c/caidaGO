import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_palette.dart';

/// Panel lateral deslizable (de derecha a izquierda) para Reacciones y Emojis
/// exclusivo para partidas Multijugador y bocadillos en juego.
class MultiplayerChatDrawer extends StatelessWidget {
  final Function(String message) onSendMessage;
  final VoidCallback onClose;

  const MultiplayerChatDrawer({
    super.key,
    required this.onSendMessage,
    required this.onClose,
  });

  static const List<String> _emojis = [
    '🔥',
    '😎',
    '👏',
    '🍅',
    '🏆',
    '🤣',
    '😱',
    '🤫',
    '🎯',
    '⚡',
    '🤝',
    '💪',
    '🎲',
    '👑',
    '👀',
    '❤️',
    '🤡',
    '😈',
    '🍿',
    '🥳',
    '💀',
    '🧠',
    '🥶',
    '🤩',
  ];

  void _sendEmoji(String emoji) {
    HapticService.instance.onSelection();
    AudioService().playCardSlide();
    onSendMessage(emoji);
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final drawerWidth = (size.width * 0.72).clamp(240.0, 300.0);

    return Container(
      width: drawerWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppPalette.cartoonBgDark,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        border: const Border(
          left: BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
          top: BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 20,
            offset: Offset(-6, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header del Drawer
            _buildHeader(),

            const SizedBox(height: 8),

            // Subtítulo indicador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: AppPalette.cartoonCyan,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TOCA UN EMOJI PARA REACCIONAR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Grid de Emojis
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];

                  return TactilePressable(
                    depth: 2.5,
                    onTap: () => _sendEmoji(emoji),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF332D8C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppPalette.cartoonBorder.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1B165E),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      decoration: const BoxDecoration(
        color: AppPalette.cartoonSurface,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_emotions_rounded,
                color: AppPalette.cartoonCyan,
                size: 22,
              ),
              SizedBox(width: 8),
              CartoonStrokeText(
                'REACCIONES',
                fontSize: 16,
                textColor: AppPalette.cartoonYellow,
                strokeColor: AppPalette.cartoonCardText,
                strokeWidth: 2.5,
              ),
            ],
          ),
          CartoonRoundButton(
            width: 34,
            height: 34,
            borderRadius: 10,
            onPressed: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: AppPalette.cartoonCardText,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
