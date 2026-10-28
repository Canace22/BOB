"""Deterministic scale/anchor export of authored crab key poses; never draws game art."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / "assets/runtime/sprites/crab-boss-prototype"
REVIEW = ROOT / "game/build/qa/crab-art"
CANVAS = (1024, 768)
PIVOT = (400, 704)
# Source body roots and shared anatomical scale, measured against the spiral shell.
# Scaling is uniform in x/y; no per-frame bounding-box normalization or deformation.
SPECS = {
    "idle": ("references/shell_crab_boss.png", 310, 288, 1.11),
    "sweep_tell": ("raw/sweep_tell.png", 850, 833, .40),
    "sweep_active": ("raw/sweep_active.png", 800, 790, .40),
    "slam_tell": ("raw/slam_tell.png", 730, 1140, .50),
    "slam_active": ("raw/slam_active.png", 840, 870, .40),
    "charge": ("raw/charge.png", 850, 810, .40),
}


def bounds(alpha, cutoff):
    return alpha.point(lambda value: 255 if value >= cutoff else 0).getbbox()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REVIEW.mkdir(parents=True, exist_ok=True)
    report = {"canvas": CANVAS, "pivot": PIVOT, "runtimeScale": .8, "assets": []}
    sheet = Image.new("RGB", (420 * len(SPECS), 640))
    draw = ImageDraw.Draw(sheet)
    for index, (key, (path, x, y, scale)) in enumerate(SPECS.items()):
        source = Image.open(HERE / path).convert("RGBA")
        size = tuple(round(value * scale) for value in source.size)
        position = (PIVOT[0] - round(x * scale), PIVOT[1] - round(y * scale))
        assert min(position) >= 0, (key, position)
        assert position[0] + size[0] <= CANVAS[0] and position[1] + size[1] <= CANVAS[1], (key, position, size)
        result = Image.new("RGBA", CANVAS)
        result.alpha_composite(source.resize(size, Image.Resampling.LANCZOS), position)
        target = OUT / f"{key}.png"
        result.save(target, optimize=True)
        alpha = result.getchannel("A")
        info = {"key": key, "file": target.relative_to(ROOT).as_posix(), "source": path,
                "sourceSize": source.size, "sourceRoot": [x, y], "exportScale": scale,
                "size": CANVAS, "pivot": PIVOT, "alphaRange": alpha.getextrema(),
                "alphaBboxes": {str(n): bounds(alpha, n) for n in [1, 8, 32]},
                "sourceAlphaBboxes": {str(n): bounds(source.getchannel("A"), n) for n in [1, 8, 32]},
                "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
        report["assets"].append(info)
        preview = result.resize((410, 307), Image.Resampling.LANCZOS)
        for row, color in enumerate(["#10242e", "#d8d7c8"]):
            draw.rectangle((index * 420, row * 320, (index + 1) * 420, (row + 1) * 320), fill=color)
            sheet.paste(preview, (index * 420, row * 320 + 10), preview)
            draw.text((index * 420 + 8, row * 320 + 8), key, fill="#6c9aa3" if row == 0 else "#263f46")
    (HERE / "export.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    sheet.save(REVIEW / "contact.png")
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
