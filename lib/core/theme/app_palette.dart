import 'package:flutter/material.dart';

/// Paleta de colores oficial unificada de CaidaGO y GME:
/// Unificada bajo la atmósfera cartoon azul índigo / violeta vibrante.
class AppPalette {
  AppPalette._();

  /// #8BDCD7 - Turquesa / Cian Suave
  static const Color cyan = Color(0xFF8BDCD7);

  /// #999966 - Oliva / Verde Salvia
  static const Color olive = Color(0xFF999966);

  /// #232323 - Pizarra Oscura / Charcoal
  static const Color darkSlate = Color(0xFF232323);

  /// #D5D4BC - Arena / Pergamino Claro
  static const Color sand = Color(0xFFD5D4BC);

  // Variantes tradicionales de acento para modos y recompensas
  static const Color gold = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color crimson = Color(0xFFEF4444);
  static const Color crimsonDark = Color(0xFFB91C1C);

  // Paleta Cartoon Azul Índigo / Púrpura Unificada (Toda la App)
  static const Color cartoonBg = Color(0xFF3B32B0);
  static const Color cartoonBgDark = Color(0xFF26206D);
  static const Color cartoonSurface = Color(0xFF332A88);
  static const Color cartoonCard = Color(0xFFDCE2FD);
  static const Color cartoonCardDark = Color(0xFF2E267D);
  static const Color cartoonCardText = Color(0xFF1E1763);
  static const Color cartoonBorder = Color(0xFF1E1763);
  static const Color cartoonCyan = Color(0xFF22D3EE);
  static const Color cartoonYellow = Color(0xFFFBBF24);
  static const Color cartoonYellowDark = Color(0xFFD97706);
  static const Color cartoonRed = Color(0xFFEF4444);
  static const Color cartoonGreen = Color(0xFF10B981);
  static const Color cartoonDeepIndigo = Color(0xFF1E1B4B);
  static const Color cartoonDarkSlate = Color(0xFF0F172A);
  static const Color cartoonShadow3d = Color(0xFF1B165E);
  static const Color goldGlow = Color(0xFFFDE047);
  static const Color goldDarkText = Color(0xFF713F12);

  /// Gradiente de fondo principal que unifica todas las vistas
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3B32B0), Color(0xFF251E75)],
  );

  /// Genera una tonalidad más oscura para la base extruida 3D (:before en CSS).
  static Color get3dEdgeColor(Color baseColor, [double factor = 0.28]) {
    final hsl = HSLColor.fromColor(baseColor);
    final darkerLightness = (hsl.lightness - factor).clamp(0.0, 1.0);
    return hsl.withLightness(darkerLightness).toColor();
  }

  /// Genera una tonalidad más clara para el brillo superior / borde.
  static Color getHighlightColor(Color baseColor, [double factor = 0.15]) {
    final hsl = HSLColor.fromColor(baseColor);
    final lighterLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lighterLightness).toColor();
  }
}
