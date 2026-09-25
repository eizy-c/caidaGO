import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/rank_system.dart';
import '../../economy/trophy_session_manager.dart';
import '../../economy/venezuela_room_tier.dart';
import 'avatar_view.dart';
import 'user_frame_view.dart';

/// Definición de paletas de fondo temáticas seleccionables por el usuario.
class LobbyThemeOption {
  final String id;
  final String name;
  final String? subtitle;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final IconData icon;
  final String? imageAsset;
  final int? requiredRoomId;

  const LobbyThemeOption({
    required this.id,
    required this.name,
    this.subtitle,
    required this.backgroundGradient,
    required this.accentColor,
    required this.icon,
    this.imageAsset,
    this.requiredRoomId,
  });

  bool get isRegionalRoom => requiredRoomId != null;

  static const List<LobbyThemeOption> allThemes = [
    // --- Temas Clásicos de Tapete ---
    LobbyThemeOption(
      id: 'royal_blue',
      name: 'Criollo Indigo (Oficial)',
      subtitle: 'Tapete tradicional de mesa Criolla',
      backgroundGradient: [Color(0xFF3B32B0), Color(0xFF2E2692), Color(0xFF251E75)],
      accentColor: Color(0xFF22D3EE),
      icon: Icons.auto_awesome_rounded,
    ),
    LobbyThemeOption(
      id: 'casino_green',
      name: 'Tapete Clásico Verde',
      subtitle: 'Fieltro tradicional de casino',
      backgroundGradient: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
      accentColor: Color(0xFF4ADE80),
      icon: Icons.table_restaurant_rounded,
    ),
    LobbyThemeOption(
      id: 'purple_night',
      name: 'Púrpura Imperial',
      subtitle: 'Noche misteriosa y elegante',
      backgroundGradient: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF581C87)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.auto_awesome_rounded,
    ),
    LobbyThemeOption(
      id: 'wood_classic',
      name: 'Madera Noble',
      subtitle: 'Vetas rústicas tradicionales',
      backgroundGradient: [Color(0xFF29150B), Color(0xFF451A03), Color(0xFF78350F)],
      accentColor: Color(0xFFFDE047),
      icon: Icons.nature_rounded,
    ),
    LobbyThemeOption(
      id: 'crimson_gold',
      name: 'Carmesí Real',
      subtitle: 'Oro y terciopelo carmesí',
      backgroundGradient: [Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF991B1B)],
      accentColor: Color(0xFFFBBF24),
      icon: Icons.shield_moon_rounded,
    ),

    // --- Fondos Regionales de Venezuela (Desbloqueables al ganar) ---
    LobbyThemeOption(
      id: 'room_fondo_1',
      name: 'Chivacoa • Yaracuy',
      subtitle: 'Mesa del Alambique y Selva Esmeralda',
      backgroundGradient: [Color(0xFF064E3B), Color(0xFF022C22)],
      accentColor: Color(0xFF34D399),
      icon: Icons.eco_rounded,
      imageAsset: 'assets/Tiers/backgrounds/1-FONDO.webp',
      requiredRoomId: 1,
    ),
    LobbyThemeOption(
      id: 'room_fondo_2',
      name: 'Barquisimeto • Lara',
      subtitle: 'Atardecer Crepuscular y Obelisco',
      backgroundGradient: [Color(0xFF78350F), Color(0xFF451A03)],
      accentColor: Color(0xFFFBBF24),
      icon: Icons.wb_sunny_rounded,
      imageAsset: 'assets/Tiers/backgrounds/2-FONDO.webp',
      requiredRoomId: 2,
    ),
    LobbyThemeOption(
      id: 'room_fondo_3',
      name: 'Tucacas • Falcón',
      subtitle: 'Brisa Marina y Parque Morrocoy',
      backgroundGradient: [Color(0xFF164E63), Color(0xFF083344)],
      accentColor: Color(0xFF22D3EE),
      icon: Icons.waves_rounded,
      imageAsset: 'assets/Tiers/backgrounds/3-FONDO.webp',
      requiredRoomId: 3,
    ),
    LobbyThemeOption(
      id: 'room_fondo_4',
      name: 'Maracaibo • Zulia',
      subtitle: 'Calor Zuliano y Relámpago',
      backgroundGradient: [Color(0xFF7F1D1D), Color(0xFF450A0A)],
      accentColor: Color(0xFFF87171),
      icon: Icons.bolt_rounded,
      imageAsset: 'assets/Tiers/backgrounds/4-FONDO.webp',
      requiredRoomId: 4,
    ),
    LobbyThemeOption(
      id: 'room_fondo_5',
      name: 'Mérida • Páramo ❄️',
      subtitle: 'Páramo Andino y Baraja Helada',
      backgroundGradient: [Color(0xFF0C4A6E), Color(0xFF082F49)],
      accentColor: Color(0xFFBAE6FD),
      icon: Icons.ac_unit_rounded,
      imageAsset: 'assets/Tiers/backgrounds/5-FONDO.webp',
      requiredRoomId: 5,
    ),
    LobbyThemeOption(
      id: 'room_fondo_6',
      name: 'Caracas • Capital',
      subtitle: 'La Gran Sultana y El Ávila',
      backgroundGradient: [Color(0xFF581C87), Color(0xFF3B0764)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.location_city_rounded,
      imageAsset: 'assets/Tiers/backgrounds/6-FONDO.webp',
      requiredRoomId: 6,
    ),
    LobbyThemeOption(
      id: 'room_fondo_7',
      name: 'Margarita VIP • Caribe',
      subtitle: 'Casino del Caribe y Playa Dorada',
      backgroundGradient: [Color(0xFF713F12), Color(0xFF422006)],
      accentColor: Color(0xFFFDE047),
      icon: Icons.workspace_premium_rounded,
      imageAsset: 'assets/Tiers/backgrounds/7-FONDO.webp',
      requiredRoomId: 7,
    ),
  ];

  static LobbyThemeOption getById(String id) {
    return allThemes.firstWhere((t) => t.id == id, orElse: () => allThemes.first);
  }
}

