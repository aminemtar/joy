import 'package:flutter/material.dart';
import 'joy_theme.dart';
import 'players.dart';
import 'party_data.dart';

class JoyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;
  const JoyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: highlighted
          ? JoyTheme.blueGradient
          : JoyTheme.panelGradient,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: highlighted ? const Color(0xFF8ACBFF) : Colors.white,
        width: highlighted ? 1.2 : 1.1,
      ),
      boxShadow: [
        BoxShadow(
          color: highlighted
              ? const Color(0x553B9DFF)
              : const Color(0x223D83BD),
          blurRadius: highlighted ? 27 : 18,
          spreadRadius: highlighted ? 1 : 0,
          offset: const Offset(0, 9),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: highlighted ? .22 : .9),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        children: [
          Padding(padding: padding, child: child),
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: .9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class PartySetup extends StatelessWidget {
  final int count;
  final List<String> names;
  final List<int> wins;
  final List<int>? avatars;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;
  const PartySetup({
    super.key,
    required this.count,
    required this.names,
    required this.wins,
    this.avatars,
    required this.onChanged,
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
                'Your party',
                style: TextStyle(
                  fontSize: 20,
                  color: JoyTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
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
          'How many are playing?',
          style: TextStyle(color: JoyTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var n = 2; n <= 4; n++) ...[
              if (n > 2) const SizedBox(width: 9),
              Expanded(
                child: Semantics(
                  selected: count == n,
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      gradient: count == n
                          ? JoyTheme.blueGradient
                          : const LinearGradient(
                              colors: [Colors.white, Color(0xFFEAF6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: count == n
                            ? const Color(0xFF9DD5FF)
                            : JoyTheme.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: count == n
                              ? const Color(0x443B9DFF)
                              : const Color(0x1D4E8DBD),
                          blurRadius: count == n ? 15 : 9,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(17),
                        onTap: () => onChanged(n),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 4,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                n == 2
                                    ? Icons.people_alt_rounded
                                    : n == 3
                                    ? Icons.groups_rounded
                                    : Icons.diversity_3_rounded,
                                color: count == n ? Colors.white : JoyTheme.accent,
                                size: 25,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$n players',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: count == n ? Colors.white : JoyTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFEAF6FF)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: JoyTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (avatars != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(profileAvatars[avatars![i]]),
                      ),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: playerColors[i],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: playerColors[i].withValues(alpha: .4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      names[i],
                      style: const TextStyle(
                        color: JoyTheme.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${wins[i]} wins',
                      style: const TextStyle(
                        color: JoyTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE5F4FF), Colors.white],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFB8DFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x223B9DFF),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: JoyTheme.accent),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: JoyTheme.accentDeep,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
