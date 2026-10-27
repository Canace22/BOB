# -*- coding: utf-8 -*-
"""Read-only delivery audit; writes only the requested integrity report."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import runpy
import xml.etree.ElementTree as ET
from PIL import Image


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def run(root, expected_counts):
    batch = root / "assets/source/whalefall-v5-2-complete"
    catalog_path, coverage_path = root / "assets/catalog.json", batch / "coverage.json"
    catalog, coverage = read_json(catalog_path), read_json(coverage_path)
    assets = {a["id"]: a for a in catalog["assets"]}
    requirements = {r["id"]: r for r in coverage["requirements"]}
    rooms = {r["id"]: r for r in coverage["rooms"]}
    errors, warnings, checked_files, occurrence_counts = [], [], {}, Counter()

    def check(condition, scope, message):
        if not condition:
            errors.append({"scope": scope, "message": message})

    def accessible(relative, role, scope):
        occurrence_counts[role] += 1
        path = (root / relative).resolve()
        check(path.is_relative_to(root), scope, f"{role} is outside project: {relative}")
        if path in checked_files:
            return checked_files[path]
        try:
            raw = path.read_bytes()
            assert raw, "empty file"
            info = {"path": str(path.relative_to(root)), "bytes": len(raw)}
            suffix = path.suffix.lower()
            if suffix in (".png", ".jpg", ".jpeg", ".webp"):
                with Image.open(path) as image:
                    info["dimensions"] = list(image.size)
                    image.verify()
            elif suffix == ".svg":
                svg = ET.fromstring(raw)
                assert svg.tag.rsplit("}", 1)[-1] == "svg", "source is not SVG"
                info["svgValid"] = True
            elif role == "prompt":
                assert raw.decode("utf-8").strip(), "empty prompt"
            checked_files[path] = info
            return info
        except (OSError, ValueError, AssertionError, ET.ParseError, UnicodeDecodeError) as exc:
            errors.append({"scope": scope, "message": f"{role} inaccessible/invalid: {relative}: {exc}"})
            checked_files[path] = None
            return None

    check(len(catalog["assets"]) == len(assets), "catalog", "duplicate asset IDs")
    check(len(coverage["requirements"]) == len(requirements), "coverage", "duplicate requirement IDs")
    check(len(coverage["rooms"]) == len(rooms), "rooms", "duplicate room IDs")
    check(len(assets) == expected_counts["assets"], "catalog", "asset count differs from final delivery")
    check(len(requirements) == expected_counts["requirements"], "coverage", "requirement count differs")
    check(len(rooms) == expected_counts["rooms"], "rooms", "room count differs")

    asset_checks, originals_ok = [], 0
    for asset in catalog["assets"]:
        id = asset["id"]
        info = accessible(asset["file"], "originalPng", id)
        hash_ok = bool(info) and digest(root / asset["file"]) == asset["sha256"]
        size_ok = bool(info) and info.get("dimensions") == [asset["width"], asset["height"]]
        check(hash_ok, id, "original PNG hash differs from catalog")
        check(size_ok, id, "original PNG dimensions differ from catalog")
        check(asset.get("status") == "accepted", id, "asset is not accepted")
        check(asset.get("spriteType") in ("static", "background", "effect", "ui"), id, "asset is not registered static")
        source = asset.get("source", {})
        check(bool(source.get("references")), id, "source references are absent")
        check(bool(source.get("prompts") or source.get("sourceFiles")), id, "no generation prompt or editable source")
        for key, role in (("references", "reference"), ("prompts", "prompt"), ("sourceFiles", "editableSource")):
            for relative in source.get(key, []):
                accessible(relative, role, id)
        check(bool(asset.get("thumbnail")), id, "thumbnail missing from catalog")
        if asset.get("thumbnail"):
            accessible(asset["thumbnail"], "thumbnail", id)
        asset_checks.append({"id": id, "hashMatches": hash_ok, "dimensionsMatch": size_ok})

    baseline_path = root / "assets/source/whalefall-v5-2-static-01/original-manifest.json"
    baseline = read_json(baseline_path)["assets"]
    check(len(baseline) == 12, "baseline", "original baseline does not contain 12 assets")
    baseline_checks = []
    for original in baseline:
        mapped = [a for a in catalog["assets"] if a.get("source", {}).get("originalId") == original["id"]]
        check(len(mapped) == 1, original["id"], "original 12 mapping missing/ambiguous")
        if len(mapped) != 1:
            continue
        current = mapped[0]
        same = current["sha256"] == original["sha256"] == digest(root / current["file"])
        check(same, current["id"], "original baseline pixels changed")
        check([current["width"], current["height"]] == [original["width"], original["height"]],
              current["id"], "original baseline dimensions changed")
        originals_ok += int(same)
        baseline_checks.append({"originalId": original["id"], "assetId": current["id"], "unchanged": same})

    requirement_checks = []
    for id, requirement in requirements.items():
        outputs = requirement.get("outputIds", [])
        check(bool(outputs), id, "requirement has no actual output IDs")
        check(requirement.get("outputPlanComplete") is True, id, "static output plan incomplete")
        ok = True
        for output in outputs:
            if output not in assets:
                check(False, id, f"dangling output: {output}")
                ok = False
                continue
            asset = assets[output]
            valid = asset.get("status") == "accepted" and (root / asset["file"]).is_file()
            check(valid, id, f"output is missing or not accepted: {output}")
            ok &= valid
        for room in requirement.get("rooms", []):
            check(room in rooms, id, f"dangling room reference: {room}")
        requirement_checks.append({"id": id, "outputCount": len(outputs), "allOutputsAcceptedAndPresent": ok})

    source_rooms = {r["id"] for r in read_json(batch / "inventory/full-scene-inventory.json")["rooms"]}
    check(set(rooms) == source_rooms, "rooms", "coverage room set differs from source inventory")
    room_links = 0
    for id, room in rooms.items():
        check(bool(room.get("requirementIds")), id, "room has no mapped requirements")
        for requirement in room.get("requirementIds", []):
            room_links += 1
            check(requirement in requirements, id, f"dangling requirement: {requirement}")
        if room.get("reference"):
            name = Path(room["reference"]).name
            accessible(str((batch / "references" / name).relative_to(root)), "roomReference", id)
    for asset in catalog["assets"]:
        for room in asset.get("rooms", []):
            check(room in rooms, asset["id"], f"dangling asset room: {room}")

    atlas_path = root / catalog["atlas"]["json"]
    destination = atlas_path.parent
    index = read_json(atlas_path)
    verifier_path = batch / "tools/verify-atlases.py"
    verifier = runpy.run_path(str(verifier_path), run_name="delivery_independent_atlas_verifier")
    expected = verifier["expected_assets"](catalog)
    atlas_errors, seen = [], set()
    check(index["inputSignature"] == verifier["input_signature"](expected), "atlas", "packing input signature stale")
    check(set(index["frames"]) == set(expected), "atlas", "index differs from accepted static assets")
    check(index["assetCount"] == expected_counts["atlasFrames"], "atlas", "atlas asset count differs")
    check(index["animations"] == {}, "atlas", "static index contains animation sequences")
    for page in index["pages"]:
        verifier["verify_page"](page, destination, expected, root, index["frames"], atlas_errors, seen)
    check(seen == set(expected), "atlas", "missing/extra packed frames")
    try:
        verifier["verify_archive"](index, destination)
    except (AssertionError, OSError) as exc:
        atlas_errors.append({"scope": "archive", "message": str(exc)})
    errors.extend(atlas_errors)
    backgrounds = {a["id"] for a in catalog["assets"] if a["kind"] == "background"}
    check(len(backgrounds) == expected_counts["backgrounds"], "atlas", "background count differs")
    check(not backgrounds.intersection(index["frames"]), "atlas", "background packed into atlas")
    prior_atlas_report = read_json(destination / "verification-report.json")
    check(prior_atlas_report.get("passed") is True and not prior_atlas_report.get("errors"),
          "atlas", "recorded atlas verification is not passed")
    check(prior_atlas_report.get("checkedAssets") == len(expected), "atlas", "recorded atlas report is stale")
    for key in ("image", "json", "zip"):
        if catalog["atlas"].get(key):
            accessible(catalog["atlas"][key], "atlasEntry", "atlas")
    unassembled = sum(not r.get("assemblyVerified") for r in rooms.values())
    if unassembled:
        warnings.append(f"{unassembled} room records have not claimed full playable room assembly; this audit validates mappings only.")

    return {
        "schemaVersion": 1, "auditedAt": datetime.now(timezone.utc).isoformat(),
        "passed": not errors,
        "scope": "Project-contained static delivery integrity; no animation, gameplay, 36-room assembly or human art acceptance claim.",
        "inputs": {"catalog": "assets/catalog.json", "catalogRevision": catalog["revision"],
                   "catalogSha256": digest(catalog_path),
                   "coverage": str(coverage_path.relative_to(root)), "coverageSha256": digest(coverage_path),
                   "originalBaseline": str(baseline_path.relative_to(root)),
                   "atlasVerifierSha256": digest(verifier_path)},
        "summary": {
            "assets": len(assets), "pngHashesAndDimensionsPassed": sum(a["hashMatches"] and a["dimensionsMatch"] for a in asset_checks),
            "requirements": len(requirements), "requirementsCovered": sum(r["allOutputsAcceptedAndPresent"] for r in requirement_checks),
            "rooms": len(rooms), "roomRequirementLinks": room_links,
            "original12Unchanged": originals_ok, "backgroundsSeparate": len(backgrounds),
            "atlasFrames": len(seen), "atlasPages": len(index["pages"]), "atlasIndependentVerificationPassed": not atlas_errors,
            "fileOccurrences": dict(occurrence_counts), "uniqueReadableFiles": sum(bool(f) for f in checked_files.values()),
            "svgFilesParsed": sum(bool(f and f.get("svgValid")) for f in checked_files.values())
        },
        "checks": [
            "All original PNG bytes and dimensions match accepted catalog.",
            "All catalog source references, prompt chains, editable SVG/source files and thumbnails are readable in this project.",
            "Each static requirement maps to actual accepted output files; all 36 room requirement and asset links resolve.",
            "Original 12 PNGs match their preserved first-batch manifest.",
            "All atlas crops, registration, padding, extrusion and ZIP bytes rechecked without modifying atlas files."
        ],
        "originalBaselineChecks": baseline_checks,
        "errors": errors, "warnings": warnings
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[4])
    parser.add_argument("--assets", type=int, default=192)
    parser.add_argument("--requirements", type=int, default=105)
    parser.add_argument("--rooms", type=int, default=36)
    parser.add_argument("--backgrounds", type=int, default=18)
    parser.add_argument("--atlas-frames", type=int, default=174)
    args = parser.parse_args()
    root = args.root.resolve()
    report = run(root, {"assets": args.assets, "requirements": args.requirements, "rooms": args.rooms,
                        "backgrounds": args.backgrounds, "atlasFrames": args.atlas_frames})
    output = root / "assets/source/whalefall-v5-2-complete/review/delivery-integrity.json"
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"passed": report["passed"], "summary": report["summary"], "errors": report["errors"],
                      "report": str(output)}, ensure_ascii=False))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