/// Modal de personalización del perfil del jugador:
/// Permite editar Nombre, Avatar de héroe, Marcos competitivos y Fondos de tapete.
/// El nivel y la XP han sido omitidos ya que se gestionan en las Estadísticas oficiales.
class ProfileAndLevelModal extends StatefulWidget {
  final PlayerSession session;
  final int initialTabIndex;

  const ProfileAndLevelModal({
    super.key,
    required this.session,
    this.initialTabIndex = 0,
  });

static Future<void> show(
    BuildContext context, {
    required PlayerSession session,
    int initialTabIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,

      builder: (_) => ProfileAndLevelModal(
        session: session,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<ProfileAndLevelModal> createState() => _ProfileAndLevelModalState();
}

class _ProfileAndLevelModalState extends State<ProfileAndLevelModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late int _tempAvatarIndex;
  late String _tempFrameId;
  late String _tempThemeId;

  @override
  void initState() {
    super.initState();
    // 3 pestañas: 0 = Avatar, 1 = Marcos, 2 = Fondos
    final initIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initIndex);
    _nameController = TextEditingController(text: widget.session.name);
    _tempAvatarIndex = widget.session.avatarIndex;
    _tempFrameId = widget.session.selectedFrameId;
    _tempThemeId = widget.session.selectedThemeId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveCustomization() {
    final finalName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Jugador';
    widget.session.updateCustomization(
      name: finalName,
      avatarIndex: _tempAvatarIndex,
      frameId: _tempFrameId,
      themeId: _tempThemeId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E267D), Color(0xFF26206D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              // 1. Cabecera superior con Avatar y Rango (sin nivel) y botón de cierre táctil
              _buildHeader(),

              // 2. Barra de Pestañas Cartoon (Avatar, Marcos, Fondos)
              Container(
                decoration: const BoxDecoration(
                  color: AppPalette.cartoonBgDark,
                  border: Border(
                    bottom: BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppPalette.cartoonCyan,
                  indicatorWeight: 3.0,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(icon: Icon(Icons.person_rounded, size: 20), text: 'Avatar'),
                    Tab(icon: Icon(Icons.filter_frames_rounded, size: 20), text: 'Marcos'),
                    Tab(icon: Icon(Icons.palette_rounded, size: 20), text: 'Fondos'),
                  ],
                ),
              ),

              // 3. Contenido de las 3 pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvatarTab(),
                    _buildFramesTab(),
                    _buildThemesTab(),
                  ],
                ),
              ),

              // 4. Botón inferior de Guardar
              Padding(
                padding: const EdgeInsets.all(12),
                child: App3dButton(
                  onPressed: _saveCustomization,
                  expand: true,
                  height: 46,
                  depth: 5,
                  borderRadius: 14,
                  variant: App3dButtonVariant.cyan,
                  label: 'GUARDAR CAMBIOS',
                  textStyle: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final trophies = PlayerStatsModel.shared.trophies;
    final rank = RankInfo.forTrophies(trophies);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          UserFrameView(
            avatarIndex: _tempAvatarIndex,
            frameId: _tempFrameId,
            size: 48,
            showLevelBadge: false, // Sin insignia numérica de nivel
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Jugador',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
const SizedBox(height: 2),

                Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: rank.gradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        rank.fullNameFor(trophies),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$trophies 🏆',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TactilePressable(
            depth: 2.5,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppGradients.redDanger,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),

            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 1: AVATAR & NOMBRE ---
  Widget _buildAvatarTab() {
    final heroes = AvatarPreset.heroesPresets;

    return Column(
      children: [
        // Campo de edición de nombre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _nameController,
            maxLength: 14,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Nombre de Jugador',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.badge_rounded, color: AppPalette.cartoonCyan, size: 18),
              filled: true,
              fillColor: AppPalette.cartoonBgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.cartoonBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppPalette.cartoonCyan, width: 1.8),
              ),
              counterStyle: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Encabezado de Héroes disponibles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, size: 16, color: AppPalette.cartoonYellow),
                  SizedBox(width: 6),
                  Text(
                    'AVATARES DISPONIBLES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppPalette.cartoonBgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppPalette.cartoonBorder),
                ),
                child: Text(
                  '${heroes.length} Héroes',
                  style: const TextStyle(
                    color: AppPalette.cartoonCyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid de Avatares Héroes
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: heroes.length,
            itemBuilder: (context, i) {
              final hero = heroes[i];
              final isSelected = _tempAvatarIndex == hero.id;

              return TactilePressable(
                depth: 2.5,
                onTap: () {
                  setState(() {
                    _tempAvatarIndex = hero.id;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF22D3EE).withValues(alpha: 0.15) : AppPalette.cartoonCardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppPalette.cartoonCyan : AppPalette.cartoonBorder,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                  color: Color(0xFF22D3EE),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AvatarView(
                          avatarId: hero.id,
                          size: 52,
                          showBorder: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? AppPalette.cartoonYellow : Colors.white70,
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- PESTAÑA 2: MARCOS DE USUARIO ---
  Widget _buildFramesTab() {
    final playerTrophies = PlayerStatsModel.shared.trophies;

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      physics: const BouncingScrollPhysics(),
      itemCount: UserFrameItem.allFrames.length,
      itemBuilder: (context, i) {
        final frame = UserFrameItem.allFrames[i];
        final isUnlocked = frame.isUnlockedByTrophies(playerTrophies);
        final isSelected = _tempFrameId == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF382F99) : AppPalette.cartoonCardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppPalette.cartoonCyan : AppPalette.cartoonBorder,
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  UserFrameView(
                    avatarIndex: _tempAvatarIndex,
                    frameId: frame.id,
                    size: 46,
                    showLevelBadge: false,
                  ),
                  if (!isUnlocked)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          frame.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFBBF24)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      frame.description,
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? 'Desbloqueado'
                          : (frame.requiredRoomId != null
                              ? 'Requiere conquistar ${frame.name} (${frame.minTrophies} 🏆)'
                              : 'Requiere ${frame.minTrophies} Trofeos 🏆'),
                      style: TextStyle(
                        color: isUnlocked ? const Color(0xFF10B981) : const Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TactilePressable(
                depth: 2.5,
                onTap: isUnlocked
                    ? () {
                        setState(() {
                          _tempFrameId = frame.id;
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppGradients.greenAccept
                        : (isUnlocked ? AppGradients.cyanAccent : null),
                    color: isUnlocked ? null : Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                      else if (!isUnlocked)
                        const Icon(Icons.lock_rounded, color: Colors.white38, size: 13),
                      if (isSelected || !isUnlocked) const SizedBox(width: 3),
                      Text(
                        isSelected ? 'ACTIVO' : (isUnlocked ? 'EQUIPAR' : 'BLOQUEADO'),
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PESTAÑA 3: FONDOS / TEMAS DE COLOR ---
  Widget _buildThemesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      physics: const BouncingScrollPhysics(),
      itemCount: LobbyThemeOption.allThemes.length,
      itemBuilder: (context, i) {
        final theme = LobbyThemeOption.allThemes[i];
        final isSelected = _tempThemeId == theme.id;

        final bool isUnlocked;
        final String effectiveSubtitle;
        if (theme.requiredRoomId != null) {
          final roomId = theme.requiredRoomId!;
          final roomTrophies = TrophySessionManager.shared.getTrophies(roomId);
          final isRoomUnlocked = TrophySessionManager.shared.isRoomUnlocked(roomId);
          final isCompleted = TrophySessionManager.shared.isRoomCompleted(roomId);
          final room = VenezuelaRoomCatalog.getById(roomId);
          isUnlocked = roomTrophies > 0 || isRoomUnlocked || isCompleted;
          effectiveSubtitle = isUnlocked
              ? (theme.subtitle ?? 'Fondo ilustrado oficial de ${room.name}')
              : '🔒 Gana trofeos en ${room.name} para desbloquear';
        } else {
          isUnlocked = true;
          effectiveSubtitle = theme.subtitle ?? 'Fondo de interfaz y tapete para el Lobby';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF382F99)
                : (!isUnlocked ? const Color(0xFF1E1742) : AppPalette.cartoonCardDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.accentColor
                  : (isUnlocked ? AppPalette.cartoonBorder : Colors.white12),
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              // Muestra visual del fondo: Imagen o Gradiente
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.accentColor : AppPalette.cartoonBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: theme.imageAsset != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(theme.imageAsset!, fit: BoxFit.cover),
                            if (!isUnlocked)
                              Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                child: const Center(
                                  child: Icon(Icons.lock_rounded, color: Color(0xFFFDE047), size: 18),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: theme.backgroundGradient),
                          ),
                          child: Center(
                            child: Icon(theme.icon, color: theme.accentColor, size: 22),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            theme.name,
                            style: TextStyle(
                              color: isUnlocked ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (theme.isRegionalRoom && isUnlocked) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.accentColor.withValues(alpha: 0.6), width: 0.8),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      effectiveSubtitle,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white60 : const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: isUnlocked ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TactilePressable(
                depth: 2.5,
                onTap: () {
                  if (!isUnlocked) {
                    HapticFeedback.lightImpact();
                    return;
                  }
                  HapticFeedback.selectionClick();
                  setState(() {
                    _tempThemeId = theme.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppGradients.greenAccept
                        : (isUnlocked ? AppGradients.cyanAccent : null),
                    color: isUnlocked ? null : const Color(0xFF2E267D).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlocked ? AppPalette.cartoonBorder : Colors.white12,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                      else if (!isUnlocked)
                        const Icon(Icons.lock_rounded, color: Colors.white38, size: 12),
                      if (isSelected || !isUnlocked) const SizedBox(width: 3),
                      Text(
                        isSelected ? 'APLICADO' : (isUnlocked ? 'APLICAR' : 'BLOQUEADO'),
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
