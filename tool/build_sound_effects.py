"""Generate JOY's original, deterministic offline arcade effects (Python stdlib)."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'

def tone(frequency, duration, *, end=None, amplitude=.32, sparkle=False):
    count = round(duration * RATE)
    phase = 0.0
    result = []
    for i in range(count):
        t = i / RATE
        progress = i / max(1, count - 1)
        hz = frequency + ((end or frequency) - frequency) * progress
        phase += 2 * math.pi * hz / RATE
        envelope = min(1, t / .007, (duration - t) / .025) * math.exp(-2 * progress)
        value = math.sin(phase) + (.2 * math.sin(phase * 2) if sparkle else 0)
        result.append(amplitude * max(0, envelope) * value)
    return result

def melody(notes, seconds=.11):
    values = []
    for hz in notes:
        values.extend(tone(hz, seconds, sparkle=True))
    return values

def write(name, samples):
    # A short silent tail guarantees clean releases on all audio backends.
    samples += [0.0] * round(.025 * RATE)
    assert max(abs(v) for v in samples) < .8
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as audio:
        audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in samples))

OUT.mkdir(parents=True, exist_ok=True)
effects = {
    'tap': tone(850, .055, end=650, amplitude=.18),
    'flip': tone(450, .11, end=1150, amplitude=.23),
    'correct': melody([659.25, 987.77], .11),
    'wrong': melody([311.13, 233.08], .14),
    'hit': tone(190, .105, end=75, amplitude=.38),
    'jump': tone(320, .16, end=950, amplitude=.28),
    'shoot': tone(1350, .11, end=180, amplitude=.23),
    'tick': tone(660, .07, amplitude=.20),
    'start': melody([523.25, 659.25, 1046.50], .085),
    'win': melody([523.25, 659.25, 783.99, 1046.50], .115) + tone(1046.50, .42, sparkle=True),
    'draw': melody([659.25, 587.33, 659.25], .14),
    'note_blue': tone(523.25, .24, amplitude=.28),
    'note_coral': tone(659.25, .24, amplitude=.28),
    'note_gold': tone(783.99, .24, amplitude=.28),
    'note_purple': tone(1046.50, .24, amplitude=.28),
}
for name, samples in effects.items():
    write(name, samples)
print(f'Generated {len(effects)} WAV effects ({sum(p.stat().st_size for p in OUT.glob("*.wav")):,} bytes).')
