"""Read-only checks of actual Framecraft PNG results and exported ZIP."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

import numpy as np
from PIL import Image

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
meta = json.loads((root / "game-metadata.json").read_text())
run = json.loads((root / "review/platform-run.json").read_text())
files = [root / name for name in meta["frameFiles"]]
project_root = root / run["projectPath"]
project = json.loads((project_root / "project.json").read_text())
embedded_sources = {frame["name"]: project_root / frame["file"] for frame in project["compression"]["sources"]}
prefer_embedded = "--embedded-source" in sys.argv[2:]
embedded_source_count = 0
records = []
for file in files:
    rgba = np.asarray(Image.open(file).convert("RGBA"))
    original_file = root / meta.get("sourceFramesDirectory", "source/frames") / file.name
    if prefer_embedded or not original_file.is_file():
        original_file = embedded_sources[file.name]
        embedded_source_count += 1
    original = np.asarray(Image.open(original_file).convert("RGBA"))
    alpha = rgba[:, :, 3]
    original_alpha = original[:, :, 3]
    records.append({
        "name": file.name,
        "size": list(rgba.shape[1::-1]),
        "borderAlphaMax": int(max(alpha[0].max(), alpha[-1].max(), alpha[:, 0].max(), alpha[:, -1].max())),
        "alphaZero": int((alpha == 0).sum()),
        "alphaPartial": int(((alpha > 0) & (alpha < 255)).sum()),
        "sourceEmpty": not bool(original_alpha.any()),
        "outputEmpty": not bool(alpha.any()),
        "sourceBorderAlphaMax": int(max(original_alpha[0].max(), original_alpha[-1].max(), original_alpha[:, 0].max(), original_alpha[:, -1].max())),
        "alphaAreaRatioNormalized": float(alpha.sum() / original_alpha.sum() / meta["scale"] ** 2) if original_alpha.any() else None,
    })

with zipfile.ZipFile(root / meta["exportFile"]) as archive:
    manifest = json.loads(archive.read("manifest.json"))
    assert len(manifest["frames"]) == len(files)
    for index, file in enumerate(files):
        assert archive.read(manifest["frames"][index]["filename"]) == file.read_bytes()
assert manifest["fps"] == meta["fps"]
assert abs(manifest["durationMs"] - meta["durationMs"]) < 0.001
assert all(record["size"] == meta["canvas"] for record in records)
assert all(record["sourceEmpty"] == record["outputEmpty"] for record in records)
assert all(record["alphaPartial"] > 0 for record in records if not record["outputEmpty"])
ratios = [record["alphaAreaRatioNormalized"] for record in records if record["alphaAreaRatioNormalized"] is not None]
report = {
    "frames": len(files), "canvas": meta["canvas"], "fps": meta["fps"], "durationMs": meta["durationMs"],
    "platformManifestLoop": manifest["loop"], "gameMetadataLoop": meta["loop"],
    "zipBytesMatchProcessed": True,
    "endpointsEqual": files[0].read_bytes() == files[-1].read_bytes(),
    "uniquePngHashes": len({hashlib.sha256(file.read_bytes()).hexdigest() for file in files}),
    "alphaAreaRatioRange": [min(ratios), max(ratios)] if ratios else None,
    "emptyFramesPreserved": [record["name"] for record in records if record["outputEmpty"]],
    "borderContactFrames": [record["name"] for record in records if record["borderAlphaMax"]],
    "sourceBorderContactFrames": [record["name"] for record in records if record["sourceBorderAlphaMax"]],
    "compressionSettings": run["settings"], "records": records,
    "sourceValidation": "Embedded platform sources" if prefer_embedded else "Original source if available, otherwise embedded platform sources",
    "embeddedSourceFrames": embedded_source_count,
    "externalSourceFrames": len(files) - embedded_source_count,
    "limits": ["Alpha and byte checks cannot establish natural motion or art approval.", "UI playback and game integration are separate checks."],
}
(root / "review/file-checks.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({key: value for key, value in report.items() if key != "records"}, ensure_ascii=False))
