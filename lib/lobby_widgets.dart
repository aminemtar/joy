import 'package:flutter/material.dart';
import 'catalog.dart';
import 'game_art.dart';
import 'joy_theme.dart';
import 'tutorial_scenes.dart';
import 'players.dart';
import 'party_data.dart';

class JoyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const JoyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Material(
    color: JoyTheme.surface,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: JoyTheme.border),
      borderRadius: BorderRadius.circular(24),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

/// The two players, face to face: who is playing and the running win count.
class PartySetup extends StatelessWidget {
  final List<String> names;
  final List<int> wins;
  final List<int>? avatars;
  final VoidCallback onEdit;
  const PartySetup({
    super.key,
    required this.names,
    required this.wins,
    this.avatars,
    required this.onEdit,
  });
  @override
  Widget build(BuildContext context) => JoyPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Tonight\'s duel',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const Text(
          'One phone, two players.',
          style: TextStyle(color: JoyTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Contender(index: 0, setup: this)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: JoyTheme.muted,
                  ),
                ),
              ),
            ),
            Expanded(child: _Contender(index: 1, setup: this)),
          ],
        ),
      ],
    ),
  );
}

class _Contender extends StatelessWidget {
  final int index;
  final PartySetup setup;
  const _Contender({required this.index, required this.setup});
  @override
  Widget build(BuildContext context) {
    final color = playerColors[index];
    final avatar = setup.avatars;
    return Semantics(
      label: '${setup.names[index]}, ${setup.wins[index]} wins',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: .6)),
        ),
        child: Column(
          children: [
            if (avatar != null)
              Text(
                profileAvatars[avatar[index]],
                style: const TextStyle(fontSize: 30),
              ),
            const SizedBox(height: 6),
            Text(
              setup.names[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: JoyTheme.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${setup.wins[index]} wins',
              style: const TextStyle(color: JoyTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoPill({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: JoyTheme.background.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: JoyTheme.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF91ACFF)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: JoyTheme.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// One accent color per game category, used for the card edge and label.
Color categoryColor(String category) => switch (category) {
  'Cars' => const Color(0xFFFF8A5B),
  'Sports' => const Color(0xFF4CD08A),
  'Arena' => const Color(0xFFFF6F83),
  'Puzzles' => const Color(0xFF6FD3FF),
  'Memory' => const Color(0xFFA08AFF),
  'Brain' => const Color(0xFFFFC16D),
  'Words' => const Color(0xFFFF9EDB),
  'Strategy' => const Color(0xFF91ACFF),
  _ => const Color(0xFFFFD166),
};

/// How a game is controlled, shown on its card.
(IconData, String) controlBadge(int id) {
  if (tutorialArrowGames.contains(id)) {
    return (Icons.gamepad_rounded, 'Arrows');
  }
  if (tutorialDragGames.contains(id)) {
    return (Icons.swipe_rounded, 'Drag');
  }
  return (Icons.touch_app_rounded, 'Tap');
}

/// A lobby tile: artwork, name, category and how the game is controlled.
///
/// Wrapped in a repaint boundary so scrolling the grid never repaints the
/// neighbouring tiles.
class GameCard extends StatelessWidget {
  final int id;
  final bool favorite;
  final VoidCallback onPlay, onFavorite;
  const GameCard({
    super.key,
    required this.id,
    required this.favorite,
    required this.onPlay,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final game = games[id];
    final color = categoryColor(game.category);
    final (icon, control) = controlBadge(id);
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${game.name}, ${game.category}, $control controls',
        excludeSemantics: true,
        onTap: onPlay,
        child: Material(
          color: JoyTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: color.withValues(alpha: .35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPlay,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 4,
                  child: ColoredBox(color: color),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Hero(
                          tag: 'game-$id',
                          child: Material(
                            color: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GameArt(id: id, size: 100),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        game.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: JoyTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              game.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: JoyTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(icon, size: 14, color: JoyTheme.muted),
                          const SizedBox(width: 3),
                          Text(
                            control,
                            style: const TextStyle(
                              color: JoyTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 6,
                  child: IconButton.filledTonal(
                    tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: onFavorite,
                    icon: Icon(
                      favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
