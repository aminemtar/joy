import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'game_factory.dart';
import 'game_art.dart';
import 'sound.dart';
import 'music.dart';
import 'splash.dart';
import 'players.dart';
import 'party_league.dart';
import 'joy_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JoySounds.instance.initialize();
  await JoyMusic.instance.initialize();
  unawaited(JoyMusic.instance.resume());
  runApp(const JoyApp());
}

const blue = Color(0xFF507CFF), coral = Color(0xFFFF6F83);

class JoyApp extends StatefulWidget {
  const JoyApp({super.key});
  @override
  State<JoyApp> createState() => _JoyAppState();
}

class _JoyAppState extends State<JoyApp> {
  bool splash = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'JOY',
    theme: JoyTheme.light,
    home: AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child:
          splash
              ? JoySplash(
                key: const ValueKey('splash'),
                onFinished: () {
                  unawaited(JoyMusic.instance.resume());
                  setState(() => splash = false);
                },
              )
              : const Lobby(key: ValueKey('lobby')),
    ),
  );
}

class Lobby extends StatefulWidget {
  const Lobby({super.key});
  @override
  State<Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<Lobby> {
  String category = 'All';
  final names = ['Blue', 'Coral', 'Amber', 'Violet'];
  int playerCount = 2;
  final wins = [0, 0, 0, 0];
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
      for (var i = 0; i < 4; i++) {
        names[i] = p.getString('name$i') ?? names[i];
        wins[i] = p.getInt('wins$i') ?? 0;
      }
      playerCount = (p.getInt('playerCount') ?? 2).clamp(2, 4);
      haptics = p.getBool('haptics') ?? true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    for (var i = 0; i < 4; i++) {
      await p.setString('name$i', names[i]);
      await p.setInt('wins$i', wins[i]);
    }
    await p.setInt('playerCount', playerCount);
    await p.setBool('haptics', haptics);
  }

