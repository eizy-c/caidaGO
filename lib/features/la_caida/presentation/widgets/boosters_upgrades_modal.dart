import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../economy/booster_model.dart';
import '../../economy/player_session.dart';
import '../../../../core/presentation/widgets/cartoon_widgets.dart';

/// Modal estilizado con estética cartoon de pergamino cálido ('Mejoras')
/// inspirado fielmente en la interfaz de referencia enviada por el usuario.
class BoostersUpgradesModal extends StatefulWidget {
  final PlayerSession session;
  final VoidCallback onOpenShop;

  const BoostersUpgradesModal({
    super.key,
    required this.session,
    required this.onOpenShop,
  });

  /// Muestra el modal posicionado en la parte superior o como diálogo centrado
  static Future<void> show(
    BuildContext context, {
    required PlayerSession session,
    required VoidCallback onOpenShop,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      builder: (ctx) => BoostersUpgradesModal(
        session: session,
        onOpenShop: onOpenShop,
      ),
    );
  }

  @override
  State<BoostersUpgradesModal> createState() => _BoostersUpgradesModalState();
}

class _BoostersUpgradesModalState extends State<BoostersUpgradesModal> {
  // Los 4 potenciadores principales que coinciden exactamente con la referencia:
  // 1. Estrella (XP x2)
  // 2. Flechas Recarga (Regen Tickets)
  // 3. Rayo (+50% Monedas)
  // 4. Medalla de Honor (Escudo de Trofeos)
  final List<BoosterType> _displayBoosters = const [
    BoosterType.xp,
    BoosterType.regen,
    BoosterType.coins,
    BoosterType.shield,
  ];

  void _handleBuy(BoosterDefinition def) {
    HapticFeedback.selectionClick();
    final cost = def.coinCost;

    if (widget.session.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF881337),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(
            'Monedas insuficientes. Necesitas $cost monedas para comprar ${def.name}.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          action: SnackBarAction(
            label: 'TIENDA',
            textColor: const Color(0xFFFDE047),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onOpenShop();
            },
          ),
        ),
      );
      return;
    }

    final success = widget.session.buyBooster(def.type);
    if (success) {
      HapticFeedback.heavyImpact();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          content: Text(
            '¡Compraste 1x ${def.name} (-$cost monedas)!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _handleToggle(BoosterType type) {
    HapticFeedback.mediumImpact();
    final count = widget.session.getBoosterCount(type);
    final isActive = widget.session.isBoosterActive(type);

    if (!isActive && count <= 0) {
      final def = BoosterDefinition.getByType(type);
      _handleBuy(def);
      return;
    }

    widget.session.toggleBooster(type);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 48), // Margen para la flechita superior
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Contenedor principal estilo Pergamino Cálido
            Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6), // Crema cálido
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6B4226), // Borde marrón cartoon
                  width: 2.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado: Título "Mejoras" y botón de cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 28), // Balance visual
                      const Text(
                        'Mejoras',
                        style: TextStyle(
                          color: Color(0xFF5A381E),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2D4BC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF5A381E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fila de los 4 potenciadores
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _displayBoosters.map((type) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5),
                          child: _buildBoosterCard(type),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Barra informativa inferior: Monedas del jugador y estado de activación
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE5CD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD6C5A2), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Color(0xFFCA8A04), size: 16),
                            const SizedBox(width: 5),
                            Text(
                              '${widget.session.coins} Monedas',
                              style: const TextStyle(
                                color: Color(0xFF451A03),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.session.activeBoosters.length}/3 activos',
                          style: TextStyle(
                            color: widget.session.activeBoosters.isEmpty
                                ? const Color(0xFF78350F)
                                : const Color(0xFF15803D),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Triangulito superior que apunta hacia arriba (al botón de la barra)
            Positioned(
              top: -12,
              left: 54, // Alineado hacia la izquierda donde está el icono en la barra
              child: CustomPaint(
                size: const Size(24, 14),
                painter: _SpeechArrowPainter(
                  fillColor: const Color(0xFFFFF9E6),
                  strokeColor: const Color(0xFF6B4226),
                  strokeWidth: 2.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye cada una de las 4 tarjetas de mejoras idénticas a la imagen de referencia
  Widget _buildBoosterCard(BoosterType type) {
    final def = BoosterDefinition.getByType(type);
    final count = widget.session.getBoosterCount(type);
    final isActive = widget.session.isBoosterActive(type);

    // Icono y colores específicos según la referencia visual
    IconData cardIcon;
    Color iconPrimaryColor;
    Color iconGlowColor;

    switch (type) {
      case BoosterType.xp:
        cardIcon = Icons.stars_rounded;
        iconPrimaryColor = const Color(0xFF0284C7); // Azul / Cyan
        iconGlowColor = const Color(0xFF38BDF8);
        break;
      case BoosterType.regen:
        cardIcon = Icons.sync_rounded;
        iconPrimaryColor = const Color(0xFFEAB308); // Amarillo / Dorado
        iconGlowColor = const Color(0xFFFACC15);
        break;
      case BoosterType.coins:
        cardIcon = Icons.bolt_rounded;
        iconPrimaryColor = const Color(0xFFF59E0B); // Rayo dorado / naranja
        iconGlowColor = const Color(0xFFFBBF24);
        break;
      case BoosterType.shield:
      default:
        cardIcon = Icons.military_tech_rounded;
        iconPrimaryColor = const Color(0xFFA855F7); // Medalla violeta / dorada
        iconGlowColor = const Color(0xFFC084FC);
        break;
    }

    return TactilePressable(
      depth: 2.5,
      onTap: () => _handleToggle(type),
      child: Container(
        width: 82,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [const Color(0xFFFEF08A), const Color(0xFFFDE047)]
                : [const Color(0xFFFFFDF5), const Color(0xFFFEF3C7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFCA8A04) : const Color(0xFFD6C5A2),
            width: isActive ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive ? const Color(0x66CA8A04) : Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Parte superior con badge rojo de cantidad en la esquina derecha
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Contenedor circular con brillo para el icono
                Container(
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconGlowColor.withValues(alpha: 0.25),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    cardIcon,
                    color: iconPrimaryColor,
                    size: 34,
                  ),
                ),

                // Badge rojo en la esquina superior derecha con el número (exacto a la imagen)
                Positioned(
                  top: -2,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF15803D) // Verde si está activo
                          : const Color(0xFF2563EB), // Azul cartoon oficial
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                      ],
                    ),
                    child: Text(
                      isActive ? 'OK' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Nombre corto del efecto
            Text(
              def.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF451A03),
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 6),

            // Botón verde redondeado 3D "Comprar" o "Activar" (exacto a la referencia)
            GestureDetector(
              onTap: () {
                if (count > 0 && !isActive) {
                  _handleToggle(type);
                } else {
                  _handleBuy(def);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                        : (count > 0)
                            ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                            : [const Color(0xFF22C55E), const Color(0xFF15803D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isActive ? const Color(0xFF075985) : const Color(0xFF14532D),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF052E16),
                      blurRadius: 0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isActive
                      ? 'Activo'
                      : (count > 0 ? 'Usar' : 'Comprar'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para dibujar la flecha / triángulo del speech bubble superior
class _SpeechArrowPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  _SpeechArrowPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    
    // Dibujamos solo los dos lados inclinados del triángulo
    final borderPath = Path();
    borderPath.moveTo(0, size.height);
    borderPath.lineTo(size.width / 2, 0);
    borderPath.lineTo(size.width, size.height);
    canvas.drawPath(borderPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
