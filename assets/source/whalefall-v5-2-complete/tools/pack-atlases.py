# -*- coding: utf-8 -*-
"""Pack accepted BOB static assets; originals and catalog are never modified."""
import argparse
import hashlib
import json
import math
import re
import zipfile
from pathlib import Path
from PIL import Image

GROUPS = ("character", "prop", "scenery", "effect", "ui")
PPU, PADDING, EXTRUSION = 128, 4, 2


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def exclusion(asset):
    if asset.get("status") != "accepted":
        return "not accepted"
    if asset.get("kind") == "background":
        return "background stays separate"
    if re.match(r"^L[01](?!\d)", str(asset.get("layer", "")).strip(), re.I):
        return "L0/L1 stays separate"
    if asset.get("spriteType", "static") not in ("static", "ui", "effect"):
        return "not a static sprite"
    return None


def input_signature(assets):
    keys = ("id", "kind", "file", "sha256", "bbox", "pivot", "world",
            "staticFamilyRegistration", "parts", "nineSlice", "attachments",
            "attachmentPoints", "familyId", "variant", "coversRequirementIds",
            "layer", "parallax", "canvasSpace", "scaleSpace")
    selected = [{key: asset[key] for key in keys if key in asset}
                for asset in sorted(assets, key=lambda a: a["id"]) if exclusion(asset) is None]
    return hashlib.sha256(json.dumps(selected, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def prepare(asset, root, maximum):
    group = asset["kind"]
    if group not in GROUPS:
        raise ValueError(f"Unsupported kind: {asset['id']} {group}")
    path = root / asset["file"]
    if asset.get("sha256") != digest(path):
        raise ValueError(f"Source hash changed: {asset['id']}")
    with Image.open(path) as opened:
        source = opened.convert("RGBA")
    ui = group == "ui"
    rect = [0, 0, source.width, source.height] if ui else asset["bbox"]
    left, top, right, bottom = rect
    if not (0 <= left < right <= source.width and 0 <= top < bottom <= source.height):
        raise ValueError(f"Invalid source rectangle: {asset['id']}")
    scale = 1.0
    if not ui:
        registration = asset.get("staticFamilyRegistration") or {}
        if registration.get("sourcePixelsPerUnit"):
            scale = PPU / float(registration["sourcePixelsPerUnit"])
        else:
            world = asset.get("world") or {}
            if world.get("axis") not in ("width", "height") or world.get("units", 0) <= 0:
                raise ValueError(f"World size missing: {asset['id']}")
            axis_pixels = right - left if world["axis"] == "width" else bottom - top
            scale = float(world["units"]) * PPU / axis_pixels
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError(f"Invalid scale: {asset['id']}")
    size = (max(1, round((right - left) * scale)), max(1, round((bottom - top) * scale)))
    if max(size) + PADDING * 2 > maximum:
        raise ValueError(f"{asset['id']}: {size} exceeds page {maximum}; do not shrink native UI or world scale")
    pixels = source.crop(rect)
    if pixels.size != size:
        pixels = pixels.resize(size, Image.Resampling.LANCZOS)
    pivot = asset.get("pivot", [source.width / 2, source.height])
    if isinstance(pivot, dict):
        pivot = [pivot["x"], pivot["y"]]
    return dict(asset=asset, pixels=pixels, rect=rect, originalSize=source.size,
                scale=scale, pivot=pivot, w=size[0], h=size[1])


def pack_group(entries, maximum):
    pages = []
    for entry in sorted(entries, key=lambda e: (-e["h"], -e["w"], e["asset"]["id"])):
        aw, ah = entry["w"] + PADDING * 2, entry["h"] + PADDING * 2
        placed = False
        for page in pages:
            for row in page["rows"]:
                if ah <= row["height"] and row["x"] + aw <= maximum:
                    entry.update(x=row["x"] + PADDING, y=row["y"] + PADDING)
                    row["x"] += aw
                    placed = True
                    break
            if not placed and page["usedHeight"] + ah <= maximum:
                entry.update(x=PADDING, y=page["usedHeight"] + PADDING)
                page["rows"].append(dict(x=aw, y=page["usedHeight"], height=ah))
                page["usedHeight"] += ah
                placed = True
            if placed:
                page["entries"].append(entry)
                break
        if not placed:
            entry.update(x=PADDING, y=PADDING)
            pages.append(dict(entries=[entry], rows=[dict(x=aw, y=0, height=ah)], usedHeight=ah))
    return pages


def extrude(canvas, pixels, x, y):
    w, h = pixels.size
    canvas.paste(pixels, (x, y))
    canvas.paste(pixels.crop((0, 0, w, 1)).resize((w, EXTRUSION), Image.Resampling.NEAREST), (x, y - EXTRUSION))
    canvas.paste(pixels.crop((0, h - 1, w, h)).resize((w, EXTRUSION), Image.Resampling.NEAREST), (x, y + h))
    canvas.paste(pixels.crop((0, 0, 1, h)).resize((EXTRUSION, h), Image.Resampling.NEAREST), (x - EXTRUSION, y))
    canvas.paste(pixels.crop((w - 1, 0, w, h)).resize((EXTRUSION, h), Image.Resampling.NEAREST), (x + w, y))
    for sx, dx in [(0, x - EXTRUSION), (w - 1, x + w)]:
        for sy, dy in [(0, y - EXTRUSION), (h - 1, y + h)]:
            canvas.paste(pixels.getpixel((sx, sy)), (dx, dy, dx + EXTRUSION, dy + EXTRUSION))


def frame_metadata(entry):
    asset = entry["asset"]
    left, top, right, bottom = entry["rect"]
    w, h = entry["w"], entry["h"]
    pivot = entry["pivot"]
    bob = dict(originalFile=asset["file"], originalSha256=asset["sha256"],
               originalSize=dict(w=entry["originalSize"][0], h=entry["originalSize"][1]),
               sourceRect=dict(x=left, y=top, w=right-left, h=bottom-top),
               originalPivot=pivot, world=asset.get("world"), pixelsPerUnit=PPU,
               scaleFactor=entry["scale"], resizeKernel="LANCZOS" if asset["kind"] != "ui" else "none",
               spriteType="static", pivotSpace="frame-normalized",
               framePivot=dict(x=(pivot[0]-left)*w/(right-left), y=(pivot[1]-top)*h/(bottom-top)))
    for key in ("staticFamilyRegistration", "parts", "nineSlice", "attachments", "attachmentPoints",
                "familyId", "variant", "coversRequirementIds", "layer", "parallax", "canvasSpace", "scaleSpace"):
        if key in asset:
            bob[key] = asset[key]
    return dict(frame=dict(x=entry["x"], y=entry["y"], w=w, h=h), rotated=False,
                trimmed=False, spriteSourceSize=dict(x=0, y=0, w=w, h=h), sourceSize=dict(w=w, h=h),
                pivot=dict(x=(pivot[0]-left)/(right-left), y=(pivot[1]-top)/(bottom-top)), bob=bob)


def write_page(page, group, number, destination, maximum):
    width = min(maximum, 2 ** math.ceil(math.log2(max(r["x"] for r in page["rows"]))))
    height = min(maximum, 2 ** math.ceil(math.log2(page["usedHeight"])))
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    frames = {}
    for entry in page["entries"]:
        extrude(image, entry["pixels"], entry["x"], entry["y"])
        frames[entry["asset"]["id"]] = frame_metadata(entry)
    stem = f"{group}-{number:03d}"
    png, metadata = destination / (stem + ".png"), destination / (stem + ".json")
    image.save(png)
    write_json(metadata, dict(frames=frames, animations={}, meta=dict(
        app="BOB multi-page static atlas", image=png.name, format="RGBA8888",
        size=dict(w=width, h=height), group=group, type="static-atlas",
        pixelsPerUnit=PPU, padding=PADDING, extrusion=EXTRUSION,
        note="Independent static assets; no animation frames. World assets contain normalized visible crops; UI retains native canvas. Original pixels and pivot are in bob.")))
    return dict(group=group, page=number, image=png.name, json=metadata.name,
                width=width, height=height, count=len(frames), sha256=digest(png)), frames


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--catalog", default="assets/catalog.json")
    parser.add_argument("--output", default="assets/runtime/sprites/whalefall-complete-atlas")
    parser.add_argument("--max-page-size", type=int, default=4096)
    args = parser.parse_args()
    if not 16 <= args.max_page_size <= 4096:
        parser.error("--max-page-size must be between 16 and 4096")
    root = args.root.resolve()
    catalog_path, destination = root / args.catalog, root / args.output
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    grouped, excluded, seen = {g: [] for g in GROUPS}, [], set()
    for asset in catalog["assets"]:
        if asset["id"] in seen:
            raise ValueError(f"Duplicate catalog id: {asset['id']}")
        seen.add(asset["id"])
        reason = exclusion(asset)
        if reason:
            excluded.append(dict(id=asset["id"], reason=reason))
            continue
        entry = prepare(asset, root, args.max_page_size)
        grouped[asset["kind"]].append(entry)
    if not any(grouped.values()):
        raise ValueError("No accepted static assets to pack")
    destination.mkdir(parents=True, exist_ok=True)
    pages, lookup = [], {}
    for group in GROUPS:
        for number, page in enumerate(pack_group(grouped[group], args.max_page_size), 1):
            record, frames = write_page(page, group, number, destination, args.max_page_size)
            pages.append(record)
            for id in frames:
                lookup[id] = dict(image=record["image"], json=record["json"], group=group)
    index = dict(schemaVersion=1, type="static-multipage-atlas", catalog=args.catalog,
                 catalogRevision=catalog.get("revision"), catalogSha256=digest(catalog_path),
                 inputSignature=input_signature(catalog["assets"]),
                 pixelsPerUnit=PPU, padding=PADDING, extrusion=EXTRUSION,
                 maxPageSize=args.max_page_size, assetCount=len(lookup),
                 pages=pages, frames=lookup, animations={}, excluded=excluded,
                 archive="whalefall-complete-atlas.zip")
    write_json(destination / "index.json", index)
    files = ["index.json"] + [p[k] for p in pages for k in ("image", "json")]
    with zipfile.ZipFile(destination / index["archive"], "w", zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(files):
            info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, (destination / name).read_bytes())
    print(json.dumps(dict(assets=len(lookup), pages=len(pages), output=str(destination), excluded=len(excluded))))


if __name__ == "__main__":
    main()

