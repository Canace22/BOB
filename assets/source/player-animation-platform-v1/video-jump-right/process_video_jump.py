"""Native video crops followed by unchanged Framecraft /api/matte requests."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import time

import httpx
from PIL import Image

TRACKS = [
    (190, 620, 324), (192, 588, 275), (194, 572, 253), (196, 562, 240),
    (198, 549, 236), (200, 529, 229), (202, 521, 229), (204, 491, 225),
    (206, 485, 224), (208, 481, 241), (210, 474, 254), (212, 460, 307),
    (214, 463, 335), (216, 460, 344), (218, 462, 346), (220, 461, 342),
    (222, 460, 341), (224, 460, 340), (226, 460, 341), (228, 459, 343),
]
SIZE = [190, 150]
TRACK_ANCHOR = [70, 79]
OPTIONS = {"mode": "birefnet", "device": "cpu", "resolution": "512", "birefnet_variant": "lite", "key_color": "#426d6f", "spill": "0"}

parser = argparse.ArgumentParser()
parser.add_argument("ffmpeg")
parser.add_argument("--start", type=int, default=0)
parser.add_argument("--end", type=int, default=len(TRACKS))
args = parser.parse_args()
out = Path(__file__).resolve().parent
source = out.parent.parent / "crab-animation-platform-v1/reference/user-crab-source-20261030.mp4"
for name in ["source", "frames", "requests", "review"]:
    (out / name).mkdir(exist_ok=True)

timeline = []
for index, (source_frame, x, y) in enumerate(TRACKS):
    name = f"frame-{index + 1:03}.png"
    crop = [x - TRACK_ANCHOR[0], y - TRACK_ANCHOR[1], *SIZE]
    timeline.append({"index": index, "file": "frames/" + name, "sourceFile": "source/" + name, "sourceFrameZeroBased": source_frame, "sourceTimeSeconds": source_frame / 24, "sourceTrackAnchorPx": [x, y], "crop": crop, "trackAnchorPx": TRACK_ANCHOR, "durationMs": 1000 / 12})
metadata = {
    "name": "video-jump-right-partial", "status": "candidate; processing/visual review required",
    "source": "../../crab-animation-platform-v1/reference/user-crab-source-20261030.mp4",
    "sourceFps": 24, "sourceCanvas": [1520, 608], "canvas": SIZE, "fps": 12,
    "loop": False, "trackAnchorPx": TRACK_ANCHOR, "gamePivotPx": None, "gamePivotStatus": "not verified", "groundLine": None,
    "direction": "facing right while source screen position travels left",
    "trackingMethod": "Manual per-sample annotation of the orange waist/chest lantern center as a visible tracking marker, not anatomical root. Integer translation only, no bbox normalization, scaling or per-frame foot alignment.",
    "sourceTrackTrajectoryRetained": True,
    "missingPhases": ["grounded preparation and initial takeoff before frame190", "confirmed transition into game's existing idle"],
    "frames": timeline,
}
(out / "timeline.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")

with httpx.Client(timeout=600, trust_env=False) as client:
    for row in timeline[args.start:args.end]:
        crop = row["crop"]
        original = out / row["sourceFile"]
        target = out / row["file"]
        # Convert before crop so YUV420 chroma alignment cannot round odd crop coordinates.
        vf = f"select='eq(n,{row['sourceFrameZeroBased']})',format=rgb24,crop={crop[2]}:{crop[3]}:{crop[0]}:{crop[1]}"
        subprocess.run([args.ffmpeg, "-v", "error", "-y", "-i", str(source), "-vf", vf, "-frames:v", "1", str(original)], check=True)
        started = time.monotonic()
        with original.open("rb") as stream:
            response = client.post("http://127.0.0.1:8766/api/matte", data=OPTIONS, files={"image": (original.name, stream, "image/png")})
        response.raise_for_status()
        if not response.headers.get("content-type", "").startswith("image/png"):
            raise RuntimeError("Framecraft did not return PNG")
        target.write_bytes(response.content)
        record = {"endpoint": "/api/matte", "request": OPTIONS, "sourceFrameZeroBased": row["sourceFrameZeroBased"], "crop": crop, "elapsedSeconds": round(time.monotonic() - started, 3), "responseHeaders": dict(response.headers), "inputSha256": hashlib.sha256(original.read_bytes()).hexdigest(), "outputSha256": hashlib.sha256(response.content).hexdigest()}
        alpha = Image.open(target).getchannel("A")
        record["alphaRange"] = alpha.getextrema()
        record["alphaBbox"] = alpha.getbbox()
        (out / "requests" / f"{target.stem}.json").write_text(json.dumps(record, indent=2) + "\n")
        print(json.dumps({"frame": row["index"] + 1, "sourceFrame": row["sourceFrameZeroBased"], "elapsedSeconds": record["elapsedSeconds"]}), flush=True)
        if alpha.getbbox() is None:
            raise RuntimeError(f"Frame {row['index'] + 1} was completely removed; stop and inspect before continuing")
