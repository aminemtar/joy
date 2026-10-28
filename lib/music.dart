import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound.dart';

abstract interface class MusicOutput {
  Future<void> play(double volume);
  Future<void> pause();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class LoopMusicOutput implements MusicOutput {
  LoopMusicOutput({AudioCache? audioCache}) : _audioCache = audioCache;
  final AudioCache? _audioCache;
  AudioPlayer? _player;
  Future<void> _queue = Future.value();
  bool _closed = false, _wanted = false;
  Future<void> _run(Future<void> Function() action) {
    final future = _queue.then((_) => action());
    _queue = future.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return future;
  }

  @override
  Future<void> play(double volume) {
    _wanted = true;
    return _run(() async {
      if (_closed || !_wanted) return;
      if (_player == null) {
        final player = AudioPlayer();
        _player = player;
        if (_audioCache != null) player.audioCache = _audioCache;
        try {
          await player.setAudioContext(PooledSoundOutput.audioContext);
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setSource(
            AssetSource('audio/background.wav', mimeType: 'audio/wav'),
          );
        } catch (_) {
          _player = null;
          await player.dispose();
          rethrow;
        }
      }
      if (_closed || !_wanted) return;
      await _player!.setVolume(volume);
      await _player!.resume();
    });
  }

  @override
  Future<void> pause() {
    _wanted = false;
    return _run(() async {
      await _player?.pause();
    });
  }

  @override
  Future<void> setVolume(double volume) => _run(() async {
    await _player?.setVolume(volume);
  });
  @override
  Future<void> dispose() {
    _closed = true;
    return _run(() async {
      await _player?.dispose();
      _player = null;
    });
  }
}

class JoyMusic extends ChangeNotifier with WidgetsBindingObserver {
  JoyMusic({required MusicOutput output}) : _output = output;
  static final instance = JoyMusic(output: LoopMusicOutput());
  final MusicOutput _output;
  SharedPreferences? _preferences;
  bool _ready = false, _closed = false, _enabled = true, _foreground = true;
  double _volume = .22;
  String? _error;
  bool get enabled => _enabled;
  double get volume => _volume;
  String? get error => _error;
  Future<void> initialize() async {
    if (_ready || _closed) return;
    _preferences = await SharedPreferences.getInstance();
    if (_closed) return;
    _enabled = _preferences!.getBool('musicEnabled') ?? true;
    _volume = (_preferences!.getDouble('musicVolume') ?? .22).clamp(0.0, 1.0);
    _ready = true;
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    notifyListeners();
  }

  Future<void> resume() async {
    if (!_ready || _closed || !_foreground || !_enabled || _volume == 0) return;
    try {
      await _output.play(_volume);
      _error = null;
    } catch (_) {
      _error = 'Music could not start. Tap the music switch to retry.';
    }
    if (!_closed) notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_closed) return;
    if (!_ready) await initialize();
    if (_closed) return;
    _enabled = value;
    if (value && _volume == 0) _volume = .22;
    notifyListeners();
    await _preferences!.setBool('musicEnabled', value);
    await _preferences!.setDouble('musicVolume', _volume);
    if (_enabled) {
      await resume();
    } else {
      await _pauseSafely();
    }
  }

  Future<void> setVolume(double value) async {
    if (_closed) return;
    if (!_ready) await initialize();
    if (_closed) return;
    _volume = value.clamp(0.0, 1.0);
    notifyListeners();
    await _preferences!.setDouble('musicVolume', _volume);
    try {
      await _output.setVolume(_volume);
    } catch (_) {
      _error = 'Music volume could not be changed.';
    }
    if (_volume == 0) {
      await _pauseSafely();
    } else if (_enabled && _foreground) {
      await resume();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(resume());
    } else {
      unawaited(_pauseSafely());
    }
  }

  Future<void> _pauseSafely() async {
    try {
      await _output.pause();
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    if (_ready) WidgetsBinding.instance.removeObserver(this);
    unawaited(_output.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
