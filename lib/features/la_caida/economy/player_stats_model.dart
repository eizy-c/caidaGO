import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger.dart';

/// Modelo de estadísticas avanzadas y detalladas del jugador en La Caída.
/// Registra estadísticas generales, jugadas en mesa (caídas, limpias, registros) y cantos tradicionales.
class PlayerStatsModel extends ChangeNotifier {
  static const String storageKey = 'caida_player_game_stats_v3';

  // --- TROFEOS Y RANGO ---
  int trophies;
  int highestRankIndex;

  // --- ESTADÍSTICAS GENERALES ---
  int totalEarnings;
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;
  int get winStreak => currentStreak;
  int soloWins;
  int teamWins;

  // --- MODALIDADES Y SALAS ---
  int onlineMatchesPlayed;
  int onlineMatchesWon;
  int botMatchesPlayed;
  int botMatchesWon;
  int vipMatchesPlayed;
  int vipMatchesWon;
  int matches1v1Played;
  int matches1v1Won;
  int matches2v2Played;
  int matches2v2Won;

  // --- JUGADAS Y MESA (CAÍDA) ---
  int caidasMade;
  int caidasReceived;
  int mesasLimpias;
  int caidasWithLimpia;
  int registros;
  int totalCardsWon;

  // --- CANTOS TRADICIONALES ---
  int rondas;
  int patrullas;
  int vigias;
  int trivilines;

  // --- LOGROS RECLAMADOS ---
  final Set<String> claimedAchievementIds;

  PlayerStatsModel({
    this.trophies = 0,
    this.highestRankIndex = 0,
    this.totalEarnings = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.soloWins = 0,
    this.teamWins = 0,
    this.onlineMatchesPlayed = 0,
    this.onlineMatchesWon = 0,
    this.botMatchesPlayed = 0,
    this.botMatchesWon = 0,
    this.vipMatchesPlayed = 0,
    this.vipMatchesWon = 0,
    this.matches1v1Played = 0,
    this.matches1v1Won = 0,
    this.matches2v2Played = 0,
    this.matches2v2Won = 0,
    this.caidasMade = 0,
    this.caidasReceived = 0,
    this.mesasLimpias = 0,
    this.caidasWithLimpia = 0,
    this.registros = 0,
    this.totalCardsWon = 0,
    this.rondas = 0,
    this.patrullas = 0,
    this.vigias = 0,
    this.trivilines = 0,
    Set<String>? claimedAchievementIds,
  }) : claimedAchievementIds = claimedAchievementIds ?? <String>{};

  static PlayerStatsModel? _shared;

  /// Instancia compartida en memoria para acceso unificado y reactivo.
  static PlayerStatsModel get shared => _shared ??= PlayerStatsModel();

  static void setShared(PlayerStatsModel model) => _shared = model;

  /// Porcentaje de victorias (0 a 100).
  int get winRatePercentage =>
      gamesPlayed == 0 ? 0 : ((gamesWon / gamesPlayed) * 100).round();

  /// Registra ingresos de monedas acumuladas de por vida (partidas, cofres, recompensas, retos, etc.)
  void recordEarnings(int amount) {
    if (amount <= 0) return;
    totalEarnings += amount;
    notifyListeners();
    save();
  }

  /// Registra el fin de una partida oficial
  void recordGameResult({
    required bool won,
    required bool isTeams,
    bool isOnline = false,
    bool isBot = true,
    bool isVip = false,
    int coinsWon = 0,
    int cardsWon = 0,
    int caidas = 0,
    int limpias = 0,
    int cantos = 0,
  }) {
    gamesPlayed++;
    totalEarnings += coinsWon;
    totalCardsWon += cardsWon;
    caidasMade += caidas;
    mesasLimpias += limpias;

    if (isTeams) {
      matches2v2Played++;
    } else {
      matches1v1Played++;
    }

    if (isOnline) {
      onlineMatchesPlayed++;
    } else {
      botMatchesPlayed++;
    }

    if (isVip) {
      vipMatchesPlayed++;
    }

    if (won) {
      gamesWon++;
      currentStreak++;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      if (isTeams) {
        teamWins++;
        matches2v2Won++;
      } else {
        soloWins++;
        matches1v1Won++;
      }
      if (isOnline) {
        onlineMatchesWon++;
      } else {
        botMatchesWon++;
      }
      if (isVip) {
        vipMatchesWon++;
      }
    } else {
      currentStreak = 0;
    }

    notifyListeners();
    save();
  }

