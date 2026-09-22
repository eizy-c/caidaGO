import 'package:flutter/services.dart';

/// Servicio de vibración y respuesta háptica táctil para CaidaGO.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool isEnabled = true;

  /// Vibración ligera al repartir o jugar cartas
  Future<void> onCardPlay() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Vibración media al declarar cantos tradicionales
  Future<void> onCanto() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Vibración fuerte al realizar una Caída o Mesa Limpia
  Future<void> onCaida() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Vibración corta de notificación / botones
  Future<void> onSelection() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
