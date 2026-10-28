import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog.dart';

enum Difficulty { easy, normal, hard }

const practiceGames = {5, 18, 19, 29};
const adjustableGames = {5, 23, 24, 26};
const timedGames = {0, 2, 5, 6, 8, 20, 21, 22, 25, 26, 27, 28, 30};
const profileAvatars = ['⚡', '🚀', '⭐', '🎮', '🦊', '🐼', '👑', '🔥'];

class MatchRecord {
  final int game, winner, seconds;
  final List<String> names;
  final DateTime date;
  final bool practice;
  MatchRecord({
    required this.game,
    required this.names,
    required this.winner,
    required this.seconds,
    required this.date,
    this.practice = false,
  });
  Map<String, dynamic> toJson() => {
    'game': game,
    'names': names,
    'winner': winner,
    'seconds': seconds,
    'date': date.toIso8601String(),
    'practice': practice,
  };
  static MatchRecord? parse(dynamic value) {
    try {
      final m = value as Map<String, dynamic>;
      final game = m['game'] as int, winner = m['winner'] as int;
      final names = (m['names'] as List).cast<String>();
      if (game < 0 ||
          game >= games.length ||
          names.length < 2 ||
          names.length > 4 ||
          winner < -1 ||
          winner >= names.length) {
        return null;
      }
      return MatchRecord(
        game: game,
        names: names,
        winner: winner,
        seconds: (m['seconds'] as int).clamp(0, 86400),
        date: DateTime.parse(m['date'] as String),
        practice: m['practice'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

class PartyData extends ChangeNotifier {
  static final instance = PartyData();
  SharedPreferences? _prefs;
  Future<void>? _loading;
  bool _ready = false;
  final favorites = <int>{}, seen = <int>{};
  final recent = <int>[];
  final history = <MatchRecord>[];
  final avatars = [0, 1, 2, 3];
  bool reducedMotion = false, largeText = false, colorSymbols = false;
  Difficulty difficulty = Difficulty.normal;
  int roundSeconds = 0;
  Future<void> initialize() => _ready ? Future.value() : (_loading ??= _load());
  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    List<int> ids(String key) =>
        (_prefs!.getStringList(key) ?? [])
            .map(int.tryParse)
            .whereType<int>()
            .where((i) => i >= 0 && i < games.length)
            .toSet()
            .toList();
    favorites.addAll(ids('favorites'));
    seen.addAll(ids('tutorialsSeen'));
    recent.addAll(ids('recentGames').take(8));
    for (final raw in _prefs!.getStringList('matchHistory') ?? []) {
      try {
        final record = MatchRecord.parse(jsonDecode(raw));
        if (record != null) history.add(record);
      } catch (_) {}
    }
    if (history.length > 100) history.removeRange(100, history.length);
    for (var i = 0; i < 4; i++) {
      avatars[i] = (_prefs!.getInt('avatar$i') ?? i).clamp(
        0,
        profileAvatars.length - 1,
      );
    }
    reducedMotion = _prefs!.getBool('reduceMotion') ?? false;
    largeText = _prefs!.getBool('largeText') ?? false;
    colorSymbols = _prefs!.getBool('playerSymbols') ?? false;
    difficulty =
        Difficulty.values[(_prefs!.getInt('difficulty') ?? 1).clamp(0, 2)];
    final duration = _prefs!.getInt('roundSeconds') ?? 0;
    roundSeconds = [0, 60, 120, 180].contains(duration) ? duration : 0;
    _ready = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(int id) async {
    await initialize();
    if (!favorites.remove(id)) favorites.add(id);
    notifyListeners();
    await _prefs!.setStringList(
      'favorites',
      favorites.map((i) => '$i').toList(),
    );
  }

  Future<void> opened(int id) async {
    await initialize();
    recent.remove(id);
    recent.insert(0, id);
    if (recent.length > 8) recent.removeLast();
    notifyListeners();
    await _prefs!.setStringList(
      'recentGames',
      recent.map((i) => '$i').toList(),
    );
  }

  Future<void> tutorialSeen(int id) async {
    await initialize();
    seen.add(id);
    await _prefs!.setStringList(
      'tutorialsSeen',
      seen.map((i) => '$i').toList(),
    );
  }

  Future<void> record(MatchRecord result) async {
    await initialize();
    history.insert(0, result);
    if (history.length > 100) history.removeLast();
    notifyListeners();
    await _prefs!.setStringList(
      'matchHistory',
      history.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> saveOptions() async {
    await initialize();
    notifyListeners();
    await _prefs!.setBool('reduceMotion', reducedMotion);
    await _prefs!.setBool('largeText', largeText);
    await _prefs!.setBool('playerSymbols', colorSymbols);
    await _prefs!.setInt('difficulty', difficulty.index);
    await _prefs!.setInt('roundSeconds', roundSeconds);
    for (var i = 0; i < 4; i++) {
      await _prefs!.setInt('avatar$i', avatars[i]);
    }
  }
}

List<int> partyPlaylist(Set<String> categories, int rounds, {Random? random}) {
  final available = [
    for (var i = 0; i < games.length; i++)
      if (categories.contains(games[i].category)) i,
  ]..shuffle(random);
  if (available.isEmpty) return [];
  // A session never repeats a concept, even when the chosen category is small.
  return available.take(rounds.clamp(1, games.length)).toList();
}

Map<int, String> partyAwards(List<MatchRecord> matches, List<String> players) {
  final awards = <int, String>{};
  if (matches.isEmpty) return awards;
  final wins = List.filled(players.length, 0);
  for (final m in matches) {
    if (m.winner >= 0) {
      final p =
          (listEquals(m.names, players)
              ? m.winner
              : players.indexOf(m.names[m.winner]));
      if (p >= 0) wins[p]++;
    }
  }
  final most = wins.reduce(max);
  for (var p = 0; p < players.length; p++) {
    if (wins[p] == most && most > 0) awards[p] = 'Party champion';
  }
  for (final entry
      in <String, Set<int>>{
        'Fastest fingers': {27},
        'Memory master': {20, 23, 24},
        'Word wizard': {28, 30, 31},
        'Arena ace': {5, 6, 10, 11, 12, 13},
      }.entries) {
    final counts = List.filled(players.length, 0);
    for (final m in matches) {
      if (entry.value.contains(m.game) && m.winner >= 0) {
        final p =
            (listEquals(m.names, players)
                ? m.winner
                : players.indexOf(m.names[m.winner]));
        if (p >= 0) counts[p]++;
      }
    }
    final high = counts.reduce(max);
    if (high > 0) {
      for (var p = 0; p < players.length; p++) {
        if (counts[p] == high && !awards.containsKey(p)) awards[p] = entry.key;
      }
    }
  }
  for (var p = 0; p < players.length; p++) {
    awards.putIfAbsent(
      p,
      () => wins[p] > 0 ? 'Comeback contender' : 'Rematch ready',
    );
  }
  return awards;
}

class MatchOptions extends InheritedWidget {
  final Difficulty difficulty;
  final bool computer;
  final ValueChanged<List<int>>? onScores;
  final ValueChanged<bool>? onPause;
  const MatchOptions({
    super.key,
    required super.child,
    this.difficulty = Difficulty.normal,
    this.computer = false,
    this.onScores,
    this.onPause,
  });
  static MatchOptions? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MatchOptions>();
  static MatchOptions? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchOptions>();
  @override
  bool updateShouldNotify(MatchOptions old) =>
      difficulty != old.difficulty || computer != old.computer;
}
