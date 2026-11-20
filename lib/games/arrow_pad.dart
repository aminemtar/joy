import 'dart:math';

import 'package:flutter/material.dart';

import '../joy_theme.dart';

/// Four arrow buttons for one player: left, up, down, right.
///
/// Directions are reported in the pad's own frame, as the player sees it.
/// The pad for the player across the table is drawn rotated by 180 degrees,
/// so the caller flips the direction for that player.
///
/// Each button reports a press and a release (not a tap), so a game can treat
/// it as a joystick direction or react on press only. Buttons use raw pointer
/// events, so two players can hold their pads at the same time.
class ArrowPad extends StatelessWidget {
  final int player;
  final Color color;
  final ValueChanged<Point<int>> onPress, onRelease;
  const ArrowPad({
    super.key,
    required this.player,
    required this.color,
    required this.onPress,
    required this.onRelease,
  });

  static const _buttons = <(String, Point<int>, IconData)>[
    ('left', Point(-1, 0), Icons.arrow_back_rounded),
    ('up', Point(0, -1), Icons.arrow_upward_rounded),
    ('down', Point(0, 1), Icons.arrow_downward_rounded),
    ('right', Point(1, 0), Icons.arrow_forward_rounded),
  ];

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final (name, direction, icon) in _buttons)
        _PadButton(
          key: ValueKey('pad-$player-$name'),
          label: name,
          icon: icon,
          color: color,
          onPress: () => onPress(direction),
          onRelease: () => onRelease(direction),
        ),
    ],
  );
}

class _PadButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPress, onRelease;
  const _PadButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPress,
    required this.onRelease,
  });

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool pressed = false;

  void set(bool value) {
    if (pressed == value) return;
    setState(() => pressed = value);
    if (value) {
      widget.onPress();
    } else {
      widget.onRelease();
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 90);
    final color = widget.color;
    return Semantics(
      button: true,
      label: 'Move ${widget.label}',
      // Assistive technology cannot hold a button, so it gets a quick nudge.
      onTap: () {
        widget.onPress();
        widget.onRelease();
      },
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => set(true),
        onPointerUp: (_) => set(false),
        onPointerCancel: (_) => set(false),
        child: AnimatedScale(
          scale: pressed ? .92 : 1,
          duration: duration,
          child: AnimatedContainer(
            duration: duration,
            width: 48,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: pressed ? color : color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: pressed ? 1 : .55),
                width: 1.5,
              ),
              boxShadow: [
                if (pressed)
                  BoxShadow(
                    color: color.withValues(alpha: .5),
                    blurRadius: 12,
                  ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 26,
              color: pressed ? JoyTheme.background : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
