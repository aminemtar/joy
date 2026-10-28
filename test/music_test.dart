import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/music.dart';
import 'dart:typed_data';

class MusicRecorder implements MusicOutput {
  int plays = 0, pauses = 0;
  double volume = 0;
  bool closed = false, fail = false;
  @override
  Future<void> play(double level) async {
    if (fail) throw StateError('blocked');
    plays++;
    volume = level;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> setVolume(double level) async {
    volume = level;
  }

  @override
  Future<void> dispose() async {
    closed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Original background track is a bounded twenty-second PCM loop',
    () async {
      final bytes = await rootBundle.load('assets/audio/background.wav');
      expect(bytes.getUint32(24, Endian.little), 22050);
      final frames = bytes.getUint32(40, Endian.little) ~/ 2;
      expect(frames / 22050, 20);
      expect(bytes.getInt16(44, Endian.little), 0);
      expect(bytes.getInt16(bytes.lengthInBytes - 2, Endian.little), 0);
    },
  );
  test(
    'Music starts, pauses in background, and resumes in foreground',
    () async {
      final output = MusicRecorder();
      final service = JoyMusic(output: output);
      await service.initialize();
      await service.resume();
      expect(output.plays, 1);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(output.pauses, 1);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(output.plays, 2);
      service.dispose();
    },
  );
  test('Music mute and volume persist independently from effects', () async {
    SharedPreferences.setMockInitialValues({
      'soundEnabled': true,
      'musicEnabled': false,
      'musicVolume': .15,
    });
    final output = MusicRecorder();
    final music = JoyMusic(output: output);
    await music.initialize();
    await music.resume();
    expect(output.plays, 0);
    await music.setEnabled(true);
    await music.setVolume(.3);
    expect(output.volume, .3);
    await music.setEnabled(false);
    expect(output.pauses, greaterThan(0));
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('musicEnabled'), false);
    expect(p.getDouble('musicVolume'), .3);
    expect(p.getBool('soundEnabled'), true);
    music.dispose();
  });
  test('Blocked autoplay reports a recoverable music status', () async {
    final output = MusicRecorder()..fail = true;
    final music = JoyMusic(output: output);
    await music.initialize();
    await music.resume();
    expect(music.error, isNotNull);
    output.fail = false;
    await music.resume();
    expect(music.error, isNull);
    expect(output.plays, 1);
    music.dispose();
  });
}
