#!/usr/bin/env python3
"""Synthesise Puff's completion 'pop'.

A pop is a fast pitch drop with a near-instant attack and a short, soft tail.
This writes a 16-bit mono WAV using only the standard library, so there is
nothing to install and the asset can be regenerated at any time.

    python3 scripts/make_pop_sound.py Puff/Resources/pop.wav
"""

import math
import struct
import sys
import wave

SAMPLE_RATE = 44100
DURATION = 0.13          # seconds — short enough to fire repeatedly
START_FREQ = 1350.0      # Hz, the 'p'
END_FREQ = 520.0         # Hz, the 'op'
PEAK = 0.55              # headroom so it never clips


def render():
    frames = int(SAMPLE_RATE * DURATION)
    phase = 0.0
    samples = []

    for i in range(frames):
        t = i / SAMPLE_RATE
        progress = i / frames

        # Exponential glide downward reads as a bloop rather than a beep.
        freq = START_FREQ * (END_FREQ / START_FREQ) ** (progress ** 0.55)
        phase += 2 * math.pi * freq / SAMPLE_RATE

        # 3 ms attack, exponential decay after it.
        attack = min(1.0, t / 0.003)
        decay = math.exp(-progress * 5.2)
        envelope = attack * decay

        # A touch of second harmonic gives the pop a rounded, plastic body.
        value = math.sin(phase) * 0.82 + math.sin(phase * 2) * 0.18
        samples.append(value * envelope * PEAK)

    # Fade the last 4 ms to zero so there is no click on release.
    tail = int(SAMPLE_RATE * 0.004)
    for i in range(tail):
        samples[-1 - i] *= i / tail

    return samples


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "pop.wav"
    samples = render()
    with wave.open(out, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(b"".join(
            struct.pack("<h", max(-32768, min(32767, int(s * 32767)))) for s in samples
        ))
    print(f"wrote {out} ({len(samples)} frames, {len(samples)/SAMPLE_RATE*1000:.0f} ms)")


if __name__ == "__main__":
    main()