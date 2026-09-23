import 'dart:async';
import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/ticket_shop_offer.dart';
import '../../economy/booster_model.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../../../core/theme/app_palette.dart';

/// Modal de Tienda de Tickets y Potenciadores para partidas de La Caída.
class BuyTicketsModal extends StatefulWidget {
  final PlayerSession session;
  final int initialTab;

  const BuyTicketsModal({
    super.key,
    required this.session,
    this.initialTab = 0,
  });

  /// Muestra el modal en un bottom sheet estilizado de alta gama.
  static Future<void> show(
    BuildContext context, {
    required PlayerSession session,
    int initialTab = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BuyTicketsModal(session: session, initialTab: initialTab),
    );
  }

  @override
  State<BuyTicketsModal> createState() => _BuyTicketsModalState();
}

class _BuyTicketsModalState extends State<BuyTicketsModal> {
  late int _selectedTab;
  String? _feedbackMessage;
  Color _feedbackColor = const Color(0xFF10B981);
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _buyBoosterOffer(BoosterType type) {
    final def = BoosterDefinition.getByType(type);
    final success = widget.session.buyBooster(type);
    if (success) {
      _showFeedback('¡Compraste 1x ${def.name}!');
    } else {
      _showFeedback('Monedas insuficientes (necesitas ${def.coinCost} monedas).', isError: true);
    }
  }

  void _buyChampionBundle() {
    const cost = 900;
    final success = widget.session.buyBoosterBundle(
      cost: cost,
      boosters: [BoosterType.xp, BoosterType.shield, BoosterType.coins],
    );
    if (success) {
      _showFeedback('¡Paquete Campeón adquirido! (3 potenciadores agregados)');
    } else {
      _showFeedback('Monedas insuficientes (necesitas 900 monedas).', isError: true);
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    });

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  void _claimAdTicket() {
    final success = widget.session.claimAdTicketReward();
    if (success) {
      _showFeedback('¡+1 Ticket obtenido viendo el video!');
    } else {
      _showFeedback('Ya tienes el máximo de tickets disponibles (10/10).', isError: true);
    }
  }

  void _buySingleTicket() {
    final success = widget.session.buyTicketsWithCoins(1);
    if (success) {
      _showFeedback('¡Compraste 1 Ticket por 400 monedas!');
    } else {
      if (widget.session.coins < 400) {
        _showFeedback('Monedas insuficientes (necesitas 400 monedas).', isError: true);
      } else {
        _showFeedback('Ya tienes el máximo de tickets disponibles.', isError: true);
      }
    }
  }

  void _buyFivePack() {
    final success = widget.session.buyTicketsWithCoins(5, customCoinCost: 1800);
    if (success) {
      _showFeedback('¡Paquete de 5 Tickets adquirido por 1,800 monedas!');
    } else {
      if (widget.session.coins < 1800) {
        _showFeedback('Monedas insuficientes (necesitas 1,800 monedas).', isError: true);
      } else {
        _showFeedback('Ya tienes el máximo de tickets disponibles.', isError: true);
      }
    }
  }

