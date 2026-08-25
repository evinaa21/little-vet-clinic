#!/usr/bin/env python3
"""Synthesise the clinic's two sounds.

    python3 scripts/make_sounds.py [output-folder]

Both are written with the standard library only, so there is nothing to install
and either can be regenerated at any time.

  stamp.wav   The rubber stamp landing on a patient's row. Two sounds at once: a
              wooden knock (a low, fast-decaying tone) and the scuff of ink
              hitting paper (a short filtered noise burst). Letting the noise die
              first is what stops it sounding like a drum.

  unroll.wav  The sheet feeding out from under the clip when the panel opens. A
              quiet motor whirr — a low buzz with a faint mechanical flutter on
              top — that spins up fast, runs flat, then stops dead into a small
              settle-thud as the paper reaches full length.

The two must never be mistakable for each other: the stamp is a single sharp
event, the unroll is sustained and an octave lower.
"""

import math
import random
import struct
import sys
import wave

SAMPLE_RATE = 44100

random.seed(7)  # a fixed grain, so every regeneration is identical


def write(path, samples):
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(b"".join(struct.pack("<h", s) for s in samples))
    print(f"  sound {path} ({len(samples) / SAMPLE_RATE:.2f}s)")


def quantise(value, peak):
    return int(max(-1.0, min(1.0, value * peak)) * 32767)


# ---------------------------------------------------------------- stamp

STAMP_DURATION = 0.16
KNOCK_FREQ = 132.0
STAMP_PEAK = 0.62


def render_stamp():
    frames = int(SAMPLE_RATE * STAMP_DURATION)
    samples = []
    knock_phase = 0.0
    filtered = 0.0

    for i in range(frames):
        t = i / SAMPLE_RATE
        progress = i / frames

        # A low tone that drops slightly in pitch as it dies, the way a struck
        # object does.
        freq = KNOCK_FREQ * (1.0 - 0.18 * progress)
        knock_phase += 2 * math.pi * freq / SAMPLE_RATE
        knock = math.sin(knock_phase) * math.exp(-t * 34.0)

        # The ink scuff: noise that is gone within about 30 ms.
        filtered += 0.22 * (random.uniform(-1.0, 1.0) - filtered)
        scuff = filtered * math.exp(-t * 120.0)

        attack = min(1.0, t / 0.001)   # 1 ms, so the first sample can't click
        value = math.tanh(attack * (knock * 0.78 + scuff * 0.55) * 1.4)
        samples.append(quantise(value, STAMP_PEAK))

    return samples


# ---------------------------------------------------------------- unroll

UNROLL_DURATION = 0.78     # matches the paper's travel in PanelPresentation
SPIN_UP = 0.09             # motor reaching speed
MOTOR_FREQ = 61.0          # Hz — an octave below the stamp's knock
FLUTTER_FREQ = 7.5         # Hz — the roller's slow wobble
THUD_AT = 0.66             # when the paper reaches full length
UNROLL_PEAK = 0.30         # deliberately quieter than the stamp


def render_unroll():
    frames = int(SAMPLE_RATE * UNROLL_DURATION)
    samples = []
    motor_phase = 0.0
    hiss = 0.0
    thud_phase = 0.0

    for i in range(frames):
        t = i / SAMPLE_RATE

        # Motor: a low tone with a slow flutter riding on its pitch, so it sounds
        # geared rather than electronic.
        flutter = math.sin(2 * math.pi * FLUTTER_FREQ * t)
        motor_phase += 2 * math.pi * (MOTOR_FREQ + flutter * 2.6) / SAMPLE_RATE
        motor = math.sin(motor_phase) + 0.34 * math.sin(motor_phase * 2)

        # Paper hiss: heavily damped noise, quiet, just texture under the motor.
        hiss += 0.06 * (random.uniform(-1.0, 1.0) - hiss)

        # Runs flat between spin-up and the stop.
        if t < SPIN_UP:
            drive = t / SPIN_UP
        elif t < THUD_AT:
            drive = 1.0
        else:
            drive = max(0.0, 1.0 - (t - THUD_AT) / 0.03)   # motor cuts out fast

        value = drive * (motor * 0.26 + hiss * 0.9)

        # The settle: paper reaches the end of its travel and the clip takes it.
        if t >= THUD_AT:
            since = t - THUD_AT
            thud_phase += 2 * math.pi * 96.0 / SAMPLE_RATE
            value += math.sin(thud_phase) * math.exp(-since * 42.0) * 0.5

        samples.append(quantise(math.tanh(value * 1.2), UNROLL_PEAK))

    return samples


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else "LittleVetClinic/Resources"
    write(f"{folder}/stamp.wav", render_stamp())
    write(f"{folder}/unroll.wav", render_unroll())


if __name__ == "__main__":
    main()
