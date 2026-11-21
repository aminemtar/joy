import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';
import 'game_factory.dart';
import 'game_art.dart';
import 'games/juice.dart' show JoyEffects;
import 'haptics.dart';
import 'sound.dart';
import 'music.dart';
import 'splash.dart';
import 'players.dart';
import 'joy_theme.dart';
import 'lobby_widgets.dart';
import 'party_data.dart';
import 'party_screens.dart';
import 'tutorial.dart';
import 'result_dialog.dart';
import 'result_share.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PartyData.instance.initialize();
  await JoySounds.instance.initialize();
  await JoyMusic.instance.initialize();
  unawaited(JoyMusic.instance.resume());
  runApp(const JoyApp());
}

const blue = JoyTheme.accent, coral = Color(0xFFFF6F83);

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
    await data.initialize();
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < playerCount; i++) {
        names[i] = p.getString('name$i') ?? names[i];
        wins[i] = p.getInt('wins$i') ?? 0;
      }
      haptics = p.getBool('haptics') ?? true;
      JoyHaptics.enabled = haptics;
      JoyEffects.enabled = p.getBool('effects') ?? true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    for (var i = 0; i < playerCount; i++) {
      await p.setString('name$i', names[i]);
      await p.setInt('wins$i', wins[i]);
    }
    await p.setBool('haptics', haptics);
    await p.setBool('effects', JoyEffects.enabled);
  }

  Future<void> _partyBuilder() async {
    final plan = await Navigator.of(context).push<PartyPlan>(
      MaterialPageRoute(builder: (_) => const PartyBuilder()),
    );
    if (plan == null || !mounted) return;
    setState(() => practice = false);
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
        solo ? [names[0], 'Computer'] : List.of(names);
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
        final winner = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder:
                (_) => MatchScreen(
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
                                    : List.generate(games.length, (i) => i);
                            pool.remove(id);
                            queue.add(pool[Random().nextInt(pool.length)]);
                          }
                          : null,
                ),
          ),
        );
        if (winner == null) break;
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
                        label: const Text('Share'),
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
    // The match screen can switch vibration too, so start from the live value.
    haptics = JoyHaptics.enabled;
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
                        const SizedBox(height: 12),
                        for (var i = 0; i < playerCount; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: playerColors[i].withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: playerColors[i].withValues(alpha: .55),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  initialValue: names[i],
                                  maxLength: 16,
                                  decoration: InputDecoration(
                                    labelText: 'Player ${i + 1}',
                                    counterText: '',
                                  ),
                                  onChanged: (v) {
                                    names[i] =
                                        v.trim().isEmpty
                                            ? 'Player ${i + 1}'
                                            : v.trim();
                                  },
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (
                                        var a = 0;
                                        a < profileAvatars.length;
                                        a++
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Semantics(
                                            button: true,
                                            selected: data.avatars[i] == a,
                                            label: 'Avatar ${a + 1}',
                                            excludeSemantics: true,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              onTap:
                                                  () => update(
                                                    () => data.avatars[i] = a,
                                                  ),
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      data.avatars[i] == a
                                                          ? playerColors[i]
                                                              .withValues(
                                                                alpha: .35,
                                                              )
                                                          : JoyTheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color:
                                                        data.avatars[i] == a
                                                            ? playerColors[i]
                                                            : JoyTheme.border,
                                                    width:
                                                        data.avatars[i] == a
                                                            ? 2
                                                            : 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  profileAvatars[a],
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const _SettingsHeading('Accessibility'),
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
                            'P1/P2 labels and distinct board symbols',
                          ),
                          value: data.colorSymbols,
                          onChanged: (v) {
                            update(() => data.colorSymbols = v);
                            data.saveOptions();
                          },
                        ),
                        const _SettingsHeading('Sound'),
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
                        const _SettingsHeading('Feel'),
                        SwitchListTile(
                          title: const Text('Vibration'),
                          value: haptics,
                          onChanged: (v) => update(() {
                            haptics = v;
                            JoyHaptics.enabled = v;
                            // Let the player feel what they just switched on.
                            JoyHaptics.buzz(Buzz.medium);
                          }),
                        ),
                        SwitchListTile(
                          title: const Text('Hit effects'),
                          subtitle: const Text('Sparks, floating points, screen shake'),
                          value: JoyEffects.enabled,
                          onChanged: (v) => update(() => JoyEffects.enabled = v),
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
    final filtered =
        games
            .asMap()
            .entries
            .where(
              (e) =>
                  (category == 'All' || e.value.category == category) &&
                  (!practice || practiceGames.contains(e.key)) &&
                  (libraryFilter != 'Favorites' ||
                      data.favorites.contains(e.key)) &&
                  (libraryFilter != 'Recent' || data.recent.contains(e.key)) &&
                  (search.isEmpty ||
                      e.value.name.toLowerCase().contains(
                        search.toLowerCase(),
                      )),
            )
            .toList();
    if (libraryFilter == 'Recent') {
      filtered.sort(
        (a, b) =>
            data.recent.indexOf(a.key).compareTo(data.recent.indexOf(b.key)),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: RepaintBoundary(child: Column(
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
                      'Small games. Big rivalries.',
                      style: TextStyle(color: JoyTheme.muted, fontSize: 17),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF213D83), Color(0xFF152447)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: JoyTheme.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20507CFF),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THE LOCAL MULTIPLAYER ARCADE',
                            style: TextStyle(letterSpacing: 2, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Pick a game.\nMake it a rivalry.',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              InfoPill(
                                icon: Icons.sports_esports_rounded,
                                label: '36 games',
                              ),
                              InfoPill(
                                icon: Icons.wifi_off_rounded,
                                label: 'Offline',
                              ),
                              InfoPill(
                                icon: Icons.people_alt_rounded,
                                label: '2 players',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed:
                                    () => _play([
                                      practice
                                          ? practiceGames.elementAt(
                                            Random().nextInt(
                                              practiceGames.length,
                                            ),
                                          )
                                          : Random().nextInt(games.length),
                                    ]),
                                icon: const Icon(Icons.shuffle),
                                label: const Text('Surprise me'),
                              ),
                              OutlinedButton(
                                onPressed: practice ? null : _partyBuilder,
                                child: const Text('Party mode'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PartySetup(
                      names: names,
                      wins: wins,
                      avatars: data.avatars,
                      onEdit: _settings,
                    ),
                    const SizedBox(height: 16),
                    JoyPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Computer practice'),
                        subtitle: const Text(
                          'Play any game against the computer',
                        ),
                        value: practice,
                        onChanged:
                            (v) => setState(() {
                              practice = v;
                              category = 'All';
                              libraryFilter = 'All games';
                            }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Match history'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Find your next game',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${filtered.length} games',
                          style: const TextStyle(
                            color: JoyTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search games',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in ['All games', 'Favorites', 'Recent'])
                          ChoiceChip(
                            label: Text(f),
                            selected: libraryFilter == f,
                            onSelected:
                                (_) => setState(() => libraryFilter = f),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                )),
              ),
            ),
            if (filtered.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No games here yet. Try another filter, save a favorite, or play your first game.',
                    style: TextStyle(color: JoyTheme.muted),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              // The column count comes from the screen width, not from a
              // SliverLayoutBuilder: that one rebuilds every grid tile on
              // every scroll frame.
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (c, i) {
                    final id = filtered[i].key;
                    return GameCard(
                      key: ValueKey(id),
                      id: id,
                      favorite: data.favorites.contains(id),
                      onPlay: () => _play([id]),
                      onFavorite: () async {
                        await data.toggleFavorite(id);
                        if (mounted) setState(() {});
                      },
                    );
                  },
                  childCount: filtered.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  addSemanticIndexes: false,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: max(
                    2,
                    ((MediaQuery.sizeOf(context).width - 48) / 220).floor(),
                  ),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent:
                      252 +
                      44 *
                          (MediaQuery.textScalerOf(context).scale(1) - 1)
                              .clamp(0.0, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small section title inside the settings sheet.
class _SettingsHeading extends StatelessWidget {
  final String label;
  const _SettingsHeading(this.label);
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 0, 4),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: JoyTheme.muted,
            fontSize: 13,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class MatchScreen extends StatefulWidget {
  final int id;
  final List<String> names;
  final bool haptics;
  final bool computer, allowRematch;
  final Future<void> Function(MatchRecord)? onResult;
  final VoidCallback? onNextGame;
  const MatchScreen({
    super.key,
    required this.id,
    required this.names,
    required this.haptics,
    this.computer = false,
    this.allowRematch = true,
    this.onResult,
    this.onNextGame,
  });
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with WidgetsBindingObserver {
  bool started = false,
      done = false,
      clockPaused = false,
      backgrounded = false,
      tutorialBusy = false;
  int attempt = 0, elapsed = 0, remaining = 0;
  List<int> liveScores = [];
  Timer? roundTimer;

  /// The running game, built once per attempt. The one-second clock calls
  /// setState; reusing this exact widget stops it from rebuilding the board.
  Widget? game;
  Difficulty difficulty = PartyData.instance.difficulty;
  int roundSeconds = PartyData.instance.roundSeconds;

  /// How many games make a series (1, 3 or 5) and the rounds each player has
  /// won in the series so far.
  int bestOf = 1;
  List<int> series = [0, 0];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    backgrounded = state != AppLifecycleState.resumed;
  }

  Future<void> tutorial() async {
    if (tutorialBusy) return;
    tutorialBusy = true;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GameTutorial(id: widget.id)),
    );
    await PartyData.instance.tutorialSeen(widget.id);
    tutorialBusy = false;
  }

  Future<void> start() async {
    if (tutorialBusy) return;
    if (!PartyData.instance.seen.contains(widget.id)) {
      await tutorial();
    }
    if (!mounted) return;
    JoySounds.instance.play(SoundEffect.start);
    roundTimer?.cancel();
    setState(() {
      started = true;
      done = false;
      attempt++;
      elapsed = 0;
      clockPaused = false;
      liveScores = List.filled(widget.names.length, 0);
      remaining = timedGames.contains(widget.id) ? roundSeconds : 0;
      game = KeyedSubtree(
        key: ValueKey(attempt),
        child: buildGame(
          id: widget.id,
          names: widget.names,
          onFinish: finish,
          haptics: widget.haptics,
        ),
      );
    });
    roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || done || backgrounded || clockPaused) return;
      setState(() {
        elapsed++;
        if (remaining > 0) remaining--;
      });
      if (roundSeconds > 0 &&
          timedGames.contains(widget.id) &&
          remaining == 0) {
        finish(leadingPlayer(liveScores));
      }
    });
  }

  @override
  void dispose() {
    roundTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    JoySounds.instance.stop();
    super.dispose();
  }

  void finish(int winner) async {
    if (done || !mounted) return;
    setState(() => done = true);
    roundTimer?.cancel();
    final inSeries = bestOf > 1 && widget.allowRematch;
    final need = bestOf ~/ 2 + 1;
    if (inSeries && winner >= 0) series[winner]++;
    final seriesOver = !inSeries || series.any((w) => w >= need);
    if (!seriesOver) {
      JoySounds.instance.play(winner < 0 ? SoundEffect.draw : SoundEffect.goal);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (c) => PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(
                  winner < 0
                      ? 'Round drawn'
                      : '${widget.names[winner]} takes the round',
                ),
                content: Text(
                  '${widget.names[0]}  ${series[0]} – ${series[1]}  '
                  '${widget.names[1]}\nFirst to $need wins the series.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(c);
                      JoySounds.instance.stop();
                      start();
                    },
                    child: const Text('Next round'),
                  ),
                ],
              ),
            ),
      );
      return;
    }
    final seriesNote =
        inSeries
            ? '${widget.names[winner]} wins the series ${series[0]} – ${series[1]}'
            : null;
    if (inSeries) series = [0, 0];
    JoySounds.instance.celebrate(winner);
    final record = MatchRecord(
      game: widget.id,
      names: List.of(widget.names),
      winner: winner,
      seconds: elapsed,
      date: DateTime.now(),
      practice: widget.computer,
    );
    if (widget.onResult != null) {
      await widget.onResult!(record);
    } else {
      await PartyData.instance.record(record);
    }
    if (!mounted) return;
    bool sharing = false;
    String? status = seriesNote;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (c) => StatefulBuilder(
            builder: (c, update) {
              final actions = <ResultAction>[
                if (widget.allowRematch)
                  ResultAction(
                    label: 'Play again',
                    icon: Icons.replay_rounded,
                    primary: true,
                    onPressed: () {
                      Navigator.pop(c);
                      JoySounds.instance.stop();
                      start();
                    },
                  ),
                if (widget.onNextGame != null)
                  ResultAction(
                    label: 'Next game',
                    icon: Icons.arrow_forward_rounded,
                    primary: !widget.allowRematch,
                    onPressed: () {
                      widget.onNextGame!();
                      Navigator.pop(c);
                      Navigator.pop(context, winner);
                    },
                  ),
                ResultAction(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onPressed:
                      sharing
                          ? null
                          : () async {
                            update(() => sharing = true);
                            final message = await shareScorecard(
                              '${games[widget.id].name} • match wins',
                              widget.names,
                              [
                                for (var i = 0; i < widget.names.length; i++)
                                  winner == i ? 1 : 0,
                              ],
                            );
                            if (c.mounted) {
                              update(() {
                                sharing = false;
                                status = message;
                              });
                            }
                          },
                ),
                ResultAction(
                  label:
                      widget.onNextGame == null ? 'Continue' : 'Back to lobby',
                  icon:
                      widget.onNextGame == null
                          ? Icons.check_circle_outline_rounded
                          : Icons.home_rounded,
                  primary: !widget.allowRematch && widget.onNextGame == null,
                  onPressed: () {
                    Navigator.pop(c);
                    Navigator.pop(context, winner);
                  },
                ),
              ];
              return PopScope(
                canPop: false,
                child: MatchResultDialog(
                  gameName: games[widget.id].name,
                  names: widget.names,
                  winner: winner,
                  seconds: elapsed,
                  actions: actions,
                  status: status,
                ),
              );
            },
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
          StatefulBuilder(
            builder:
                (context, setBuzz) => IconButton(
                  tooltip:
                      JoyHaptics.enabled
                          ? 'Turn vibration off'
                          : 'Turn vibration on',
                  onPressed: () {
                    final value = !JoyHaptics.enabled;
                    JoyHaptics.enabled = value;
                    if (value) JoyHaptics.buzz(Buzz.medium);
                    setBuzz(() {});
                    unawaited(
                      SharedPreferences.getInstance().then(
                        (p) => p.setBool('haptics', value),
                      ),
                    );
                  },
                  icon: Icon(
                    JoyHaptics.enabled
                        ? Icons.vibration_rounded
                        : Icons.phone_android_rounded,
                  ),
                ),
          ),
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (widget.allowRematch)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              for (final n in const [1, 3, 5])
                                ChoiceChip(
                                  label: Text(n == 1 ? 'Single game' : 'Best of $n'),
                                  selected: bestOf == n,
                                  onSelected:
                                      (_) => setState(() {
                                        bestOf = n;
                                        series = [0, 0];
                                      }),
                                ),
                            ],
                          ),
                        ),
                      if (timedGames.contains(widget.id))
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: JoyTheme.accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: JoyTheme.accent.withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.timer_outlined,
                                      color: Color(0xFF8EABFF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ROUND DURATION',
                                          style: TextStyle(
                                            color: JoyTheme.ink,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Choose how long the challenge lasts',
                                          style: TextStyle(
                                            color: JoyTheme.muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 360;
                                  final options = [
                                    (0, 'Untimed', 'No time limit', Icons.all_inclusive_rounded),
                                    (60, '1 minute', '60 seconds', Icons.timer_rounded),
                                    (120, '2 minutes', '120 seconds', Icons.hourglass_bottom_rounded),
                                    (180, '3 minutes', '180 seconds', Icons.hourglass_full_rounded),
                                  ];
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: options.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: compact ? 1 : 2,
                                      mainAxisSpacing: 9,
                                      crossAxisSpacing: 9,
                                      mainAxisExtent: 70,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option = options[index];
                                      final selected = roundSeconds == option.$1;
                                      return Semantics(
                                        button: true,
                                        selected: selected,
                                        label: '${option.$2}, ${option.$3}',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(17),
                                            onTap: () {
                                              JoySounds.instance.play(SoundEffect.tap);
                                              setState(() => roundSeconds = option.$1);
                                              PartyData.instance.roundSeconds = option.$1;
                                              PartyData.instance.saveOptions();
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 220),
                                              curve: Curves.easeOutCubic,
                                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(17),
                                                gradient: selected
                                                    ? const LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [Color(0xFF315CCB), JoyTheme.accent],
                                                      )
                                                    : null,
                                                color: selected ? null : const Color(0xFF202A49),
                                                border: Border.all(
                                                  color: selected
                                                      ? const Color(0xFF91ACFF)
                                                      : const Color(0xFF344264),
                                                  width: selected ? 1.5 : 1,
                                                ),
                                                boxShadow: selected
                                                    ? [
                                                        BoxShadow(
                                                          color: JoyTheme.accent.withValues(alpha: 0.24),
                                                          blurRadius: 16,
                                                          offset: const Offset(0, 5),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 220),
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: selected ? 0.18 : 0.07),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Icon(
                                                      option.$4,
                                                      color: selected ? Colors.white : const Color(0xFF9DB4FF),
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          option.$2,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: selected ? Colors.white : JoyTheme.ink,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          option.$3,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: selected ? Colors.white.withValues(alpha: 0.78) : JoyTheme.muted,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (selected)
                                                    const Icon(
                                                      Icons.check_circle_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
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
              : Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Theme(
                    data: JoyTheme.arena,
                    child: ColoredBox(
                      color: const Color(0xFF161C36),
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
                                child: game ?? const SizedBox.shrink(),
                              ),
                    ),
                  ),
                ),
              ),
    );
  }
}
