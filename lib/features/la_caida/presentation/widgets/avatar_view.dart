import 'package:flutter/material.dart';

/// Definición y configuración de los avatares disponibles (Héroes).
class AvatarPreset {
  final int id;
  final String name;
  final String imagePath;
  final Color bgColor;
  final Color skinColor;
  final Color hairColor;
  final Color shirtColor;
  final String hairType;
  final bool hasGlasses;
  final bool hasMustache;
  final bool hasBeard;
  final bool hasBowtie;
  final bool isStyleB;
  final String category;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.imagePath,
    this.bgColor = const Color(0xFF1E293B),
    this.skinColor = const Color(0xFFFFDBAC),
    this.hairColor = const Color(0xFF1E293B),
    this.shirtColor = const Color(0xFF3B82F6),
    this.hairType = 'short',
    this.hasGlasses = false,
    this.hasMustache = false,
    this.hasBeard = false,
    this.hasBowtie = false,
    this.isStyleB = false,
    this.category = 'heroes',
  });

  /// Lista oficial y unificada de avatares héroes (imágenes de assets/player/avatar/)
  static const List<AvatarPreset> allPresets = [
    AvatarPreset(
      id: 0,
      name: 'Caballero',
      imagePath: 'assets/player/avatar/1-AVATAR.png',
      bgColor: Color(0xFF1E3A8A),
    ),
    AvatarPreset(
      id: 1,
      name: 'Arquera',
      imagePath: 'assets/player/avatar/2-AVATAR.png',
      bgColor: Color(0xFF14532D),
    ),
    AvatarPreset(
      id: 2,
      name: 'Vikingo',
      imagePath: 'assets/player/avatar/3-AVATAR.png',
      bgColor: Color(0xFF9A3412),
    ),
    AvatarPreset(
      id: 3,
      name: 'Mago',
      imagePath: 'assets/player/avatar/4-AVATAR.png',
      bgColor: Color(0xFF581C87),
    ),
    AvatarPreset(
      id: 4,
      name: 'Pícaro',
      imagePath: 'assets/player/avatar/5-AVATAR.png',
      bgColor: Color(0xFF1F2937),
    ),
  ];

  static List<AvatarPreset> get heroesPresets => allPresets;
  static List<AvatarPreset> get styleAPresets => allPresets;
  static List<AvatarPreset> get styleBPresets => allPresets;

  static AvatarPreset getById(int id) {
    if (allPresets.isEmpty) {
      return const AvatarPreset(
        id: 0,
        name: 'Héroe',
        imagePath: 'assets/player/avatar/1-AVATAR.png',
      );
    }
    // Mapeo retrocompatible para IDs antiguos (20 a 24) o cualquier otro número
    final normalized = (id >= 20 && id < 20 + allPresets.length) ? (id - 20) : id;
    return allPresets.firstWhere(
      (p) => p.id == normalized || p.id == id,
      orElse: () => allPresets[normalized.abs() % allPresets.length],
    );
  }
}

/// Widget ilustrado para renderizar cualquier avatar seleccionado.
class AvatarView extends StatelessWidget {
  final int avatarId;
  final double size;
  final bool showBorder;
  final bool isSelected;
  final VoidCallback? onTap;

  const AvatarView({
    super.key,
    required this.avatarId,
    this.size = 54,
    this.showBorder = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preset = AvatarPreset.getById(avatarId);

    Widget avatarContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: preset.bgColor,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: showBorder
            ? Border.all(
                color: isSelected ? const Color(0xFFFDE047) : Colors.white.withValues(alpha: 0.9),
                width: isSelected ? 2.5 : 1.5,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18 - 1),
        child: preset.imagePath.isNotEmpty
            ? Image.asset(
                preset.imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildProceduralStack(preset),
              )
            : _buildProceduralStack(preset),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarContent);
    }
    return avatarContent;
  }

  Widget _buildProceduralStack(AvatarPreset preset) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Cuerpo / Camisa (abajo)
        Positioned(
          bottom: 0,
          child: Container(
            width: size * 0.72,
            height: size * 0.38,
            decoration: BoxDecoration(
              color: preset.shirtColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.25)),
            ),
          ),
        ),

        // Cuello
        Positioned(
          bottom: size * 0.28,
          child: Container(
            width: size * 0.22,
            height: size * 0.16,
            color: preset.skinColor.withValues(alpha: 0.9),
          ),
        ),

        // Pajarita (si tiene)
        if (preset.hasBowtie)
          Positioned(
            bottom: size * 0.26,
            child: Icon(Icons.change_history_rounded, size: size * 0.16, color: Colors.amber),
          ),

        // 2. Cabeza / Rostro
        Positioned(
          top: size * 0.22,
          child: Container(
            width: size * 0.44,
            height: size * 0.50,
            decoration: BoxDecoration(
              color: preset.skinColor,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
          ),
        ),

        // Cabello
        _buildHair(preset),

        // Barba o Bigote
        if (preset.hasBeard)
          Positioned(
            bottom: size * 0.28,
            child: Container(
              width: size * 0.32,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: preset.hairColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(size * 0.16)),
              ),
            ),
          ),
        if (preset.hasMustache)
          Positioned(
            bottom: size * 0.38,
            child: Container(
              width: size * 0.24,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: preset.hairColor,
                borderRadius: BorderRadius.circular(size * 0.04),
              ),
            ),
          ),

        // Ojos
        Positioned(
          top: size * 0.44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size * 0.06,
                height: size * 0.06,
                decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              ),
              SizedBox(width: size * 0.14),
              Container(
                width: size * 0.06,
                height: size * 0.06,
                decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              ),
            ],
          ),
        ),

        // Lentes (si tiene)
        if (preset.hasGlasses)
          Positioned(
            top: size * 0.38,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF18181B), width: 1.5),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: size * 0.06, height: 1.5, color: const Color(0xFF18181B)),
                Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF18181B), width: 1.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

        // Sombrero Vaquero (si tiene)
        if (preset.hairType == 'cowboy')
          Positioned(
            top: size * 0.08,
            child: Container(
              width: size * 0.72,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A), // Paja clara
                borderRadius: BorderRadius.circular(size * 0.08),
                border: Border.all(color: const Color(0xFFD97706), width: 1),
              ),
              child: Center(
                child: Container(
                  width: size * 0.38,
                  height: size * 0.18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHair(AvatarPreset preset) {
    if (preset.hairType == 'cowboy') {
      return const SizedBox.shrink();
    }

    switch (preset.hairType) {
      case 'curly':
        return Positioned(
          top: size * 0.12,
          child: Container(
            width: size * 0.48,
            height: size * 0.26,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.24)),
            ),
          ),
        );
      case 'spiky':
        return Positioned(
          top: size * 0.10,
          child: Container(
            width: size * 0.46,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.circular(size * 0.08),
            ),
          ),
        );
      case 'long':
        return Positioned(
          top: size * 0.14,
          child: Container(
            width: size * 0.52,
            height: size * 0.46,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.circular(size * 0.14),
            ),
          ),
        );
      default:
        return Positioned(
          top: size * 0.14,
          child: Container(
            width: size * 0.46,
            height: size * 0.22,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.22)),
            ),
          ),
        );
    }
  }
}
