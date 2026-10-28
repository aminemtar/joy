import 'package:flutter/material.dart';
import 'players.dart';
import 'joy_theme.dart';
import 'game_art.dart';
import 'sound.dart';
import 'games/game_stage.dart';

class PartyLeagueScreen extends StatefulWidget {
  final int gameId;
  final List<String> names;
  final Widget Function(List<String>) duelBuilder;
  const PartyLeagueScreen({
    super.key,
    required this.gameId,
    required this.names,
    required this.duelBuilder,
  });
  @override
  State<PartyLeagueScreen> createState() => _PartyLeagueScreenState();
}

class _PartyLeagueScreenState extends State<PartyLeagueScreen> {
  late final PartyLeague league;
  int current = 0;
  bool playing = false;
  @override
  void initState() {
    super.initState();
    league = PartyLeague(widget.names.length);
  }

  @override
  void dispose() {
    JoySounds.instance.stop();
    super.dispose();
  }

  Future<void> next() async {
    if (playing || current >= league.fixtures.length) return;
    setState(() => playing = true);
    final pair = league.fixtures[current];
    final winner = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder:
            (_) => widget.duelBuilder([
              widget.names[pair.first],
              widget.names[pair.second],
            ]),
      ),
    );
    if (!mounted) return;
    if (winner == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      league.record(current, winner);
      current++;
      playing = false;
    });
    if (current == league.fixtures.length) {
      JoySounds.instance.celebrate(league.winner);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = current == league.fixtures.length;
    final pair = done ? null : league.fixtures[current];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.names.length}-player league')),
      body: GameStage(
        names: widget.names,
        scores: league.points,
        turn: -1,
        message: '3 points for a win • 1 point each for a draw',
        child: Column(
          children: [
            GameArt(id: widget.gameId, size: 115),
            const SizedBox(height: 14),
            Text(
              done
                  ? (league.winner < 0
                      ? 'League tied'
                      : '${widget.names[league.winner]} wins the league!')
                  : 'Everyone plays everyone',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Two opponents per match, with all selected players included.',
              textAlign: TextAlign.center,
              style: TextStyle(color: JoyTheme.muted),
            ),
            const SizedBox(height: 24),
            if (pair != null) ...[
              Text(
                'Match ${current + 1} / ${league.fixtures.length}',
                style: const TextStyle(color: JoyTheme.muted),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.names[pair.first]}  vs  ${widget.names[pair.second]}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: playing ? null : next,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start next match'),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.pop(context, league.winner),
                child: const Text('Finish league'),
              ),
          ],
        ),
      ),
    );
  }
}
