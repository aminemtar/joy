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
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF3FAFF), Color(0xFFDCEFFF)],
        stops: [0, .52, 1],
      ),
      border: Border.all(color: Colors.white, width: 1.4),
      boxShadow: const [
        BoxShadow(color: Color(0x660044A8), blurRadius: 22, offset: Offset(0, 11)),
        BoxShadow(color: Color(0x99FFFFFF), blurRadius: 1, offset: Offset(0, -2)),
        BoxShadow(color: Color(0x2275BFFF), blurRadius: 7, spreadRadius: -2, offset: Offset(0, 3)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: Padding(padding: padding, child: child),
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
              if (n > 2) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: count == n,
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () => onChanged(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: count == n
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF52BDFF), Color(0xFF087BFF), Color(0xFF0754C5)],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Color(0xFFEAF6FF)],
                                ),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: count == n ? const Color(0xFFBCEBFF) : const Color(0xFFD1E9F8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: count == n ? const Color(0x77004DAA) : const Color(0x22004488),
                              blurRadius: count == n ? 16 : 9,
                              offset: Offset(0, count == n ? 8 : 5),
                            ),
                            const BoxShadow(color: Color(0xAAFFFFFF), blurRadius: 1, offset: Offset(0, -1)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              n == 2
                                  ? Icons.people_alt_rounded
                                  : n == 3
                                  ? Icons.groups_rounded
                                  : Icons.diversity_3_rounded,
                              color: count == n ? Colors.white : JoyTheme.accentDeep,
                              size: 25,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$n players',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE5F3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFD3EAFB)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22004488), blurRadius: 8, offset: Offset(0, 4)),
                    BoxShadow(color: Colors.white, blurRadius: 1, offset: Offset(0, -1)),
                  ],
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
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFE2F3FF)],
      ),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFC9E6FA), width: 1.1),
      boxShadow: const [
        BoxShadow(color: Color(0x22004488), blurRadius: 9, offset: Offset(0, 4)),
        BoxShadow(color: Colors.white, blurRadius: 1, offset: Offset(0, -1)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: JoyTheme.accentDeep),
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
