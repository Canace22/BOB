"""导出静态角色并生成透明/100px检查图；不生成或补画美术。"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "assets/source/chapter-characters-v1"
OUTPUT = ROOT / "assets/runtime/sprites/chapter-characters-v1"
IDS = ["nest_mender", "fat_store_keeper", "ring_keeper", "lung_keeper",
       "resident_settled", "resident_migrant", "resident_carrier"]


def relative(path):
    return path.relative_to(ROOT).as_posix()


def export_asset(identity):
    source = SOURCE / (identity + ".png")
    image = Image.open(source).convert("RGBA")
    # 按实体范围裁画布，保留抗锯齿及8像素余量；不改Alpha、不清底、不重绘。
    box = image.getchannel("A").point(lambda a: 255 if a >= 32 else 0).getbbox()
    crop = (max(0, box[0] - 8), max(0, box[1] - 8),
            min(image.width, box[2] + 8), min(image.height, box[3] + 8))
    result = image.crop(crop)
    result.thumbnail((640, 640), Image.Resampling.LANCZOS)
    destination = OUTPUT / (identity + ".png")
    result.save(destination)
    visible = result.getchannel("A").point(lambda a: 255 if a >= 32 else 0).getbbox()
    references = ["assets/source/chapter-characters-v1/nest_mender.png"]
    if identity == "nest_mender":
        references = ["assets/runtime/sprites/yusuo/base.png", "game/art/world-kit/r3-gastric-depth.png"]
    elif identity == "fat_store_keeper":
        references.append("game/art/world-kit/r3-gastric-depth.png")
    return dict(id=identity, source=relative(source), file=relative(destination),
                runtimeFile="game/art/chapter-characters-v1/" + identity + ".png",
                sourceSize=list(image.size), size=list(result.size), sourceCrop=list(crop),
                bbox=list(visible), pivot=[(visible[0] + visible[2]) / 2, visible[3]],
                alphaRange=list(result.getchannel("A").getextrema()),
                sha256=hashlib.sha256(destination.read_bytes()).hexdigest(),
                sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                prompt="assets/source/chapter-characters-v1/" + identity + ".prompt.txt",
                references=references, status="candidate", method="built-in image_gen",
                animation="static, not frame animation")


def build_review(assets):
    sheet = Image.new("RGB", (1120, 340), (24, 47, 54))
    draw = ImageDraw.Draw(sheet)
    for index, asset in enumerate(assets):
        image = Image.open(ROOT / asset["file"])
        image.thumbnail((142, 100), Image.Resampling.LANCZOS)
        x = 10 + index * 158
        sheet.paste(image, (x + (142 - image.width) // 2, 132 - image.height), image)
        draw.text((x, 143), asset["id"], fill=(230, 225, 205))
        light = Image.new("RGBA", (142, 136), (222, 215, 192, 255))
        light.alpha_composite(image, ((142 - image.width) // 2, 120 - image.height))
        sheet.paste(light.convert("RGB"), (x, 185))
    (SOURCE / "review").mkdir(exist_ok=True)
    sheet.save(SOURCE / "review/static-100px.png")


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    assets = [export_asset(identity) for identity in IDS]
    (SOURCE / "assets.json").write_text(json.dumps(assets, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    entries = [{"src": asset["file"], "dest": "chapter-characters-v1/" + asset["id"] + ".png"} for asset in assets]
    (SOURCE / "manifest-entries.json").write_text(json.dumps(entries, indent=2) + "\n", encoding="utf-8")
    build_review(assets)
    print("Exported 7 static candidates; source originals unchanged.")
