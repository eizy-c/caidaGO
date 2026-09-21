import 'package:flutter/material.dart';
import 'avatar_view.dart';

/// Definición de un marco cosmético para el avatar del usuario.
class UserFrameItem {
  final String id;
  final String name;
  final int minLevel;
  final List<Color> borderGradient;
  final Color shadowColor;
  final double borderWidth;
  final IconData? crownIcon;
  final String description;
  final String? imagePath;

  const UserFrameItem({
    required this.id,
    required this.name,
    required this.minLevel,
    required this.borderGradient,
    required this.shadowColor,
    this.borderWidth = 3.5,
    this.crownIcon,
    required this.description,
    this.imagePath,
  });

  static const List<UserFrameItem> allFrames = [
    UserFrameItem(
      id: 'wood',
      name: 'Madera Clásica',
      minLevel: 0,
      borderGradient: [Color(0xFF854D0E), Color(0xFFD97706), Color(0xFF78350F)],
      shadowColor: Color(0xFF451A03),
      borderWidth: 3.5,
      description: 'Marco tradicional de madera caoba pulida.',
      imagePath: 'assets/player/marcos/MADERA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'bronze',
      name: 'Bronce Rústico',
      minLevel: 1,
      borderGradient: [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)],
      shadowColor: Color(0xFF78350F),
      borderWidth: 3.8,
      description: 'Marco forjado en bronce de combate.',
      imagePath: 'assets/player/marcos/BRONCE-MARCOS.png',
    ),
    UserFrameItem(
      id: 'silver',
      name: 'Plata Pulida',
      minLevel: 2,
      borderGradient: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFF8FAFC)],
      shadowColor: Color(0xFF64748B),
      borderWidth: 4.0,
      description: 'Marco de plata brillante para aprendices destacados.',
      imagePath: 'assets/player/marcos/PLATA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'gold',
      name: 'Oro Imperial',
      minLevel: 3,
      borderGradient: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
      shadowColor: Color(0xFFCA8A04),
      borderWidth: 4.5,
      crownIcon: Icons.military_tech_rounded,
      description: 'Bisel forjado en oro puro con insignias reales.',
      imagePath: 'assets/player/marcos/ORO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'emerald',
      name: 'Esmeralda Criolla',
      minLevel: 4,
      borderGradient: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
      shadowColor: Color(0xFF047857),
      borderWidth: 4.5,
      crownIcon: Icons.diamond_rounded,
      description: 'Piedra esmeralda venezolana con resplandor natural.',
      imagePath: 'assets/player/marcos/ESMEALDA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'diamond',
      name: 'Diamante Mítico',
      minLevel: 5,
      borderGradient: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF60A5FA)],
      shadowColor: Color(0xFF9333EA),
      borderWidth: 5.0,
      crownIcon: Icons.auto_awesome_rounded,
      description: 'Marco prismático exclusivo para leyendas criollas.',
      imagePath: 'assets/player/marcos/DIAMANTE-MARCOS.png',
    ),
    UserFrameItem(
      id: 'master',
      name: 'Maestro de Caída',
      minLevel: 6,
      borderGradient: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
      shadowColor: Color(0xFF991B1B),
      borderWidth: 5.0,
      crownIcon: Icons.workspace_premium_rounded,
      description: 'Insignia otorgada únicamente a los maestros consumados.',
      imagePath: 'assets/player/marcos/MAESTRO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'grand_master',
      name: 'Gran Maestro',
      minLevel: 7,
      borderGradient: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
      shadowColor: Color(0xFF78350F),
      borderWidth: 5.2,
      crownIcon: Icons.emoji_events_rounded,
      description: 'Marco de Gran Maestro con gemas relucientes.',
      imagePath: 'assets/player/marcos/GRAN-MAESTRO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'heroic',
      name: 'Heroico',
      minLevel: 8,
      borderGradient: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
      shadowColor: Color(0xFF312E81),
      borderWidth: 5.5,
      crownIcon: Icons.shield_rounded,
      description: 'Rango heroico forjado con metales legendarios.',
      imagePath: 'assets/player/marcos/HEROICO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'legend',
      name: 'Leyenda Suprema',
      minLevel: 10,
      borderGradient: [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF881337)],
      shadowColor: Color(0xFF4C0519),
      borderWidth: 5.5,
      crownIcon: Icons.star_rounded,
      description: 'El pináculo absoluto del juego. La Caída Suprema.',
      imagePath: 'assets/player/marcos/LEYENDA-MARCOS.png',
    ),
  ];

  static UserFrameItem getById(String id) {
    return allFrames.firstWhere((f) => f.id == id, orElse: () => allFrames.first);
  }
}

/// Widget visual para renderizar el Avatar del usuario contenido en su Marco seleccionado
/// e insignia de Nivel en forma de escudo.
class UserFrameView extends StatelessWidget {
  final int avatarIndex;
  final String frameId;
  final int level;
  final double size;
  final bool showLevelBadge;
  final VoidCallback? onTap;

  const UserFrameView({
    super.key,
    required this.avatarIndex,
    this.frameId = 'wood',
    this.level = 0,
    this.size = 64,
    this.showLevelBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final frame = UserFrameItem.getById(frameId);
    final badgeSize = size * 0.38;

    Widget content = SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Resplandor / Sombra exterior del marco
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: frame.shadowColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 2. Marco Ornamental (PNG Ilustrado o Gradiente procedural)
          if (frame.imagePath != null)
            SizedBox(
              width: size + 4,
              height: size + 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AvatarView(
                    avatarId: avatarIndex,
                    size: size * 0.76,
                    showBorder: false,
                  ),
                  Image.asset(
                    frame.imagePath!,
                    width: size + 4,
                    height: size + 4,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
            )
          else
            Container(
              width: size + 4,
              height: size + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: frame.borderGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(frame.borderWidth),
                child: ClipOval(
                  child: AvatarView(
                    avatarId: avatarIndex,
                    size: size - (frame.borderWidth * 2),
                  ),
                ),
              ),
            ),

          // 3. Ícono de Corona / Joya superior si tiene
          if (frame.crownIcon != null)
            Positioned(
              top: -6,
              child: Icon(
                frame.crownIcon,
                size: size * 0.32,
                color: const Color(0xFFFDE047),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),

          // 4. Insignia de Nivel en forma de escudo en la esquina superior derecha
          if (showLevelBadge)
            Positioned(
              top: -2,
              right: -2,
              child: _buildLevelShield(badgeSize),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildLevelShield(double badgeSize) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFDE047), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: const Color(0xFFFDE047),
            fontWeight: FontWeight.w900,
            fontSize: badgeSize * 0.52,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