  /// Registra un canto cantado por el jugador
  void recordCanto(String cantoName) {
    final lower = cantoName.toLowerCase();
    if (lower.contains('trivil')) {
      trivilines++;
    } else if (lower.contains('registro')) {
      registros++;
    } else if (lower.contains('vigi') || lower.contains('vigí')) {
      vigias++;
    } else if (lower.contains('patrulla')) {
      patrullas++;
    } else if (lower.contains('ronda')) {
      rondas++;
    }
    notifyListeners();
    save();
  }

  /// Registra una caída cantada al rival
  void recordCaidaMade({bool withLimpia = false}) {
    caidasMade++;
    if (withLimpia) {
      caidasWithLimpia++;
      mesasLimpias++;
    }
    notifyListeners();
    save();
  }

  /// Registra una caída recibida por parte del rival
  void recordCaidaReceived() {
    caidasReceived++;
    notifyListeners();
    save();
  }

  /// Registra una mesa limpia
  void recordMesaLimpia() {
    mesasLimpias++;
    notifyListeners();
    save();
  }

  /// Marca un logro como reclamado
  bool claimAchievement(String id) {
    if (claimedAchievementIds.contains(id)) return false;
    claimedAchievementIds.add(id);
    notifyListeners();
    save();
    return true;
  }

  // --- SERIALIZACIÓN JSON Y PERSISTENCIA LOCAL ---

  /// Agrega o quita trofeos. Respeta la protección de Novato (mínimo 0).
  void addTrophies(int delta) {
    trophies = (trophies + delta).clamp(0, 999999);
    notifyListeners();
    save();
  }

