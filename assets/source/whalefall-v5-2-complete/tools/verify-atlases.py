# -*- coding: utf-8 -*-
"""Independently verify atlas pixels, padding, registration and ZIP contents."""
import argparse
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path
from PIL import Image

GROUPS = {"character", "prop", "scenery", "effect", "ui"}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected_assets(catalog):
    return {a["id"]: a for a in catalog["assets"]
            if a.get("status") == "accepted" and a.get("kind") != "background"
            and not re.match(r"^L[01](?!\d)", str(a.get("layer", "")).strip(), re.I)
            and a.get("spriteType", "static") in ("static", "effect", "ui")}


def input_signature(assets):
    keys = ("id", "kind", "file", "sha256", "bbox", "pivot", "world",
            "staticFamilyRegistration", "parts", "nineSlice", "attachments",
            "attachmentPoints", "familyId", "variant", "coversRequirementIds",
            "layer", "parallax", "canvasSpace", "scaleSpace")
    selected = [{key: asset[key] for key in keys if key in asset}
                for asset in sorted(assets.values(), key=lambda a: a["id"])]
    return hashlib.sha256(json.dumps(selected, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def source_expectation(asset, root):
    path = root / asset["file"]
    assert sha(path) == asset["sha256"], "source hash differs from accepted catalog"
    with Image.open(path) as opened:
        source = opened.convert("RGBA")
    rect = (0, 0, source.width, source.height) if asset["kind"] == "ui" else tuple(asset["bbox"])
    left, top, right, bottom = rect
    assert 0 <= left < right <= source.width and 0 <= top < bottom <= source.height, "invalid catalog bbox"
    factor = 1
    if asset["kind"] != "ui":
        registered_ppu = (asset.get("staticFamilyRegistration") or {}).get("sourcePixelsPerUnit")
        if registered_ppu:
            factor = 128 / registered_ppu
        else:
            world = asset["world"]
            factor = world["units"] * 128 / ((right-left) if world["axis"] == "width" else (bottom-top))
    size = (max(1, round((right-left)*factor)), max(1, round((bottom-top)*factor)))
    pixels = source.crop(rect)
    if size != pixels.size:
        pixels = pixels.resize(size, resample=Image.Resampling.LANCZOS)
    return source, pixels, rect, factor


def verify_registration(frame, asset, source, rect, factor, size):
    bob = frame["bob"]
    left, top, right, bottom = rect
    pivot = asset.get("pivot", [source.width/2, source.height])
    if isinstance(pivot, dict):
        pivot = [pivot["x"], pivot["y"]]
    assert bob["originalFile"] == asset["file"], "original file mapping differs"
    assert bob["originalSha256"] == asset["sha256"], "original hash mapping differs"
    assert bob["originalSize"] == {"w": source.width, "h": source.height}, "original size differs"
    assert bob["sourceRect"] == {"x": left, "y": top, "w": right-left, "h": bottom-top}, "sourceRect differs"
    assert bob["originalPivot"] == pivot, "original pivot differs"
    assert abs(bob["scaleFactor"]-factor) < 1e-10, "scale factor differs"
    assert bob["world"] == asset.get("world"), "world dimensions lost"
    assert bob["pixelsPerUnit"] == 128, "world pixel density differs"
    expected_pivot = ((pivot[0]-left)/(right-left), (pivot[1]-top)/(bottom-top))
    assert abs(frame["pivot"]["x"]-expected_pivot[0]) < 1e-10, "horizontal pivot differs"
    assert abs(frame["pivot"]["y"]-expected_pivot[1]) < 1e-10, "vertical pivot differs"
    assert abs(bob["framePivot"]["x"]-expected_pivot[0]*size[0]) < 1e-8, "frame pivot x differs"
    assert abs(bob["framePivot"]["y"]-expected_pivot[1]*size[1]) < 1e-8, "frame pivot y differs"
    for key in ("staticFamilyRegistration", "parts", "nineSlice", "attachments", "attachmentPoints",
                "familyId", "variant", "coversRequirementIds", "layer", "parallax", "canvasSpace", "scaleSpace"):
        if key in asset:
            assert bob.get(key) == asset[key], f"{key} lost or modified"
    if asset["kind"] == "ui":
        assert size == source.size and factor == 1, "UI native canvas changed"


def verify_gutter(atlas, expected, x, y, w, h):
    actual, source = atlas.load(), expected.load()
    # Check every replicated border pixel, including four corners.
    for dy in range(-2, h+2):
        for dx in (range(-2, w+2) if dy < 0 or dy >= h else (-2, -1, w, w+1)):
            sx, sy = min(max(dx, 0), w-1), min(max(dy, 0), h-1)
            assert actual[x+dx, y+dy] == source[sx, sy], f"extrusion mismatch at {dx},{dy}"
    # The remaining two pixels of the four-pixel padding must be transparent.
    for dy in range(-4, h+4):
        for dx in (range(-4, w+4) if dy < -2 or dy >= h+2 else (-4, -3, w+2, w+3)):
            assert actual[x+dx, y+dy][3] == 0, f"outer padding not transparent at {dx},{dy}"


def overlap(a, b):
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


def verify_frame(id, frame, asset, root, atlas):
    source, expected, rect, factor = source_expectation(asset, root)
    x, y, w, h = (frame["frame"][k] for k in ("x", "y", "w", "h"))
    assert all(isinstance(v, int) for v in (x, y, w, h)), "frame rectangle is not integer"
    assert w > 0 and h > 0 and expected.size == (w, h), "frame dimensions differ from source normalization"
    assert 4 <= x and 4 <= y and x+w+4 <= atlas.width and y+h+4 <= atlas.height, "padding outside atlas"
    assert frame["rotated"] is False, "unexpected rotation"
    actual = atlas.crop((x, y, x+w, y+h))
    assert actual.tobytes() == expected.tobytes(), "independent frame pixel comparison failed"
    verify_registration(frame, asset, source, rect, factor, (w, h))
    verify_gutter(atlas, expected, x, y, w, h)
    return (x-4, y-4, x+w+4, y+h+4)


def verify_page(record, destination, expected, root, lookup, errors, seen):
    def error(scope, message):
        errors.append({"scope": scope, "message": str(message)})
    name = record["json"]
    page = json.loads((destination/name).read_text(encoding="utf-8"))
    with Image.open(destination/record["image"]) as opened:
        atlas = opened.convert("RGBA")
    try:
        assert 0 < atlas.width <= 4096 and 0 < atlas.height <= 4096, "page exceeds 4096"
        assert (record["width"], record["height"]) == atlas.size, "index page size differs"
        assert sha(destination/record["image"]) == record["sha256"], "page hash differs"
        assert page["meta"]["size"] == {"w": atlas.width, "h": atlas.height}, "page metadata size differs"
        assert page["meta"]["padding"] == 4 and page["meta"]["extrusion"] == 2, "padding contract differs"
        assert page["meta"]["pixelsPerUnit"] == 128, "page pixel density differs"
        assert page["meta"]["group"] == record["group"] and record["group"] in GROUPS, "page grouping differs"
        assert page["meta"]["image"] == record["image"], "page image path differs"
        assert page["animations"] == {}, "static page contains animations"
        assert len(page["frames"]) == record["count"], "page count differs"
    except AssertionError as exc:
        error(name, exc)
    allocations = []
    for id, frame in page["frames"].items():
        try:
            assert id not in seen, "frame occurs more than once"
            seen.add(id)
            assert id in expected, "unexpected or excluded asset packed"
            assert expected[id]["kind"] == record["group"], "asset in wrong group"
            assert lookup[id] == {"image": record["image"], "json": record["json"], "group": record["group"]}, "index lookup differs"
            rectangle = verify_frame(id, frame, expected[id], root, atlas)
            for previous_id, previous in allocations:
                assert not overlap(rectangle, previous), f"allocation overlaps {previous_id}"
            allocations.append((id, rectangle))
        except (AssertionError, KeyError, ValueError) as exc:
            error(id, exc)
    return len(page["frames"])


def verify_archive(index, destination):
    names = {"index.json"} | {p[k] for p in index["pages"] for k in ("image", "json")}
    with zipfile.ZipFile(destination/index["archive"]) as archive:
        assert archive.testzip() is None, "archive CRC failure"
        assert set(archive.namelist()) == names and len(archive.namelist()) == len(names), "archive membership differs"
        for name in names:
            assert archive.read(name) == (destination/name).read_bytes(), f"archive stale file: {name}"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--catalog", default="assets/catalog.json")
    parser.add_argument("--output", default="assets/runtime/sprites/whalefall-complete-atlas")
    args = parser.parse_args()
    root, destination = args.root.resolve(), args.root.resolve()/args.output
    catalog_path = root/args.catalog
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    index = json.loads((destination/"index.json").read_text(encoding="utf-8"))
    expected, errors, seen = expected_assets(catalog), [], set()
    def check(condition, message):
        if not condition:
            errors.append({"scope": "index", "message": message})
    check(index["inputSignature"] == input_signature(expected), "atlas input assets changed after packing")
    check(index["animations"] == {}, "index contains animations")
    check(index["padding"] == 4 and index["extrusion"] == 2 and index["pixelsPerUnit"] == 128, "atlas contract differs")
    check(set(index["frames"]) == set(expected), "index assets differ from accepted static catalog")
    check(index["assetCount"] == len(expected), "asset count differs")
    for record in index["pages"]:
        verify_page(record, destination, expected, root, index["frames"], errors, seen)
    check(seen == set(expected), "packed frames missing or extra")
    try:
        verify_archive(index, destination)
    except (AssertionError, zipfile.BadZipFile) as exc:
        errors.append({"scope": "archive", "message": str(exc)})
    report = dict(passed=not errors, checkedAssets=len(seen), expectedAssets=len(expected),
                  checkedPages=len(index["pages"]), checks=[
                      "accepted static coverage; backgrounds/L0/L1 excluded",
                      "native UI canvas/nineSlice and shared family registration preserved",
                      "independent source crop/resample equals every atlas RGBA pixel",
                      "frame allocations bounded and non-overlapping",
                      "all extrusion pixels copied; outer padding transparent; ZIP bytes match"],
                  errors=errors, scope="Static atlas technical verification; no gameplay, animation or user art acceptance.")
    (destination/"verification-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())

