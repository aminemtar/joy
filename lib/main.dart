import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'game_factory.dart';
import 'game_art.dart';

void main() => runApp(const JoyApp());
const blue = Color(0xFF507CFF), coral = Color(0xFFFF6F83);

class JoyApp extends StatelessWidget {
  const JoyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'JOY',
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1128),
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const Lobby(),
  );
}

class Lobby extends StatefulWidget {
  const Lobby({super.key});
  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  String category = 'All';
  final names = ['Blue', 'Coral'];
  final wins = [0, 0];
  bool haptics = true;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < 2; i++) {
        names[i] = p.getString('name$i') ?? names[i];
        wins[i] = p.getInt('wins$i') ?? 0;
      }
      haptics = p.getBool('haptics') ?? true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    for (var i = 0; i < 2; i++) {
      await p.setString('name$i', names[i]);
      await p.setInt('wins$i', wins[i]);
    }
    await p.setBool('haptics', haptics);
  }

  Future<void> _play(List<int> queue) async {
    if (busy) return;
    busy = true;
    final points = [0, 0];
    for (final id in queue) {
      if (!mounted) break;
      final winner = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder:
              (_) =>
                  MatchScreen(id: id, names: List.of(names), haptics: haptics),
        ),
      );
      if (winner == null) break;
      if (winner >= 0) {
        points[winner]++;
        wins[winner]++;
        await _save();
      }
      if (mounted) setState(() {});
    }
    busy = false;
    if (queue.length > 1 && mounted) {
      showDialog<void>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Tournament results'),
              content: Text(
                '${names[0]}  ${points[0]} — ${points[1]}  ${names[1]}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Done'),
                ),
              ],
            ),
      );
    }
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, update) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + MediaQuery.viewInsetsOf(c).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Make it your party',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      for (var i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextFormField(
                            initialValue: names[i],
                            maxLength: 16,
                            decoration: InputDecoration(
                              labelText: 'Player ${i + 1}',
                            ),
                            onChanged: (v) {
                              names[i] =
                                  v.trim().isEmpty
                                      ? 'Player ${i + 1}'
                                      : v.trim();
                            },
                          ),
                        ),
                      SwitchListTile(
                        title: const Text('Vibration'),
                        value: haptics,
                        onChanged: (v) => update(() => haptics = v),
                      ),
                      FilledButton(
                        onPressed: () {
                          _save();
                          setState(() {});
                          Navigator.pop(c);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        games
            .asMap()
            .entries
            .where((e) => category == 'All' || e.value.category == category)
            .toList();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/art/app_icon.png',
                            width: 44,
                            height: 44,
                            cacheWidth: 128,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'JOY',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _settings,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      'Small games. Big rivalries.',
                      style: TextStyle(color: Colors.white60, fontSize: 17),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF375DE0), Color(0xFF233678)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ONE SCREEN. TWO RIVALS.',
                            style: TextStyle(letterSpacing: 2, fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Your next\nparty starts here.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '36 different games • Offline • Two rivals',
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed:
                                    () =>
                                        _play([Random().nextInt(games.length)]),
                                icon: const Icon(Icons.shuffle),
                                label: const Text('Surprise me'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  final q = List.generate(
                                    games.length,
                                    (i) => i,
                                  )..shuffle();
                                  _play(q.take(5).toList());
                                },
                                child: const Text('5-round cup'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${names[0]}  •  ${wins[0]} wins',
                            style: const TextStyle(color: blue),
                          ),
                        ),
                        Text(
                          '${names[1]}  •  ${wins[1]} wins',
                          style: const TextStyle(color: coral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in [
                            'All',
                            'Cars',
                            'Sports',
                            'Arena',
                            'Puzzles',
                            'Memory',
                            'Brain',
                            'Words',
                            'Strategy',
                            'Arcade',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: category == c,
                                onSelected: (_) => setState(() => category = c),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverLayoutBuilder(
                builder:
                    (c, constraints) => SliverGrid(
                      delegate: SliverChildBuilderDelegate((c, i) {
                        final entry = filtered[i];
                        final g = entry.value;
                        return Card(
                          color: const Color(0xFF111C37),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _play([entry.key]),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'game-${entry.key}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: GameArt(id: entry.key, size: 110),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    g.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    g.category,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: filtered.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: max(
                          2,
                          (constraints.crossAxisExtent / 220).floor(),
                        ),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 240,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchScreen extends StatefulWidget {
  final int id;
  final List<String> names;
  final bool haptics;
  const MatchScreen({
    super.key,
    required this.id,
    required this.names,
    required this.haptics,
  });
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  bool started = false, done = false;
  void finish(int winner) {
    if (done || !mounted) return;
    done = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (c) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(
                winner < 0
                    ? 'A perfect draw!'
                    : '${widget.names[winner]} wins!',
              ),
              content: const Text('Ready for another rivalry?'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(c);
                    Navigator.pop(context, winner);
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = games[widget.id];
    return Scaffold(
      appBar: AppBar(title: Text(g.name)),
      body:
          !started
              ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'game-${widget.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: GameArt(id: widget.id, size: 200),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        g.rules,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Two players • Shared screen • Offline',
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () => setState(() => started = true),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Let’s play'),
                      ),
                    ],
                  ),
                ),
              )
              : buildGame(
                id: widget.id,
                names: widget.names,
                onFinish: finish,
                haptics: widget.haptics,
              ),
    );
  }
}
