"""核对母版切片重叠像素和真实碰撞脚线，不修改素材。"""
import collections
import json
import math
from pathlib import Path
from PIL import Image, ImageChops

repo = Path(__file__).resolve().parents[2]
runtime = repo / "assets/runtime/sprites/world-terrain-v2"
records = json.loads((runtime / "chunks.json").read_text(encoding="utf-8"))
images = {
    (int(r["x"] // 1536), int(r["y"] // 1536)): Image.open(runtime / r["file"]).convert("RGBA")
    for r in records
}
edges = []
for (x, y), bitmap in images.items():
    for dx, dy in [(1, 0), (0, 1)]:
        other = images.get((x + dx, y + dy))
        if other is None:
            continue
        first = bitmap.crop((1536, 0, 1540, 1540) if dx else (0, 1536, 1540, 1540))
        second = other.crop((0, 0, 4, 1540) if dx else (0, 0, 1540, 4))
        delta = ImageChops.difference(first, second)
        edges.append(max(channel[1] for channel in delta.getextrema()))

low = []
samples = 0
layout = json.loads((repo / "assets/source/world-terrain-v2/world-layout.json").read_text(encoding="utf-8"))
authored = json.loads((repo / "game/content/whalebelly/layout/rooms.json").read_text(encoding="utf-8"))
membranes = {r["id"]: r.get("layout", {}).get("membrane", {}) for r in authored["rooms"]}
supports = json.loads((repo / "game/content/whalebelly/layout/painted_supports.json").read_text(encoding="utf-8"))["rooms"]
for room in layout:
    for surface in room["surfaces"] + supports.get(room["id"], []):
        # 只排除实时膜面，不能把整间房的其他静态平台漏验。
        membrane = membranes.get(room["id"], {})
        zone = membrane.get("load_rect", [])
        if zone and all(zone[0] <= p[0] <= zone[0] + zone[2] and zone[1] <= p[1] <= zone[1] + zone[3] for p in surface):
            continue
        for a, b in zip(surface, surface[1:]):
            steps = max(1, math.ceil(abs(b[0] - a[0]) / 40))
            for step in range(1, steps):
                ratio = step / steps
                x = room["origin"][0] + a[0] + (b[0] - a[0]) * ratio
                y = room["origin"][1] + a[1] + (b[1] - a[1]) * ratio
                alpha = []
                for depth in range(21):
                    image = images.get((math.floor(x / 1536), math.floor((y + depth) / 1536)))
                    alpha.append(image.getpixel((math.floor(x) % 1536 + 2, math.floor(y + depth) % 1536 + 2))[3] if image else 0)
                samples += 1
                if max(alpha) < 128:
                    low.append({"room": room["id"], "local": [x - room["origin"][0], y - room["origin"][1]], "alpha": max(alpha)})

connection_samples = 0
for link in json.loads((repo / "assets/source/world-terrain-v2/connections.json").read_text(encoding="utf-8")):
    for x, y in link["path"]:
        # 台阶之间本来需要跳跃，只核对实际落脚台，不把空中路径误当实体路面。
        for offset in [-30, 0, 30]:
            # 房内门锚点不一定等于地面高度；房内使用上面的真实surface，动态舌台也不在切片内。
            if any(r["origin"][0] <= x + offset < r["origin"][0] + r["size"][0]
                   and r["origin"][1] <= y < r["origin"][1] + r["size"][1] for r in layout):
                continue
            alpha = []
            for depth in range(21):
                image = images.get((math.floor((x + offset) / 1536), math.floor((y + depth) / 1536)))
                alpha.append(image.getpixel((math.floor(x + offset) % 1536 + 2, math.floor(y + depth) % 1536 + 2))[3] if image else 0)
            connection_samples += 1
            if max(alpha) < 128:
                low.append({"room": link["a"] + "--" + link["b"], "world": [x + offset, y], "alpha": max(alpha)})

# 脚线覆盖不能发现空水区的黑色哑光背景，单独核对每张新画的大面积不透明黑底。
opaque_black = {}
for entry in json.loads((repo / "assets/runtime/sprites/world-seam-repaint-v3/registration.json").read_text(encoding="utf-8")):
    bitmap = Image.open(repo / "assets/runtime/sprites/world-seam-repaint-v3" / entry["file"]).convert("RGBA")
    red, green, blue, alpha = bitmap.split()
    dark = ImageChops.darker(ImageChops.darker(red.point(lambda p: 255 if p < 8 else 0), green.point(lambda p: 255 if p < 8 else 0)), blue.point(lambda p: 255 if p < 8 else 0))
    count = ImageChops.darker(dark, alpha.point(lambda p: 255 if p > 200 else 0)).histogram()[255]
    if count > 4096:
        opaque_black[entry["id"]] = count

report = {"tiles": len(records), "gutter_pairs": len(edges), "max_delta": max(edges), "surface_samples": samples, "connection_samples": connection_samples, "low": low, "opaque_black": opaque_black}
output = repo / "game/build/qa/master-pixel-report.json"
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps({**report, "low_by_room": dict(collections.Counter(p["room"] for p in low))}))
raise SystemExit(1 if low or opaque_black or max(edges) > 2 else 0)
