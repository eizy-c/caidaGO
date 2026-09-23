import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger.dart';
import 'player_session.dart';
import 'venezuela_room_tier.dart';

/// Gestor central de estado, economía y progresión estricta por trofeos
/// para las Salas VIP Regionales de Venezuela.
class TrophySessionManager extends ChangeNotifier {
  static const String _storageKeyTrophies = 'caida_venezuela_trophies_v1';
  static const String _storageKeyCoins = 'caida_venezuela_coins_v1';

  static TrophySessionManager? _shared;

  /// Instancia global compartida para acceso unificado en toda la aplicación.
  static TrophySessionManager get shared =>
      _shared ??= TrophySessionManager();

  /// Permite establecer una instancia mock o configurada para pruebas unitarias.
  static void setShared(TrophySessionManager manager) => _shared = manager;

  final Map<int, int> _roomTrophies = {};
  int _coins = 0;
  bool _isLoaded = false;

  TrophySessionManager() {
    _initialize();
  }

  bool get isLoaded => _isLoaded;
  int get coins => _coins;
  Map<int, int> get roomTrophies => Map.unmodifiable(_roomTrophies);

  /// Inicializa la sesión cargando los datos guardados o sincronizando con PlayerSession.
  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trophiesJson = prefs.getString(_storageKeyTrophies);

      if (trophiesJson != null && trophiesJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(trophiesJson);
        decoded.forEach((key, val) {
          final roomId = int.tryParse(key);
          if (roomId != null && val is int) {
            final room = VenezuelaRoomCatalog.getById(roomId);
            _roomTrophies[roomId] = val.clamp(0, room.trophyCap);
          }
        });
      }

