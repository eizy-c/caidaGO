import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_palette.dart';
import '../../../features/la_caida/economy/rank_system.dart';

/// Gradientes semánticos complementarios del juego:
/// - Verde: Aceptar, Jugar, Confirmar, Conectar, Listo.
/// - Rojo: Eliminar, Cancelar, Abandonar, Salir, Peligro.
/// - Dorado: Monedas, Trofeos, Premios, VIP, Crear Sala.
/// - Cyan: Niveles, Tickets, Selección activa, Información.
/// - Rangos: Gradientes de bronce a leyenda para insignias y tarjetas de perfil.
class AppGradients {
  static const LinearGradient greenAccept = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient redDanger = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  static const LinearGradient goldReward = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
  );

  static const LinearGradient cyanAccent = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF22D3EE), Color(0xFF0284C7)],
  );

  // Gradientes específicos de Rango por Trofeos
  static const LinearGradient rankNovato = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF64748B), Color(0xFF475569)],
  );

  static const LinearGradient rankBronce = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB45309), Color(0xFF78350F)],
  );

  static const LinearGradient rankPlata = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
  );

  static const LinearGradient rankOro = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFACC15), Color(0xFFD97706)],
  );

  static const LinearGradient rankEsmeralda = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF047857)],
  );

  static const LinearGradient rankDiamante = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF1D4ED8)],
  );

  static const LinearGradient rankLeyenda = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
  );

  /// Retorna el gradiente semántico adecuado según el tier de rango
  static LinearGradient getRankGradient(RankTier tier) {
    switch (tier) {
      case RankTier.novato:
        return rankNovato;
      case RankTier.bronce:
        return rankBronce;
      case RankTier.plata:
        return rankPlata;
      case RankTier.oro:
        return rankOro;
      case RankTier.esmeralda:
        return rankEsmeralda;
      case RankTier.diamante:
        return rankDiamante;
      case RankTier.maestro1:
      case RankTier.maestro2:
      case RankTier.maestro3:
      case RankTier.leyenda:
        return rankLeyenda;
    }
  }

  /// Retorna el gradiente de rango según la cantidad de trofeos
  static LinearGradient getRankGradientForTrophies(int trophies) {
    final rank = RankInfo.forTrophies(trophies);
    return getRankGradient(rank.tier);
  }
}

/// Envoltorio universal táctil con efecto de presión física al pulsar:
/// - Se desplaza en el eje Y (`translateY: +depth`)
/// - Dispara respuesta háptica suave (`HapticFeedback.lightImpact`)
/// - Vuelve a su elevación normal con curva suave al soltar
class TactilePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double depth;
  final bool enableHaptics;
  final HitTestBehavior behavior;
  final Duration duration;

  const TactilePressable({
    super.key,
    required this.child,
    this.onTap,
    this.depth = 3.0,
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
    this.duration = const Duration(milliseconds: 70),
  });

  @override
  State<TactilePressable> createState() => _TactilePressableState();
}

class _TactilePressableState extends State<TactilePressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOffset = (_isPressed && widget.onTap != null) ? widget.depth : 0.0;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutQuad,
        transform: Matrix4.translationValues(0, effectiveOffset, 0),
        child: widget.child,
      ),
    );
  }
}

/// Widget de tipografía limpia y nítida (sin bordes ni trazos oscuros grotescos),
/// con soporte opcional de gradiente o sombra suave de elevación.
class CartoonStrokeText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color strokeColor; // Parámetro conservado para retrocompatibilidad
  final double strokeWidth; // Parámetro conservado para retrocompatibilidad
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;
  final bool showShadow;
  final Gradient? gradient;

  const CartoonStrokeText(
    this.text, {
    super.key,
    required this.fontSize,
    this.textColor = AppPalette.cartoonYellow,
    this.strokeColor = Colors.transparent,
    this.strokeWidth = 0.0,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 0.8,
    this.textAlign = TextAlign.center,
    this.showShadow = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: gradient == null ? textColor : Colors.white,
        shadows: showShadow
            ? const [
                Shadow(
                  color: Color(0x40000000),
                  blurRadius: 3,
                  offset: Offset(0, 1.5),
                ),
              ]
            : null,
      ),
    );

    if (gradient != null) {
      return ShaderMask(
        shaderCallback: (bounds) => gradient!.createShader(bounds),
        child: textWidget,
      );
    }
    return textWidget;
  }
}

/// Botón redondeado estilo cartoon con borde 3D, soporte de gradiente y relieve táctil
class CartoonRoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color backgroundColor;
  final Gradient? gradient;
  final Color borderColor;
  final Color shadowColor;
  final double borderRadius;
  final double depth;

  const CartoonRoundButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width = 46,
    this.height = 46,
    this.backgroundColor = const Color(0xFFDCE2FD),
    this.gradient,
    this.borderColor = AppPalette.cartoonBorder,
    this.shadowColor = const Color(0xFF1E1763),
    this.borderRadius = 14,
    this.depth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: onPressed,
      depth: depth,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Switch estilo cartoon con pista turquesa/neutra y deslizador redondeado
class CartoonSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CartoonSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TactilePressable(
      onTap: () => onChanged(!value),
      depth: 1.5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: value ? AppPalette.cartoonCyan : const Color(0xFF2E2A7A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPalette.cartoonBorder,
            width: 2.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1B165E),
              offset: Offset(0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppPalette.cartoonBorder,
              width: 1.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1B165E),
                offset: Offset(0, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de sala redondeada estilo cartoon con respuesta táctil física
class CartoonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Gradient? gradient;
  final double borderRadius;
  final double depth;

  const CartoonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = AppPalette.cartoonCard,
    this.gradient,
    this.borderRadius = 16,
    this.depth = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B165E),
            offset: Offset(0, depth),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return TactilePressable(
        onTap: onTap,
        depth: depth,
        child: cardContent,
      );
    }
    return cardContent;
  }
}
