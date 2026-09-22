import 'package:flutter/material.dart';
import 'avatar_view.dart';
import '../../economy/user_progress.dart';

/// Definición de un marco cosmético para el avatar del usuario.
class UserFrameItem {
  final String id;
  final String name;
  final int minTrophies;
  final List<Color> borderGradient;
  final Color shadowColor;
  final double borderWidth;
  final IconData? crownIcon;
  final String description;
  final String? imagePath;

  const UserFrameItem({
    required this.id,
    required this.name,
    required this.minTrophies,
    required this.borderGradient,
    required this.shadowColor,
    this.borderWidth = 3.5,
    this.crownIcon,
    required this.description,
    this.imagePath,
  });

  bool isUnlockedByTrophies(int trophies) => trophies >= minTrophies;

  static const List<UserFrameItem> allFrames = [
    UserFrameItem(
      id: 'rank_novato',
      name: 'Madera Clásica',
      minTrophies: 0,
      borderGradient: [Color(0xFF854D0E), Color(0xFFD97706), Color(0xFF78350F)],
      shadowColor: Color(0xFF451A03),
      borderWidth: 3.5,
      description: 'Marco de novato. Todos empiezan aquí.',
      imagePath: 'assets/player/marcos/MADERA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_bronce',
      name: 'Bronce Rústico',
      minTrophies: 150,
      borderGradient: [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)],
      shadowColor: Color(0xFF78350F),
      borderWidth: 3.8,
      description: 'Marco de rango Bronce. 150+ trofeos.',
      imagePath: 'assets/player/marcos/BRONCE-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_plata',
      name: 'Plata Pulida',
      minTrophies: 450,
      borderGradient: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFF8FAFC)],
      shadowColor: Color(0xFF64748B),
      borderWidth: 4.0,
      description: 'Marco de rango Plata. 450+ trofeos.',
      imagePath: 'assets/player/marcos/PLATA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_oro',
      name: 'Oro Imperial',
      minTrophies: 900,
      borderGradient: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
      shadowColor: Color(0xFFCA8A04),
      borderWidth: 4.5,
      crownIcon: Icons.military_tech_rounded,
      description: 'Marco de rango Oro. 900+ trofeos.',
      imagePath: 'assets/player/marcos/ORO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_esmeralda',
      name: 'Esmeralda Criolla',
      minTrophies: 1500,
      borderGradient: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
      shadowColor: Color(0xFF047857),
      borderWidth: 4.5,
      crownIcon: Icons.diamond_rounded,
      description: 'Marco de rango Esmeralda. 1500+ trofeos.',
      imagePath: 'assets/player/marcos/ESMEALDA-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_diamante',
      name: 'Diamante Mítico',
      minTrophies: 2300,
      borderGradient: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF60A5FA)],
      shadowColor: Color(0xFF9333EA),
      borderWidth: 5.0,
      crownIcon: Icons.auto_awesome_rounded,
      description: 'Marco de rango Diamante. 2300+ trofeos.',
      imagePath: 'assets/player/marcos/DIAMANTE-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_maestro',
      name: 'Maestro de Caída',
      minTrophies: 3300,
      borderGradient: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
      shadowColor: Color(0xFF991B1B),
      borderWidth: 5.0,
      crownIcon: Icons.workspace_premium_rounded,
      description: 'Marco de rango Maestro I. 3300+ trofeos.',
      imagePath: 'assets/player/marcos/MAESTRO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_gran_maestro',
      name: 'Gran Maestro',
      minTrophies: 3700,
      borderGradient: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
      shadowColor: Color(0xFF78350F),
      borderWidth: 5.2,
      crownIcon: Icons.emoji_events_rounded,
      description: 'Marco de rango Maestro II. 3700+ trofeos.',
      imagePath: 'assets/player/marcos/GRAN-MAESTRO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_heroico',
      name: 'Heroico',
      minTrophies: 4100,
      borderGradient: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
      shadowColor: Color(0xFF312E81),
      borderWidth: 5.5,
      crownIcon: Icons.shield_rounded,
      description: 'Marco de rango Maestro III. 4100+ trofeos.',
      imagePath: 'assets/player/marcos/HEROICO-MARCOS.png',
    ),
    UserFrameItem(
      id: 'rank_leyenda',
      name: 'Leyenda Suprema',
      minTrophies: 4500,
      borderGradient: [Color(0xFFE11D48), Color(0xFFBE123C), Color(0xFF881337)],
      shadowColor: Color(0xFF4C0519),
      borderWidth: 5.5,
      crownIcon: Icons.star_rounded,
      description: 'Marco de rango Leyenda. 4500+ trofeos.',
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
    this.frameId = 'rank_novato',
    this.level = 0,
    this.size = 64,
    this.showLevelBadge = true,
    this.onTap,
  });

  /// Precarga todos los marcos y avatares oficiales en la memoria de Flutter
  /// para renderizado instantáneo sin demoras ni recargas.
  /// [context] must come from a mounted widget; caller should check mounted.
  static Future<void> precacheAllAssets(BuildContext context) async {
    for (final frame in UserFrameItem.allFrames) {
      if (frame.imagePath != null) {
        try {
          // ignore: use_build_context_synchronously
          await precacheImage(AssetImage(frame.imagePath!), context);
        } catch (_) {}
      }
    }
    for (int i = 1; i <= 5; i++) {
      try {
        // ignore: use_build_context_synchronously
        await precacheImage(AssetImage('assets/player/avatar/$i-AVATAR.png'), context);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = UserFrameItem.getById(frameId);
    final badgeSize = size * 0.38;
    final borderRadius = BorderRadius.circular(size * 0.22);

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
              borderRadius: borderRadius,
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
                    size: size * 0.78,
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
                borderRadius: borderRadius,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.18),
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

          // 4. Insignia de Nivel en la esquina superior derecha
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
    final badgeColor = UserProgress.levelBadgeColor(level);
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(badgeSize * 0.30),
        border: Border.all(color: badgeColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w900,
            fontSize: badgeSize * 0.52,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
