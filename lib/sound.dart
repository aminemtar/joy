import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'haptics.dart';

enum SoundEffect {
  tap('tap'),
  flip('flip'),
  correct('correct'),
  wrong('wrong'),
  hit('hit'),
  jump('jump'),
  shoot('shoot'),
  tick('tick'),
  start('start'),
  win('win'),
  draw('draw'),
  noteBlue('note_blue'),
  noteCoral('note_coral'),
  noteGold('note_gold'),
  notePurple('note_purple'),
  paddle('paddle'),
  wall('wall'),
  puck('puck'),
  place('place'),
  land('land'),
  bump('bump'),
  crash('crash'),
  blast('blast'),
  swish('swish'),
  splash('splash'),
  goal('goal'),
  whistle('whistle'),
  coin('coin'),
  unlock('unlock'),
  eat('eat'),
  pop('pop');

  final String file;
  const SoundEffect(this.file);
  String get asset => 'audio/$file.wav';
}

abstract interface class SoundOutput {
  Future<void> play(SoundEffect effect, double volume);
  Future<void> stopAll();
  Future<void> dispose();
}

/// Native resources are created only for effects actually used. A serialized
/// command queue avoids play/dispose races while a platform is loading a clip.
class PooledSoundOutput implements SoundOutput {
  PooledSoundOutput({AudioCache? audioCache}) : _audioCache = audioCache;
  final AudioCache? _audioCache;

  // Game effects use media volume, not notification/ringer volume. Playback
  // plus mixWithOthers is a valid iOS pair; ambient plus that option is not.
  static AudioContext get audioContext => AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  final _pools = <SoundEffect, AudioPool>{};
  Future<void> _queue = Future.value();
  int _generation = 0;
  bool _disposed = false;
  Future<void> _enqueue(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    // A rejected platform operation must not poison the next queue operation.
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<void> play(SoundEffect effect, double volume) {
    final generation = _generation;
    return _enqueue(() async {
      if (_disposed || generation != _generation) return;
      var pool = _pools[effect];
      if (pool == null) {
        pool = await AudioPool.create(
          source: AssetSource(effect.asset, mimeType: 'audio/wav'),
          audioCache: _audioCache,
          minPlayers: 1,
          maxPlayers: 2,
          audioContext: audioContext,
        );
        _pools[effect] = pool;
      }
      if (_disposed || generation != _generation) return;
      await pool.start(volume: volume);
    });
  }

  Future<void> _release() async {
    final pools = _pools.values.toList();
    _pools.clear();
    await Future.wait(pools.map((p) => p.dispose()));
  }

  @override
  Future<void> stopAll() {
    _generation++;
    return _enqueue(_release);
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    return stopAll();
  }
}

class JoySounds extends ChangeNotifier with WidgetsBindingObserver {
  JoySounds({required SoundOutput output, DateTime Function()? now})
    : _output = output,
      _now = now ?? DateTime.now;
  static final instance = JoySounds(output: PooledSoundOutput());
  final SoundOutput _output;
  final DateTime Function() _now;
  final _lastPlayed = <SoundEffect, DateTime>{};
  SharedPreferences? _preferences;
  bool _initialized = false,
      _enabled = true,
      _foreground = true,
      _closed = false;
  bool _celebrating = false;
  String? _lastError;
  String? get lastError => _lastError;
  double _volume = .6;
  int _generation = 0;
  bool get enabled => _enabled;
  double get volume => _volume;
  bool get canPlay =>
      _initialized && !_closed && _enabled && _foreground && _volume > 0;

  Future<void> initialize() async {
    if (_initialized || _closed) return;
    _preferences = await SharedPreferences.getInstance();
    if (_closed) return;
    _enabled = _preferences!.getBool('soundEnabled') ?? true;
    _volume = (_preferences!.getDouble('soundVolume') ?? .6).clamp(0.0, 1.0);
    _initialized = true;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_closed) return;
    _enabled = value;
    // Toggling the speaker on should actually restore an audible level.
    if (value && _volume == 0) {
      _volume = .6;
      final preferences =
          _preferences ??= await SharedPreferences.getInstance();
      await preferences.setDouble('soundVolume', _volume);
    }
    if (!value) stop();
    notifyListeners();
    final p = _preferences ??= await SharedPreferences.getInstance();
    await p.setBool('soundEnabled', value);
  }

