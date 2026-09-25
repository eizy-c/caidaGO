import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../presentation/widgets/app_3d_button.dart';
import '../theme/app_palette.dart';

/// Servicio y gestor de notas del parche y noticias para CaidaGO.
/// Muestra un modal informativo al actualizar la versión del juego y permite consultarlo
/// en cualquier momento desde el lobby principal con el botón Noticias.
class PatchNotesService {
  static const String currentVersion = '2.5.0';
  static const String _storageKey = 'caidago_last_viewed_patch_version';

  /// Determina si se debe mostrar automáticamente el popup en el primer inicio tras la actualización.
  static Future<bool> shouldShowPatchNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewed = prefs.getString(_storageKey);
      return lastViewed != currentVersion;
    } catch (_) {
      return false;
    }
  }

  /// Marca la versión actual como vista para no reabrir el popup en el siguiente inicio.
  static Future<void> markPatchNotesViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, currentVersion);
    } catch (_) {}
  }

  /// Muestra el modal estilizado de novedades y notas del parche (100% libre de emojis).
  static void showPatchNotesModal(BuildContext context) {
    markPatchNotesViewed();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E267D), Color(0xFF1E1746)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera Cartoon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1746),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                    border: Border(
                      bottom: BorderSide(color: AppPalette.cartoonBorder, width: 1.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTICIAS Y NOVEDADES',
                              style: TextStyle(
                                color: Color(0xFFFDE047),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Actualización v$currentVersion',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                ),

                // Lista de novedades con scroll
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      _PatchNoteItem(
                        icon: Icons.hub_rounded,
                        iconColor: Color(0xFF38BDF8),
                        title: 'Multijugador Unificado y Código de Sala',
                        description:
                            'Las salas públicas y privadas se integran en una sola vista con ID único de 5 caracteres en mayúsculas y soporte de Red Local sin internet.',
                      ),
                      SizedBox(height: 10),
                      _PatchNoteItem(
                        icon: Icons.mic_rounded,
                        iconColor: Color(0xFFA855F7),
                        title: 'Chat con Voz Criolla en Vivo',
                        description:
                            'Botón de micrófono para transmitir voces de juego y cantos tradicionales directamente en partida.',
                      ),
                      SizedBox(height: 10),
                      _PatchNoteItem(
                        icon: Icons.emoji_events_rounded,
                        iconColor: Color(0xFFF59E0B),
                        title: 'Trofeos Calibrados por Sala Regional',
                        description:
                            'Se aplican exactamente los trofeos de victoria y derrota correspondientes a cada mesa regional venezolana.',
                      ),
                      SizedBox(height: 10),
                      _PatchNoteItem(
                        icon: Icons.inventory_2_rounded,
                        iconColor: Color(0xFF10B981),
                        title: 'Cofres Escalables y Recompensas',
                        description:
                            'Gana cofres con monedas, XP, potenciadores garantizados y trofeos adicionales según la sala jugada.',
                      ),
                      SizedBox(height: 10),
                      _PatchNoteItem(
                        icon: Icons.backpack_rounded,
                        iconColor: Color(0xFFEC4899),
                        title: 'Inventario Filtrado Exclusivo',
                        description:
                            'El inventario ahora muestra únicamente los potenciadores, marcos, avatares y fondos que posees o has desbloqueado.',
                      ),
                      SizedBox(height: 10),
                      _PatchNoteItem(
                        icon: Icons.style_rounded,
                        iconColor: Color(0xFF6366F1),
                        title: 'Arrastre Final y Mini Cartas Temáticas',
                        description:
                            'Las cartas restantes vuelan animadas hacia quien recogió de último, y las mini cartas del avatar se adaptan al color del tapete.',
                      ),
                    ],
                  ),
                ),

                // Botón inferior
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: App3dButton(
                    label: '¡A JUGAR!',
                    variant: App3dButtonVariant.emerald,
                    depth: 4.0,
                    expand: true,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PatchNoteItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _PatchNoteItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
