import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuditEntryType {
  canto,   // Cantos declarados y cantados
  puntos,  // Sumas de puntos (caídas, limpias, volumen, etc.)
  jugada,  // Jugadas clave y mensajes
}

class MatchAuditItem {
  final String round;
  final String playerName;
  final AuditEntryType type;
  final String description;
  final int points;
  final DateTime timestamp;
  final bool isUserTeam;

  const MatchAuditItem({
    required this.round,
    required this.playerName,
    required this.type,
    required this.description,
    this.points = 0,
    required this.timestamp,
    this.isUserTeam = true,
  });

  Map<String, dynamic> toJson() => {
    'round': round,
    'playerName': playerName,
    'type': type.name,
    'description': description,
    'points': points,
    'timestamp': timestamp.toIso8601String(),
    'isUserTeam': isUserTeam,
  };

  factory MatchAuditItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'puntos';
    final type = AuditEntryType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => AuditEntryType.puntos,
    );
    return MatchAuditItem(
      round: json['round'] as String? ?? 'Ronda 1',
      playerName: json['playerName'] as String? ?? 'Jugador',
      type: type,
      description: json['description'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isUserTeam: json['isUserTeam'] as bool? ?? true,
    );
  }
}

class MatchHistoryEntry {
  final String id;
  final DateTime playedAt;
  final bool won;
  final String gameMode; // '1 vs 1' o '2 vs 2'
  final int userScore;
  final int opponentScore;
  final int coinsEarned;
  final int xpEarned;
  final int trophyDelta;
  final int caidasCount;
  final int limpiasCount;
  final int cantosCount;
  final List<MatchAuditItem> auditLogs;

  const MatchHistoryEntry({
    required this.id,
    required this.playedAt,
    required this.won,
    required this.gameMode,
    required this.userScore,
    required this.opponentScore,
    required this.coinsEarned,
    required this.xpEarned,
    this.trophyDelta = 0,
    this.caidasCount = 0,
    this.limpiasCount = 0,
    this.cantosCount = 0,
    this.auditLogs = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playedAt': playedAt.toIso8601String(),
    'won': won,
    'gameMode': gameMode,
    'userScore': userScore,
    'opponentScore': opponentScore,
    'coinsEarned': coinsEarned,
    'xpEarned': xpEarned,
    'trophyDelta': trophyDelta,
    'caidasCount': caidasCount,
    'limpiasCount': limpiasCount,
    'cantosCount': cantosCount,
    'auditLogs': auditLogs.map((e) => e.toJson()).toList(),
  };

  factory MatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    List<MatchAuditItem> logs = [];
    if (json['auditLogs'] is List) {
      logs = (json['auditLogs'] as List)
          .map((e) => MatchAuditItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return MatchHistoryEntry(
      id: json['id'] as String? ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse(json['playedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      won: json['won'] as bool? ?? false,
      gameMode: json['gameMode'] as String? ?? '1 vs 1',
      userScore: json['userScore'] as int? ?? 0,
      opponentScore: json['opponentScore'] as int? ?? 0,
      coinsEarned: json['coinsEarned'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      trophyDelta: json['trophyDelta'] as int? ?? 0,
      caidasCount: json['caidasCount'] as int? ?? 0,
      limpiasCount: json['limpiasCount'] as int? ?? 0,
      cantosCount: json['cantosCount'] as int? ?? 0,
      auditLogs: logs,
    );
  }
}

/// Almacenamiento persistente de las últimas 20 partidas jugadas
class MatchHistoryStorage extends ChangeNotifier {
  static const String storageKey = 'caida_match_history_v1';
  static const int maxMatches = 20;

  static final MatchHistoryStorage instance = MatchHistoryStorage._();
  MatchHistoryStorage._() {
    _load();
  }

  List<MatchHistoryEntry> _matches = [];
  List<MatchHistoryEntry> get matches => List.unmodifiable(_matches);

  Future<void> saveMatch(MatchHistoryEntry entry) async {
    _matches.insert(0, entry);
    if (_matches.length > maxMatches) {
      _matches = _matches.sublist(0, maxMatches);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _matches.map((m) => m.toJson()).toList();
      await prefs.setString(storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        _matches = decoded
            .map((e) => MatchHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }
}
