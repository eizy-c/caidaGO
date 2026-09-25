import 'package:flutter/material.dart';
import '../../economy/booster_model.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/trophy_session_manager.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/services/haptic_service.dart';
import 'avatar_view.dart';
import 'chest_slots_view.dart';
import 'profile_and_level_modal.dart';
import 'user_frame_view.dart';

/// Modal centralizado de Inventario para CaidaGO:
/// Solo muestra elementos que el usuario posee, ha comprado o ha desbloqueado.
/// - Pestaña 1: Potenciadores (Disponibles y activos)
/// - Pestaña 2: Marcos (Desbloqueados)
/// - Pestaña 3: Avatares (Héroes disponibles)
/// - Pestaña 4: Fondos (Desbloqueados)
/// - Pestaña 5: Cofres (Slots y recompensas)
class InventoryModal extends StatefulWidget {
  const InventoryModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const InventoryModal(),
    );
  }

  @override
  State<InventoryModal> createState() => _InventoryModalState();
}

class _InventoryModalState extends State<InventoryModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerSession.shared,
      builder: (context, _) {
        final session = PlayerSession.shared;
        final stats = PlayerStatsModel.shared;

        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E267D), Color(0xFF26206D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Tirador superior
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Cabecera: solo título y botón cerrar (sin balances según requerimiento)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppPalette.cartoonCardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppPalette.cartoonBorder,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.backpack_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Inventario',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      TactilePressable(
                        depth: 2.0,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppGradients.redDanger,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Pestañas de categorías
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppPalette.cartoonBgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    indicator: BoxDecoration(
                      gradient: AppGradients.cyanAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.bolt_rounded, size: 16),
                        text: 'Potenciadores',
                      ),
                      Tab(
                        icon: Icon(Icons.crop_square_rounded, size: 16),
                        text: 'Marcos',
                      ),
                      Tab(
                        icon: Icon(Icons.face_rounded, size: 16),
                        text: 'Avatares',
                      ),
                      Tab(
                        icon: Icon(Icons.wallpaper_rounded, size: 16),
                        text: 'Fondos',
                      ),
                      Tab(
                        icon: Icon(Icons.inventory_2_rounded, size: 16),
                        text: 'Cofres',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Contenido de las pestañas
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBoostersTab(session),
                      _buildFramesTab(session, stats.trophies),
                      _buildAvatarsTab(session),
                      _buildThemesTab(session),
                      _buildChestsTab(session),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 1: POTENCIADORES (Solo adquiridos / disponibles) ---
  Widget _buildBoostersTab(PlayerSession session) {
    final catalog = BoosterDefinition.catalog;
    final active = session.activeBoosters;
    final owned = catalog.where((def) => session.getBoosterCount(def.type) > 0 || active.contains(def.type)).toList();

    if (owned.isEmpty && active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_outlined, size: 52, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(height: 12),
              const Text(
                'No tienes potenciadores en tu inventario.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '¡Gánalos al abrir cofres de victoria en las distintas mesas!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (active.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppPalette.cartoonCardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Potenciadores Activos en Partida',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: active.map((type) {
                    final def = BoosterDefinition.getByType(type);
                    return Chip(
                      backgroundColor: AppPalette.cartoonBgDark,
                      side: BorderSide(color: AppPalette.cartoonBorder),
                      avatar: Icon(def.icon, color: def.color, size: 16),
                      label: Text(
                        def.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                      onDeleted: () {
                        HapticService.instance.onSelection();
                        session.deactivateBooster(type);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        ...owned.map((def) {
          final count = session.getBoosterCount(def.type);
          final isActive = active.contains(def.type);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.cartoonCardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppPalette.cartoonBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
                  ),
                  child: Icon(def.icon, color: def.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            def.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: count > 0 ? const Color(0xFF0284C7) : Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x$count',
                              style: TextStyle(
                                color: count > 0 ? Colors.white : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        def.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  App3dButton(
                    label: 'Activo',
                    variant: App3dButtonVariant.emerald,
                    depth: 3.5,
                    onPressed: () {
                      HapticService.instance.onSelection();
                      session.deactivateBooster(def.type);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    icon: Icons.check_rounded,
                  )
                else if (count > 0)
                  App3dButton(
                    label: 'Activar',
                    variant: App3dButtonVariant.cyan,
                    depth: 3.5,
                    onPressed: () {
                      HapticService.instance.onSelection();
                      final ok = session.activateBooster(def.type);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Máximo 3 potenciadores activos a la vez'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    icon: Icons.bolt_rounded,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 2: MARCOS (Solo desbloqueados) ---
  Widget _buildFramesTab(PlayerSession session, int trophies) {
    final unlockedFrames = UserFrameItem.allFrames.where((f) => f.isUnlockedByTrophies(trophies)).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: unlockedFrames.length,
      itemBuilder: (context, index) {
        final frame = unlockedFrames[index];
        final isEquipped = session.selectedFrameId == frame.id;

        return Container(
          decoration: BoxDecoration(
            color: AppPalette.cartoonCardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEquipped ? const Color(0xFFFDE047) : AppPalette.cartoonBorder,
              width: isEquipped ? 2.2 : 1.5,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: UserFrameView(
                  avatarIndex: session.avatarIndex,
                  frameId: frame.id,
                  size: 64,
                  level: session.level,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                frame.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Desbloqueado',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (isEquipped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.cartoonBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Color(0xFFFDE047), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Equipado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                App3dButton(
                  label: 'Equipar',
                  variant: App3dButtonVariant.gold,
                  depth: 3.0,
                  onPressed: () {
                    HapticService.instance.onSelection();
                    session.updateCustomization(frameId: frame.id);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: AVATARES (Avatares disponibles) ---
  Widget _buildAvatarsTab(PlayerSession session) {
    final heroes = AvatarPreset.allPresets;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: heroes.length,
      itemBuilder: (context, index) {
        final hero = heroes[index];
        final isEquipped = session.avatarIndex == hero.id;

        return GestureDetector(
          onTap: () {
            HapticService.instance.onSelection();
            session.updateCustomization(avatarIndex: hero.id);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppPalette.cartoonCardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEquipped ? const Color(0xFFFDE047) : AppPalette.cartoonBorder,
                width: isEquipped ? 2.5 : 1.5,
              ),
              boxShadow: isEquipped
                  ? [
                      const BoxShadow(
                        color: Color(0x60FDE047),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      hero.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEquipped ? const Color(0xFFFDE047) : Colors.white,
                    fontWeight: isEquipped ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEquipped ? 'Equipado' : 'Tocar para usar',
                  style: TextStyle(
                    color: isEquipped ? const Color(0xFF86EFAC) : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 4: FONDOS (Solo desbloqueados) ---
  Widget _buildThemesTab(PlayerSession session) {
    final unlockedThemes = LobbyThemeOption.allThemes.where((theme) {
      if (theme.requiredRoomId == null) return true;
      return TrophySessionManager.shared.isRoomUnlocked(theme.requiredRoomId!);
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: unlockedThemes.length,
      itemBuilder: (context, index) {
        final theme = unlockedThemes[index];
        final isEquipped = session.selectedThemeId == theme.id;

        return GestureDetector(
          onTap: () {
            HapticService.instance.onSelection();
            session.updateCustomization(themeId: theme.id);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.backgroundGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEquipped ? const Color(0xFFFDE047) : AppPalette.cartoonBorder,
                width: isEquipped ? 2.5 : 1.5,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(theme.icon, color: theme.accentColor, size: 20),
                    if (isEquipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE047),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(color: Color(0xFF1E1B4B), fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (theme.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        theme.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 5: COFRES ---
  Widget _buildChestsTab(PlayerSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.cartoonCardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Gana partidas para obtener cofres con monedas, XP, potenciadores y trofeos.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ChestSlotsView(session: session),
        ],
      ),
    );
  }
}
