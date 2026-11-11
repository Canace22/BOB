"""Build the game's font subset from its text; keep the upstream font intact.

Requires fonttools (pip install fonttools). Run from any directory, then sync-art.
"""
import hashlib
import json
from pathlib import Path

from fontTools import __version__
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/runtime/fonts/NotoSansSC.ttf"
TARGET = ROOT / "assets/runtime/fonts/WhalefallUI.ttf"


def main():
    characters = set(chr(n) for n in range(0x20, 0x100))
    for directory in [ROOT / "game/src", ROOT / "game/content"]:
        for file in sorted(directory.rglob("*")):
            if file.suffix in [".gd", ".tscn", ".tres"]:
                characters.update(file.read_text(encoding="utf-8"))
    font = TTFont(SOURCE, recalcTimestamp=False)
    available = font.getBestCmap()
    codepoints = sorted(ord(c) for c in characters if ord(c) in available)
    if "fvar" in font:
        # The upstream variable default is Thin (100); game UI needs readable Regular.
        axes = {axis.axisTag: axis.defaultValue for axis in font["fvar"].axes}
        if "wght" in axes:
            axes["wght"] = 400
        instantiateVariableFont(font, axes, inplace=True)
    options = subset.Options()
    options.recalc_timestamp = False
    options.notdef_glyph = True
    options.recommended_glyphs = True
    sub = subset.Subsetter(options=options)
    sub.populate(unicodes=codepoints)
    sub.subset(font)
    # Give this modified font its own name, retaining the upstream license.
    names = {1: "Whalefall UI", 2: "Regular", 3: "WhalefallUI-Regular", 4: "Whalefall UI Regular", 6: "WhalefallUI-Regular", 16: "Whalefall UI", 17: "Regular"}
    for record in font["name"].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    font.save(TARGET)
    metadata = {
        "source": "assets/runtime/fonts/NotoSansSC.ttf",
        "sourceSha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "output": "assets/runtime/fonts/WhalefallUI.ttf",
        "outputSha256": hashlib.sha256(TARGET.read_bytes()).hexdigest(),
        "bytes": TARGET.stat().st_size,
        "characters": len(codepoints),
        "fonttools": __version__,
        "weight": 400,
    }
    with (Path(__file__).parent / "subset.json").open("w", encoding="utf-8", newline="\n") as output:
        output.write(json.dumps(metadata, indent=2) + "\n")
    print(json.dumps(metadata))


if __name__ == "__main__":
    main()
