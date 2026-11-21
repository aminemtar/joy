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

def click_sound():
    """A short, dry tactile UI click: crisp transient, no pitched chime."""
    duration = .052
    count = round(duration * RATE)
    result = []
    seed = 731
    for i in range(count):
        t = i / RATE
        seed = (1664525 * seed + 1013904223) & 0xffffffff
        noise = (seed / 0xffffffff) * 2 - 1
        transient = math.exp(-t / .0022) * noise * .24
        body = (math.sin(2 * math.pi * 1850 * t) * math.exp(-t / .008) * .16
                + math.sin(2 * math.pi * 920 * t) * math.exp(-t / .012) * .055)
        result.append(transient + body)
    return result

def melody(notes, seconds=.11):
    values = []
    for hz in notes:
        values.extend(tone(hz, seconds, sparkle=True))
    return values


def noise(seed):
    state = seed
    while True:
        state = (1664525 * state + 1013904223) & 0xffffffff
        yield (state / 0xffffffff) * 2 - 1

def mix(*tracks):
    length = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(length)]

def knock(body_hz, duration, *, click=.2, body=.3, decay=.012, overtone=2.0, seed=11, wood=.0):
    """A percussive contact: a noise transient plus a short decaying resonance."""
    rnd = noise(seed)
    out = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        transient = next(rnd) * math.exp(-t / .0018) * click
        ring = math.sin(2 * math.pi * body_hz * t) * math.exp(-t / decay) * body
        upper = math.sin(2 * math.pi * body_hz * overtone * t) * math.exp(-t / (decay * .6)) * body * .45
        low = math.sin(2 * math.pi * body_hz * .5 * t) * math.exp(-t / (decay * 1.6)) * wood
        out.append(transient + ring + upper + low)
    return out

def burst(duration, *, level=.4, decay=.1, smooth=.5, seed=5, sweep=None):
    """Filtered noise with an exponential decay (explosions, splashes, nets)."""
    rnd = noise(seed)
    out, last = [], 0.0
    count = round(duration * RATE)
    for i in range(count):
        t = i / RATE
        progress = i / max(1, count - 1)
        k = smooth if sweep is None else smooth + (sweep - smooth) * progress
        last += (next(rnd) - last) * (1 - k)
        out.append(last * level * min(1, t / .004) * math.exp(-t / decay))
    return out

def thump(start, end, duration, *, amplitude=.5, decay=.06):
    count = round(duration * RATE)
    phase, out = 0.0, []
    for i in range(count):
        t = i / RATE
        progress = i / max(1, count - 1)
        phase += 2 * math.pi * (start + (end - start) * progress) / RATE
        out.append(amplitude * math.sin(phase) * min(1, t / .004) * math.exp(-t / decay))
    return out

def horn(frequency, duration, *, amplitude=.22):
    count = round(duration * RATE)
    out = []
    for i in range(count):
        t = i / RATE
        progress = i / max(1, count - 1)
        hz = frequency * (1 + .012 * math.sin(2 * math.pi * 7 * t)) * (1 - .12 * progress ** 3)
        value = sum(math.sin(2 * math.pi * hz * h * t) / h for h in (1, 2, 3, 5))
        out.append(amplitude * value * min(1, t / .02, (duration - t) / .06))
    return out

def whistle(duration):
    count = round(duration * RATE)
    return [.2 * math.sin(2 * math.pi * 2350 * (1 + .02 * math.sin(2 * math.pi * 28 * i / RATE)) * i / RATE)
            * min(1, i / RATE / .01, (duration - i / RATE) / .04) for i in range(count)]

def later(track, delay):
    return [0.0] * round(delay * RATE) + track

def write(name, samples):
    # A short silent tail guarantees clean releases on all audio backends.
    samples += [0.0] * round(.025 * RATE)
    assert max(abs(v) for v in samples) < .8
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as audio:
        audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        audio.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in samples))

OUT.mkdir(parents=True, exist_ok=True)
effects = {
    'tap': click_sound(),
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
    # Contact and arena cues.
    'paddle': knock(1650, .07, click=.3, body=.28, decay=.011, overtone=2.0, seed=21),
    'wall': knock(880, .06, click=.16, body=.2, decay=.016, overtone=1.5, seed=22),
    'puck': knock(540, .11, click=.26, body=.3, decay=.02, overtone=2.0, seed=23, wood=.12),
    'place': knock(390, .09, click=.18, body=.3, decay=.022, overtone=2.0, seed=24, wood=.1),
    'land': mix(thump(150, 80, .1, amplitude=.4, decay=.04), knock(700, .06, click=.22, body=.1, seed=25)),
    'bump': mix(thump(115, 50, .18, amplitude=.55, decay=.07), burst(.08, level=.3, decay=.02, smooth=.7, seed=26)),
    'crash': mix(burst(.26, level=.42, decay=.07, smooth=.35, seed=27), thump(150, 60, .2, amplitude=.4, decay=.06)),
    'blast': mix(burst(.5, level=.6, decay=.13, smooth=.8, seed=28, sweep=.97), thump(90, 38, .4, amplitude=.5, decay=.12)),
    'swish': burst(.24, level=.7, decay=.07, smooth=.55, seed=29, sweep=.9),
    'splash': burst(.3, level=.55, decay=.09, smooth=.4, seed=30, sweep=.92),
    'goal': mix(horn(330, .36, amplitude=.17), later(horn(440, .3, amplitude=.17), .05), thump(110, 70, .12, amplitude=.3)),
    'whistle': whistle(.3),
    'coin': melody([1318.51, 1975.53], .06) + tone(1975.53, .1, amplitude=.2, sparkle=True),
    'unlock': mix(click_sound(), later(tone(880, .16, end=1320, amplitude=.22, sparkle=True), .05)),
    'eat': tone(620, .06, end=1240, amplitude=.26) + tone(1240, .05, amplitude=.2),
    'pop': tone(950, .07, end=320, amplitude=.3),
}
for name, samples in effects.items():
    write(name, samples)
print(f'Generated {len(effects)} WAV effects ({sum(p.stat().st_size for p in OUT.glob("*.wav")):,} bytes).')
