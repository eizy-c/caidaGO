import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ChallengeActionType {
  winMatch,
  playMatch,
  makeCaida,
  mesaLimpia,
  playTeams,
  winTeams,
  cantoRonda,
  cantoPatrulla,
  cantoVigia,
  cantoRegistro,
  cantoTrivilin,
  playVip,
  winVip,
  winStreak,
  collectCards,
  caidaAndLimpia,
  openChest,
  useBooster,
}

class DailyChallengeTemplate {
  final String id;
  final String title;
  final ChallengeActionType actionType;
  final int targetProgress;
  final int coinReward;
  final int xpReward;

  const DailyChallengeTemplate({
    required this.id,
    required this.title,
    required this.actionType,
    required this.targetProgress,
    required this.coinReward,
    required this.xpReward,
  });
}

class DailyChallengeInstance {
  final String id;
  final String title;
  final ChallengeActionType actionType;
  final int targetProgress;
  final int currentProgress;
  final int coinReward;
  final int xpReward;
  final bool isClaimed;

  const DailyChallengeInstance({
    required this.id,
    required this.title,
    required this.actionType,
    required this.targetProgress,
    this.currentProgress = 0,
    required this.coinReward,
    required this.xpReward,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetProgress;
  String get progressText => '${math.min(currentProgress, targetProgress)} / $targetProgress';
  String get rewardText => '+$coinReward Monedas  +$xpReward XP';

  DailyChallengeInstance copyWith({
    int? currentProgress,
    bool? isClaimed,
  }) {
    return DailyChallengeInstance(
      id: id,
      title: title,
      actionType: actionType,
      targetProgress: targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      coinReward: coinReward,
      xpReward: xpReward,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'actionType': actionType.name,
    'targetProgress': targetProgress,
    'currentProgress': currentProgress,
    'coinReward': coinReward,
    'xpReward': xpReward,
    'isClaimed': isClaimed,
  };

  factory DailyChallengeInstance.fromJson(Map<String, dynamic> json) {
    final actionName = json['actionType'] as String? ?? 'playMatch';
    final action = ChallengeActionType.values.firstWhere(
      (a) => a.name == actionName,
      orElse: () => ChallengeActionType.playMatch,
    );
    return DailyChallengeInstance(
      id: json['id'] as String,
      title: json['title'] as String,
      actionType: action,
      targetProgress: json['targetProgress'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      coinReward: json['coinReward'] as int,
      xpReward: json['xpReward'] as int,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }
}

/// Gestor del sistema dinámico de Retos Diarios.
/// Genera 3 retos deterministas por día basados en una semilla de fecha.
class DailyChallengeSystem extends ChangeNotifier {
  static const String storageKey = 'caida_daily_challenges_v1';

  static const List<DailyChallengeTemplate> pool = [
    DailyChallengeTemplate(
      id: 'win_match',
      title: 'Gana 1 partida en CaidaGO',
      actionType: ChallengeActionType.winMatch,
      targetProgress: 1,
      coinReward: 250,
      xpReward: 50,
    ),
    DailyChallengeTemplate(
      id: 'win_2_matches',
      title: 'Gana 2 partidas oficiales',
      actionType: ChallengeActionType.winMatch,
      targetProgress: 2,
      coinReward: 400,
      xpReward: 80,
    ),
    DailyChallengeTemplate(
      id: 'make_caida',
      title: 'Canta 1 Caída a tus rivales',
      actionType: ChallengeActionType.makeCaida,
      targetProgress: 1,
      coinReward: 150,
      xpReward: 30,
    ),
    DailyChallengeTemplate(
      id: 'make_3_caidas',
      title: 'Realiza 3 Caídas en partidas',
      actionType: ChallengeActionType.makeCaida,
      targetProgress: 3,
      coinReward: 300,
      xpReward: 60,
    ),
    DailyChallengeTemplate(
      id: 'mesa_limpia',
      title: 'Realiza una Mesa Limpia',
      actionType: ChallengeActionType.mesaLimpia,
      targetProgress: 1,
      coinReward: 200,
      xpReward: 40,
    ),
    DailyChallengeTemplate(
      id: 'play_teams',
      title: 'Juega en Parejas (2 vs 2)',
      actionType: ChallengeActionType.playTeams,
      targetProgress: 1,
      coinReward: 200,
      xpReward: 40,
    ),
    DailyChallengeTemplate(
      id: 'win_teams',
      title: 'Gana una partida en Parejas',
      actionType: ChallengeActionType.winTeams,
      targetProgress: 1,
      coinReward: 350,
      xpReward: 70,
    ),
    DailyChallengeTemplate(
      id: 'canto_ronda',
      title: 'Canta una Ronda',
      actionType: ChallengeActionType.cantoRonda,
      targetProgress: 1,
      coinReward: 120,
      xpReward: 25,
    ),
    DailyChallengeTemplate(
      id: 'canto_patrulla',
      title: 'Canta una Patrulla',
      actionType: ChallengeActionType.cantoPatrulla,
      targetProgress: 1,
      coinReward: 150,
      xpReward: 30,
    ),
    DailyChallengeTemplate(
      id: 'canto_vigia',
      title: 'Canta un Vigía',
      actionType: ChallengeActionType.cantoVigia,
      targetProgress: 1,
      coinReward: 180,
      xpReward: 35,
    ),
    DailyChallengeTemplate(
      id: 'canto_registro',
      title: 'Canta un Registro',
      actionType: ChallengeActionType.cantoRegistro,
      targetProgress: 1,
      coinReward: 220,
      xpReward: 45,
    ),
    DailyChallengeTemplate(
      id: 'canto_trivilin',
      title: '¡Canta un Trivilín!',
      actionType: ChallengeActionType.cantoTrivilin,
      targetProgress: 1,
      coinReward: 500,
      xpReward: 100,
    ),
    DailyChallengeTemplate(
      id: 'play_3_matches',
      title: 'Juega 3 partidas',
      actionType: ChallengeActionType.playMatch,
      targetProgress: 3,
      coinReward: 180,
      xpReward: 30,
    ),
    DailyChallengeTemplate(
      id: 'play_vip',
      title: 'Juega en una Mesa VIP',
      actionType: ChallengeActionType.playVip,
      targetProgress: 1,
      coinReward: 300,
      xpReward: 60,
    ),
    DailyChallengeTemplate(
      id: 'win_vip',
      title: 'Gana en una Mesa VIP',
      actionType: ChallengeActionType.winVip,
      targetProgress: 1,
      coinReward: 600,
      xpReward: 120,
    ),
    DailyChallengeTemplate(
      id: 'win_streak_2',
      title: 'Gana 2 partidas seguidas',
      actionType: ChallengeActionType.winStreak,
      targetProgress: 2,
      coinReward: 450,
      xpReward: 90,
    ),
    DailyChallengeTemplate(
      id: 'collect_30_cards',
      title: 'Recoge 30 cartas en mesa',
      actionType: ChallengeActionType.collectCards,
      targetProgress: 30,
      coinReward: 200,
      xpReward: 40,
    ),
    DailyChallengeTemplate(
      id: 'make_caida_limpia',
      title: 'Haz una Caída y Mesa Limpia',
      actionType: ChallengeActionType.caidaAndLimpia,
      targetProgress: 1,
      coinReward: 400,
      xpReward: 80,
    ),
    DailyChallengeTemplate(
      id: 'open_chest',
      title: 'Abre un cofre de recompensa',
      actionType: ChallengeActionType.openChest,
      targetProgress: 1,
      coinReward: 100,
      xpReward: 20,
    ),
    DailyChallengeTemplate(
      id: 'use_booster',
      title: 'Usa un potenciador en partida',
      actionType: ChallengeActionType.useBooster,
      targetProgress: 1,
      coinReward: 150,
      xpReward: 30,
    ),
  ];

  String _currentDateKey = '';
  List<DailyChallengeInstance> _challenges = [];

  List<DailyChallengeInstance> get challenges => List.unmodifiable(_challenges);

  static DailyChallengeSystem? _instance;
  static DailyChallengeSystem get instance => _instance ??= DailyChallengeSystem();

  DailyChallengeSystem() {
    _init();
  }

  void _init() {
    final now = DateTime.now().toUtc();
    _currentDateKey = _formatDateKey(now);
    _generateChallengesForToday();
    _loadFromStorage();
  }

  static String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Retorna la duración hasta la próxima medianoche UTC (rotación de retos)
  Duration timeUntilNextReset() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Asegura que los retos correspondan al día actual
  void checkDayRollOver() {
    final now = DateTime.now().toUtc();
    final todayKey = _formatDateKey(now);
    if (todayKey != _currentDateKey) {
      _currentDateKey = todayKey;
      _generateChallengesForToday();
    }
  }

  void _generateChallengesForToday() {
    final now = DateTime.now().toUtc();
    // Semilla determinista: ej. 2026 * 10000 + 09 * 100 + 21
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = math.Random(seed);

    final indices = List.generate(pool.length, (i) => i)..shuffle(rng);
    final selectedTemplates = indices.take(3).map((i) => pool[i]).toList();

    _challenges = selectedTemplates.map((t) {
      return DailyChallengeInstance(
        id: t.id,
        title: t.title,
        actionType: t.actionType,
        targetProgress: t.targetProgress,
        coinReward: t.coinReward,
        xpReward: t.xpReward,
      );
    }).toList();

    save();
    notifyListeners();
  }

  /// Registra progreso en las misiones diarias que coincidan con la acción realizada.
  /// Retorna la lista de misiones que se acaban de completar en esta llamada.
  List<DailyChallengeInstance> recordAction(ChallengeActionType action, [int amount = 1]) {
    checkDayRollOver();
    final newlyCompleted = <DailyChallengeInstance>[];

    for (int i = 0; i < _challenges.length; i++) {
      final ch = _challenges[i];
      if (ch.actionType == action && !ch.isCompleted) {
        final newProgress = ch.currentProgress + amount;
        final updated = ch.copyWith(currentProgress: newProgress);
        _challenges[i] = updated;

        if (updated.isCompleted && !ch.isCompleted) {
          newlyCompleted.add(updated);
        }
      }
    }

    if (newlyCompleted.isNotEmpty) {
      save();
      notifyListeners();
    }
    return newlyCompleted;
  }

  /// Reclama la recompensa de una misión completada y genera un nuevo reto aleatorio.
  DailyChallengeInstance? claimReward(String id) {
    checkDayRollOver();
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index == -1) return null;

    final ch = _challenges[index];
    if (ch.isCompleted && !ch.isClaimed) {
      final claimed = ch.copyWith(isClaimed: true);

      // Reemplazo dinámico continuo con retos del catálogo para que nunca se acaben
      final activeActionTypes = _challenges.map((c) => c.actionType).toSet();
      final availableTemplates = pool.where((t) => !activeActionTypes.contains(t.actionType)).toList();
      final candidatePool = availableTemplates.isNotEmpty ? availableTemplates : pool;
      final rng = math.Random();
      final nextTemplate = candidatePool[rng.nextInt(candidatePool.length)];

      _challenges[index] = DailyChallengeInstance(
        id: '${nextTemplate.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: nextTemplate.title,
        actionType: nextTemplate.actionType,
        targetProgress: nextTemplate.targetProgress,
        coinReward: nextTemplate.coinReward,
        xpReward: nextTemplate.xpReward,
      );

      save();
      notifyListeners();
      return claimed;
    }
    return null;
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'dateKey': _currentDateKey,
        'challenges': _challenges.map((c) => c.toJson()).toList(),
      };
      await prefs.setString(storageKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final dateKey = decoded['dateKey'] as String? ?? '';
        final nowKey = _formatDateKey(DateTime.now().toUtc());

        if (dateKey == nowKey && decoded['challenges'] is List) {
          _currentDateKey = dateKey;
          _challenges = (decoded['challenges'] as List)
              .map((e) => DailyChallengeInstance.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
          return;
        }
      }
    } catch (_) {}
    _generateChallengesForToday();
  }
}
