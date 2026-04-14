#!/usr/bin/env python3

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT / "FocusFlight" / "Resources" / "Audio"
SAMPLE_RATE = 44_100
DURATION_SECONDS = 8


def clamp(value: float) -> float:
    return max(-1.0, min(1.0, value))


def render_track(name: str, seed: int, rumble_gain: float, hiss_gain: float, shimmer_gain: float) -> None:
    rng = random.Random(seed)
    total_frames = SAMPLE_RATE * DURATION_SECONDS
    left_low = 0.0
    right_low = 0.0
    left_hiss = 0.0
    right_hiss = 0.0

    wav_path = OUTPUT_DIR / f"{name}.wav"

    with wave.open(str(wav_path), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)

        for frame in range(total_frames):
            t = frame / SAMPLE_RATE
            # Filtered noise layers create a softer cabin texture than pure white noise.
            left_low = 0.995 * left_low + 0.005 * rng.uniform(-1.0, 1.0)
            right_low = 0.995 * right_low + 0.005 * rng.uniform(-1.0, 1.0)
            left_hiss = 0.92 * left_hiss + 0.08 * rng.uniform(-1.0, 1.0)
            right_hiss = 0.92 * right_hiss + 0.08 * rng.uniform(-1.0, 1.0)

            engine_bed = 0.22 * math.sin(2 * math.pi * 92 * t)
            engine_harmonic = 0.11 * math.sin(2 * math.pi * 184 * t + 0.15)
            cabin_air = 0.07 * math.sin(2 * math.pi * 410 * t + 0.35 * math.sin(2 * math.pi * 0.17 * t))
            shimmer = shimmer_gain * math.sin(2 * math.pi * 1_800 * t + 0.4 * math.sin(2 * math.pi * 0.08 * t))
            swell = 0.90 + 0.10 * math.sin(2 * math.pi * 0.035 * t)

            left = swell * (
                rumble_gain * left_low
                + hiss_gain * left_hiss
                + engine_bed
                + engine_harmonic
                + cabin_air
                + shimmer
            )
            right = swell * (
                rumble_gain * right_low
                + hiss_gain * right_hiss
                + engine_bed
                + engine_harmonic
                + cabin_air * 0.96
                + shimmer * 0.92
            )

            packed = struct.pack(
                "<hh",
                int(clamp(left) * 32767),
                int(clamp(right) * 32767),
            )
            handle.writeframesraw(packed)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    render_track("cabin_steady_01", seed=17, rumble_gain=0.34, hiss_gain=0.16, shimmer_gain=0.016)
    render_track("cabin_rain_01", seed=29, rumble_gain=0.28, hiss_gain=0.22, shimmer_gain=0.011)
    render_track("cabin_night_01", seed=43, rumble_gain=0.23, hiss_gain=0.11, shimmer_gain=0.008)


if __name__ == "__main__":
    main()
