import 'package:flutter/material.dart';
import '../../theme/app_palette.dart';

/// Widget de texto con efecto cartoon: trazo exterior y relleno sólido vibrante
class CartoonStrokeText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color strokeColor;
  final double strokeWidth;
  final FontWeight fontWeight;
  final double letterSpacing;
  final TextAlign textAlign;

  const CartoonStrokeText(
    this.text, {
    super.key,
    required this.fontSize,
    this.textColor = AppPalette.cartoonYellow,
    this.strokeColor = AppPalette.cartoonCardText,
    this.strokeWidth = 3.5,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 1.0,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Trazo exterior
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        // Relleno interior
        Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Botón redondeado estilo cartoon con borde 3D y relieve inferior
class CartoonRoundButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final Color backgroundColor;
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
    this.borderColor = AppPalette.cartoonBorder,
    this.shadowColor = const Color(0xFF1E1763),
    this.borderRadius = 14,
    this.depth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.white24,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
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
    return GestureDetector(
      onTap: () => onChanged(!value),
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

/// Tarjeta de sala redondeada estilo cartoon
class CartoonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderRadius;

  const CartoonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = AppPalette.cartoonCard,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppPalette.cartoonBorder, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1B165E),
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
