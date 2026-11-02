"""Crop measured rectangles and register anatomical anchors; no pose synthesis."""
from pathlib import Path
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parent
SCALE = 0.375
RECTS = {
    "hurt": [(80, 0, 790, 724), (790, 0, 1463, 724), (1463, 0, 2172, 724)],
    "dash": [(0, 0, 745, 724), (745, 0, 1520, 724), (1520, 0, 2172, 724)],
    "heal": [(0, 0, 745, 724), (745, 0, 1453, 724), (1453, 0, 2172, 724)],
}
# x is the near ankle for planted actions, pelvis for the in-place dash.
ANCHORS = {"hurt": [(234, 676), (202, 676), (200, 676)],
           "heal": [(257, 676), (225, 676), (190, 676)],
           "dash": [(420, 666), (400, 666), (360, 666)]}
DURATIONS = {"hurt": [40, 80, 60], "dash": [60, 100, 60], "heal": [200, 660, 240]}


def main():
    records = []
    for name, rects in RECTS.items():
        source = Image.open(ROOT / "raw" / f"{name}-v01.png").convert("RGBA")
        folder = ROOT / name
        for child in ("poses", "frames"):
            (folder / child).mkdir(parents=True, exist_ok=True)
        cursor = 1
        for index, (rect, anchor, duration) in enumerate(zip(rects, ANCHORS[name], DURATIONS[name])):
            cropped = source.crop(rect)
            pose_scale = SCALE
            target = (192 if name == "dash" else 167, 342)
            source_file = f"raw/{name}-v01.png"
            if name == "dash" and index == 2:
                source_file = "raw/dash-recovery-v02.png"
                cropped = Image.open(ROOT / source_file).convert("RGBA")
                rect, anchor, target = (0, 0, 1254, 1254), (548, 1120), (167, 342)
                pose_scale = 384 / 1254
            scaled = cropped.resize(tuple(round(n * pose_scale) for n in cropped.size), Image.Resampling.LANCZOS)
            offset = tuple(round(target[i] - anchor[i] * pose_scale) for i in range(2))
            canvas = Image.new("RGBA", (384, 384))
            canvas.alpha_composite(scaled, offset)
            pose = folder / "poses" / f"{name}-{index:02}.png"
            canvas.save(pose)
            for tick in range(duration // 20):
                shutil.copy2(pose, folder / "frames" / f"frame-{cursor:03}.png")
                cursor += 1
            records.append({"clip": name, "pose": index, "source": source_file, "rectXYXY": rect, "scale": pose_scale,
                            "anchor": anchor, "target": target, "offset": offset, "durationMs": duration})
        options = {"name": f"TidePicker_RIGHT_v2_{name}_50FPS", "output": str(folder / "platform"),
                   "framesDirectory": "frames", "fps": 50, "loop": False, "pivot": [192, 342],
                   "direction": "right", "exportName": f"player-right-v2-{name}",
                   "settings": {"scale": 1, "alphaThreshold": 8, "sharpen": 0}, "copySourceFrames": False,
                   "limitations": ["Three independently drawn poses; repeated ticks only encode duration.",
                                   "Contact and runtime visual review remain separate from export checks."]}
        (folder / "platform-options.json").write_text(json.dumps(options, indent=2) + "\n")
    report = {"method": "Explicit non-grid cuts; constant 0.375 scale matching helmet ~85px and lamp ~40px; near ankle/sole or pelvis registration.",
              "canvas": [384, 384], "pivot": [192, 342], "records": records,
              "landmarkUncertaintySourcePx": 8, "userVisualApproval": False}
    (ROOT / "registration.json").write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
