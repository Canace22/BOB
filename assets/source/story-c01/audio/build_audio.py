"""Rebuild the chapter's original synthesized cues with Python's standard library.

No recordings, third-party samples, network access, or random seeds are involved.
Run from any directory; --check verifies committed PCM without changing files.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import wave

RATE = 44100
SOURCE = Path(__file__).resolve().parent
OUTPUT = SOURCE.parents[2] / "runtime" / "story-c01" / "audio"


def smooth(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def add_voice(samples: list[float], start: float, length: float,
              frequency: float, glide: float, amplitude: float) -> None:
    phase = 0.0
    begin = round(start * RATE)
    count = round(length * RATE)
    for index in range(count):
        time = index / RATE
        progress = index / max(1, count - 1)
        pitch = frequency + glide * smooth(progress)
        pitch *= 1.0 + 0.006 * math.sin(2.0 * math.pi * 1.3 * time)
        phase += 2.0 * math.pi * pitch / RATE
        envelope = math.sin(math.pi * progress) ** 2
        tone = (math.sin(phase) + 0.24 * math.sin(phase * 2.0 + 0.2)
                + 0.065 * math.sin(phase * 3.0 + 0.4))
        # A quiet detuned body adds width without a bright attack or noisy sample.
        tone += 0.14 * math.sin(phase * 0.997)
        samples[begin + index] += amplitude * envelope * tone


def finish(samples: list[float], peak: float,
           echoes: tuple[tuple[float, float], ...]) -> bytes:
    dry = samples.copy()
    for seconds, gain in echoes:
        offset = round(seconds * RATE)
        for index in range(offset, len(samples)):
            samples[index] += dry[index - offset] * gain
    for index in range(len(samples)):
        fade_in = smooth(index / (RATE * 0.025))
        fade_out = smooth((len(samples) - 1 - index) / (RATE * 0.12))
        samples[index] *= fade_in * fade_out
    scale = peak / max(abs(sample) for sample in samples)
    integers = [round(sample * scale * 32767) for sample in samples]
    assert all(-32768 < sample < 32767 for sample in integers)
    return struct.pack(f"<{len(integers)}h", *integers)


def whale_call() -> bytes:
    samples = [0.0] * round(3.2 * RATE)
    add_voice(samples, 0.06, 0.76, 92.5, 10.5, 0.88)
    add_voice(samples, 0.95, 0.92, 110.0, -12.0, 1.0)
    add_voice(samples, 1.99, 0.83, 87.3, -4.9, 0.78)
    return finish(samples, 0.31, ((0.115, 0.16), (0.23, 0.07), (0.38, 0.025)))


def resonance() -> bytes:
    samples = [0.0] * round(0.55 * RATE)
    for index in range(len(samples)):
        time = index / RATE
        envelope = smooth(time / 0.045) * math.exp(-time * 6.8)
        envelope *= smooth((0.51 - time) / 0.16)
        phase = 2.0 * math.pi * (293.66 * time - 1.5 * time * time)
        tone = (math.sin(phase) + 0.32 * math.sin(phase * 1.5)
                + 0.07 * math.sin(phase * 2.0))
        samples[index] = envelope * tone
    return finish(samples, 0.23, ((0.038, 0.08), (0.083, 0.03)))


def measure(path: Path, expected: bytes) -> dict:
    with wave.open(str(path), "rb") as reader:
        assert reader.getnchannels() == 1, "Expected mono"
        assert reader.getsampwidth() == 2, "Expected PCM 16 bit"
        assert reader.getframerate() == RATE, "Unexpected sample rate"
        assert reader.getcomptype() == "NONE", "Expected uncompressed PCM"
        actual = reader.readframes(reader.getnframes())
    assert actual == expected, f"Rebuild differs: {path.name}"
    values = struct.unpack(f"<{len(actual) // 2}h", actual)
    peak = max(abs(value) for value in values) / 32768.0
    rms = math.sqrt(sum(value * value for value in values) / len(values)) / 32768.0
    step = max(abs(b - a) for a, b in zip(values, values[1:])) / 32768.0
    edge_count = round(0.01 * RATE)
    edge_rms = [math.sqrt(sum(value * value for value in edge) / len(edge)) / 32768.0
                for edge in (values[:edge_count], values[-edge_count:])]
    clipping = sum(value <= -32768 or value >= 32767 for value in values)
    assert values[0] == values[-1] == 0, "Nonzero endpoint"
    assert clipping == 0 and 0.01 < peak < 0.5, "Unsafe or silent signal"
    assert rms > 0 and step < 0.08, "Unexpected discontinuity"
    assert all(value < rms * 0.15 for value in edge_rms), "Missing edge fade"
    return {
        "file": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "bytes": path.stat().st_size, "seconds": len(values) / RATE,
        "sample_rate": RATE, "channels": 1, "pcm_bits": 16,
        "peak_linear": round(peak, 7), "peak_dbfs": round(20 * math.log10(peak), 3),
        "rms_linear": round(rms, 7), "rms_dbfs": round(20 * math.log10(rms), 3),
        "clipped_samples": clipping, "max_adjacent_step": round(step, 7),
        "first_sample": values[0], "last_sample": values[-1],
        "first_10ms_rms": round(edge_rms[0], 8), "last_10ms_rms": round(edge_rms[1], 8),
        "technical_validation": "passed", "listening_review": "pending",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    results = []
    for name, build in (("whale-call.wav", whale_call), ("resonance.wav", resonance)):
        pcm = build()
        destination = OUTPUT / name
        if not args.check:
            OUTPUT.mkdir(parents=True, exist_ok=True)
            with wave.open(str(destination), "wb") as writer:
                writer.setnchannels(1)
                writer.setsampwidth(2)
                writer.setframerate(RATE)
                writer.writeframes(pcm)
        results.append(measure(destination, pcm))
    report = {"method": "original additive synthesis; no recorded samples", "files": results}
    if not args.check:
        (SOURCE / "validation.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
