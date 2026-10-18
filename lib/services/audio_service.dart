import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Servicio para reproducir sonidos de la Pokédex.
/// Usa reproductores separados para que música, pokébola y gritos no se corten entre sí.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String _pokeballAsset = 'musica/pokeball opening sound FX.mp3';
  static const String _backgroundMusicAsset =
      'musica/Pokémon Blanco y Negro OST - 16 - Centro Pokémon.mp3';

  // Let just_audio apply the shared audio-session settings and activate the
  // session when playback starts. Disabling this can leave every player silent.
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _cryPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _musicMuted = false;
  bool _initialized = false;
  bool _musicLoaded = false;
  bool _sfxLoaded = false;
  bool _musicStarting = false;
  bool _appIsActive = true;
  Future<void>? _initFuture;

  bool get isMuted => _isMuted;
  bool get musicMuted => _musicMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _sfxPlayer.pause();
      _cryPlayer.pause();
    }
  }

  void toggleMusicMute() {
    // If startup autoplay was blocked by the browser, the first tap should
    // retry playback instead of turning music off.
    if (_musicMuted || !_musicPlayer.playing) {
      _musicMuted = false;
      startBackgroundMusic();
    } else {
      _musicMuted = true;
      _musicPlayer.pause();
    }
  }

  Future<void> _initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    if (_initialized) return;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Error inicializando audio session: $e');
    }

    _initialized = true;
  }

  /// Reproduce el grito de un Pokémon desde PokeAPI (no comparte player con SFX).
  Future<void> playPokemonCry(int pokemonId) async {
    if (_isMuted) return;

    await _initialize();

    final urls = [
      'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/latest/$pokemonId.ogg',
      'https://raw.githubusercontent.com/PokeAPI/cries/main/cries/pokemon/legacy/$pokemonId.ogg',
    ];

    try {
      await _cryPlayer.stop();
      Object? lastError;
      for (final url in urls) {
        try {
          // Avoid custom headers: just_audio implements them through a local
          // HTTP proxy on mobile, which requires extra cleartext configuration.
          await _cryPlayer.setUrl(url);
          await _cryPlayer.setVolume(1.0);
          await _cryPlayer.play();
          return;
        } catch (e) {
          lastError = e;
        }
      }
      debugPrint('Error reproduciendo grito: $lastError');
    } catch (e) {
      debugPrint('Error reproduciendo audio: $e');
    } finally {
      // Release the platform decoder after the cry completes. Keeping a
      // completed MediaCodec around for every opened detail screen can build
      // up memory pressure on Android devices.
      try {
        await _cryPlayer.stop();
      } catch (_) {}
    }
  }

  /// Reproduce el efecto de abrir la Pokébola (asset local).
  Future<void> playPokeballOpen() async {
    if (_isMuted) return;

    await _initialize();

    try {
      if (!_sfxLoaded) {
        await _sfxPlayer.setAsset(_pokeballAsset);
        await _sfxPlayer.setVolume(0.85);
        _sfxLoaded = true;
      }
      await _sfxPlayer.seek(Duration.zero);
      await _sfxPlayer.play();
    } catch (e) {
      debugPrint('Error reproduciendo pokeball: $e');
    } finally {
      try {
        await _sfxPlayer.stop();
      } catch (_) {}
    }
  }

  /// Inicia la música de fondo en loop (asset local).
  Future<void> startBackgroundMusic() async {
    if (_musicMuted || !_appIsActive || _musicStarting) return;

    _musicStarting = true;
    try {
      await _initialize();
      if (_musicMuted || !_appIsActive || _musicPlayer.playing) return;

      if (!_musicLoaded) {
        await _musicPlayer.setAsset(_backgroundMusicAsset);
        await _musicPlayer.setLoopMode(LoopMode.one);
        await _musicPlayer.setVolume(0.4);
        _musicLoaded = true;
      }

      if (_musicMuted || !_appIsActive || _musicPlayer.playing) return;
      unawaited(
        _musicPlayer.play().catchError((Object error) {
          debugPrint('Error reproduciendo música: $error');
        }),
      );
    } catch (e) {
      debugPrint('Error reproduciendo música: $e');
    } finally {
      _musicStarting = false;
    }
  }

  Future<void> pauseBackgroundMusic() async {
    _appIsActive = false;
    await _musicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    _appIsActive = true;
    if (_musicMuted) return;
    await startBackgroundMusic();
  }

  /// No llamar desde pantallas individuales: este servicio es singleton.
  void dispose() {
    _sfxPlayer.dispose();
    _cryPlayer.dispose();
    _musicPlayer.dispose();
    _initialized = false;
    _musicLoaded = false;
    _sfxLoaded = false;
    _musicStarting = false;
    _appIsActive = true;
    _initFuture = null;
  }
}
