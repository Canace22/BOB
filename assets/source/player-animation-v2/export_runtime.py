"""Assemble reviewed directional PNGs; no drawing, mirroring or frame synthesis."""
from pathlib import Path
import hashlib
import json
from io import BytesIO
import os
from tempfile import TemporaryDirectory
import shutil
import sys

import requests
from PIL import Image

SOURCE = Path(__file__).resolve().parent
REPO = SOURCE.parents[2]
OUTPUT = REPO / "assets/runtime/sprites/tide-picker-animation-v2"
CLIPS = {"idle", "run", "jump_rise", "jump_fall", "land", "attack", "attack2", "heavy", "hurt", "dash", "heal"}


def compress_frame(source, target):
    base = os.environ.get("FRAMECRAFT_URL", "http://127.0.0.1:8765").rstrip("/")
    options = {"scale": 0.5, "resize_mode": "soft", "algorithm": "lanczos",
               "alpha_threshold": 0, "sharpen": 0}
    with source.open("rb") as file:
        response = requests.post(f"{base}/api/compression/frame", files={"image": file},
                                 data=options, timeout=30)
    response.raise_for_status()
    with Image.open(BytesIO(response.content)) as image:
        if image.format != "PNG" or image.mode != "RGBA" or image.size != (192, 192):
            raise ValueError(f"Unexpected Framecraft output: {source}")
        bbox = image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
        if not bbox or min(bbox[:2]) <= 0 or max(bbox[2:]) >= 192:
            raise ValueError(f"Empty or clipped runtime frame: {source}")
    target.write_bytes(response.content)
    return bbox


def read_direction(direction, allow_partial, staging):
    folder = SOURCE / direction / "delivery"
    data = json.loads((folder / "manifest.json").read_text())
    clips = data.get("clips", data.get(direction, data))
    missing = CLIPS - clips.keys()
    if missing and not allow_partial:
        raise ValueError(f"{direction} missing clips: {sorted(missing)}")
    records = []
    for name, clip in clips.items():
        if name not in CLIPS:
            raise ValueError(f"Unknown clip: {name}")
        if not clip.get("frames"):
            raise ValueError(f"Empty clip: {direction}/{name}")
        if name == "run" and clip.get("stridePixels", 0) <= 0:
            raise ValueError("Run needs a measured positive world stride")
        for frame in clip["frames"]:
            relative = Path(frame["file"])
            if len(relative.parts) != 2 or relative.parts[0] != direction or relative.suffix != ".png":
                raise ValueError(f"Expected {direction}/<frame>.png: {relative}")
            if frame.get("durationMs", 0) <= 0:
                raise ValueError(f"Invalid duration: {relative}")
            source = folder / relative.name
            with Image.open(source) as image:
                if image.mode != "RGBA" or image.size != (384, 384):
                    raise ValueError(f"Expected 384x384 RGBA: {source}")
                alpha = image.getchannel("A")
                bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
                if not bbox or min(bbox[:2]) <= 0 or max(bbox[2:]) >= 384:
                    raise ValueError(f"Empty or clipped pose: {source}")
            target = staging / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            bbox = compress_frame(source, target)
            records.append({"clip": name, "file": str(relative), "bboxAlphaAbove8": bbox,
                            "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
    return clips, {"missing": sorted(missing), "frames": records}


def main():
    allow_partial = "--allow-partial" in sys.argv[1:]
    result = {"version": 1, "canvas": [192, 192], "pivot": [96, 171],
              "scale": 0.55, "directions": {}}
    checks = {"partial": allow_partial, "directions": {}, "gameplayVerified": False,
              "note": "File checks do not establish gait, contact or artistic acceptance."}
    with TemporaryDirectory() as temp:
        staging = Path(temp)
        for direction in ("left", "right"):
            result["directions"][direction], checks["directions"][direction] = read_direction(direction, allow_partial, staging)
        (staging / "animations.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        shutil.copytree(staging, OUTPUT, dirs_exist_ok=True)
    (SOURCE / "export-checks.json").write_text(json.dumps(checks, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {OUTPUT / 'animations.json'}")


if __name__ == "__main__":
    main()
