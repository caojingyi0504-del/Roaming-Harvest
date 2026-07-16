"""Generate deterministic original garden music and ambience WAV assets."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 22_050
ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "audio" / "v2"


def midi(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def soft_clip(value: float) -> float:
    return math.tanh(value * 1.15) * 0.84


def write_stereo(path: Path, frames: list[tuple[float, float]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        payload = bytearray()
        for left, right in frames:
            payload.extend(struct.pack("<hh", int(soft_clip(left) * 32767), int(soft_clip(right) * 32767)))
        wav.writeframes(payload)


def write_mono(path: Path, frames: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(soft_clip(value) * 32767)) for value in frames))


def garden_music() -> list[tuple[float, float]]:
    duration = 48.0
    beat = 60.0 / 80.0
    total = int(duration * SAMPLE_RATE)
    chords = [
        (48, 55, 59, 64),  # Cmaj7
        (45, 52, 57, 60),  # Am7
        (41, 48, 52, 57),  # Fmaj7
        (43, 50, 55, 60),  # Gsus
    ]
    melody = [72, 74, 76, 79, 76, 74, 72, 69, 72, 76, 77, 81, 79, 76, 74, 71]
    rng = random.Random(20260716)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(total)]
    frames: list[tuple[float, float]] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        beat_index = int(t / beat)
        bar = beat_index // 4
        chord = chords[bar % len(chords)]
        beat_phase = (t % beat) / beat
        bar_phase = (t % (beat * 4.0)) / (beat * 4.0)

        pad_env = min(bar_phase / 0.12, 1.0) * min((1.0 - bar_phase) / 0.16, 1.0)
        pad = 0.0
        for voice, note in enumerate(chord):
            frequency = midi(note)
            pad += math.sin(math.tau * frequency * t + voice * 0.71) * (0.055 if voice < 2 else 0.037)
            pad += math.sin(math.tau * frequency * 2.0 * t + voice * 0.41) * 0.009
        pad *= max(pad_env, 0.0)

        pluck_note = chord[beat_index % len(chord)] + 12
        pluck_env = math.exp(-beat_phase * 7.5)
        pluck = math.sin(math.tau * midi(pluck_note) * t) * 0.105 * pluck_env
        pluck += math.sin(math.tau * midi(pluck_note) * 2.0 * t) * 0.025 * pluck_env

        eighth = int(t / (beat * 0.5))
        melody_note = melody[eighth % len(melody)]
        melody_phase = (t % (beat * 0.5)) / (beat * 0.5)
        melody_env = math.sin(math.pi * min(melody_phase / 0.35, 1.0)) * math.exp(-melody_phase * 2.4)
        bell = math.sin(math.tau * midi(melody_note) * t) * 0.065 * melody_env
        bell += math.sin(math.tau * midi(melody_note) * 2.01 * t) * 0.020 * melody_env

        shaker_env = math.exp(-beat_phase * 14.0) if beat_index % 2 == 1 else 0.0
        shaker = noise[index] * 0.018 * shaker_env
        breeze = math.sin(math.tau * 0.075 * t) * 0.010 + math.sin(math.tau * 0.13 * t + 1.7) * 0.007

        seam = min(t / 0.16, (duration - t) / 0.16, 1.0)
        mix = (pad + pluck + bell + shaker + breeze) * max(seam, 0.0)
        pan = math.sin(math.tau * 0.021 * t) * 0.12
        frames.append((mix * (1.0 - pan), mix * (1.0 + pan)))
    return frames


def creek_loop() -> list[float]:
    duration = 16.0
    total = int(duration * SAMPLE_RATE)
    rng = random.Random(62191)
    phases = [rng.uniform(0.0, math.tau) for _ in range(24)]
    frequencies = [float(index + 1) / duration for index in range(24)]
    frames: list[float] = []
    for index in range(total):
        t = index / SAMPLE_RATE
        water = 0.0
        for frequency, phase in zip(frequencies, phases):
            water += math.sin(math.tau * frequency * t + phase) / math.sqrt(frequency * duration + 1.0)
        ripple = math.sin(math.tau * 2.7 * t + math.sin(math.tau * 0.19 * t)) * 0.020
        sparkle = math.sin(math.tau * 7.2 * t + math.sin(math.tau * 0.31 * t) * 2.4) * 0.012
        frames.append(water * 0.018 + ripple + sparkle)
    return frames


def bird_chirp() -> list[float]:
    duration = 3.2
    total = int(duration * SAMPLE_RATE)
    frames: list[float] = []
    calls = [(0.28, 0.42, 1350.0, 1950.0), (1.12, 0.34, 1650.0, 2380.0), (2.05, 0.52, 1280.0, 2140.0)]
    for index in range(total):
        t = index / SAMPLE_RATE
        value = 0.0
        for start, length, low, high in calls:
            local = t - start
            if local < 0.0 or local > length:
                continue
            phase = local / length
            envelope = math.sin(math.pi * phase) ** 2
            frequency = low + (high - low) * (0.5 - 0.5 * math.cos(math.tau * phase * 2.0))
            value += math.sin(math.tau * frequency * local + math.sin(math.tau * 7.0 * local) * 0.8) * envelope * 0.20
        frames.append(value)
    return frames


def main() -> None:
    write_stereo(OUTPUT / "bgm_garden_v1.wav", garden_music())
    write_mono(OUTPUT / "garden_creek_v1.wav", creek_loop())
    write_mono(OUTPUT / "garden_bird_v1.wav", bird_chirp())
    print("generated garden audio in", OUTPUT)


if __name__ == "__main__":
    main()
