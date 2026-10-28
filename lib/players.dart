import 'package:flutter/material.dart';

const playerColors = [
  Color(0xFF507CFF),
  Color(0xFFFF6F83),
  Color(0xFFFFC16D),
  Color(0xFFA08AFF),
];
const groupTurnGames = {
  1,
  15,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  30,
  31,
  32,
  34,
  35,
};
bool supportsGroupTurns(int id) => groupTurnGames.contains(id);
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

class LeagueFixture {
  final int first, second;
  const LeagueFixture(this.first, this.second);
}

class PartyLeague {
  final int players;
  final _recorded = <int>{};
  late final List<int> points;
  late final List<LeagueFixture> fixtures;
  PartyLeague(this.players) {
    if (players < 2 || players > 4) throw ArgumentError('Choose 2–4 players');
    points = List.filled(players, 0);
    fixtures = [
      for (var a = 0; a < players; a++)
        for (var b = a + 1; b < players; b++) LeagueFixture(a, b),
    ];
  }
  void record(int fixture, int winner) {
    if (fixture < 0 ||
        fixture >= fixtures.length ||
        winner < -1 ||
        winner > 1) {
      throw ArgumentError('Invalid league result');
    }
    if (!_recorded.add(fixture)) throw StateError('Fixture already recorded');
    final pair = fixtures[fixture];
    if (winner < 0) {
      points[pair.first]++;
      points[pair.second]++;
    } else {
      points[winner == 0 ? pair.first : pair.second] += 3;
    }
  }

  int get winner => leadingPlayer(points);
}
