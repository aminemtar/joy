import 'package:flutter_test/flutter_test.dart';
import 'package:joy/games/tuning.dart';
import 'package:joy/party_data.dart';

void main() {
  test('The rally boost grows with each hit and stops at the cap', () {
    expect(FieldTuning.rallyBoost(0), 1);
    for (var rally = 1; rally < 40; rally++) {
      expect(
        FieldTuning.rallyBoost(rally),
        greaterThanOrEqualTo(FieldTuning.rallyBoost(rally - 1)),
      );
    }
    expect(FieldTuning.rallyBoost(1000), FieldTuning.rallyCap);
  });

  test('Ping Pong stays reactable: crossing takes over half a second', () {
    for (final level in Difficulty.values) {
      expect(
        FieldTuning.crossingSeconds(level, 1000),
        greaterThan(.5),
        reason: '$level at the longest rally',
      );
    }
  });

  test('Difficulty orders ball and computer speed', () {
    expect(
      FieldTuning.ballSpeed(Difficulty.easy),
      lessThan(FieldTuning.ballSpeed(Difficulty.normal)),
    );
    expect(
      FieldTuning.ballSpeed(Difficulty.normal),
      lessThan(FieldTuning.ballSpeed(Difficulty.hard)),
    );
    expect(
      FieldTuning.botSpeed(Difficulty.easy),
      lessThan(FieldTuning.botSpeed(Difficulty.normal)),
    );
    expect(
      FieldTuning.botSpeed(Difficulty.normal),
      lessThan(FieldTuning.botSpeed(Difficulty.hard)),
    );
  });

  test('Air Hockey strikers are quicker than the puck they chase', () {
    expect(FieldTuning.hockeyFollow, greaterThan(.7));
  });

  test('The Sumo ring holds, then closes in, then stops shrinking', () {
    expect(FieldTuning.sumoRadius(0), .43);
    expect(FieldTuning.sumoRadius(FieldTuning.sumoShrinkStart), .43);
    expect(
      FieldTuning.sumoRadius(FieldTuning.sumoShrinkStart + 4),
      lessThan(.43),
    );
    expect(
      FieldTuning.sumoRadius(600),
      closeTo(.43 - FieldTuning.sumoShrinkMax, 1e-9),
    );
  });
}