  /// Marca un nuevo rango máximo alcanzado (por índice en RankInfo.allRanks).
  /// Retorna true si es un nuevo máximo (para entregar recompensa).
  bool markHighestRank(int rankIndex) {
    if (rankIndex > highestRankIndex) {
      highestRankIndex = rankIndex;
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'trophies': trophies,
        'highestRankIndex': highestRankIndex,
        'totalEarnings': totalEarnings,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'soloWins': soloWins,
        'teamWins': teamWins,
        'onlineMatchesPlayed': onlineMatchesPlayed,
        'onlineMatchesWon': onlineMatchesWon,
        'botMatchesPlayed': botMatchesPlayed,
        'botMatchesWon': botMatchesWon,
        'vipMatchesPlayed': vipMatchesPlayed,
        'vipMatchesWon': vipMatchesWon,
        'matches1v1Played': matches1v1Played,
        'matches1v1Won': matches1v1Won,
        'matches2v2Played': matches2v2Played,
        'matches2v2Won': matches2v2Won,
        'caidasMade': caidasMade,
        'caidasReceived': caidasReceived,
        'mesasLimpias': mesasLimpias,
        'caidasWithLimpia': caidasWithLimpia,
        'registros': registros,
        'totalCardsWon': totalCardsWon,
        'rondas': rondas,
        'patrullas': patrullas,
        'vigias': vigias,
        'trivilines': trivilines,
        'claimedAchievementIds': claimedAchievementIds.toList(),
      };

  static const List<String> legacyStorageKeys = [
    'caida_player_game_stats_v3',
    'caida_player_game_stats_v2',
    'caida_player_game_stats_v1',
    'caida_player_game_stats',
    'player_stats',
  ];

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    final claimed = (json['claimedAchievementIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    int toInt(dynamic v, [int fallback = 0]) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    return PlayerStatsModel(
      trophies: toInt(json['trophies']),
      highestRankIndex: toInt(json['highestRankIndex']),
      totalEarnings: toInt(json['totalEarnings']),
      gamesPlayed: toInt(json['gamesPlayed']),
      gamesWon: toInt(json['gamesWon']),
      currentStreak: toInt(json['currentStreak']),
      maxStreak: toInt(json['maxStreak']),
      soloWins: toInt(json['soloWins']),
      teamWins: toInt(json['teamWins']),
      onlineMatchesPlayed: toInt(json['onlineMatchesPlayed']),
      onlineMatchesWon: toInt(json['onlineMatchesWon']),
      botMatchesPlayed: toInt(json['botMatchesPlayed']),
      botMatchesWon: toInt(json['botMatchesWon']),
      vipMatchesPlayed: toInt(json['vipMatchesPlayed']),
      vipMatchesWon: toInt(json['vipMatchesWon']),
      matches1v1Played: toInt(json['matches1v1Played'], toInt(json['soloWins'])),
      matches1v1Won: toInt(json['matches1v1Won'], toInt(json['soloWins'])),
      matches2v2Played: toInt(json['matches2v2Played'], toInt(json['teamWins'])),
      matches2v2Won: toInt(json['matches2v2Won'], toInt(json['teamWins'])),
      caidasMade: toInt(json['caidasMade']),
      caidasReceived: toInt(json['caidasReceived']),
      mesasLimpias: toInt(json['mesasLimpias']),
      caidasWithLimpia: toInt(json['caidasWithLimpia']),
      registros: toInt(json['registros']),
      totalCardsWon: toInt(json['totalCardsWon']),
      rondas: toInt(json['rondas']),
      patrullas: toInt(json['patrullas']),
      vigias: toInt(json['vigias']),
      trivilines: toInt(json['trivilines']),
      claimedAchievementIds: claimed,
    );
  }

  /// Restablece todas las estadísticas a 0 (útil para pruebas y reinicios).
  void reset() {
    trophies = 0;
    highestRankIndex = 0;
    totalEarnings = 0;
    gamesPlayed = 0;
    gamesWon = 0;
    currentStreak = 0;
    maxStreak = 0;
    soloWins = 0;
    teamWins = 0;
    onlineMatchesPlayed = 0;
    onlineMatchesWon = 0;
    botMatchesPlayed = 0;
    botMatchesWon = 0;
    vipMatchesPlayed = 0;
    vipMatchesWon = 0;
    matches1v1Played = 0;
    matches1v1Won = 0;
    matches2v2Played = 0;
    matches2v2Won = 0;
    caidasMade = 0;
    caidasReceived = 0;
    mesasLimpias = 0;
    caidasWithLimpia = 0;
    registros = 0;
    totalCardsWon = 0;
    rondas = 0;
    patrullas = 0;
    vigias = 0;
    trivilines = 0;
    claimedAchievementIds.clear();
    notifyListeners();
    save();
  }

  /// Carga las estadísticas desde SharedPreferences con migración de claves
  Future<void> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();

    for (final key in legacyStorageKeys) {
      try {
        final raw = p.getString(key);
        if (raw != null && raw.isNotEmpty) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final loaded = PlayerStatsModel.fromJson(data);
          _copyFrom(loaded);
          notifyListeners();
          // Si cargó desde una clave heredada, migrar a storageKey
          if (key != storageKey) {
            save(prefs: p);
          }
          return;
        }
      } catch (e) {
        DebugLogger.instance.log(
          'Error cargando PlayerStatsModel con clave $key: $e',
          category: 'Sistema',
          level: LogLevel.warning,
        );
      }
    }
  }

  /// Guarda las estadísticas en SharedPreferences
  void save({SharedPreferences? prefs}) {
    final raw = jsonEncode(toJson());
    if (prefs != null) {
      prefs.setString(storageKey, raw).catchError((_) => false);
      return;
    }
    SharedPreferences.getInstance().then((p) {
      p.setString(storageKey, raw).catchError((_) => false);
    }).catchError((_) {});
  }

  void _copyFrom(PlayerStatsModel other) {
    trophies = other.trophies;
    highestRankIndex = other.highestRankIndex;
    totalEarnings = other.totalEarnings;
    gamesPlayed = other.gamesPlayed;
    gamesWon = other.gamesWon;
    currentStreak = other.currentStreak;
    maxStreak = other.maxStreak;
    soloWins = other.soloWins;
    teamWins = other.teamWins;
    onlineMatchesPlayed = other.onlineMatchesPlayed;
    onlineMatchesWon = other.onlineMatchesWon;
    botMatchesPlayed = other.botMatchesPlayed;
    botMatchesWon = other.botMatchesWon;
    vipMatchesPlayed = other.vipMatchesPlayed;
    vipMatchesWon = other.vipMatchesWon;
    matches1v1Played = other.matches1v1Played;
    matches1v1Won = other.matches1v1Won;
    matches2v2Played = other.matches2v2Played;
    matches2v2Won = other.matches2v2Won;
    caidasMade = other.caidasMade;
    caidasReceived = other.caidasReceived;
    mesasLimpias = other.mesasLimpias;
    caidasWithLimpia = other.caidasWithLimpia;
    registros = other.registros;
    totalCardsWon = other.totalCardsWon;
    rondas = other.rondas;
    patrullas = other.patrullas;
    vigias = other.vigias;
    trivilines = other.trivilines;
    claimedAchievementIds.clear();
    claimedAchievementIds.addAll(other.claimedAchievementIds);
  }
}
