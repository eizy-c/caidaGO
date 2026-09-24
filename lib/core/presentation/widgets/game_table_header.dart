import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';
import 'cartoon_widgets.dart';

/// Barra superior de navegación para mesas de juegos tradicionales.
/// Incluye degradado púrpura oscuro, botón de regreso, menú de reglas, trofeos/monedas y latencia.
class GameTableHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onOpenRules;
  final VoidCallback? onSettings;
  final int trophies;
  final int pingMs;
  final bool showPing;
  final int? playerLevel;
  final bool isMuted;
  final VoidCallback? onToggleMute;
  final bool showTrophies;
  final Widget? titleWidget;

  const GameTableHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onOpenRules,
    this.onSettings,
    this.trophies = 7500,
    this.pingMs = 60,
    this.showPing = false,
    this.playerLevel,
    this.isMuted = false,
    this.onToggleMute,
    this.showTrophies = true,
    this.titleWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.cartoonSurface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: AppPalette.cartoonBorder, width: 2.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Botón Atrás a la izquierda
            CartoonRoundButton(
              width: 36,
              height: 36,
              borderRadius: 12,
              depth: 2.5,
              backgroundColor: const Color(0xFF352B6E),
              borderColor: AppPalette.cartoonBorder,
              shadowColor: const Color(0xFF151035),
              onPressed: onBack,
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),

            // Título central
            Expanded(
              child: titleWidget ??
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
            ),

            // Indicador de Latencia / Ping (solo en partidas online o red local)
            if (showPing)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pingMs}ms',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.signal_cellular_alt_rounded, color: Color(0xFF4ADE80), size: 13),
                  ],
                ),
              ),

            // Indicador de Nivel del Jugador (si está presente)
            if (playerLevel != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cartoonCyan, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      'Nv. $playerLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Píldora de Trofeos / Puntos (solo si showTrophies es true)
            if (showTrophies) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonCardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x30000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 5),
                    Text(
                      _formatNumber(trophies),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Botón Ajustes a la derecha
            if (onSettings != null)
              CartoonRoundButton(
                width: 36,
                height: 36,
                borderRadius: 12,
                depth: 2.5,
                backgroundColor: const Color(0xFF352B6E),
                borderColor: AppPalette.cartoonBorder,
                shadowColor: const Color(0xFF151035),
                onPressed: onSettings,
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final k = number / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return number.toString();
  }
}
