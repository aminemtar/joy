import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:joy/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:joy/sound.dart';

class RecordingSoundOutput implements SoundOutput {
  final played = <SoundEffect>[];
  final levels = <double>[];
  int stops = 0;
  bool disposed = false, fail = false;
  Completer<void>? gate;
  @override
  Future<void> play(SoundEffect effect, double volume) async {
    if (fail) throw StateError('Simulated unavailable output');
    played.add(effect);
    levels.add(volume);
  }

  @override
  Future<void> stopAll() async {
    stops++;
    await gate?.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Future<void> flush() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'Every bundled effect is a finite non-clipping offline PCM WAV',
    () async {
      expect(SoundEffect.values.length, 15);
      final signatures = <String>{};
      for (final effect in SoundEffect.values) {
        final data = await rootBundle.load('assets/${effect.asset}');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE');
        expect(data.getUint16(20, Endian.little), 1);
        expect(data.getUint16(22, Endian.little), 1);
        expect(data.getUint32(24, Endian.little), 22050);
        expect(data.getUint16(34, Endian.little), 16);
        final length = data.getUint32(40, Endian.little);
        expect(length + 44, data.lengthInBytes);
        expect(length / 2 / 22050, inInclusiveRange(.05, 1.2));
        var peak = 0;
        for (var i = 44; i < data.lengthInBytes; i += 2) {
          final v = data.getInt16(i, Endian.little).abs();
          if (v > peak) peak = v;
        }
        expect(peak, inInclusiveRange(1000, 26000));
        expect(data.getInt16(data.lengthInBytes - 2, Endian.little), 0);
        signatures.add('$length:$peak');
      }
      expect(signatures.length, 15);
    },
  );
  test('Audio is inert until explicitly initialized', () async {
    final output = RecordingSoundOutput();
    final audio = JoySounds(output: output);
    audio.play(SoundEffect.tap);
    await flush();
    expect(output.played, isEmpty);
    audio.dispose();
  });
  test('Mute and volume are restored and persisted', () async {
    SharedPreferences.setMockInitialValues({
      'soundEnabled': false,
      'soundVolume': .25,
    });
    final output = RecordingSoundOutput(), audio = JoySounds(output: output);
    await audio.initialize();
    expect(audio.enabled, false);
    expect(audio.volume, .25);
    audio.play(SoundEffect.win);
    await flush();
    expect(output.played, isEmpty);
    await audio.setEnabled(true);
    await audio.setVolume(.4);
    audio.play(SoundEffect.tap);
    await flush();
    expect(output.played, [SoundEffect.tap]);
    expect(output.levels, [.4]);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('soundEnabled'), true);
    expect(p.getDouble('soundVolume'), .4);
    await audio.setEnabled(false);
    await flush();
    expect(output.stops, greaterThan(0));
    audio.dispose();
  });
  test(
    'Repeated collisions are throttled but different effects may overlap',
    () async {
      var clock = DateTime(2026);
      final output = RecordingSoundOutput();
      final service = JoySounds(output: output, now: () => clock);
      await service.initialize();
      service.play(SoundEffect.hit);
      service.play(SoundEffect.hit);
      service.play(SoundEffect.jump);
      await flush();
      expect(output.played, [SoundEffect.hit, SoundEffect.jump]);
      clock = clock.add(const Duration(milliseconds: 100));
      service.play(SoundEffect.hit);
      await flush();
      expect(output.played.last, SoundEffect.hit);
      expect(output.played.length, 3);
      service.dispose();
    },
  );
  test(
    'Lifecycle pause stops playback and suppresses new effects until resumed',
    () async {
      final output = RecordingSoundOutput(), audio = JoySounds(output: output);
      await audio.initialize();
      audio.play(SoundEffect.flip);
      await flush();
      audio.didChangeAppLifecycleState(AppLifecycleState.paused);
      audio.play(SoundEffect.hit);
      await flush();
      expect(output.stops, 1);
      expect(output.played, [SoundEffect.flip]);
      audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
      audio.play(SoundEffect.correct);
      await flush();
      expect(output.played.last, SoundEffect.correct);
      audio.dispose();
    },
  );
  test(
    'Victory replaces gameplay cues, and leaving the result unlocks sound',
    () async {
      final output = RecordingSoundOutput(), audio = JoySounds(output: output);
      await audio.initialize();
      audio.celebrate(0);
      await flush();
      expect(output.stops, 1);
      expect(output.played, [SoundEffect.win]);
      audio.play(SoundEffect.hit);
      await flush();
      expect(output.played.length, 1);
      audio.stop();
      audio.play(SoundEffect.start);
      await flush();
      expect(output.played.last, SoundEffect.start);
      audio.dispose();
    },
  );
  test('A draw has its own fanfare', () async {
    final output = RecordingSoundOutput(), audio = JoySounds(output: output);
    await audio.initialize();
    audio.celebrate(-1);
    await flush();
    expect(output.played, [SoundEffect.draw]);
    audio.dispose();
  });
  test('Muting cancels a victory waiting for an output operation', () async {
    final output = RecordingSoundOutput()..gate = Completer<void>();
    final service = JoySounds(output: output);
    await service.initialize();
    service.celebrate(1);
    await service.setEnabled(false);
    output.gate!.complete();
    await flush();
    expect(output.played, isEmpty);
    service.dispose();
  });
  test(
    'Zero volume suppresses playback and values clamp to valid range',
    () async {
      final output = RecordingSoundOutput(), audio = JoySounds(output: output);
      await audio.initialize();
      await audio.setVolume(-1);
      expect(audio.volume, 0);
      audio.play(SoundEffect.tap);
      await flush();
      expect(output.played, isEmpty);
      await audio.setVolume(2);
      expect(audio.volume, 1);
      audio.dispose();
    },
  );
  test('Output errors do not escape into gameplay', () async {
    final output = RecordingSoundOutput()..fail = true;
    final service = JoySounds(output: output);
    await service.initialize();
    service.play(SoundEffect.flip);
    await flush();
    service.celebrate(0);
    await flush();
    service.dispose();
  });
  test('Disposal releases resources and prevents later playback', () async {
    final output = RecordingSoundOutput(), audio = JoySounds(output: output);
    await audio.initialize();
    audio.dispose();
    await flush();
    audio.play(SoundEffect.tap);
    await flush();
    expect(output.disposed, true);
    expect(output.played, isEmpty);
  });
  testWidgets('Quick mute updates the lobby and saves the preference', (
    tester,
  ) async {
    await JoySounds.instance.setEnabled(true);
    await tester.pumpWidget(const JoyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mute sound effects'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Enable sound effects'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('soundEnabled'), false);
    await tester.tap(find.byTooltip('Enable sound effects'));
    await tester.pumpAndSettle();
    expect(preferences.getBool('soundEnabled'), true);
    expect(tester.takeException(), isNull);
  });
}
