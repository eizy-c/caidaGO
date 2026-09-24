import 'package:flutter/material.dart';
import '../../economy/booster_model.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/services/haptic_service.dart';
import 'chest_slots_view.dart';
import 'user_frame_view.dart';

/// Modal centralizado de Inventario para CaidaGO:
/// - Pestaña 1: Potenciadores (Inventario, activos y adquisición)
/// - Pestaña 2: Marcos (Marcos desbloqueados por trofeos y marco equipado)
/// - Pestaña 3: Cofres (Slots y recompensas)
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
    _tabController = TabController(length: 3, vsync: this);
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

                // Cabecera con balances
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
                      // Balances Monedas y Tickets
                      Row(
                        children: [
                          _buildBalanceBadge(
                            icon: Icons.monetization_on_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            text: '${session.coins}',
                          ),
                          const SizedBox(width: 8),
                          _buildBalanceBadge(
                            icon: Icons.confirmation_number_rounded,
                            iconColor: const Color(0xFF38BDF8),
                            text: '${session.tickets}/${session.maxTickets}',
                          ),
                          const SizedBox(width: 8),
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
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Pestañas
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppPalette.cartoonBgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.cartoonBorder, width: 1.5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppGradients.cyanAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.bolt_rounded, size: 18),
                        text: 'Potenciadores',
                      ),
                      Tab(
                        icon: Icon(Icons.crop_square_rounded, size: 18),
                        text: 'Marcos',
                      ),
                      Tab(
                        icon: Icon(Icons.inventory_2_rounded, size: 18),
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

  Widget _buildBalanceBadge({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.cartoonCardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.cartoonBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: POTENCIADORES ---
  Widget _buildBoostersTab(PlayerSession session) {
    final catalog = BoosterDefinition.catalog;
    final active = session.activeBoosters;

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
        ...catalog.map((def) {
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
                  )
                else
                  App3dButton(
                    label: '${def.coinCost}',
                    variant: App3dButtonVariant.gold,
                    depth: 3.5,
                    onPressed: () {
                      HapticService.instance.onSelection();
                      if (session.coins >= def.coinCost) {
                        session.deductCoinsForVipMatch(def.coinCost);
                        session.addBooster(def.type, 1);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Monedas insuficientes'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    icon: Icons.monetization_on_rounded,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 2: MARCOS ---
  Widget _buildFramesTab(PlayerSession session, int trophies) {
    final frames = UserFrameItem.allFrames;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: frames.length,
      itemBuilder: (context, index) {
        final frame = frames[index];
        final isUnlocked = frame.isUnlockedByTrophies(trophies);
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
              // Preview del marco con avatar cuadrado
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
              Text(
                isUnlocked
                    ? 'Desbloqueado'
                    : (frame.requiredRoomId != null
                        ? 'Completar ${frame.name}'
                        : '${frame.minTrophies} trofeos'),
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.white38,
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
              else if (isUnlocked)
                App3dButton(
                  label: 'Equipar',
                  variant: App3dButtonVariant.gold,
                  depth: 3.0,
                  onPressed: () {
                    HapticService.instance.onSelection();
                    session.updateCustomization(frameId: frame.id);
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white38, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Bloqueado',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: COFRES ---
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
                    'Gana partidas para obtener cofres con monedas, XP y potenciadores.',
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
