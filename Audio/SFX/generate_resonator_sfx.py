"""Synthesize five original harmonic, non-looping Resonator sounds as PCM WAV."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).parent
RATE = 44100


def render(name, duration, partials, noise=0.0, sweep=0.0, seed=19):
    rng = random.Random(seed)
    frames = int(RATE * duration)
    pcm = bytearray()
    for i in range(frames):
        t = i / RATE
        x = i / max(1, frames - 1)
        attack = min(1.0, t / 0.008)
        env = attack * math.exp(-t * (4.0 if duration > .25 else 10.0))
        env *= max(0.0, 1.0 - x**3 * 0.72)
        env *= min(1.0, max(0.0, (duration - t) / 0.028))
        sample = 0.0
        for freq, amp, phase, decay in partials:
            f = freq * (1.0 + sweep * x)
            partial_env = math.exp(-t * decay)
            sample += amp * partial_env * math.sin(2*math.pi*f*t + phase)
        if noise:
            sample += noise * (rng.random()*2-1) * math.exp(-t*40.0)
        sample *= env
        sample = max(-0.95, min(0.95, sample * 0.72))
        pcm.extend(struct.pack('<h', int(sample * 32767)))
    path = OUT / (name + '.wav')
    with wave.open(str(path), 'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE); wav.writeframes(pcm)
    print(path.name, duration, 's')


if __name__ == '__main__':
    render('turret_resonator_shot', .15, [(740,.40,0,8),(1110,.22,.2,12),(1480,.12,0,17),(2220,.08,.1,21)], .10, .08, 101)
    render('turret_resonator_charge', .24, [(587,.31,0,5),(880,.25,.3,7),(1175,.12,0,10),(1760,.06,.2,13)], .035, .14, 202)
    render('turret_resonator_pulse', .43, [(392,.24,0,4),(587,.26,.1,5),(784,.23,.2,6),(1175,.15,0,8),(1568,.08,.1,11)], .025, -.025, 303)
    render('turret_resonator_impact', .20, [(164,.35,0,22),(330,.28,0,15),(660,.20,.1,13),(990,.10,.2,18)], .20, -.12, 404)
    render('turret_resonator_perfect', .68, [(523,.18,0,3),(659,.20,.1,3.5),(784,.22,.2,4),(1047,.20,0,5),(1319,.16,.1,6),(1568,.12,.2,7),(2093,.07,0,9)], .018, .06, 505)