  void _executeOffer(TicketShopOffer offer) {
    if (offer.isAd) {
      _claimAdTicket();
    } else if (offer.ticketsGranted == 1) {
      _buySingleTicket();
    } else {
      _buyFivePack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final isMaxTickets = session.tickets >= session.maxTickets;

        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  blurRadius: 25,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tirador superior para arrastre
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Encabezado con título, saldo y botón cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF242424),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E2E2E), width: 1.0),
                            ),
                            child: const Icon(
                              Icons.confirmation_num_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TIENDA DE TICKETS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'Pases de Juego',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Contador de monedas del jugador
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 5),
                          Text(
                            '${session.coins}',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Selector de pestañas: Tickets vs Potenciadores
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? const Color(0xFF2E2E2E)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.confirmation_num_rounded,
                                size: 16,
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tickets',
                                style: TextStyle(
                                  color: _selectedTab == 0
                                      ? Colors.white
                                      : Colors.white54,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? const Color(0xFF2E2E2E)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2E2E2E),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: _selectedTab == 1
                                    ? const Color(0xFFFDE047)
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Potenciadores',
                                    style: TextStyle(
                                      color: _selectedTab == 1
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_feedbackMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _feedbackColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _feedbackColor, width: 1),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                if (_selectedTab == 0) ...[
                  // Barra de energía / tickets actuales
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'TICKETS DISPONIBLES',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${session.tickets} / ${session.maxTickets}',
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.confirmation_num_rounded, color: Color(0xFF38BDF8), size: 16),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: session.tickets / session.maxTickets,
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMaxTickets
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMaxTickets ? Icons.bolt_rounded : Icons.timer_outlined,
                                    size: 13,
                                    color: isMaxTickets ? const Color(0xFF10B981) : Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isMaxTickets
                                          ? '¡Energía al 100%!'
                                          : '1 ticket cada 20 min',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMaxTickets) ...[
                              const SizedBox(width: 8),
                              const Text(
                                'Activa',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Opciones oficiales de la tienda basadas en el objeto TicketShopOffer
                  ...TicketShopOffer.standardOffers.map((offer) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOptionCard(
                        icon: offer.icon,
                        iconColor: offer.iconColor,
                        title: offer.title,
                        subtitle: offer.subtitle,
                        priceLabel: offer.priceLabel,
                        isPriceCoin: offer.isPriceCoin,
                        isEnabled: offer.isEnabled(isMaxTickets: isMaxTickets, playerCoins: session.coins),
                        disabledLabel: offer.disabledLabel(isMaxTickets: isMaxTickets, playerCoins: session.coins),
                        badgeText: offer.badgeText,
                        badgeColor: offer.badgeColor,
                        oldPriceLabel: offer.oldPriceLabel,
                        isHighlighted: offer.isHighlighted,
                        onTap: () => _executeOffer(offer),
                      ),
                    );
                  }),
                ] else ...[
                  // PESTAÑA: POTENCIADORES
                  // Oferta Destacada: Paquete Campeón
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildOptionCard(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: const Color(0xFFFDE047),
                      title: 'Paquete Campeón (3x)',
                      subtitle: '1x Racha Dorada, 1x Escudo, 1x Lluvia',
                      priceLabel: '900',
                      oldPriceLabel: '1,150',
                      badgeText: 'AHORRA 22%',
                      badgeColor: const Color(0xFFD97706),
                      isPriceCoin: true,
                      isHighlighted: true,
                      isEnabled: session.coins >= 900,
                      disabledLabel: 'SIN MONEDAS',
                      onTap: _buyChampionBundle,
                    ),
                  ),

                  // Ofertas Individuales
                  ...BoosterDefinition.catalog.map((def) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOptionCard(
                        icon: def.icon,
                        iconColor: def.color,
                        title: '${def.name} (1x)',
                        subtitle: def.description,
                        priceLabel: '${def.coinCost}',
                        isPriceCoin: true,
                        isEnabled: session.coins >= def.coinCost,
                        disabledLabel: 'SIN MONEDAS',
                        onTap: () => _buyBoosterOffer(def.type),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String priceLabel,
    String? oldPriceLabel,
    String? badgeText,
    Color? badgeColor,
    required bool isPriceCoin,
    required bool isEnabled,
    String? disabledLabel,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppPalette.cartoonCardDark
            : AppPalette.cartoonBgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.cartoonBorder,
          width: 1.5,
        ),
        boxShadow: isHighlighted
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icono temático
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Títulos y badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (oldPriceLabel != null) ...[
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 10, color: Colors.white38),
                          const SizedBox(width: 2),
                          Text(
                            oldPriceLabel,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botón de acción interactivo 3D táctil
          App3dButton(
            onPressed: isEnabled ? onTap : null,
            label: isEnabled ? priceLabel : (disabledLabel ?? 'NO DISP.'),
            icon: (isEnabled && isPriceCoin) ? Icons.monetization_on_rounded : null,
            iconColor: const Color(0xFFFDE047),
            iconSize: 13,
            variant: isHighlighted ? App3dButtonVariant.gold : App3dButtonVariant.emerald,
            depth: 3.5,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isEnabled
                  ? (isHighlighted ? const Color(0xFF1E1B4B) : Colors.white)
                  : const Color(0xFF7E7E7E),
            ),
          ),
        ],
      ),
    );
  }
}
