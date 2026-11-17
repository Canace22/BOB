"""从源PNG离线提取脚底位置，避免运行中从GPU回读动画帧。"""
import hashlib
import json
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[2]
MANIFEST = GAME / "art/tide-picker-action36/animations.json"
TARGET = Path(__file__).with_name("foot_offsets.json")


def main():
    actions = json.loads(MANIFEST.read_text(encoding="utf-8"))["actions"]
    output = {"version": 1, "generated_by": "build_foot_offsets.py", "actions": {}}
    for key, action in actions.items():
        spec = action["body"]
        source = GAME / spec["texture"].removeprefix("res://")
        with Image.open(source) as sheet:
            alpha = sheet.convert("RGBA").getchannel("A")
            bottoms = []
            for x, y, width, height in spec["frames"]:
                bbox = alpha.crop((x, y, x + width, y + height)).getbbox()
                bottoms.append(bbox[3] if bbox else 0)
        output["actions"][key] = {
            "texture": spec["texture"],
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "frames": spec["frames"],
            "bottom": bottoms,
        }
    with TARGET.open("w", encoding="utf-8", newline="\n") as target:
        target.write(json.dumps(output, ensure_ascii=False, separators=(",", ":")) + "\n")
    print(f"Foot offsets: {len(output['actions'])} actions -> {TARGET}")


if __name__ == "__main__":
    main()
