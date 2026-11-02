"""Select distinct processed poses from Framecraft's held-frame exports."""
import json
from pathlib import Path
import shutil
from register import DURATIONS

ROOT = Path(__file__).resolve().parent
output = ROOT / "delivery"
output.mkdir(exist_ok=True)
clips = {}
for name, durations in DURATIONS.items():
    cursor = 1
    frames = []
    for index, duration in enumerate(durations):
        filename = f"{name}-{index:02}.png"
        shutil.copy2(ROOT / name / "platform" / "processed" / f"frame-{cursor:03}.png", output / filename)
        frames.append({"file": f"right/{filename}", "durationMs": duration})
        cursor += duration // 20
    clips[name] = {"loop": False, "frames": frames}
(output / "clips.json").write_text(json.dumps(clips, indent=2) + "\n")
