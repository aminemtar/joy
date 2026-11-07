import 'package:flutter/material.dart';
import 'joy_theme.dart';
import 'players.dart';
import 'party_data.dart';

/// Raised, light surface used by the lobby and setup screens.
class JoyPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? accentColor;
  const JoyPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.color, this.accentColor});

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? JoyTheme.surface,
    elevation: 5,
    shadowColor: const Color(0x222D659B),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: accentColor?.withValues(alpha: .35) ?? JoyTheme.border),
      borderRadius: BorderRadius.circular(23),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      Positioned(top: 0, left: 22, right: 22, height: 2,
        child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, accentColor ?? const Color(0xFF76B9FF), Colors.transparent])))),
      Padding(padding: padding, child: child),
    ]),
  );
}

class PartySetup extends StatelessWidget {
  final int count;
  final List<String> names;
  final List<int> wins;
  final List<int>? avatars;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;
  const PartySetup({super.key, required this.count, required this.names, required this.wins, this.avatars, required this.onChanged, required this.onEdit});

  @override
  Widget build(BuildContext context) => JoyPanel(
    accentColor: JoyTheme.accent,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Your party', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: JoyTheme.ink))),
        TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Edit')),
      ]),
      const Text('How many are playing?', style: TextStyle(color: JoyTheme.muted, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(children: [
        for (var n = 2; n <= 4; n++) ...[
          if (n > 2) const SizedBox(width: 9),
          Expanded(child: Semantics(selected: count == n, button: true, child: AnimatedContainer(
            duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: count == n
                ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF42A5FF), Color(0xFF0868E8), Color(0xFF0754C4)])
                : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Color(0xFFF0F7FF)]),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: count == n ? const Color(0xFF8CC6FF) : JoyTheme.border, width: count == n ? 1.4 : 1),
              boxShadow: count == n
                ? const [BoxShadow(color: Color(0x33087BFF), blurRadius: 12, offset: Offset(0, 5)), BoxShadow(color: Color(0x66FFFFFF), blurRadius: 0, offset: Offset(0, -2))]
                : const [BoxShadow(color: Color(0x140B4F8A), blurRadius: 7, offset: Offset(0, 3))],
            ),
            child: Material(color: Colors.transparent, child: InkWell(
              borderRadius: BorderRadius.circular(17), onTap: () => onChanged(n),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4), child: Column(children: [
                Icon(n == 2 ? Icons.people_alt_rounded : n == 3 ? Icons.groups_rounded : Icons.diversity_3_rounded, color: count == n ? Colors.white : JoyTheme.accentDeep, size: 25),
                const SizedBox(height: 8),
                Text('$n players', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: count == n ? Colors.white : JoyTheme.ink)),
              ])),
            )),
          ))),
        ],
      ]),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < count; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: const [Color(0xFFE5F1FF), Color(0xFFFFEAF0), Color(0xFFFFF3DB), Color(0xFFF0ECFF)][i],
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: playerColors[i].withValues(alpha: .28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (avatars != null) Padding(padding: const EdgeInsets.only(right: 6), child: Text(profileAvatars[avatars![i]])),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: playerColors[i], shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(names[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: JoyTheme.ink)),
              const SizedBox(width: 8),
              Text('${wins[i]} wins', style: const TextStyle(color: JoyTheme.muted, fontSize: 11)),
            ]),
          ),
      ]),
    ]),
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
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFDCEEFF)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFA9D1FA)),
      boxShadow: const [BoxShadow(color: Color(0x220B4F8A), blurRadius: 7, offset: Offset(0, 3))],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: JoyTheme.accentDeep),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11, color: JoyTheme.ink, fontWeight: FontWeight.w800)),
    ]),
  );
}
