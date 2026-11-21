import 'package:flutter/material.dart';

import '../joy_theme.dart';

/// The six code colors. Each also has a glyph and a name, so the code never
/// depends on color alone.
const codeColors = [
  Color(0xFF507CFF),
  Color(0xFFFF6F83),
  Color(0xFFFFC16D),
  Color(0xFFA08AFF),
  Color(0xFF63D7F1),
  Color(0xFFFF9366),
];
const codeGlyphs = ['●', '▲', '■', '◆', '★', '✚'];
const codeNames = ['Blue', 'Coral', 'Amber', 'Violet', 'Cyan', 'Orange'];

const _vault = Color(0xFF0D1830);
const _vaultEdge = Color(0xFF526487);
const _exact = Color(0xFFFFFFFF);
const _misplaced = Color(0xFF8A97B3);
const _good = Color(0xFF4CD08A);

/// One guess with its feedback.
class CodeAttempt {
  final List<int> pegs;
  final int exact, misplaced;
  const CodeAttempt(this.pegs, this.exact, this.misplaced);
  bool get solved => exact == pegs.length;
}

/// The Code Breaker play area: a vault with four slots, a color palette and a
/// ledger of earlier guesses with their feedback pegs.
///
/// It only draws and reports taps; the game owns the state. When [enabled] is
/// false (the rival's turn) every control is inert.
class CodeBreakerBoard extends StatelessWidget {
  final List<int> guess;
  final List<CodeAttempt> history;
  final int maxAttempts;
  final bool enabled;
  final ValueChanged<int> onPick, onRemove;
  final VoidCallback onClear, onCheck;

  /// Name and progress of the rival, shown as a strip when playing against
  /// the computer.
  final String? rivalName;
  final List<CodeAttempt> rivalHistory;
  final bool rivalThinking;

