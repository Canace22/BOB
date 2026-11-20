"""Render original player cues, using plucked strings and soft sustained notes."""
from pathlib import Path
import wave
import numpy as np

RATE = 44100
DEST = Path(__file__).resolve().parents[2] / "runtime/godot-support/whalebelly/runtime/audio/player"
# Onset in seconds, MIDI note, duration, strength.
SCORES = {
    "jump": [(0, 67, .20, .65)],
    "air_jump": [(0, 67, .18, .55), (.065, 74, .29, .75)],
    "dash": [(0, 62, .14, .8), (.048, 69, .19, .52)],
    "float": [(0, 62, .46, .60), (.12, 69, .50, .72), (.28, 74, .53, .48)],
    "anchor": [(0, 57, .23, .86), (.085, 64, .41, .64)],
    "hit": [(0, 50, .16, .83), (.025, 57, .20, .55)],
    "parry": [(0, 69, .23, .65), (.075, 76, .40, .84)],
    "low": [(0, 55, .43, .85), (.27, 50, .65, .72)],
    "recover": [(0, 57, .42, .56), (.16, 62, .54, .70), (.36, 69, .63, .65)],
    "defeat": [(0, 62, .58, .72), (.28, 57, .68, .66), (.62, 50, 1.13, .80)],
}

def render(name, notes):
    length = max(start + duration for start, _, duration, _ in notes) + .18
    mix = np.zeros((int(RATE * length) + 1, 2))
    attack = .033 if name in ("float", "recover", "low", "defeat") else .007
    for start, pitch, duration, strength in notes:
        t = np.arange(int(RATE * duration)) / RATE
        freq = 440 * 2 ** ((pitch - 69) / 12)
        phase = 2 * np.pi * freq * t
        env = (1 - np.exp(-t / attack)) * np.exp(-t / (duration * .34))
        env *= np.minimum(1, (duration - t) / .05)
        string = np.sin(phase) + .29*np.sin(2*phase)*np.exp(-t/.19) + .12*np.sin(3*phase)*np.exp(-t/.09)
        body = .12 * np.sin(phase * 1.002) + .06 * np.sin(phase * 4.003) * np.exp(-t/.13)
        dry = (string + body) * env * strength
        for channel, taps in enumerate([[(0, 1), (.043, .12), (.107, .07)], [(0, .98), (.059, .13), (.144, .07)]]):
            for delay, level in taps:
                offset = int((start + delay) * RATE)
                mix[offset:offset + len(dry),channel] += dry * level
    pcm = np.round(mix * (.70 / np.max(np.abs(mix))) * 32767).astype("<i2")
    with wave.open(str(DEST / (name + ".wav")), "wb") as output:
        output.setparams((2, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())

if __name__ == "__main__":
    DEST.mkdir(parents=True, exist_ok=True)
    for name, notes in SCORES.items():
        render(name, notes)
