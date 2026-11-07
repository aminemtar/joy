import 'package:flutter/material.dart';
import 'catalog.dart';
import 'joy_theme.dart';
import 'lobby_widgets.dart';
import 'party_data.dart';

class PartyPlan {
  final int players, rounds;
  final Set<String> categories;
  const PartyPlan(this.players, this.rounds, this.categories);
}

class PartyBuilder extends StatefulWidget {
  final int players;
  const PartyBuilder({super.key, required this.players});
  @override
  State<PartyBuilder> createState() => _PartyBuilderState();
}

class _PartyBuilderState extends State<PartyBuilder> {
  late int players = widget.players;
  int rounds = 5;
  final categories = games.map((g) => g.category).toSet();

  @override
  Widget build(BuildContext context) {
    final available =
        games.where((g) => categories.contains(g.category)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Build your party')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          JoyPanel(
            highlighted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR NEXT GAME NIGHT',
                  style: TextStyle(
                    color: Color(0xFFD5E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Your people.\nYour playlist.',
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Pick categories and a session size. Every round is a different game.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Players', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final n in [2, 3, 4])
                ChoiceChip(
                  label: Text('$n players'),
                  selected: players == n,
                  onSelected: (_) => setState(() => players = n),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Session length', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final n in [3, 5, 8, 12])
                ChoiceChip(
                  label: Text('$n rounds'),
                  selected: rounds == n,
                  onSelected: (_) => setState(() => rounds = n),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in games.map((g) => g.category).toSet())
                FilterChip(
                  label: Text(category),
                  selected: categories.contains(category),
                  onSelected: (v) => setState(
                    () => v ? categories.add(category) : categories.remove(category),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          JoyPanel(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: JoyTheme.blueGradient,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [
                      BoxShadow(color: JoyTheme.glow, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    available == 0
                        ? 'Select at least one category.'
                        : '${rounds.clamp(0, available)} different games • $players players\n${players > 2 ? 'Two-sided games include everyone in a league.' : 'Shared screen, offline, ready to play.'}',
                    style: const TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: available == 0
                ? null
                : () => Navigator.pop(
                    context,
                    PartyPlan(players, rounds, Set.of(categories)),
                  ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start party'),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Match history')),
    body: ListenableBuilder(
      listenable: PartyData.instance,
      builder: (context, _) {
        final records = PartyData.instance.history;
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: JoyPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.emoji_events_rounded, size: 42, color: JoyTheme.accentBright),
                    SizedBox(height: 14),
                    Text(
                      'Your first rivalry starts here.\nComplete a match to save it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.5, color: JoyTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: records.length,
          separatorBuilder: (_, i) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final r = records[i];
            return JoyPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: JoyTheme.blueGradient,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.sports_esports_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          games[r.game].name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    r.winner < 0 ? 'Draw' : '${r.names[r.winner]} won',
                    style: const TextStyle(color: JoyTheme.accentBright, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${r.names.join(' vs ')}\n${r.date.toLocal().toString().substring(0, 16)} • ${r.seconds}s${r.practice ? ' • Computer practice' : ''}',
                    style: const TextStyle(color: JoyTheme.muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
