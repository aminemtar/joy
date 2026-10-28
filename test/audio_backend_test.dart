import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    as bridge;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/sound.dart';
import 'package:joy/music.dart';

// Keep AudioPool and AudioPlayer real: fake only the OS bridge and cache path.
// This executes the platform configuration that the old service fakes skipped.
class BundledCache extends AudioCache {
  @override
  Future<String> loadPath(String name) async {
    final bytes = await rootBundle.load('assets/$name');
    expect(bytes.lengthInBytes, greaterThan(44));
    return '/test/$name';
  }
}

class PlayerBridge extends Fake
    implements bridge.AudioplayersPlatformInterface {
  final streams = <String, StreamController<bridge.AudioEvent>>{};
  final contexts = <AudioContext>[], sources = <String>[];
  PlayerBridge({this.expectedVolume = .6});
  final double expectedVolume;
  final releaseModes = <ReleaseMode>[];
  int resumed = 0, disposed = 0, paused = 0;
  @override
  Future<void> create(String id) async {
    streams[id] = StreamController.broadcast();
  }

  @override
  Stream<bridge.AudioEvent> getEventStream(String id) => streams[id]!.stream;
  @override
  Future<void> setPlayerMode(String id, PlayerMode mode) async {}
  @override
  Future<void> setAudioContext(String id, AudioContext context) async {
    contexts.add(context);
  }

  @override
  Future<void> setSourceUrl(
    String id,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    sources.add(url);
    expect(isLocal, true);
    expect(mimeType, 'audio/wav');
    streams[id]!.add(
      const bridge.AudioEvent(
        eventType: bridge.AudioEventType.prepared,
        isPrepared: true,
      ),
    );
  }

  @override
  Future<void> setReleaseMode(String id, ReleaseMode mode) async {
    releaseModes.add(mode);
  }

  @override
  Future<void> setVolume(String id, double volume) async {
    expect(volume, expectedVolume);
  }

  @override
  Future<void> resume(String id) async {
    resumed++;
  }

  @override
  Future<int?> getDuration(String id) async => 900;
  @override
  Future<int?> getCurrentPosition(String id) async => 0;
  @override
  Future<void> pause(String id) async {
    paused++;
  }

  @override
  Future<void> stop(String id) async {}
  @override
  Future<void> release(String id) async {}
  @override
  Future<void> dispose(String id) async {
    disposed++;
    await streams.remove(id)?.close();
  }
}

class GlobalBridge extends Fake
    implements bridge.GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}
  @override
  Stream<bridge.GlobalAudioEvent> getGlobalEventStream() =>
      const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test(
      'Real audio pool prepares and resumes a bundled WAV on $platform',
      () async {
        final original = bridge.AudioplayersPlatformInterface.instance;
        final originalGlobal =
            bridge.GlobalAudioplayersPlatformInterface.instance;
        final player = PlayerBridge();
        bridge.AudioplayersPlatformInterface.instance = player;
        bridge.GlobalAudioplayersPlatformInterface.instance = GlobalBridge();
        debugDefaultTargetPlatformOverride = platform;
        final output = PooledSoundOutput(audioCache: BundledCache());
        try {
          await output.play(SoundEffect.win, .6);
          expect(player.resumed, 1);
          expect(player.sources, ['/test/audio/win.wav']);
          expect(
            player.contexts.single.android.usageType,
            AndroidUsageType.game,
          );
          expect(
            player.contexts.single.android.audioFocus,
            AndroidAudioFocus.none,
          );
          expect(
            player.contexts.single.iOS.category,
            AVAudioSessionCategory.playback,
          );
          expect(
            player.contexts.single.iOS.options,
            contains(AVAudioSessionOptions.mixWithOthers),
          );
          await output.stopAll();
          expect(player.disposed, 1);
        } finally {
          await output.dispose();
          debugDefaultTargetPlatformOverride = null;
          bridge.AudioplayersPlatformInterface.instance = original;
          bridge.GlobalAudioplayersPlatformInterface.instance = originalGlobal;
        }
      },
    );
  }
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test(
      'Real background player loops and reuses its source on $platform',
      () async {
        final original = bridge.AudioplayersPlatformInterface.instance;
        final originalGlobal =
            bridge.GlobalAudioplayersPlatformInterface.instance;
        final player = PlayerBridge(expectedVolume: .22);
        bridge.AudioplayersPlatformInterface.instance = player;
        bridge.GlobalAudioplayersPlatformInterface.instance = GlobalBridge();
        debugDefaultTargetPlatformOverride = platform;
        final output = LoopMusicOutput(audioCache: BundledCache());
        try {
          await output.play(.22);
          await output.pause();
          await output.play(.22);
          expect(player.sources, ['/test/audio/background.wav']);
          expect(player.releaseModes, contains(ReleaseMode.loop));
          expect(player.resumed, 2);
          expect(player.paused, 1);
        } finally {
          await output.dispose();
          debugDefaultTargetPlatformOverride = null;
          bridge.AudioplayersPlatformInterface.instance = original;
          bridge.GlobalAudioplayersPlatformInterface.instance = originalGlobal;
        }
        expect(player.disposed, 1);
      },
    );
  }
}
