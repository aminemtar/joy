"""Compose JOY's original 32-beat, seamless arcade lounge loop (stdlib only)."""
import math
import random
import struct
import wave
from pathlib import Path
RATE=22050
BPM=96
BEAT=60/BPM
LENGTH=32*BEAT
samples=[0.0]*round(RATE*LENGTH)
rng=random.Random(2401)
def note(start,duration,hz,volume,kind='keys'):
    count=round(duration*RATE)
    for i in range(count):
        t=i/RATE
        if kind=='pad':
            env=min(1,t/.22,max(0,(duration-t)/.3))
            value=(math.sin(2*math.pi*hz*t)+.2*math.sin(2*math.pi*hz*1.002*t))/1.2
        else:
            env=min(1,t/.012,max(0,(duration-t)/.045))*math.exp(-3*t/duration)
            value=math.sin(2*math.pi*hz*t)+.18*math.sin(2*math.pi*2*hz*t)
        index=(round(start*RATE)+i)%len(samples)
        samples[index]+=volume*max(0,env)*value
# Cmaj7 / Am7 / Fmaj7 / G6, each held for eight beats.
chords=[[261.63,329.63,392,493.88],[220,261.63,329.63,392],[174.61,220,261.63,329.63],[196,246.94,329.63,392]]
melody=[[523.25,659.25,783.99,659.25],[659.25,523.25,440,523.25],[523.25,440,659.25,523.25],[587.33,659.25,783.99,587.33]]
for bar,chord in enumerate(chords):
    start=bar*8*BEAT
    for hz in chord:note(start,8*BEAT,hz,.022,'pad')
    for beat in range(8):note(start+beat*BEAT,.45*BEAT,chord[0]/2,.075)
    for i,hz in enumerate(melody[bar]):note(start+(i*2+.5)*BEAT,.9*BEAT,hz,.09)
for beat in range(32):
    start=round(beat*BEAT*RATE)
    for i in range(round(.12*RATE)):
        t=i/RATE;hz=85-38*t/.12
        samples[(start+i)%len(samples)]+=.09*math.sin(2*math.pi*hz*t)*math.exp(-35*t)*min(1,t/.004)
    for off in [.5]:
        start=round((beat+off)*BEAT*RATE)
        for i in range(round(.035*RATE)):
            env=math.exp(-i/(RATE*.007))*min(1,i/(RATE*.002))
            samples[(start+i)%len(samples)]+=.012*rng.uniform(-1,1)*env
peak=max(map(abs,samples));assert peak<.8
samples=[v*(.65/peak) for v in samples]
peak=max(map(abs,samples))
out=Path(__file__).resolve().parents[1]/'assets/audio/background.wav'
with wave.open(str(out),'wb') as w:
    w.setparams((1,2,RATE,0,'NONE','not compressed'))
    w.writeframes(b''.join(struct.pack('<h',round(v*32767)) for v in samples))
print(f'{out.name}: {LENGTH:.1f}s loop, peak {peak:.3f}')
