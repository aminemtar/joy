import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  notePurple('note_purple');

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
          source: AssetSource(effect.asset),
          minPlayers: 1,
          maxPlayers: 2,
          audioContext:
              AudioContextConfig(
                focus: AudioContextConfigFocus.mixWithOthers,
                respectSilence: true,
              ).build(),
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
    if (!canPlay || _celebrating) return;
    final now = _now(), previous = _lastPlayed[effect];
    final interval = effect == SoundEffect.hit ? 95 : 55;
    if (previous != null &&
        now.difference(previous).inMilliseconds < interval) {
      return;
    }
    _lastPlayed[effect] = now;
    unawaited(_safely(() => _output.play(effect, _volume)));
  }

  /// The result fanfare replaces pending effects instead of layering on top.
  void celebrate(int winner) {
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
  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      // Audio failure should never interrupt a move or strand a result screen.
      debugPrint('JOY sound unavailable: $error');
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