  Future<void> setVolume(double value) async {
    if (_closed) return;
    _volume = value.clamp(0.0, 1.0);
    if (_volume == 0) stop();
    notifyListeners();
    final p = _preferences ??= await SharedPreferences.getInstance();
    await p.setDouble('soundVolume', _volume);
  }

  void play(SoundEffect effect) {
    final now = _now();
    // Touch feedback is independent of the speaker: it still fires when the
    // sound is muted, with its own throttle so a burst never turns to a buzz.
    final lastBuzz = _lastBuzz;
    if (JoyHaptics.enabled &&
        !_celebrating &&
        (lastBuzz == null || now.difference(lastBuzz).inMilliseconds >= 45)) {
      _lastBuzz = now;
      JoyHaptics.fire(effect);
    }
    if (!canPlay || _celebrating) return;
    final previous = _lastPlayed[effect];
    if (previous != null &&
        now.difference(previous).inMilliseconds < _interval(effect)) {
      return;
    }
    _lastPlayed[effect] = now;
    final effectVolume = effect == SoundEffect.tap ? _volume * .72 : _volume;
    unawaited(_safely(() => _output.play(effect, effectVolume)));
  }

  DateTime? _lastBuzz;

  /// Shortest gap between two plays of [effect], in milliseconds. Fast ball
  /// sports need tight gaps so every hit is heard; long cues are spaced out.
  static int _interval(SoundEffect effect) => switch (effect) {
    SoundEffect.paddle || SoundEffect.puck || SoundEffect.wall => 50,
    SoundEffect.hit || SoundEffect.bump => 110,
    SoundEffect.tap => 85,
    SoundEffect.goal || SoundEffect.crash || SoundEffect.blast => 160,
    _ => 65,
  };

  /// The result fanfare replaces pending effects instead of layering on top.
  void celebrate(int winner) {
    JoyHaptics.fire(winner < 0 ? SoundEffect.draw : SoundEffect.win);
    if (!canPlay) return;
    _generation++;
    _lastPlayed.clear();
    _celebrating = true;
    final generation = _generation;
    unawaited(
      _safely(() async {
        await _output.stopAll();
        if (!canPlay || generation != _generation) return;
        await _output.play(
          winner < 0 ? SoundEffect.draw : SoundEffect.win,
          _volume,
        );
      }),
    );
  }

  void stop() {
    _generation++;
    _celebrating = false;
    _lastPlayed.clear();
    if (_initialized && !_closed) unawaited(_safely(_output.stopAll));
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      setForeground(state == AppLifecycleState.resumed);
  String _describeError(Object error) {
    if (error is MissingPluginException) {
      return 'Audio plugin needs a full restart. Stop the app, run flutter pub get, then flutter run.';
    }
    final detail = error.toString();
    return 'Sound playback failed: ${detail.length > 240 ? detail.substring(0, 240) : detail}';
  }

  void _reportError(Object error) {
    debugPrint('JOY sound unavailable: $error');
    if (_closed) return;
    _lastError = _describeError(error);
    notifyListeners();
  }

  /// Explicit user-triggered diagnosis; never claims to detect speaker output.
  Future<String?> testSound() async {
    if (_closed) return 'Audio is no longer available. Restart the app.';
    await initialize();
    if (!_enabled) return 'Sound effects are muted. Enable them first.';
    if (_volume == 0) return 'Sound volume is zero. Raise the volume slider.';
    if (!_foreground) return 'Return to the app before testing sound.';
    _generation++;
    final generation = _generation;
    _celebrating = false;
    _lastPlayed.clear();
    _lastError = null;
    try {
      await _output.stopAll().timeout(const Duration(seconds: 5));
      if (!canPlay || generation != _generation) return 'Sound test cancelled.';
      await _output
          .play(SoundEffect.win, _volume)
          .timeout(const Duration(seconds: 8));
      if (!_closed) notifyListeners();
      return null;
    } catch (error) {
      _reportError(error);
      return _lastError;
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // Preserve gameplay, but make the failure visible in sound settings.
      _reportError(error);
    }
  }

  @override
  void dispose() {
    if (_closed) return;
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _closed = true;
    _generation++;
    unawaited(_safely(_output.dispose));
    super.dispose();
  }
}
