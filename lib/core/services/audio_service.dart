import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_logger.dart';

/// Modelo POO para los efectos de voz y cantos tradicionales de La Caída.
/// Encapsula la ruta del asset y las palabras clave de detección para evitar cadenas de `if-else`.
enum CantoSound {
  ronda('assets/sfx/cantos/sfx_ronda.mp3', ['ronda']),
  patrulla('assets/sfx/cantos/sfx_patrulla.mp3', ['patrulla']),
  vigia('assets/sfx/cantos/sfx_vigia.mp3', ['vigi', 'vigí']),
  registro('assets/sfx/cantos/sfx_registro.mp3', ['registro']),
  mesaLimpia('assets/sfx/cantos/sfx_mesa-limpia.mp3', ['limpia']),
  caida('assets/sfx/cantos/sfx_caida.mp3', ['caida', 'caída']),
  ultimas('assets/sfx/cantos/Ultimas.mp3', ['ultimas', 'últimas']),
  cuatro('assets/sfx/cantos/sfx_cuatro.mp3', ['cuatro']),
  uno('assets/sfx/cantos/sfx_uno.mp3', ['uno']);

  final String assetPath;
  final List<String> keywords;

  const CantoSound(this.assetPath, this.keywords);

  /// Búsqueda declarativa del canto por nombre o término descriptivo
  static CantoSound? fromName(String name) {
    final lower = name.toLowerCase();
    for (final sound in values) {
      if (sound.keywords.any((kw) => lower.contains(kw))) {
        return sound;
      }
    }
    return null;
  }
}

