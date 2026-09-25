import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_palette.dart';
import 'avatar_view.dart';

/// Modelo de datos para un mensaje en el historial efímero de la partida.
class ChatMessageItem {
  final String senderName;
  final int senderAvatarId;
  final Color senderColor;
  final String message;
  final String? voiceSoundKey;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessageItem({
    required this.senderName,
    this.senderAvatarId = 0,
    required this.senderColor,
    required this.message,
    this.voiceSoundKey,
    required this.isUser,
    required this.timestamp,
  });
}

/// Drawer lateral deslizable interactivo para chat y voces en partida.
/// Optimizado y simplificado:
/// - Muestra un feed de historial en vivo durante la partida.
/// - Menú rápido y limpio sin sobrecarga de botones.
/// - Transmisión y reproducción de voces criollas (Caída, Limpia, Ronda, etc.).
class MultiplayerChatDrawer extends StatefulWidget {
  final List<ChatMessageItem> messages;
  final Function(String message, {String? voiceSoundKey}) onSendMessage;
  final VoidCallback onClose;

  const MultiplayerChatDrawer({
    super.key,
    required this.messages,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  State<MultiplayerChatDrawer> createState() => _MultiplayerChatDrawerState();
}

class _MultiplayerChatDrawerState extends State<MultiplayerChatDrawer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Reacciones rápidas curadas (Frases, Emojis y Voces Criollas)
  static const List<String> _quickPhrases = [
    '¡Buena jugada! 👏',
    '¡Me caí! 💥',
    '¡Revancha! 🔥',
    '¡Dale que te toca! ⏳',
  ];

  static const List<String> _quickEmojis = [
    '🔥', '🤣', '👏', '👑', '👀', '💪',
  ];

  static const List<Map<String, String>> _voiceTaunts = [
    {'label': '¡Caída! 📢', 'key': 'caida'},
    {'label': '¡Limpia! 📢', 'key': 'limpia'},
    {'label': '¡Ronda! 📢', 'key': 'ronda'},
    {'label': '¡Últimas! 📢', 'key': 'ultimas'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant MultiplayerChatDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendTextMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticService.instance.onSelection();
    widget.onSendMessage(trimmed);
    _textController.clear();
  }

  void _sendQuickReaction(String reaction) {
    HapticService.instance.onSelection();
    widget.onSendMessage(reaction);
  }

  void _sendVoice(String label, String soundKey) {
    HapticService.instance.onSelection();
    widget.onSendMessage(label, voiceSoundKey: soundKey);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final drawerWidth = (size.width * 0.82).clamp(280.0, 340.0);

    return Container(
      width: drawerWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF160F33),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        border: const Border(
          left: BorderSide(color: AppPalette.cartoonBorder, width: 2.2),
          top: BorderSide(color: AppPalette.cartoonBorder, width: 2.2),
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 24,
            offset: Offset(-8, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Header con indicador en vivo y botón cerrar
            _buildHeader(),

            // 2. Historial de mensajes en vivo de la partida
            Expanded(
              child: _buildChatFeed(),
            ),

            // 3. Barra de reacciones rápidas y envío de voz
            _buildQuickReactionsBar(),

            // 4. Input inferior de texto
            _buildTextInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1746),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(22)),
        border: Border(
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 1.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF22C55E), blurRadius: 6, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CartoonStrokeText(
                'CHAT DE PARTIDA',
                fontSize: 14,
                textColor: AppPalette.cartoonYellow,
                strokeColor: AppPalette.cartoonCardText,
                strokeWidth: 2.5,
              ),
            ],
          ),
          CartoonRoundButton(
            width: 32,
            height: 32,
            borderRadius: 10,
            onPressed: widget.onClose,
            child: const Icon(
              Icons.close_rounded,
              color: AppPalette.cartoonCardText,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatFeed() {
    if (widget.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                'Aún no hay mensajes en la mesa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¡Envía una frase rápida o un grito de Caída!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final item = widget.messages[index];
        return _buildMessageBubble(item);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageItem item) {
    final isMe = item.isUser;
    final timeStr =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.senderColor, width: 1.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AvatarView(
                  avatarId: item.senderAvatarId,
                  size: 26,
                  showBorder: false,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF221A4C),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 3),
                  bottomRight: Radius.circular(isMe ? 3 : 14),
                ),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF60A5FA).withValues(alpha: 0.6)
                      : item.senderColor.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x35000000),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        item.senderName,
                        style: TextStyle(
                          color: item.senderColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (item.voiceSoundKey != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volume_up_rounded, color: Color(0xFFFDE047), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          item.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReactionsBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1B143E),
        border: Border(
          top: BorderSide(color: Color(0x30FFFFFF), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Emojis + Voces Criollas directas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Emojis rápidos
                for (final emoji in _quickEmojis)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _sendQuickReaction(emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C225C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // Botones directos de Cantos de Voz Criollos
                for (final vt in _voiceTaunts)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _sendVoice(vt['label']!, vt['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA78BFA), width: 1.1),
                          boxShadow: const [
                            BoxShadow(color: Color(0x40000000), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          vt['label']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Fila 2: Frases rápidas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final phrase in _quickPhrases)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _sendQuickReaction(phrase),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF241B4E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          phrase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF140D30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1746),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                textInputAction: TextInputAction.send,
                onSubmitted: _sendTextMessage,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11.5),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TactilePressable(
            depth: 2.0,
            onTap: () => _sendTextMessage(_textController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppGradients.cyanAccent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppPalette.cartoonBorder, width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0F172A), offset: Offset(0, 1.5)),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF1E1B4B),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
