import 'dart:math';

import '../party_data.dart';

/// Balance knobs for the field games (Ping Pong and Air Hockey).
///
/// Everything that decides how the rally feels lives here, so it can be
/// adjusted after playing on a real device without touching the game loop.
/// All distances are in the normalized arena (the full court is 1 × 1).
abstract final class FieldTuning {
  /// Vertical ball speed right after a paddle hit, before the rally boost.
  static const hitSpeed = .55;

  /// Distance between the two Ping Pong paddle lines.
  static const courtLength = .74;

  /// Each paddle hit in a rally adds this fraction of [hitSpeed].
  static const rallyStep = .04;

  /// The rally boost never exceeds this multiple of [hitSpeed].
  static const rallyCap = 1.4;

  /// Seconds the ball waits at the centre after a point.
  static const serveDelay = .7;

  /// How fast a held finger drags a striker or tank, per second.
  static const defaultFollow = .65;

  /// Air Hockey strikers follow faster: the puck moves at .7 per second.
  static const hockeyFollow = 1.2;

  /// Multiplier on [hitSpeed] for the current rally length.
  static double rallyBoost(int rally) => min(rallyCap, 1 + rally * rallyStep);

  /// Ball speed multiplier of a difficulty.
  static double ballSpeed(Difficulty level) => switch (level) {
    Difficulty.easy => .8,
    Difficulty.normal => 1.0,
    Difficulty.hard => 1.25,
  };

  /// Horizontal speed of the computer paddle, per second.
  static double botSpeed(Difficulty level) => switch (level) {
    Difficulty.easy => .30,
    Difficulty.normal => .48,
    Difficulty.hard => .80,
  };

  /// Seconds the ball needs to cross the court at a given rally length.
  static double crossingSeconds(Difficulty level, int rally) =>
      courtLength / (hitSpeed * rallyBoost(rally) * ballSpeed(level));
}
