import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:joy/catalog.dart';
import 'package:joy/tutorial_scenes.dart';

void main() {
  test('Every game has a tutorial scene that paints at any moment', () {
    for (var id = 0; id < games.length; id++) {
      for (final t in [0.0, .12, .3, .5, .62, .8, .99]) {
        final recorder = PictureRecorder();
        paintTutorialScene(Canvas(recorder), const Size(340, 220), t, id);
        recorder.endRecording().dispose();
      }
    }
  });

  test('Sumo and Snake are taught with arrows, the rest by drag or tap', () {
    expect(tutorialHint(10), contains('arrow'));
    expect(tutorialHint(12), contains('arrow'));
    expect(tutorialHint(5), contains('drag'));
    expect(tutorialHint(19), contains('tap'));
  });
}
