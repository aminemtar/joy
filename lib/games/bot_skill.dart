import 'dart:math';

import 'package:flutter/widgets.dart';

import '../party_data.dart';

/// How strong the computer opponent is, derived from the match difficulty.
///
/// Every game that can be played against the computer uses this one helper, so
/// "Easy", "Normal" and "Hard" mean the same thing everywhere.
class BotSkill {
  final Difficulty level;
  const BotSkill(this.level);

  /// Reads the difficulty the current match was started with.
  factory BotSkill.of(BuildContext context) =>
      BotSkill(MatchOptions.read(context)?.difficulty ?? Difficulty.normal);

  /// Whether the match is played against the computer.
  static bool isComputer(BuildContext context) =>
      MatchOptions.read(context)?.computer == true;

  /// Chance that the computer picks the right answer or the best move.
  double get accuracy => switch (level) {
    Difficulty.easy => .55,
    Difficulty.normal => .78,
    Difficulty.hard => .95,
  };

  /// Multiplier on how fast the computer moves or reacts (1 is a fair rival).
  double get speed => switch (level) {
    Difficulty.easy => .7,
    Difficulty.normal => 1.0,
    Difficulty.hard => 1.3,
  };

  /// How long the computer "thinks" before acting, around [seconds].
  ///
  /// Slower on Easy and quicker on Hard, with a little randomness so it does
  /// not feel mechanical.
  Duration think(Random random, {double seconds = 1.2}) {
    final scaled = seconds / speed * (.75 + .5 * random.nextDouble());
    return Duration(milliseconds: (scaled * 1000).round());
  }

  /// Rolls whether the computer gets this decision right.
  bool succeeds(Random random) => random.nextDouble() < accuracy;
}
