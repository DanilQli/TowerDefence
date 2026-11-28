"""Synthesize six original non-looping Echoarchive SFX as 44.1 kHz PCM WAV."""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parent
RATE = 44100


def render(name: str, duration: float, partials: list, noise: float = 0.0, sweep: float = 0.0, seed: int = 20) -> None:
    rng = random.Random(seed)
    frames = int(RATE * duration)
    pcm = bytearray()
    for i in range(frames):
        t = i / RATE
        x = i / max(1, frames - 1)
        attack = min(1.0, t / 0.009)
        env = attack * math.exp(-t * (3.6 if duration > 0.28 else 9.0))
        env *= max(0.0, 1.0 - (x ** 3) * 0.68)
        env *= min(1.0, max(0.0, (duration - t) / 0.032))
        sample = 0.0
        for freq, amp, phase, decay in partials:
            f = freq * (1.0 + sweep * x)
            sample += amp * math.exp(-t * decay) * math.sin(math.tau * f * t + phase)
        if noise > 0.0:
            sample += noise * (rng.random() * 2.0 - 1.0) * math.exp(-t * 36.0)
        sample = max(-0.94, min(0.94, sample * env * 0.72))
        pcm.extend(struct.pack("<h", int(sample * 32767)))
    path = OUT / f"{name}.wav"
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm)
    print(path.name, f"{duration:.2f}s")


if __name__ == "__main__":
    # 1. Build — solemn brass-crystal archival seal
    render("turret_echoarchive_build", 0.38, [(293.66, 0.34, 0.0, 4.5), (440.0, 0.28, 0.2, 5.5), (587.33, 0.24, 0.1, 7.0), (880.0, 0.14, 0.0, 10.0)], 0.04, 0.05, 1201)
    # 2. Shot — crystalline quill-bolt launch
    render("turret_echoarchive_shot", 0.16, [(680.0, 0.38, 0.0, 9.0), (1020.0, 0.22, 0.2, 13.0), (1360.0, 0.12, 0.0, 18.0)], 0.09, 0.06, 1202)
    # 3. Target lock — crisp astrolabe index click-chime
    render("turret_echoarchive_lock", 0.20, [(523.25, 0.32, 0.0, 8.0), (783.99, 0.26, 0.1, 10.0), (1567.98, 0.14, 0.3, 16.0)], 0.03, 0.12, 1203)
    # 4. Record — shimmering rising script harmonic
    render("turret_echoarchive_record", 0.18, [(659.25, 0.26, 0.0, 7.0), (987.77, 0.20, 0.2, 9.0), (1318.5, 0.14, 0.1, 12.0)], 0.02, 0.18, 1204)
    # 5. Window end — sealed codex cadence
    render("turret_echoarchive_window_end", 0.26, [(440.0, 0.28, 0.0, 6.0), (659.25, 0.24, 0.2, 7.5), (880.0, 0.16, 0.1, 9.5)], 0.025, -0.04, 1205)
    # 6. Echo release — rich multi-harmonic cathedral archival echo burst
    render("turret_echoarchive_echo", 0.54, [(329.63, 0.24, 0.0, 3.2), (493.88, 0.24, 0.1, 3.8), (659.25, 0.25, 0.2, 4.4), (987.77, 0.20, 0.0, 5.5), (1318.5, 0.14, 0.1, 7.0), (1975.5, 0.08, 0.2, 9.5)], 0.035, 0.04, 1206)
