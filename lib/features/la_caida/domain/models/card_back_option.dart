import 'package:flutter/material.dart';

/// Representa una opción de diseño de reverso (dorso) de naipes coleccionable y equipable.
class CardBackOption {
  final String id;
  final String name;
  final String subtitle;
  final String assetPath;
  final int? requiredRoomId;
  final bool isDefault;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const CardBackOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
    this.requiredRoomId,
    this.isDefault = false,
    this.primaryColor = const Color(0xFF1E1B4B),
    this.accentColor = const Color(0xFF38BDF8),
    this.icon = Icons.style_rounded,
  });

  /// Indica si este reverso pertenece a una sala regional VIP específica.
  bool get isRegionalRoom => requiredRoomId != null;

  /// Catálogo oficial con reversos predeterminados y reversos de cada sala VIP de Venezuela.
  static const List<CardBackOption> allCardBacks = [
    // --- Reversos por Defecto ---
    CardBackOption(
      id: 'classic_criollo',
      name: 'Clásico CaidaGO',
      subtitle: 'El diseño oficial y tradicional de los naipes CaidaGO',
      assetPath: 'assets/cards/reversos/default.webp',
      isDefault: true,
      primaryColor: Color(0xFF1E1B4B),
      accentColor: Color(0xFF38BDF8),
      icon: Icons.auto_awesome_rounded,
    ),

    // --- Reversos Desbloqueables por cada Sala VIP de Venezuela (1 a 7) ---
    CardBackOption(
      id: 'back_room_1',
      name: 'Chivacoa • Selva Esmeralda',
      subtitle: 'Desbloqueado al ganar en la Sala Chivacoa (Yaracuy)',
      assetPath: 'assets/cards/reversos/1-REVERSO.webp',
      requiredRoomId: 1,
      primaryColor: Color(0xFF064E3B),
      accentColor: Color(0xFF34D399),
      icon: Icons.eco_rounded,
    ),
    CardBackOption(
      id: 'back_room_2',
      name: 'Barquisimeto • Crepúsculo',
      subtitle: 'Desbloqueado al ganar en la Sala Barquisimeto (Lara)',
      assetPath: 'assets/cards/reversos/2-REVERSO.webp',
      requiredRoomId: 2,
      primaryColor: Color(0xFF78350F),
      accentColor: Color(0xFFFBBF24),
      icon: Icons.wb_sunny_rounded,
    ),
    CardBackOption(
      id: 'back_room_3',
      name: 'Tucacas • Océano Caribe',
      subtitle: 'Desbloqueado al ganar en la Sala Tucacas (Falcón)',
      assetPath: 'assets/cards/reversos/3-REVERSO.webp',
      requiredRoomId: 3,
      primaryColor: Color(0xFF164E63),
      accentColor: Color(0xFF22D3EE),
      icon: Icons.waves_rounded,
    ),
    CardBackOption(
      id: 'back_room_4',
      name: 'Maracaibo • Relámpago',
      subtitle: 'Desbloqueado al ganar en la Sala Maracaibo (Zulia)',
      assetPath: 'assets/cards/reversos/4-REVERSO.webp',
      requiredRoomId: 4,
      primaryColor: Color(0xFF7F1D1D),
      accentColor: Color(0xFFF87171),
      icon: Icons.bolt_rounded,
    ),
    CardBackOption(
      id: 'back_room_5',
      name: 'Mérida • Escarcha Andina',
      subtitle: 'Desbloqueado al ganar en la Sala Mérida (Páramo)',
      assetPath: 'assets/cards/reversos/5-REVERSO.webp',
      requiredRoomId: 5,
      primaryColor: Color(0xFF0C4A6E),
      accentColor: Color(0xFFBAE6FD),
      icon: Icons.ac_unit_rounded,
    ),
    CardBackOption(
      id: 'back_room_6',
      name: 'Caracas • Gran Sultana',
      subtitle: 'Desbloqueado al ganar en la Sala Caracas (Capital)',
      assetPath: 'assets/cards/reversos/6-REVERSO.webp',
      requiredRoomId: 6,
      primaryColor: Color(0xFF581C87),
      accentColor: Color(0xFFC084FC),
      icon: Icons.location_city_rounded,
    ),
    CardBackOption(
      id: 'back_room_7',
      name: 'Margarita • Casino Imperial',
      subtitle: 'Desbloqueado al ganar en la Sala Margarita VIP',
      assetPath: 'assets/cards/reversos/7-REVERSO.webp',
      requiredRoomId: 7,
      primaryColor: Color(0xFF713F12),
      accentColor: Color(0xFFFDE047),
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  static CardBackOption getById(String id) {
    return allCardBacks.firstWhere(
      (b) => b.id == id,
      orElse: () => allCardBacks.first,
    );
  }

  static CardBackOption? getByRoomId(int roomId) {
    return allCardBacks.where((b) => b.requiredRoomId == roomId).firstOrNull;
  }
}
