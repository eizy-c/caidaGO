import 'package:flutter/material.dart';
import '../../economy/booster_model.dart';
import '../../economy/player_session.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';

/// Widget compacto en el lobby para ver y equipar potenciadores antes de jugar.
class BoosterSelectorWidget extends StatelessWidget {
  final PlayerSession session;
  final VoidCallback onOpenShop;

  const BoosterSelectorWidget({
    super.key,
    required this.session,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final active = session.activeBoosters;

        return GestureDetector(
          onTap: () => _openManagementSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1338), Color(0xFF120B24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2E2E2E),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFFDE047),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'POTENCIADORES',
                          style: TextStyle(
                            color: Color(0xFFE9D5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          active.isEmpty
                              ? 'Ninguno activo'
                              : '${active.length}/3 activos',
                          style: TextStyle(
                            color: active.isEmpty ? Colors.white54 : const Color(0xFFFDE047),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Slots visuales (3 slots)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final hasBooster = index < active.length;
                    final boosterType = hasBooster ? active[index] : null;
                    final def = boosterType != null
                        ? BoosterDefinition.getByType(boosterType)
                        : null;

                    return Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: hasBooster
                            ? def!.color.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasBooster ? def!.color : Colors.white24,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: hasBooster
                            ? Icon(def!.icon, size: 14, color: def.color)
                            : const Icon(Icons.add_rounded, size: 12, color: Colors.white30),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openManagementSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BoosterManagementSheet(
        session: session,
        onOpenShop: () {
          Navigator.of(context).pop();
          onOpenShop();
        },
      ),
    );
  }
}

class _BoosterManagementSheet extends StatelessWidget {
  final PlayerSession session;
  final VoidCallback onOpenShop;

  const _BoosterManagementSheet({
    required this.session,
    required this.onOpenShop,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final active = session.activeBoosters;

        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF201335), Color(0xFF0F071A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'GESTIÓN DE POTENCIADORES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Activa hasta 3 potenciadores para la próxima partida.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Lista de tipos de potenciadores
                ...BoosterDefinition.catalog.map((def) {
                  final inInventory = session.getBoosterCount(def.type);
                  final isActive = active.contains(def.type);
                  final activeCount = active.where((t) => t == def.type).length;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2E2E2E),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: def.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(def.icon, color: def.color, size: 20),
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (activeCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: def.color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Activo x$activeCount',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                def.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'En inventario: $inInventory',
                                style: TextStyle(
                                  color: inInventory > 0 ? const Color(0xFFFDE047) : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Botones de acción
                        if (isActive)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () => session.deactivateBooster(def.type),
                            child: const Text('Quitar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        else if (inInventory > 0)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: def.color,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: active.length < 3
                                ? () => session.activateBooster(def.type)
                                : null,
                            child: const Text('Activar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF262626),
                              foregroundColor: const Color(0xFFFDE047),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: onOpenShop,
                            child: const Text('Comprar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 10),

                App3dButton(
                  onPressed: onOpenShop,
                  height: 44,
                  depth: 4,
                  borderRadius: 14,
                  variant: App3dButtonVariant.gold,
                  label: '🛒 TIENDA DE POTENCIADORES',
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
