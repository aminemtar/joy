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
import 'lobby_widgets.dart';
import 'party_data.dart';
import 'party_screens.dart';
import 'tutorial.dart';
import 'result_share.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PartyData.instance.initialize();
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
    theme: JoyTheme.dark,
    builder:
        (context, child) => ListenableBuilder(
          listenable: PartyData.instance,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                disableAnimations:
                    media.disableAnimations || PartyData.instance.reducedMotion,
                textScaler: TextScaler.linear(
                  max(
                    media.textScaler.scale(1),
                    PartyData.instance.largeText ? 1.15 : 1.0,
                  ),
                ),
              ),
              child: child!,
            );
          },
        ),
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
  String category = 'All', libraryFilter = 'All games';
  String search = '';
  bool practice = false;
  final data = PartyData.instance;
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
    await data.initialize();
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

  Future<void> _partyBuilder() async {
    final plan = await Navigator.of(context).push<PartyPlan>(
      MaterialPageRoute(builder: (_) => PartyBuilder(players: playerCount)),
    );
    if (plan == null || !mounted) return;
    setState(() {
      playerCount = plan.players;
      practice = false;
    });
    await _save();
    if (!mounted) return;
    await _play(partyPlaylist(plan.categories, plan.rounds));
  }

  Future<void> _play(List<int> playlist) async {
    if (busy || playlist.isEmpty) return;
    busy = true;
    final queue = List<int>.of(playlist);
    final solo = practice;
    final participants =
        solo ? [names[0], 'Computer'] : names.take(playerCount).toList();
    final points = List.filled(participants.length, 0);
    final completed = <MatchRecord>[];
    JoySounds.instance.play(SoundEffect.tap);
    unawaited(JoyMusic.instance.resume());
    Future<void> accept(MatchRecord record, {bool persist = true}) async {
      completed.add(record);
      if (record.winner >= 0) {
        points[record.winner]++;
        if (!solo || record.winner == 0) wins[record.winner]++;
      }
      if (persist) await data.record(record);
      await _save();
      if (mounted) setState(() {});
    }

    try {
      for (var round = 0; round < queue.length; round++) {
        final id = queue[round];
        if (!mounted) break;
        if (solo && !practiceGames.contains(id)) continue;
        await data.opened(id);
        if (!mounted) break;
        final league = participants.length > 2 && !supportsGroupTurns(id);
        final started = DateTime.now();
        final winner = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder:
                (_) =>
                    league
                        ? PartyLeagueScreen(
                          gameId: id,
                          names: participants,
                          duelBuilder:
                              (pair) => MatchScreen(
                                id: id,
                                names: pair,
                                haptics: haptics,
                                allowRematch: false,
                              ),
                        )
                        : MatchScreen(
                          id: id,
                          names: participants,
                          haptics: haptics,
                          computer: solo,
                          onResult: (r) => accept(r),
                          onNextGame:
                              playlist.length == 1
                                  ? () {
                                    final pool =
                                        solo
                                            ? practiceGames.toList()
                                            : List.generate(
                                              games.length,
                                              (i) => i,
                                            );
                                    pool.remove(id);
                                    queue.add(
                                      pool[Random().nextInt(pool.length)],
                                    );
                                  }
                                  : null,
                        ),
          ),
        );
        if (winner == null) break;
        if (league) {
          await accept(
            MatchRecord(
              game: id,
              names: List.of(participants),
              winner: winner,
              seconds: DateTime.now().difference(started).inSeconds,
              date: DateTime.now(),
            ),
            persist: false,
          );
        }
      }
    } finally {
      busy = false;
    }
    if (completed.isNotEmpty &&
        (playlist.length > 1 || completed.length > 1) &&
        mounted) {
      JoySounds.instance.celebrate(leadingPlayer(points));
      final awards = partyAwards(completed, participants);
      bool sharing = false;
      await showDialog<void>(
        context: context,
        builder:
            (c) => StatefulBuilder(
              builder:
                  (c, update) => AlertDialog(
                    title: const Text('Party results'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < participants.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                '${participants[i]} • ${points[i]} wins\n${awards[i] ?? ''}',
                                style: const TextStyle(height: 1.5),
                              ),
                            ),
                          Text(
                            '${completed.length} completed matches',
                            style: const TextStyle(color: JoyTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton.icon(
                        onPressed:
                            sharing
                                ? null
                                : () async {
                                  update(() => sharing = true);
                                  final message = await shareScorecard(
                                    'Party results',
                                    participants,
                                    points,
                                    awards: awards,
                                  );
                                  if (c.mounted) {
                                    update(() => sharing = false);
                                    ScaffoldMessenger.of(c).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  }
                                },
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Share scorecard'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
            ),
      );
      JoySounds.instance.stop();
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
                        for (var i = 0; i < playerCount; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${names[i]} avatar',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownButton<int>(
                                  value: data.avatars[i],
                                  items: [
                                    for (
                                      var a = 0;
                                      a < profileAvatars.length;
                                      a++
                                    )
                                      DropdownMenuItem(
                                        value: a,
                                        child: Text(profileAvatars[a]),
                                      ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      update(() => data.avatars[i] = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        SwitchListTile(
                          title: const Text('Reduced motion'),
                          subtitle: const Text(
                            'Simpler transitions and static tutorials',
                          ),
                          value: data.reducedMotion,
                          onChanged: (v) {
                            update(() => data.reducedMotion = v);
                            data.saveOptions();
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Larger text'),
                          value: data.largeText,
                          onChanged: (v) {
                            update(() => data.largeText = v);
                            data.saveOptions();
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Player symbols'),
                          subtitle: const Text(
                            'P1–P4 labels and distinct board symbols',
                          ),
                          value: data.colorSymbols,
                          onChanged: (v) {
                            update(() => data.colorSymbols = v);
                            data.saveOptions();
                          },
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
                            data.saveOptions();
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
    final g = games[widget.id];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          remaining > 0 && started ? '${g.name} • ${remaining}s' : g.name,
        ),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: GameArt(id: widget.id, size: 160),
                          ),
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
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: JoyPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF91ACFF),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'How to play',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
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
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.5,
                                  color: JoyTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${widget.names.length} players • Shared screen • Offline',
                        style: TextStyle(color: JoyTheme.muted),
                      ),
                      const SizedBox(height: 20),
                      if (adjustableGames.contains(widget.id) ||
                          widget.computer && widget.id != 29)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            for (final level in Difficulty.values)
                              ChoiceChip(
                                label: Text(
                                  level.name[0].toUpperCase() +
                                      level.name.substring(1),
                                ),
                                selected: difficulty == level,
                                onSelected: (_) {
                                  setState(() => difficulty = level);
                                  PartyData.instance.difficulty = level;
                                  PartyData.instance.saveOptions();
                                },
                              ),
                          ],
                        ),
                      if (adjustableGames.contains(widget.id) ||
                          widget.computer && widget.id != 29)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            widget.id == 5
                                ? 'Changes ball speed and computer reaction speed.'
                                : widget.id == 23
                                ? 'Changes pattern length and flash speed.'
                                : widget.id == 24
                                ? 'Changes cup shuffle speed.'
                                : widget.id == 26
                                ? 'Changes the arithmetic number range.'
                                : 'Changes computer move strength.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: JoyTheme.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (timedGames.contains(widget.id))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: DropdownButton<int>(
                            value: roundSeconds,
                            items: [
                              for (final seconds in [0, 60, 120, 180])
                                DropdownMenuItem(
                                  value: seconds,
                                  child: Text(
                                    seconds == 0
                                        ? 'Untimed round'
                                        : '$seconds-second round',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => roundSeconds = value);
                                PartyData.instance.roundSeconds = value;
                                PartyData.instance.saveOptions();
                              }
                            },
                          ),
                        ),
                      TextButton.icon(
                        onPressed: tutorial,
                        icon: const Icon(Icons.touch_app_rounded),
                        label: const Text('Watch tutorial'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Let’s play'),
                      ),
                    ],
                  ),
                ),
              )
              : Container(
                padding: const EdgeInsets.fromLTRB(9, 1.5, 9, 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF74CEFF),
                      Color(0xFF168BFF),
                      Color(0xFF0754D6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55397BFF),
                      blurRadius: 25,
                      spreadRadius: 1,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Theme(
                    data: JoyTheme.arena,
                    child: ColoredBox(
                      color: JoyTheme.accent,
                      child:
                          done
                              ? const Center(
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  size: 80,
                                  color: Color(0xFFFFC16D),
                                ),
                              )
                              : MatchOptions(
                                difficulty: difficulty,
                                computer: widget.computer,
                                onScores: (scores) {
                                  if (mounted && !done) {
                                    liveScores = List.of(scores);
                                  }
                                },
                                onPause: (paused) {
                                  clockPaused = paused;
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(attempt),
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
                ),
              ),
    );
  }
}
