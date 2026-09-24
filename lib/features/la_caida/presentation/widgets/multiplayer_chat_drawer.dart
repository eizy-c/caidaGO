import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_palette.dart';

enum ChatTab { write, emojis, voice }

/// Drawer lateral deslizable interactivo para multijugador y partidas en vivo.
/// Ofrece:
/// 1. 💬 Escribir: Campo de texto libre y frases rápidas venezolanas.
/// 2. 😀 Reacciones: 24 emojis táctiles con respuesta háptica.
/// 3. 🎙️ Hablar: Micrófono interactivo Push-to-Talk y botonera de cantos/voces criollas.
class MultiplayerChatDrawer extends StatefulWidget {
  final Function(String message, {String? voiceSoundKey}) onSendMessage;
  final VoidCallback onClose;

  const MultiplayerChatDrawer({
    super.key,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  State<MultiplayerChatDrawer> createState() => _MultiplayerChatDrawerState();
}

class _MultiplayerChatDrawerState extends State<MultiplayerChatDrawer>
    with SingleTickerProviderStateMixin {
  ChatTab _currentTab = ChatTab.write;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Animación para el micrófono Push-to-Talk
  bool _isHoldingMic = false;
  late AnimationController _micWaveController;
  Timer? _micTimer;

  static const List<String> _emojis = [
    '🔥', '😎', '👏', '🍅', '🏆', '🤣',
    '😱', '🤫', '🎯', '⚡', '🤝', '💪',
    '🎲', '👑', '👀', '❤️', '🤡', '😈',
    '🍿', '🥳', '💀', '🧠', '🥶', '🤩',
  ];

  static const List<String> _quickPhrases = [
    '¡Buena jugada! 👏',
    '¡Me caí! 💥',
    '¡Canto Ronda! 🎴',
    '¡Dale que te toca! ⏳',
    '¡Mala suerte! 😅',
    '¡Revancha! 🔥',
    '¡Paga la cuenta! 💰',
    '¡Qué caída! 👑',
    '¡Bien jugado socio! 🤝',
    '¡Mesa limpia! 🧹',
    '¡No te duermas! ⚡',
    '¡Gracias! 👍',
    '¡A llorar pal valle! 😭',
    '¡Aquí no hay miedo! 🦁',
  ];

  static const List<Map<String, String>> _voiceTaunts = [
    {'title': '¡Caída!', 'sound': 'caida', 'desc': 'Grito de Caída tradicional'},
    {'title': '¡Mesa Limpia!', 'sound': 'limpia', 'desc': 'Anuncio de Limpia'},
    {'title': '¡Ronda!', 'sound': 'ronda', 'desc': 'Canto de Ronda'},
    {'title': '¡Patrulla!', 'sound': 'patrulla', 'desc': 'Canto de Patrulla'},
    {'title': '¡Vigía!', 'sound': 'vigia', 'desc': 'Canto de Vigía'},
    {'title': '¡Registro!', 'sound': 'registro', 'desc': 'Canto de Registro'},
    {'title': '¡Últimas!', 'sound': 'ultimas', 'desc': 'Anuncio de Últimas'},
    {'title': '¡Uno!', 'sound': 'uno', 'desc': 'Canto Uno'},
    {'title': '¡Cuatro!', 'sound': 'cuatro', 'desc': 'Canto Cuatro'},
  ];

  @override
  void initState() {
    super.initState();
    _micWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _micWaveController.dispose();
    _micTimer?.cancel();
    super.dispose();
  }

  void _sendTextMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticService.instance.onSelection();
    AudioService().playCardSlide();
    widget.onSendMessage(trimmed);
    _textController.clear();
    _focusNode.unfocus();
    widget.onClose();
  }

  void _sendEmoji(String emoji) {
    HapticService.instance.onSelection();
    AudioService().playCardSlide();
    widget.onSendMessage(emoji);
    widget.onClose();
  }

  void _sendVoiceTaunt(String title, String soundKey) {
    HapticService.instance.onSelection();
    AudioService().playCanto(soundKey);
    widget.onSendMessage('🎙️ $title', voiceSoundKey: soundKey);
    widget.onClose();
  }

  void _startPushToTalk() {
    setState(() {
      _isHoldingMic = true;
    });
    HapticService.instance.onSelection();
    AudioService().playCardDeal();
    _micWaveController.repeat(reverse: true);
  }

  void _stopPushToTalk() {
    if (!_isHoldingMic) return;
    setState(() {
      _isHoldingMic = false;
    });
    _micWaveController.stop();
    _micWaveController.reset();
    HapticService.instance.onSelection();
    AudioService().playCardFlip();
    widget.onSendMessage('🎙️ [Mensaje de voz]');
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
            // Header del Drawer
            _buildHeader(),

            // Barra de Pestañas (Escribir / Emojis / Hablar)
            _buildTabsSelector(),

            const SizedBox(height: 6),

            // Contenido de la pestaña activa
            Expanded(
              child: switch (_currentTab) {
                ChatTab.write => _buildWriteTab(),
                ChatTab.emojis => _buildEmojisTab(),
                ChatTab.voice => _buildVoiceTab(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
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
                Icons.forum_rounded,
                color: AppPalette.cartoonCyan,
                size: 20,
              ),
              SizedBox(width: 8),
              CartoonStrokeText(
                'CHAT & VOCES',
                fontSize: 15,
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

  Widget _buildTabsSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B165E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.cartoonBorder.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          _buildTabButton(
            tab: ChatTab.write,
            label: 'Escribir',
            icon: Icons.edit_note_rounded,
          ),
          _buildTabButton(
            tab: ChatTab.emojis,
            label: 'Emojis',
            icon: Icons.emoji_emotions_rounded,
          ),
          _buildTabButton(
            tab: ChatTab.voice,
            label: 'Hablar',
            icon: Icons.mic_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required ChatTab tab,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.instance.onSelection();
          setState(() {
            _currentTab = tab;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1E1B4B) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PESTAÑA 1: ESCRIBIR =================
  Widget _buildWriteTab() {
    return Column(
      children: [
        // Input de texto con botón enviar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B165E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.5),
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
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11.5),
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
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF0F172A), offset: Offset(0, 2)),
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
        ),

        // Subtítulo Frases Rápidas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppPalette.cartoonYellow, size: 14),
              const SizedBox(width: 5),
              Text(
                'FRASES RÁPIDAS EN MESA',
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

        // Lista de frases rápidas tipo chips
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: _quickPhrases.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final phrase = _quickPhrases[index];
              return TactilePressable(
                depth: 2.0,
                onTap: () => _sendTextMessage(phrase),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF332D8C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.cartoonBorder.withValues(alpha: 0.7), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 1.5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: AppPalette.cartoonCyan, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phrase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= PESTAÑA 2: EMOJIS =================
  Widget _buildEmojisTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: AppPalette.cartoonCyan,
                size: 14,
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
    );
  }

  // ================= PESTAÑA 3: HABLAR (VOZ Y CANTOS) =================
  Widget _buildVoiceTab() {
    return Column(
      children: [
        // Botón Push-To-Talk Micrófono en Vivo
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1656),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHoldingMic ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHoldingMic
                    ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _isHoldingMic ? '🔴 TRANSMITIENDO VOZ EN VIVO...' : 'MICRÓFONO EN VIVO',
                style: TextStyle(
                  color: _isHoldingMic ? const Color(0xFFF87171) : const Color(0xFF38BDF8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTapDown: (_) => _startPushToTalk(),
                onTapUp: (_) => _stopPushToTalk(),
                onTapCancel: () => _stopPushToTalk(),
                child: AnimatedBuilder(
                  animation: _micWaveController,
                  builder: (context, _) {
                    final scale = _isHoldingMic
                        ? 1.0 + (_micWaveController.value * 0.12)
                        : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isHoldingMic
                              ? const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                                )
                              : AppGradients.cyanAccent,
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: _isHoldingMic
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                  : const Color(0xFF38BDF8).withValues(alpha: 0.45),
                              blurRadius: _isHoldingMic ? 18 : 8,
                              spreadRadius: _isHoldingMic ? 3 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isHoldingMic ? Icons.record_voice_over_rounded : Icons.mic_rounded,
                          color: _isHoldingMic ? Colors.white : const Color(0xFF1E1B4B),
                          size: 30,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isHoldingMic ? 'Suelta para enviar' : 'Mantén presionado para hablar',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // Subtítulo Voces de Caída
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppPalette.cartoonYellow, size: 14),
              const SizedBox(width: 5),
              Text(
                'VOCES Y CANTOS TRADICIONALES',
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

        // Lista de frases de voz y cantos
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: _voiceTaunts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final voice = _voiceTaunts[index];
              return TactilePressable(
                depth: 2.0,
                onTap: () => _sendVoiceTaunt(voice['title']!, voice['sound']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF332D8C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5), width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1B165E), offset: Offset(0, 1.5)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFFBBF24), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voice['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              voice['desc']!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF38BDF8), size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
