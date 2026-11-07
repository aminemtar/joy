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
  Widget build(BuildContext context) {
    const radius = 28.0;
    return Container(
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8BD8FF), Color(0xFF168BFF), Color(0xFF0754C8)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF5FAFF), Color(0xFFDCEEFF)],
                stops: [0, .52, 1],
              ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted ? const Color(0xFFBDEBFF) : Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D9E).withValues(alpha: highlighted ? .34 : .22),
            blurRadius: highlighted ? 30 : 24,
            spreadRadius: highlighted ? 1 : 0,
            offset: const Offset(0, 13),
          ),
          BoxShadow(
            color: const Color(0xFF62C4FF).withValues(alpha: highlighted ? .34 : .22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0xAAFFFFFF),
            blurRadius: 1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              child: IgnorePointer(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: highlighted ? .9 : 1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              right: -34,
              child: IgnorePointer(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: highlighted ? .22 : .72),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class JoyActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  const JoyActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final colors = primary
        ? const [Color(0xFF46B8FF), Color(0xFF087BFF), Color(0xFF0754D6)]
        : const [Colors.white, Color(0xFFEAF6FF), Color(0xFFD5EAFF)];
    return Opacity(
      opacity: enabled ? 1 : .48,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: primary ? const Color(0xFFB7E8FF) : Colors.white,
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003D9E).withValues(alpha: primary ? .34 : .16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Color(0x88FFFFFF),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(19),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 19, color: primary ? Colors.white : JoyTheme.accentDeep),
                  const SizedBox(width: 9),
                  Text(
                    label,
                    style: TextStyle(
                      color: primary ? Colors.white : JoyTheme.accentDeep,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: .1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
