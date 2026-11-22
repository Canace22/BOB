"""确定性打包普通敌人：保留源像素，不逐帧拉伸，不以程序生成姿态。"""
from pathlib import Path
import hashlib
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / "assets/runtime/sprites/combat-animation-v2/enemies"
# 行脚底为已审视源图的共同接地点，修正生成器排版漂移；不按每格最低像素对齐。
SPECS = {
    "forager-rush": ("forager", "rush", 1, [246, 250, 240, 242], .62),
    "forager-double": ("forager", "double", 2, [233, 233, 233, 233], .62),
    "mudback-ambush": ("mudback", "ambush", 1, [253, 250, 247, 253], .52),
    "mudback-press": ("mudback", "press", 1, [252, 257, 254, 251], .52),
    "mudback-flip": ("mudback", "flip", 1, [264, 257, 248, 246], .52),
    "shell_guard-poke": ("shell_guard", "poke", 1, [274, 273, 273, 274], .64),
    "shell_guard-shell_push": ("shell_guard", "shell_push", 1, [268, 268, 266, 268], .64),
    "shell_guard-realign": ("shell_guard", "realign", 1, [267, 263, 257, 256], .64),
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def bounds(alpha):
    return alpha.point(lambda x: 255 if x > 8 else 0).getbbox()

def frame_sha(image):
    box = image.getchannel("A").getbbox()
    image = image.crop(box) if box else image
    raw = bytearray(image.tobytes())
    for pos in range(0, len(raw), 4):
        if raw[pos + 3] == 0:
            raw[pos:pos + 3] = b"\0\0\0"
    return hashlib.sha256(str(image.size).encode() + raw).hexdigest()

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    config = {"schema_version": 1, "enemies": {}}
    report = {"method": "source pixels copied at scale 1 into common 400px cells; rounded source grid boundaries; per-row authored root; no per-frame resize", "actions": []}
    for name, (profile, action, version, row_roots, root_x) in SPECS.items():
        source = HERE / "masters" / f"{name}-v{version}.png"
        original = Image.open(source).convert("RGBA")
        atlas = Image.new("RGBA", (1600, 1600))
        entries, inspected, hashes = [], [], []
        reference_height = None
        for index in range(16):
            col, row = index % 4, index // 4
            rect = [round(col * original.width / 4), round(row * original.height / 4), round((col + 1) * original.width / 4), round((row + 1) * original.height / 4)]
            frame = original.crop(rect)
            box = bounds(frame.getchannel("A"))
            if box is None:
                raise ValueError(f"{name} frame{index}: empty")
            if box[0] == 0 or box[1] == 0 or box[2] == frame.width or box[3] == frame.height:
                raise ValueError(f"{name} frame{index}: real source edge contact, needs review")
            if reference_height is None:
                reference_height = box[3] - box[1]
            dx = (400 - frame.width) // 2
            dy = 300 - row_roots[row]
            atlas.paste(frame, (col * 400 + dx, row * 400 + dy))
            pivot = [dx + round(frame.width * root_x), 300]
            entries.append({"rect": [col * 400, row * 400, 400, 400], "pivot": pivot})
            hashes.append(frame_sha(frame))
            inspected.append({"index": index, "source_rect_xyxy": rect, "source_alpha_gt8_bbox": box, "translation": [dx, dy], "source_root": [round(frame.width * root_x), row_roots[row]], "pivot": pivot})
        target = OUT / f"{name}.png"
        atlas.save(target, optimize=True)
        enemy = config["enemies"].setdefault(profile, {"clips": [], "windups": []})
        for state, ids in [("tell", range(6)), ("active", range(6, 10)), ("recover", range(10, 16))]:
            ids = list(ids)
            frames = [dict(entries[index], at=round(cursor / len(ids), 6)) for cursor, index in enumerate(ids)]
            clip = {"action": action, "state": state, "texture": f"res://art/combat-animation-v2/enemies/{name}.png", "reference_height": reference_height, "frames": frames}
            if profile == "forager":
                clip.update(chapter_height=163.18, chapter_ground_offset=26.24)
            enemy["clips"].append(clip)
        # 离线动画预览只编码现有16张绘制帧，不生成插值或新增姿态。
        previews = []
        for index in range(16):
            cell = atlas.crop((index % 4 * 400, index // 4 * 400, index % 4 * 400 + 400, index // 4 * 400 + 400))
            background = Image.new("RGBA", (400, 400), "#122027")
            background.alpha_composite(cell)
            previews.append(background.convert("RGB"))
        preview_dir = ROOT / "game/build/qa/combat-animation-v2/normal"
        preview_dir.mkdir(parents=True, exist_ok=True)
        previews[0].save(preview_dir / f"{name}.gif", save_all=True, append_images=previews[1:], duration=[100]*6+[50]*4+[100]*6, loop=0)
        report["actions"].append({"id": name, "selected": source.relative_to(ROOT).as_posix(), "source_sha256": sha(source), "runtime": target.relative_to(ROOT).as_posix(), "runtime_sha256": sha(target), "source_size": list(original.size), "runtime_size": list(atlas.size), "frames": inspected, "unique_visible_rgba": len(set(hashes)), "reference_height": reference_height, "review": "static identity and complete silhouettes checked; GIF encoded but playback and actual game acceptance delegated", "limits": ["AI-authored fine surface/coral details vary slightly between frames", "per-row registration needs real playback and terrain review"]})
    add_fx(config, report)
    (OUT / "animations-normal.json").write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (HERE / "normal-production.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Packed", len(SPECS), "actions / 128 authored body frames, and shared 6-frame windup FX")

def add_fx(config, report):
    source = HERE / "masters/normal-windup-fx-v2.png"
    original = Image.open(source).convert("RGBA")
    target = OUT / "normal-windup-fx.png"
    # 六格源图已完整；直接保留原图，不造帧、不抽掉半透明笔触。
    target.write_bytes(source.read_bytes())
    frames = []
    hashes = []
    for index in range(6):
        col, row = index % 3, index // 3
        x, y = round(col * original.width / 3), round(row * original.height / 2)
        right, bottom = round((col + 1) * original.width / 3), round((row + 1) * original.height / 2)
        rect = [x, y, right - x, bottom - y]
        frames.append({"at": round(index / 6, 6), "rect": rect, "pivot": [(right - x) / 2, (bottom - y) * .74]})
        hashes.append(frame_sha(original.crop((x, y, right, bottom))))
    for profile, enemy in config["enemies"].items():
        for action in dict.fromkeys(clip["action"] for clip in enemy["clips"]):
            enemy["windups"].append({"action": action, "state": "tell", "texture": "res://art/combat-animation-v2/enemies/normal-windup-fx.png", "reference_height": 512, "anchor": [0, -5], "scale": .24 if profile == "forager" else .33, "frames": frames})
    report["windup_fx"] = {"selected": source.relative_to(ROOT).as_posix(), "source_sha256": sha(source), "frame_count": 6, "unique_visible_rgba": len(set(hashes)), "runtime_sha256": sha(target), "status": "independent six-drawing anticipation FX; static reviewed, actual composite pending", "revision": "v1 broad haze rejected; v2 alpha-zero pixels increased from1065184 to1333958; preserve residual authored antialiasing; no programmatically erased halo"}

if __name__ == "__main__":
    main()
