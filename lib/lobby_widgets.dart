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
      gradient: highlighted ? JoyTheme.blueGradient : JoyTheme.panelGradient,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: highlighted
            ? const Color(0xFF83B4FF)
            : const Color(0xFF304A77),
        width: highlighted ? 1.2 : .85,
      ),
      boxShadow: [
        BoxShadow(
          color: highlighted ? const Color(0x55397BFF) : const Color(0x44000000),
          blurRadius: highlighted ? 25 : 17,
          spreadRadius: highlighted ? 1 : 0,
          offset: const Offset(0, 9),
        ),
        const BoxShadow(
          color: Color(0x223D75D8),
          blurRadius: 1,
          offset: Offset(0, -1),
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
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: .20),
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
                              colors: [Color(0xFF192B4A), Color(0xFF111D34)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: count == n
                            ? const Color(0xFF91BDFF)
                            : JoyTheme.border,
                      ),
                      boxShadow: count == n
                          ? const [
                              BoxShadow(
                                color: Color(0x55397BFF),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 4),
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
                                color: Colors.white,
                                size: 25,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$n players',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20365B), Color(0xFF162743)],
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
                            color: playerColors[i].withValues(alpha: .55),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      names[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
        colors: [Color(0xFF294B8A), Color(0xFF1A315C)],
      ),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFF668DCE).withValues(alpha: .65)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33397BFF),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFB8D5FF)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
