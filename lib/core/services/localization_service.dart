import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  spanish('es', 'Español'),
  english('en', 'English');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);
}

/// Servicio singleton reactivo para gestión y alternancia de idioma (Español / Inglés).
class LocalizationService extends ChangeNotifier {
  static const String storageKey = 'caidago_app_language';

  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  static LocalizationService get instance => _instance;

  LocalizationService._internal();

  AppLanguage _currentLanguage = AppLanguage.spanish;

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isEnglish => _currentLanguage == AppLanguage.english;
  bool get isSpanish => _currentLanguage == AppLanguage.spanish;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(storageKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.values.firstWhere(
          (lang) => lang.code == savedCode,
          orElse: () => AppLanguage.spanish,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, language.code);
    } catch (_) {}
  }

  /// Diccionario bilingüe base de términos clave de interfaz y juego
  static const Map<String, Map<String, String>> _localizedStrings = {
    'es': {
      'app_title': 'CaidaGO',
      'play': 'JUGAR',
      'tutorial': 'TUTORIAL',
      'settings': 'AJUSTES',
      'shop': 'TIENDA',
      'profile': 'PERFIL',
      'stats': 'ESTADÍSTICAS',
      'achievements': 'LOGROS',
      'sound': 'SONIDO',
      'language': 'IDIOMA',
      'wins': 'Victorias',
      'matches': 'Partidas',
      'coins': 'Monedas',
      'trophies': 'Trofeos',
      'level': 'Nivel',
      'rank': 'Rango',
      'caida': '¡Caída!',
      'limpia': '¡Limpia!',
      'trivilin': '¡Trivilín!',
      'turn': 'Turno',
      'table': 'Mesa',
      'chat': 'Chat',
      'exit': 'SALIR',
    },
    'en': {
      'app_title': 'CaidaGO',
      'play': 'PLAY',
      'tutorial': 'TUTORIAL',
      'settings': 'SETTINGS',
      'shop': 'SHOP',
      'profile': 'PROFILE',
      'stats': 'STATISTICS',
      'achievements': 'ACHIEVEMENTS',
      'sound': 'SOUND',
      'language': 'LANGUAGE',
      'wins': 'Wins',
      'matches': 'Matches',
      'coins': 'Coins',
      'trophies': 'Trophies',
      'level': 'Level',
      'rank': 'Rank',
      'caida': 'Caida!',
      'limpia': 'Sweep!',
      'trivilin': 'Trivilin!',
      'turn': 'Turn',
      'table': 'Table',
      'chat': 'Chat',
      'exit': 'EXIT',
    },
  };

  /// Traduce una clave según el idioma actualmente seleccionado
  String translate(String key, {String? fallback}) {
    final langMap = _localizedStrings[_currentLanguage.code];
    if (langMap != null && langMap.containsKey(key)) {
      return langMap[key]!;
    }
    return fallback ?? key;
  }
}
