import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy/haptics.dart';
import 'package:joy/sound.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every sound effect has a vibration strength', () {
    for (final effect in SoundEffect.values) {
      expect(JoyHaptics.forEffect(effect), isNot(Buzz.none));
    }
  });

  test('Ball hits are light, crashes and goals are heavy, taps are faint', () {
    expect(JoyHaptics.forEffect(SoundEffect.paddle), Buzz.light);
    expect(JoyHaptics.forEffect(SoundEffect.puck), Buzz.light);
    expect(JoyHaptics.forEffect(SoundEffect.tap), Buzz.selection);
    expect(JoyHaptics.forEffect(SoundEffect.crash), Buzz.heavy);
    expect(JoyHaptics.forEffect(SoundEffect.goal), Buzz.heavy);
  });

  test('Vibration follows the Settings toggle', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
    addTearDown(() {
      JoyHaptics.enabled = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    JoyHaptics.enabled = false;
    JoyHaptics.fire(SoundEffect.crash);
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
    JoyHaptics.enabled = true;
    JoyHaptics.fire(SoundEffect.crash);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['HapticFeedbackType.heavyImpact']);
  });
}
