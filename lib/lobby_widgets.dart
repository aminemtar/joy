import 'package:flutter/material.dart';
import 'joy_theme.dart';
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
              if (n > 2) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: count == n,
                  button: true,
                  child: Material(
                    color: count == n ? JoyTheme.accent : JoyTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onChanged(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                count == n
                                    ? const Color(0xFF91ACFF)
                                    : JoyTheme.border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              n == 2
                                  ? Icons.people_alt_rounded
                                  : n == 3
                                  ? Icons.groups_rounded
                                  : Icons.diversity_3_rounded,
                              color: count == n ? Colors.white : JoyTheme.muted,
                              size: 25,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$n players',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: JoyTheme.ink,
                              ),
                            ),
                          ],
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
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: JoyTheme.raised,
                  borderRadius: BorderRadius.circular(12),
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
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      names[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