/// Servicio singleton para reproducción de efectos de sonido (SFX) y cantos tradicionales.
/// Implementa soporte polifónico mediante pools de AudioPlayers separados para SFX (cartas, interfaz)
/// y Cantos/Voces (Caída, Limpia, Últimas, etc.), con configuración de AudioContext sin interrupciones
/// de foco de audio (AndroidAudioFocus.none y AVAudioSessionCategory.ambient con mixWithOthers).
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    _initAudioContext();
  }

  // Pool para efectos de sonido recurrentes (repartir, voltear, clics)
  static const int _sfxPoolSize = 6;
  final List<AudioPlayer> _sfxPlayers = List.generate(
    _sfxPoolSize,
    (index) => AudioPlayer(playerId: 'sfx_pool_$index'),
  );
  int _sfxIndex = 0;

  // Pool para cantos y anuncios de voz (Últimas, Caída, Limpia, etc.)
  // Permite que una voz no sea cortada abruptamente por otra o por efectos de cartas.
  static const int _voicePoolSize = 3;
  final List<AudioPlayer> _voicePlayers = List.generate(
    _voicePoolSize,
    (index) => AudioPlayer(playerId: 'voice_pool_$index'),
  );
  int _voiceIndex = 0;

  final Map<String, Uint8List> _audioCache = {};
  bool _isMuted = false;
  bool _isPreloading = false;

  static const String cardDealPath = 'assets/sfx/cards/repartir-una.mp3';
  static const String cardFlipPath = 'assets/sfx/cards/voltear-carta.mp3';

  bool get isMuted => _isMuted;
  set isMuted(bool val) {
    _isMuted = val;
    if (_isMuted) {
      for (final p in _sfxPlayers) {
        p.stop().catchError((_) {});
      }
      for (final p in _voicePlayers) {
        p.stop().catchError((_) {});
      }
    }
  }

  void toggleMute() {
    isMuted = !isMuted;
  }

  /// Configura el AudioContext global para evitar que los sonidos compitan entre sí
  /// o se corten/pausen mutuamente en Android e iOS.
  void _initAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none, // Clave: no solicita exclusividad de foco de audio
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('AudioService: Error al configurar AudioContext global: $e');
      }
    }
  }

  /// Pre-carga todos los audios en memoria para reproducción instantánea sin descargas ni retardos.
  Future<void> preloadAudios() async {
    if (_isPreloading) return;
    _isPreloading = true;
    final soundPaths = [
      ...CantoSound.values.map((c) => c.assetPath),
      cardDealPath,
      cardFlipPath,
    ];

    for (final path in soundPaths) {
      try {
        if (!_audioCache.containsKey(path)) {
          final data = await rootBundle.load(path);
          _audioCache[path] = data.buffer.asUint8List();
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService preload error for $path: $e');
        }
      }
    }
  }

  Future<Uint8List?> _loadBytes(String assetPath) async {
    Uint8List? bytes = _audioCache[assetPath];
    if (bytes == null) {
      try {
        final data = await rootBundle.load(assetPath);
        bytes = data.buffer.asUint8List();
        _audioCache[assetPath] = bytes;
      } catch (e) {
        DebugLogger.instance.log(
          'Error al cargar bytes de audio ($assetPath): $e',
          category: 'Audio',
          level: LogLevel.warning,
        );
      }
    }
    return bytes;
  }

  Future<void> _playSfx(String assetPath, String name) async {
    if (_isMuted) return;
    try {
      final bytes = await _loadBytes(assetPath);
      if (bytes == null) return;

      final player = _sfxPlayers[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPlayers.length;

      await player.stop();
      await player.play(BytesSource(bytes));
      DebugLogger.instance.logAudio('SFX reproducido: $name');
    } catch (e) {
      DebugLogger.instance.log(
        'Error al reproducir SFX ($assetPath): $e',
        category: 'Audio',
        level: LogLevel.warning,
      );
    }
  }

  /// Reproduce el efecto de sonido a partir de un enum tipado CantoSound.
  Future<void> playCantoSound(CantoSound sound) async {
    if (_isMuted) return;
    try {
      final bytes = await _loadBytes(sound.assetPath);
      if (bytes == null) return;

      final player = _voicePlayers[_voiceIndex];
      _voiceIndex = (_voiceIndex + 1) % _voicePlayers.length;

      await player.stop();
      await player.play(BytesSource(bytes));
      DebugLogger.instance.logAudio('Canto reproducido: ${sound.name}');
    } catch (e) {
      DebugLogger.instance.log(
        'Error al reproducir canto (${sound.assetPath}): $e',
        category: 'Audio',
        level: LogLevel.warning,
      );
    }
  }

  /// Reproduce el efecto de sonido según el nombre del canto o evento de juego.
  Future<void> playCanto(String name) async {
    final sound = CantoSound.fromName(name);
    if (sound != null) {
      await playCantoSound(sound);
    }
  }

  // Accesos directos tipados
  Future<void> playCaida() => playCantoSound(CantoSound.caida);
  Future<void> playMesaLimpia() => playCantoSound(CantoSound.mesaLimpia);
  Future<void> playRonda() => playCantoSound(CantoSound.ronda);
  Future<void> playPatrulla() => playCantoSound(CantoSound.patrulla);
  Future<void> playVigia() => playCantoSound(CantoSound.vigia);
  Future<void> playRegistro() => playCantoSound(CantoSound.registro);
  Future<void> playUno() => playCantoSound(CantoSound.uno);
  Future<void> playCuatro() => playCantoSound(CantoSound.cuatro);
  Future<void> playUltimas() => playCantoSound(CantoSound.ultimas);

  /// Reproduce el efecto de sonido al repartir o colocar/jugar una carta en la mesa.
  Future<void> playCardDeal() async {
    if (_isMuted) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    await _playSfx(cardDealPath, 'Repartir / Colocar carta');
  }

  /// Alias para colocar una carta sobre la mesa de juego
  Future<void> playCardPlace() => playCardDeal();

  /// Alias para deslizamiento / barajado de carta
  Future<void> playCardSlide() => playCardDeal();

  /// Reproduce el efecto de sonido al voltear una carta (revelación boca arriba).
  Future<void> playCardFlip() async {
    if (_isMuted) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    await _playSfx(cardFlipPath, 'Volteo de carta');
  }

  void dispose() {
    for (final p in _sfxPlayers) {
      p.dispose();
    }
    for (final p in _voicePlayers) {
      p.dispose();
    }
  }
}
