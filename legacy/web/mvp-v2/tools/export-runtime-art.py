"""Build small V2 WebP derivatives without editing the library originals.

Requires Python/Pillow with WebP support and Node.js. Run from any directory:
    python mvp-v2/tools/export-runtime-art.py
The selected IDs and room mapping come from art-manifest.js; original pixels,
dimensions, pivots and attribution always come from assets/catalog.json.
"""
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image, features


ROOT = Path(__file__).resolve().parents[4]
GAME = ROOT / "legacy/web/mvp-v2"
MANIFEST = GAME / "art-manifest.js"
OUTPUT = ROOT / "assets/runtime/sprites/whalefall-v2-optimized"
PLATFORMS = {
    "r1-tongue-ledge", "r1-weight-membrane", "r1-weight-membrane-pressed",
    "r2-membrane-platform", "r3-bank-platform", "r4-bone-platform",
}
FOREGROUND = {
    "r1-baleen-shadow", "r2-foreground-membrane",
    "r3-foreground-fold", "r4-foreground-bone",
}
CAMPAIGN_SCENERY = {"r1-wound-section", "r1-esophagus-fold", "r1-baleen-curtain"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def limit(asset):
    identity = asset["id"]
    if asset["kind"] == "background":
        return (1600, 900)
    if identity in {"tide-picker", "tide-picker-left"}:
        return (256, 256)
    if identity in {"shell-camp", "gate-shell-crab"}:
        return (512, 512)
    if identity in PLATFORMS or identity in FOREGROUND or identity in CAMPAIGN_SCENERY:
        return (1024, 1024)
    return (384, 384)


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def export_legacy():
    """Title and existing fallback art use compact derivatives as well."""
    inputs = [
        (ROOT / "docs/鲸腹遗城原画集/V2/images/A01_鲸落万物生_世界主视觉.png", GAME / "assets/title-v2.webp", (1600, 900)),
        (GAME / "assets/abyss-backdrop-v2.png", GAME / "assets/abyss-backdrop-v2.webp", (1600, 900)),
        # Keep source pixels for the existing fallback crop contract in scenes.js.
        (GAME / "assets/bone-ledge-v2.png", GAME / "assets/bone-ledge-v2.webp", None),
    ]
    result = []
    for source, target, bounds in inputs:
        original_hash = digest(source)
        with Image.open(source) as original:
            image = original.convert("RGBA")
            if bounds:
                image.thumbnail(bounds, Image.Resampling.LANCZOS)
            image.save(target, "WEBP", quality=82, method=6, exact=True)
            size = image.size
        assert digest(source) == original_hash, source
        result.append({"source": source.relative_to(ROOT).as_posix(), "export": target.relative_to(ROOT).as_posix(), "size": list(size), "sourceBytes": source.stat().st_size, "exportBytes": target.stat().st_size})
    return result


def main():
    if not features.check("webp"):
        raise RuntimeError("This Pillow build has no WebP encoder")
    node = shutil.which("node")
    if not node:
        raise RuntimeError("Node.js is required to read the runtime selection")
    selected = json.loads(subprocess.check_output([
        node, "--input-type=module", "-e",
        "const m=await import(process.argv[1]); console.log(JSON.stringify({ids:Object.keys(m.ART_ASSETS),regions:m.REGION_ART}));",
        MANIFEST.as_uri(),
    ], text=True, encoding="utf-8"))
    catalog = json.loads((ROOT / "assets/catalog.json").read_text(encoding="utf-8"))
    library = {a["id"]: a for a in catalog["assets"]}
    OUTPUT.mkdir(parents=True, exist_ok=True)
    report_path = GAME / "output/art-optimization/export-report.json"
    previous = json.loads(report_path.read_text(encoding="utf-8")) if report_path.exists() else {}
    prior = {a["id"]: a for a in previous.get("assets", [])} if previous.get("quality") == 82 else {}
    assets, reports = {}, []
    for identity in selected["ids"]:
        original = library[identity]
        source = ROOT / original["file"]
        source_digest = digest(source)
        destination = OUTPUT / f"{identity}.webp"
        with Image.open(source) as source_image:
            assert source_image.size == (original["width"], original["height"]), identity
            max_width, max_height = limit(original)
            ratio = min(1, max_width / source_image.width, max_height / source_image.height)
            size = (max(1, round(source_image.width * ratio)), max(1, round(source_image.height * ratio)))
            cached = prior.get(identity, {})
            unchanged = (destination.exists() and cached.get("sourceSha256") == source_digest
                         and cached.get("exportSize") == list(size)
                         and cached.get("exportSha256") == digest(destination))
            if not unchanged:
                image = source_image.convert("RGBA").resize(size, Image.Resampling.LANCZOS)
                image.save(destination, "WEBP", quality=82, method=6, exact=True)
        with Image.open(destination) as exported:
            assert exported.size == size and exported.format == "WEBP", identity
            # A transparent source must remain transparent after export.
            if original.get("alphaRange", [255])[0] == 0:
                assert exported.convert("RGBA").getchannel("A").getextrema()[0] == 0, identity
        assert digest(source) == source_digest, f"Original changed: {identity}"
        sx, sy = size[0] / original["width"], size[1] / original["height"]
        assets[identity] = {
            "id": identity,
            "src": "../" + destination.relative_to(ROOT).as_posix(),
            "sourceFile": original["file"],
            "sourceWidth": original["width"], "sourceHeight": original["height"],
            "exportScale": sx, "exportScaleY": sy,
            "width": size[0], "height": size[1],
            "bbox": [n * (sx if i % 2 == 0 else sy) for i, n in enumerate(original["bbox"])],
            "pivot": [original["pivot"][0] * sx, original["pivot"][1] * sy],
            "world": original["world"],
            "source": {"region": original["region"], "batchId": original["source"]["batchId"], "references": original["source"]["references"]},
        }
        reports.append({
            "id": identity, "source": original["file"], "sourceSha256": source_digest,
            "export": destination.relative_to(ROOT).as_posix(), "exportSha256": digest(destination),
            "sourceSize": [original["width"], original["height"]], "exportSize": list(size),
            "sourceBytes": source.stat().st_size, "exportBytes": destination.stat().st_size,
        })
    header = """// Generated by tools/export-runtime-art.py from assets/catalog.json.
// Original PNGs and source coordinates are preserved in the library.
// V2 uses small WebP derivatives; bbox/pivot are scaled into exported pixels.
// Explicit source-pixel attachment/crop coordinates must apply exportScale(X/Y).
// Full background canvases and separate left/right poses remain intact.
export const ART_ASSETS = {
"""
    lines = [header]
    for identity, asset in assets.items():
        lines.append(f"  {compact(identity)}: {{\n")
        for keys in [
            ("id", "src"), ("sourceFile",), ("sourceWidth", "sourceHeight"),
            ("exportScale", "exportScaleY"), ("width", "height"),
            ("bbox", "pivot"), ("world",), ("source",),
        ]:
            lines.append("    " + ", ".join(f"{k}: {compact(asset[k])}" for k in keys) + ",\n")
        lines.append("  },\n")
    lines.append("};\n\n// V2 room order differs from source region numbering.\nexport const REGION_ART = ")
    lines.append(json.dumps(selected["regions"], ensure_ascii=False, indent=2) + ";\n")
    MANIFEST.write_text("".join(lines), encoding="utf-8")
    report = {
        "format": "WebP", "quality": 82, "count": len(reports),
        "sourceBytes": sum(item["sourceBytes"] for item in reports),
        "exportBytes": sum(item["exportBytes"] for item in reports),
        "sourcePixels": sum(item["sourceSize"][0] * item["sourceSize"][1] for item in reports),
        "exportPixels": sum(item["exportSize"][0] * item["exportSize"][1] for item in reports),
        "assets": reports,
        "legacy": export_legacy(),
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "assets"}, indent=2))


if __name__ == "__main__":
    main()