  Future<void> _play(List<int> queue) async {
    if (busy) return;
    busy = true;
    JoySounds.instance.play(SoundEffect.tap);
    final participants = names.take(playerCount).toList();
    final points = List.filled(playerCount, 0);
    unawaited(JoyMusic.instance.resume());
    for (final id in queue) {
      if (!mounted) break;
      final winner = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder:
              (_) =>
                  participants.length > 2 && !supportsGroupTurns(id)
                      ? PartyLeagueScreen(
                        gameId: id,
                        names: participants,
                        duelBuilder:
                            (pair) => MatchScreen(
                              id: id,
                              names: pair,
                              haptics: haptics,
                            ),
                      )
                      : MatchScreen(
                        id: id,
                        names: participants,
                        haptics: haptics,
                      ),
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
      JoySounds.instance.celebrate(leadingPlayer(points));
      showDialog<void>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Tournament results'),
              content: Text(
                [
                  for (var i = 0; i < participants.length; i++)
                    '${participants[i]}: ${points[i]}',
                ].join('\n'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(c);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
      ).whenComplete(JoySounds.instance.stop);
    }
  }

  void _settings() {
    bool testingSound = false, testFailed = false;
    String? soundTestResult;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, update) => SingleChildScrollView(
                  child: Padding(
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
                        for (var i = 0; i < playerCount; i++)
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
                        ListenableBuilder(
                          listenable: JoyMusic.instance,
                          builder:
                              (c, child) => Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Background music'),
                                    subtitle: const Text(
                                      'Original arcade loop',
                                    ),
                                    value: JoyMusic.instance.enabled,
                                    onChanged:
                                        (v) => JoyMusic.instance.setEnabled(v),
                                  ),
                                  Slider(
                                    value: JoyMusic.instance.volume,
                                    label:
                                        'Music ${(JoyMusic.instance.volume * 100).round()}%',
                                    onChanged:
                                        JoyMusic.instance.enabled
                                            ? (v) =>
                                                JoyMusic.instance.setVolume(v)
                                            : null,
                                  ),
                                  if (JoyMusic.instance.error != null)
                                    Text(
                                      JoyMusic.instance.error!,
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                ],
                              ),
                        ),
                        SwitchListTile(
                          title: const Text('Sound effects'),
                          subtitle: const Text(
                            'Play actions and victory celebrations',
                          ),
                          value: JoySounds.instance.enabled,
                          onChanged: (value) {
                            JoySounds.instance.setEnabled(value);
                            update(() {});
                          },
                        ),
                        Row(
                          children: [
                            const Icon(Icons.volume_down_rounded),
                            Expanded(
                              child: Slider(
                                label:
                                    '${(JoySounds.instance.volume * 100).round()}%',
                                value: JoySounds.instance.volume,
                                onChanged:
                                    JoySounds.instance.enabled
                                        ? (v) {
                                          JoySounds.instance.setVolume(v);
                                          update(() {});
                                        }
                                        : null,
                                onChangeEnd:
                                    (_) => JoySounds.instance.play(
                                      SoundEffect.tap,
                                    ),
                              ),
                            ),
                            const Icon(Icons.volume_up_rounded),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(testingSound ? 'Testing…' : 'Test sound'),
                          onPressed:
                              testingSound
                                  ? null
                                  : () async {
                                    update(() {
                                      testingSound = true;
                                      soundTestResult = null;
                                    });
                                    final error =
                                        await JoySounds.instance.testSound();
                                    if (!c.mounted) return;
                                    update(() {
                                      testingSound = false;
                                      testFailed = error != null;
                                      soundTestResult =
                                          error ??
                                          'Playing test sound. If silent, raise Media volume and check headphones or Bluetooth output.';
                                    });
                                  },
                        ),
                        ListenableBuilder(
                          listenable: JoySounds.instance,
                          builder: (c, child) {
                            final status =
                                JoySounds.instance.lastError ?? soundTestResult;
                            return status == null
                                ? const SizedBox()
                                : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color:
                                          JoySounds.instance.lastError !=
                                                      null ||
                                                  testFailed
                                              ? Colors.orangeAccent
                                              : JoyTheme.muted,
                                    ),
                                  ),
                                );
                          },
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
                        ListenableBuilder(
                          listenable: JoySounds.instance,
                          builder:
                              (context, child) => IconButton(
                                tooltip:
                                    JoySounds.instance.enabled
                                        ? 'Mute sound effects'
                                        : 'Enable sound effects',
                                onPressed:
                                    () => JoySounds.instance.setEnabled(
                                      !JoySounds.instance.enabled,
                                    ),
                                icon: Icon(
                                  JoySounds.instance.enabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                ),
                              ),
                        ),
                        IconButton(
                          onPressed: _settings,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      'A little play. A lot of happy.',
                      style: TextStyle(color: JoyTheme.muted, fontSize: 17),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE69A), Color(0xFFFFD6B6)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFFFD18B)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10C99137),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GOOD TIMES, TOGETHER',
                            style: TextStyle(letterSpacing: 2, fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'More laughs.\nMore rematches.',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('36 games • Offline • 2–4 players'),
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
                    const Text(
                      'BRING YOUR PEOPLE',
                      style: TextStyle(color: JoyTheme.muted, letterSpacing: 2),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2 players')),
                        ButtonSegment(value: 3, label: Text('3 players')),
                        ButtonSegment(value: 4, label: Text('4 players')),
                      ],
                      selected: {playerCount},
                      onSelectionChanged: (v) {
                        setState(() => playerCount = v.single);
                        _save();
                      },
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < playerCount; i++)
                          Text(
                            '${names[i]} • ${wins[i]} wins',
                            style: TextStyle(
                              color:
                                  [
                                    Color(0xFF3659C8),
                                    Color(0xFFBF405B),
                                    Color(0xFF986000),
                                    Color(0xFF7350B5),
                                  ][i],
                              fontWeight: FontWeight.w700,
                            ),
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
                                onSelected: (_) {
                                  JoySounds.instance.play(SoundEffect.tap);
                                  setState(() => category = c);
                                },
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
                          color:
                              JoyTheme.pastels[entry.key %
                                  JoyTheme.pastels.length],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0x18000000)),
                          ),
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: GameArt(
                                          id: entry.key,
                                          size: 110,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    g.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: JoyTheme.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    playerCount == 2
                                        ? g.category
                                        : '${playerCount}P ${supportsGroupTurns(entry.key) ? 'shared turns' : 'league'}',
                                    style: const TextStyle(
                                      color: JoyTheme.muted,
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
                        mainAxisExtent: 250,
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
  @override
  void dispose() {
    JoySounds.instance.stop();
    super.dispose();
  }

  void finish(int winner) {
    if (done || !mounted) return;
    done = true;
    JoySounds.instance.celebrate(winner);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (c) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(
                winner < 0 ? 'Match tied!' : '${widget.names[winner]} wins!',
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
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          ListenableBuilder(
            listenable: JoySounds.instance,
            builder:
                (context, child) => IconButton(
                  tooltip:
                      JoySounds.instance.enabled
                          ? 'Mute sound effects'
                          : 'Enable sound effects',
                  onPressed:
                      () => JoySounds.instance.setEnabled(
                        !JoySounds.instance.enabled,
                      ),
                  icon: Icon(
                    JoySounds.instance.enabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                  ),
                ),
          ),
        ],
      ),
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < widget.names.length; i++)
                            Chip(
                              label: Text(widget.names[i]),
                              avatar: CircleAvatar(
                                backgroundColor: playerColors[i],
                                radius: 8,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.id == 27 && widget.names.length > 2
                            ? 'Tap your own pad after NOW. An early tap loses one point. First to five wins.'
                            : widget.id == 23
                            ? 'Repeat the entire pattern. Four rounds per player; longest-memory score wins.'
                            : g.rules,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.names.length} players • Shared screen • Offline',
                        style: TextStyle(color: JoyTheme.muted),
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () {
                          JoySounds.instance.play(
                            [Family.action, Family.arcade].contains(g.family)
                                ? SoundEffect.tap
                                : SoundEffect.start,
                          );
                          setState(() => started = true);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Let’s play'),
                      ),
                    ],
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Theme(
                    data: JoyTheme.arena,
                    child: ColoredBox(
                      color: const Color(0xFF161C36),
                      child: buildGame(
                        id: widget.id,
                        names: widget.names,
                        onFinish: finish,
                        haptics: widget.haptics,
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
