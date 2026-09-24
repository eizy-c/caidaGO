import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';

/// Panel lateral deslizable (de derecha a izquierda) para Chat y Frases Rápidas
/// exclusivo para partidas Multijugador.
class MultiplayerChatDrawer extends StatefulWidget {
  final Function(String message) onSendMessage;
  final VoidCallback onClose;

  const MultiplayerChatDrawer({
    super.key,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  State<MultiplayerChatDrawer> createState() => _MultiplayerChatDrawerState();
}

class _MultiplayerChatDrawerState extends State<MultiplayerChatDrawer> {
  final TextEditingController _textController = TextEditingController();
  int _selectedCategory = 0; // 0: Frases Criollas, 1: Emojis

  static const List<String> _frasesCriollas = [
    '¡Toma tu tomate! 🍅',
    '¡Buena esa, compañero! 👏',
    '¡Me caí! 😱',
    '¡Cántalo! 🎶',
    '¡Te tengo cazao! 🎯',
    '¡Juega rápido! ⏳',
    '¡Silencio, estoy pensando! 🤫',
    '¡Tiembla la mesa! 🔥',
    '¡Buena partida! 🤝',
    '¡Eso no se vale! 😅',
    '¡A ganar esta ronda! 🏆',
    '¡Ponte las pilas! ⚡',
  ];

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
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _send(String message) {
    if (message.trim().isEmpty) return;
    widget.onSendMessage(message.trim());
    _textController.clear();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final drawerWidth = (size.width * 0.78).clamp(260.0, 320.0);

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
            // Header del Chat
            _buildHeader(),

            // Selector de pestaña (Frases vs Emojis)
            _buildTabSelector(),

            const SizedBox(height: 10),

            // Contenido de Frases / Emojis con scroll
            Expanded(
              child: _selectedCategory == 0
                  ? _buildQuickPhrasesList()
                  : _buildEmojisGrid(),
            ),

            // Barra de entrada de texto libre
            _buildTextInputBar(),
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
                Icons.chat_bubble_rounded,
                color: AppPalette.cartoonCyan,
                size: 20,
              ),
              SizedBox(width: 8),
              CartoonStrokeText(
                'CHAT DE SALA',
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
            onPressed: widget.onClose,
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

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'FRASES',
              index: 0,
              icon: Icons.chat_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              label: 'EMOJIS',
              index: 1,
              icon: Icons.emoji_emotions_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == index;

    return TactilePressable(
      depth: 2.0,
      onTap: () => setState(() => _selectedCategory = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? null : const Color(0xFF262169),
          gradient: isSelected ? AppGradients.cyanAccent : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppPalette.cartoonBorder
                : AppPalette.cartoonBorder.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B165E),
              offset: Offset(0, isSelected ? 2 : 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPhrasesList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _frasesCriollas.length,
      itemBuilder: (context, index) {
        final phrase = _frasesCriollas[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TactilePressable(
            depth: 2.0,
            onTap: () => _send(phrase),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF332D8C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppPalette.cartoonBorder.withValues(alpha: 0.8),
                  width: 1.4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1B165E),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: AppPalette.cartoonCyan,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phrase,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojisGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
          depth: 2.0,
          onTap: () => _send(emoji),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF332D8C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppPalette.cartoonBorder.withValues(alpha: 0.8),
                width: 1.4,
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
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppPalette.cartoonSurface,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF262169),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppPalette.cartoonBorder,
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11.5),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TactilePressable(
            depth: 2.5,
            onTap: () => _send(_textController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppGradients.greenAccept,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1B165E),
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