  const CodeBreakerBoard({
    super.key,
    required this.guess,
    required this.history,
    required this.maxAttempts,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
    required this.onClear,
    required this.onCheck,
    this.rivalName,
    this.rivalHistory = const [],
    this.rivalThinking = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Vault(
        guess: guess,
        used: history.length,
        maxAttempts: maxAttempts,
        enabled: enabled,
        onPick: onPick,
        onRemove: onRemove,
        onClear: onClear,
        onCheck: onCheck,
      ),
      if (rivalName != null) ...[
        const SizedBox(height: 12),
        _RivalStrip(
          name: rivalName!,
          history: rivalHistory,
          maxAttempts: maxAttempts,
          thinking: rivalThinking,
        ),
      ],
      const SizedBox(height: 14),
      Row(
        children: [
          const Expanded(
            child: Text(
              'LEDGER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Text(
            '${maxAttempts - history.length} left',
            style: const TextStyle(fontSize: 11, color: JoyTheme.muted),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (history.isEmpty)
        const _EmptyLedger()
      else
        for (var i = history.length - 1; i >= 0; i--)
          _LedgerRow(
            key: ValueKey('ledger-$i'),
            number: i + 1,
            attempt: history[i],
            newest: i == history.length - 1,
          ),
      const SizedBox(height: 8),
      const _Legend(),
    ],
  );
}

class _Vault extends StatelessWidget {
  final List<int> guess;
  final int used, maxAttempts;
  final bool enabled;
  final ValueChanged<int> onPick, onRemove;
  final VoidCallback onClear, onCheck;
  const _Vault({
    required this.guess,
    required this.used,
    required this.maxAttempts,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
    required this.onClear,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final full = guess.length == 4;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22407A), Color(0xFF111C36)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF507CFF).withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF507CFF).withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                full ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: const Color(0xFF9DB7FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'CRACK THE VAULT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              Semantics(
                label: 'Attempt ${used + 1} of $maxAttempts',
                excludeSemantics: true,
                child: _AttemptDots(used: used, total: maxAttempts),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '4 hidden colors • repeats allowed • 8 tries',
              style: TextStyle(color: JoyTheme.muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _Slot(
                    key: ValueKey('slot-$i'),
                    index: i,
                    color: i < guess.length ? guess[i] : null,
                    onTap:
                        enabled && i < guess.length ? () => onRemove(i) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < codeColors.length; i++)
                _PaletteOrb(
                  key: ValueKey('pick-$i'),
                  color: i,
                  onTap: enabled && guess.length < 4 ? () => onPick(i) : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled && guess.isNotEmpty ? onClear : null,
                  icon: const Icon(Icons.backspace_outlined, size: 17),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB8CAFF),
                    side: const BorderSide(color: _vaultEdge),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: enabled && full ? onCheck : null,
                  icon: const Icon(Icons.vpn_key_rounded, size: 18),
                  label: const Text('Try this code'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF507CFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF33415F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttemptDots extends StatelessWidget {
  final int used, total;
  const _AttemptDots({required this.used, required this.total});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < total; i++)
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                i < used
                    ? const Color(0xFFFF6F83)
                    : i == used
                    ? const Color(0xFFFFC16D)
                    : Colors.white24,
          ),
        ),
    ],
  );
}

/// A glossy sphere: the look shared by slots, palette and ledger pegs.
class _Orb extends StatelessWidget {
  final int color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final base = codeColors[color];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.4, -.5),
          radius: .95,
          colors: [
            Color.lerp(base, Colors.white, .6)!,
            base,
            Color.lerp(base, Colors.black, .4)!,
          ],
          stops: const [0, .55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: .45),
            blurRadius: size * .3,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: Text(
        codeGlyphs[color],
        style: TextStyle(
          fontSize: size * .42,
          color: Colors.white,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final int index;
  final int? color;
  final VoidCallback? onTap;
  const _Slot({
    super.key,
    required this.index,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final filled = color != null;
    return Semantics(
      button: filled,
      label:
          filled
              ? 'Slot ${index + 1}, ${codeNames[color!]} ${codeGlyphs[color!]}. '
                  'Tap to remove'
              : 'Slot ${index + 1}, empty',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _vault,
            border: Border.all(
              color: filled ? Colors.white54 : _vaultEdge,
              width: 2,
            ),
          ),
          child: AnimatedScale(
            scale: filled ? 1 : .4,
            duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            child:
                filled
                    ? _Orb(color: color!, size: 42)
                    : Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF7384A7),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _PaletteOrb extends StatelessWidget {
  final int color;
  final VoidCallback? onTap;
  const _PaletteOrb({super.key, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: 'Add ${codeNames[color]} ${codeGlyphs[color]}',
    excludeSemantics: true,
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? .4 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: _Orb(color: color, size: 42)),
        ),
      ),
    ),
  );
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF17243E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFC16D), size: 17),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Clues appear here after each try.',
            textAlign: TextAlign.center,
            style: TextStyle(color: JoyTheme.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _LedgerRow extends StatelessWidget {
  final int number;
  final CodeAttempt attempt;
  final bool newest;
  const _LedgerRow({
    super.key,
    required this.number,
    required this.attempt,
    required this.newest,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final row = Semantics(
      label:
          'Try $number: '
          '${[for (final p in attempt.pegs) codeNames[p]].join(', ')}. '
          '${attempt.exact} in the right place, '
          '${attempt.misplaced} right color elsewhere.',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              attempt.solved
                  ? _good.withValues(alpha: .16)
                  : const Color(0xFF17243E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                attempt.solved
                    ? _good
                    : newest
                    ? const Color(0xFF507CFF).withValues(alpha: .6)
                    : Colors.white.withValues(alpha: .07),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: JoyTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final peg in attempt.pegs)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _Orb(color: peg, size: 26),
              ),
            const Spacer(),
            _FeedbackPegs(exact: attempt.exact, misplaced: attempt.misplaced),
            const SizedBox(width: 8),
            Text(
              '${attempt.exact}•${attempt.misplaced}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB8CAFF),
              ),
            ),
          ],
        ),
      ),
    );
    if (!newest || reduce) return row;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder:
          (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * -10),
              child: child,
            ),
          ),
      child: row,
    );
  }
}

/// Four feedback pegs in a 2x2 grid: bright for right place, grey for right
/// color elsewhere, dark for nothing.
class _FeedbackPegs extends StatelessWidget {
  final int exact, misplaced;
  const _FeedbackPegs({required this.exact, required this.misplaced});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 30,
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  i < exact
                      ? _exact
                      : i < exact + misplaced
                      ? _misplaced
                      : _vault,
              border: Border.all(color: Colors.white24, width: .8),
              boxShadow: [
                if (i < exact)
                  const BoxShadow(color: Colors.white54, blurRadius: 4),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _LegendDot(color: _exact, label: 'Right place'),
      SizedBox(width: 16),
      _LegendDot(color: _misplaced, label: 'Right color, wrong place'),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white24, width: .8),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: JoyTheme.muted, fontSize: 10)),
    ],
  );
}

class _RivalStrip extends StatelessWidget {
  final String name;
  final List<CodeAttempt> history;
  final int maxAttempts;
  final bool thinking;
  const _RivalStrip({
    required this.name,
    required this.history,
    required this.maxAttempts,
    required this.thinking,
  });

  @override
  Widget build(BuildContext context) {
    final best = history.fold<int>(0, (m, a) => a.exact > m ? a.exact : m);
    return Semantics(
      label:
          '$name has used ${history.length} of $maxAttempts tries '
          'and found $best of 4 colors in place.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6F83).withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF6F83).withValues(alpha: .45),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thinking ? '$name is thinking…' : name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Container(
                          width: 18,
                          height: 6,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color:
                                i < best
                                    ? const Color(0xFFFF6F83)
                                    : Colors.white24,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        'best $best/4',
                        style: const TextStyle(
                          fontSize: 10,
                          color: JoyTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${history.length}/$maxAttempts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFC1CB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
