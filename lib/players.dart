import 'package:flutter/material.dart';

const playerColors = [
  Color(0xFF507CFF),
  Color(0xFFFF6F83),
  Color(0xFFFFC16D),
  Color(0xFFA08AFF),
];
/// Joy is a two-player game: every match is one phone, two people.
const playerCount = 2;

int leadingPlayer(List<int> scores, {Iterable<int>? eligible}) {
  final players = (eligible ?? List.generate(scores.length, (i) => i)).toList();
  if (players.isEmpty) return -1;
  var winner = players.first, tied = false;
  for (final p in players.skip(1)) {
    if (scores[p] > scores[winner]) {
      winner = p;
      tied = false;
    } else if (scores[p] == scores[winner]) {
      tied = true;
    }
  }
  return tied ? -1 : winner;
}
