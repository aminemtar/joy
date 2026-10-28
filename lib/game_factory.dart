import 'package:flutter/material.dart';
import 'catalog.dart';
import 'games/action.dart';
import 'games/arcade.dart';
import 'games/brain.dart';
import 'games/observation.dart';
import 'games/puzzle.dart';
import 'games/strategy.dart';
import 'games/words.dart';

/// Shared by navigation and the catalog smoke tests, so new entries cannot
/// accidentally fall through to an unrelated numeric-ID engine.
Widget buildGame({
  required int id,
  required List<String> names,
  required ValueChanged<int> onFinish,
  bool haptics = false,
}) => switch (games[id].family) {
  Family.action => ActionGame(
    id: id,
    names: names,
    onFinish: onFinish,
    haptics: haptics,
  ),
  Family.arcade => ArcadeGame(id: id, names: names, onFinish: onFinish),
  Family.brain => BrainGame(id: id, names: names, onFinish: onFinish),
  Family.observation => ObservationGame(
    id: id,
    names: names,
    onFinish: onFinish,
  ),
  Family.puzzle => PuzzleGame(id: id, names: names, onFinish: onFinish),
  Family.strategy => StrategyGame(id: id, names: names, onFinish: onFinish),
  Family.words => WordsGame(id: id, names: names, onFinish: onFinish),
};
