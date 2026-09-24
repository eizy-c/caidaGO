import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_logger.dart';

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
      'assets/sfx/cantos/sfx_caida.mp3',
      'assets/sfx/cantos/sfx_mesa-limpia.mp3',
      'assets/sfx/cantos/sfx_patrulla.mp3',
      'assets/sfx/cantos/sfx_registro.mp3',
      'assets/sfx/cantos/sfx_ronda.mp3',
      'assets/sfx/cantos/sfx_vigia.mp3',
      'assets/sfx/cantos/sfx_uno.mp3',
      'assets/sfx/cantos/sfx_cuatro.mp3',
      'assets/sfx/cantos/Ultimas.mp3',
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

  /// Reproduce el efecto de sonido según el nombre del canto o evento de juego.
  /// Utiliza un pool de reproductores dedicados para voces para no ser interrumpido
  /// por efectos de cartas o clics.
  Future<void> playCanto(String name) async {
    if (_isMuted) return;

    final lower = name.toLowerCase();
    String? assetPath;

    if (lower.contains('ronda')) {
      assetPath = 'assets/sfx/cantos/sfx_ronda.mp3';
    } else if (lower.contains('patrulla')) {
      assetPath = 'assets/sfx/cantos/sfx_patrulla.mp3';
    } else if (lower.contains('vigi') || lower.contains('vigí')) {
      assetPath = 'assets/sfx/cantos/sfx_vigia.mp3';
    } else if (lower.contains('registro')) {
      assetPath = 'assets/sfx/cantos/sfx_registro.mp3';
    } else if (lower.contains('limpia')) {
      assetPath = 'assets/sfx/cantos/sfx_mesa-limpia.mp3';
    } else if (lower.contains('caida') || lower.contains('caída')) {
      assetPath = 'assets/sfx/cantos/sfx_caida.mp3';
    } else if (lower.contains('ultimas') || lower.contains('últimas')) {
      assetPath = 'assets/sfx/cantos/Ultimas.mp3';
    } else if (lower == 'cuatro') {
      assetPath = 'assets/sfx/cantos/sfx_cuatro.mp3';
    } else if (lower == 'uno') {
      assetPath = 'assets/sfx/cantos/sfx_uno.mp3';
    }

    if (assetPath != null) {
      try {
        final bytes = await _loadBytes(assetPath);
        if (bytes == null) return;

        final player = _voicePlayers[_voiceIndex];
        _voiceIndex = (_voiceIndex + 1) % _voicePlayers.length;

        await player.stop();
        await player.play(BytesSource(bytes));
        DebugLogger.instance.logAudio('Canto reproducido: $name');
      } catch (e) {
        DebugLogger.instance.log(
          'Error al reproducir canto ($assetPath): $e',
          category: 'Audio',
          level: LogLevel.warning,
        );
      }
    }
  }

  Future<void> playCaida() => playCanto('caida');
  Future<void> playMesaLimpia() => playCanto('limpia');
  Future<void> playRonda() => playCanto('ronda');
  Future<void> playPatrulla() => playCanto('patrulla');
  Future<void> playVigia() => playCanto('vigia');
  Future<void> playRegistro() => playCanto('registro');
  Future<void> playUno() => playCanto('uno');
  Future<void> playCuatro() => playCanto('cuatro');
  Future<void> playUltimas() => playCanto('ultimas');

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