      // Sincronizar monedas iniciales desde PlayerSession si no hay clave local
      if (prefs.containsKey(_storageKeyCoins)) {
        _coins = prefs.getInt(_storageKeyCoins) ?? PlayerSession.shared.coins;
      } else {
        _coins = PlayerSession.shared.coins;
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e, stack) {
      DebugLogger.instance.log(
        'Error cargando TrophySessionManager',
        category: 'Economía VIP',
        level: LogLevel.error,
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Guarda el estado actual en almacenamiento persistente local.
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> exportMap = {};
      _roomTrophies.forEach((k, v) => exportMap[k.toString()] = v);
      await prefs.setString(_storageKeyTrophies, jsonEncode(exportMap));
      await prefs.setInt(_storageKeyCoins, _coins);
    } catch (e) {
      DebugLogger.instance.log(
        'Error guardando trofeos',
        category: 'Economía VIP',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  /// Obtiene los trofeos actuales de una sala específica (0 a cap).
  int getTrophies(int roomId) {
    final room = VenezuelaRoomCatalog.getById(roomId);
    return (_roomTrophies[roomId] ?? 0).clamp(0, room.trophyCap);
  }

  /// Suma total de todos los trofeos acumulados en todas las salas.
  int getTotalTrophies() {
    int sum = 0;
    for (final room in VenezuelaRoomCatalog.rooms) {
      sum += getTrophies(room.id);
    }
    return sum;
  }

  /// Progreso normalizado de trofeos de una sala (0.0 a 1.0).
  double getTrophyProgress(int roomId) {
    final room = VenezuelaRoomCatalog.getById(roomId);
    if (room.trophyCap <= 0) return 1.0;
    return (getTrophies(roomId) / room.trophyCap).clamp(0.0, 1.0);
  }

  /// Determina si una sala ha alcanzado el 100% de sus trofeos máximos.
  bool isRoomCompleted(int roomId) {
    final room = VenezuelaRoomCatalog.getById(roomId);
    return getTrophies(roomId) >= room.trophyCap;
  }

  /// Comprueba si una sala está desbloqueada:
  /// - Sala 1 (Chivacoa): Desbloqueada por defecto.
  /// - Sala N (N > 1): La sala anterior (N-1) debe haber alcanzado el 100% de sus trofeos.
  bool isRoomUnlocked(int roomId) {
    if (roomId <= 1) return true;
    final prevRoom = VenezuelaRoomCatalog.getPreviousRoom(roomId);
    if (prevRoom == null) return true;
    return getTrophies(prevRoom.id) >= prevRoom.trophyCap;
  }

  /// Trofeos restantes en la sala anterior para desbloquear la sala indicada.
  int getRemainingTrophiesForUnlock(int roomId) {
    if (isRoomUnlocked(roomId)) return 0;
    final prevRoom = VenezuelaRoomCatalog.getPreviousRoom(roomId);
    if (prevRoom == null) return 0;
    final currentInPrev = getTrophies(prevRoom.id);
    return (prevRoom.trophyCap - currentInPrev).clamp(0, prevRoom.trophyCap);
  }

  /// Verifica si el saldo del jugador es suficiente para la entrada.
  bool canAfford(int entryFee) {
    final currentBalance = _getCurrentActiveCoins();
    return currentBalance >= entryFee;
  }

  /// Deduce la tarifa de entrada tanto en este gestor como en PlayerSession.
  bool deductEntryFee(int entryFee) {
    if (!canAfford(entryFee)) return false;

    // Descontar en PlayerSession para mantener sincronizada toda la UI global
    final sessionDeducted = PlayerSession.shared.deductCoinsForVipMatch(entryFee);
    if (sessionDeducted) {
      _coins = PlayerSession.shared.coins;
    } else {
      _coins = (_coins - entryFee).clamp(0, 99999999);
    }

    DebugLogger.instance.log(
      'Entrada VIP regional deducida: -$entryFee. Balance restante: $_coins',
      category: 'Economía VIP',
    );

    notifyListeners();
    save();
    return true;
  }

  /// Agrega monedas por victoria o recompensa y sincroniza con PlayerSession.
  void addCoins(int amount) {
    if (amount <= 0) return;
    PlayerSession.shared.addCoins(amount);
    _coins = PlayerSession.shared.coins;
    notifyListeners();
    save();
  }

  /// Sincroniza el balance con PlayerSession.
  int _getCurrentActiveCoins() {
    _coins = PlayerSession.shared.coins;
    return _coins;
  }

  /// Actualiza directamente el balance de monedas (útil en testing).
  void setCoins(int coins) {
    _coins = coins.clamp(0, 99999999);
    PlayerSession.shared.addCoins(coins - PlayerSession.shared.coins);
    notifyListeners();
    save();
  }

  /// Establece manualmente los trofeos de una sala (útil para pruebas y calibración).
  void setTrophiesForTesting(int roomId, int trophies) {
    final room = VenezuelaRoomCatalog.getById(roomId);
    _roomTrophies[roomId] = trophies.clamp(0, room.trophyCap);
    notifyListeners();
  }

  /// Procesa el resultado de una partida en una sala regional:
  /// - Victoria: Acredita premio en monedas y suma trofeos (respetando el cap de la sala).
  /// - Derrota: Descuenta trofeos de esa sala sin bajar de 0.
  void processMatchResult({
    required int roomId,
    required bool isWinner,
    required GameMode mode,
  }) {
    final room = VenezuelaRoomCatalog.getById(roomId);
    final currentTrophies = getTrophies(roomId);

    if (isWinner) {
      final delta = room.winTrophies;
      final newTrophies = (currentTrophies + delta).clamp(0, room.trophyCap);
      _roomTrophies[roomId] = newTrophies;

      final prize = room.getPrizePerWinner(mode);
      addCoins(prize);

      DebugLogger.instance.log(
        '¡Victoria en ${room.name}! +$delta 🏆 ($newTrophies/${room.trophyCap}) | +🪙$prize ganadas.',
        category: 'Economía VIP',
      );
    } else {
      final delta = room.lossTrophies.abs();
      final newTrophies = (currentTrophies - delta).clamp(0, room.trophyCap);
      _roomTrophies[roomId] = newTrophies;

      DebugLogger.instance.log(
        'Derrota en ${room.name}. -$delta 🏆 ($newTrophies/${room.trophyCap}).',
        category: 'Economía VIP',
      );
    }

    notifyListeners();
    save();
  }

  /// Reinicia todos los trofeos a 0 (para pruebas y depuración).
  void resetTrophies() {
    _roomTrophies.clear();
    notifyListeners();
    save();
  }
}
