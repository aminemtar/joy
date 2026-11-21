import 'dart:async';

import 'package:flutter/services.dart';

import 'sound.dart';

/// The strength of one vibration.
enum Buzz { none, selection, light, medium, heavy }

/// One place that decides how every sound effect feels in the hand.
///
/// Games only call `JoySounds.instance.play(effect)`; the matching vibration
/// fires from there, so sound and touch always agree and no game can forget
/// either. The Vibration toggle in Settings flips [enabled].
abstract final class JoyHaptics {
  /// Whether vibration is switched on in Settings.
  static bool enabled = true;

  /// How strongly [effect] vibrates. Ball hits are crisp and light, a crash or
  /// a blast is heavy, menu taps are the faintest tick.
  static Buzz forEffect(SoundEffect effect) => switch (effect) {
    SoundEffect.tap || SoundEffect.flip || SoundEffect.tick => Buzz.selection,
    SoundEffect.paddle ||
    SoundEffect.puck ||
    SoundEffect.wall ||
    SoundEffect.place ||
    SoundEffect.pop ||
    SoundEffect.hit ||
    SoundEffect.shoot ||
    SoundEffect.jump ||
    SoundEffect.eat ||
    SoundEffect.coin ||
    SoundEffect.swish ||
    SoundEffect.splash => Buzz.light,
    SoundEffect.correct ||
    SoundEffect.wrong ||
    SoundEffect.land ||
    SoundEffect.bump ||
    SoundEffect.unlock ||
    SoundEffect.start ||
    SoundEffect.whistle => Buzz.medium,
    SoundEffect.crash ||
    SoundEffect.blast ||
    SoundEffect.goal ||
    SoundEffect.win ||
    SoundEffect.draw => Buzz.heavy,
    SoundEffect.noteBlue ||
    SoundEffect.noteCoral ||
    SoundEffect.noteGold ||
    SoundEffect.notePurple => Buzz.light,
  };

  /// Vibrates for [effect] when vibration is enabled.
  static void fire(SoundEffect effect) => buzz(forEffect(effect));

  /// Vibrates with strength [level] when vibration is enabled.
  static void buzz(Buzz level) {
    if (!enabled) return;
    final Future<void>? call = switch (level) {
      Buzz.none => null,
      Buzz.selection => HapticFeedback.selectionClick(),
      Buzz.light => HapticFeedback.lightImpact(),
      Buzz.medium => HapticFeedback.mediumImpact(),
      Buzz.heavy => HapticFeedback.heavyImpact(),
    };
    // A device without a vibration motor must never break gameplay.
    if (call != null) unawaited(call.catchError((Object _) {}));
  }
}
