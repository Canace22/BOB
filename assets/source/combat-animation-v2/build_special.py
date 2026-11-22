"""特殊敌人源图确定性裁片/配准；不生成姿态、不逐帧缩放、不写合并清单。"""
from pathlib import Path
import copy
import hashlib
import json
import math
import sys
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / "assets/runtime/sprites/combat-animation-v2/enemies"
QA = ROOT / "game/build/qa/combat-animation-v2/special"
PHASES = {"tell": list(range(6)), "active": list(range(6, 10)), "recover": list(range(10, 16))}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def visible_sha(image):
    array = np.array(image)
    array[array[:, :, 3] == 0, :3] = 0
    return hashlib.sha256(array.tobytes()).hexdigest()


def get_components(image):
    alpha = np.array(image)[:, :, 3]
    labels, _ = ndimage.label(alpha > 96)
    sizes = np.bincount(labels.ravel())
    ids = np.flatnonzero(sizes[1:] > 1000) + 1
    if len(ids) != 16:
        raise ValueError(f"Expected exactly16 complete alpha>96 components, got{len(ids)}")
    objects = ndimage.find_objects(labels)
    components = []
    for label in ids:
        ys, xs = objects[label - 1]
        components.append(dict(label=int(label), pixels=int(sizes[label]), box=[xs.start, ys.start, xs.stop, ys.stop]))
    # 每行4个角色按中心y分组，再按中心x排序；不按名义格线切角色。
    components.sort(key=lambda item: item["box"][1] + item["box"][3])
    ordered = []
    for row in range(4):
        ordered += sorted(components[row * 4:row * 4 + 4], key=lambda item: item["box"][0] + item["box"][2])
    return labels, ordered


def weakpoint(frame):
    rgba = np.array(frame).astype(np.int16)
    red, green, blue, alpha = [rgba[:, :, index] for index in range(4)]
    # 只在角色右后侧找青囊，不允许胸前灰青衣物成为弱点。
    core = np.argwhere(alpha > 96)
    left, right = int(core[:, 1].min()), int(core[:, 1].max())
    cyan = (alpha > 32) & (green - red > 10) & (blue - red > 8) & (green > 65)
    labels, count = ndimage.label(cyan)
    sizes = np.bincount(labels.ravel())
    if count == 0 or sizes[1:].max() < 120:
        raise ValueError("Rear cyan sac not detected; manual correction required, no fabricated anchor")
    label = int(np.argmax(sizes[1:]) + 1)
    yy, xx = np.where(labels == label)
    box = [int(xx.min()), int(yy.min()), int(xx.max() + 1), int(yy.max() + 1)]
    center = [(box[0] + box[2]) / 2, (box[1] + box[3]) / 2]
    # 完整检测囊后再验证后侧位置，不硬切mask把错误的前移囊伪装成后侧小边条。
    fraction = (center[0] - left) / max(1, right - left)
    if fraction < .68:
        raise ValueError(f"Actual cyan sac moved to body mid/front: centerFraction={fraction:.4f}, bbox={box}, pixels={int(sizes[label])}; require rear>=0.68")
    radius = [max(3, (box[2] - box[0]) / 2 + 2), max(3, (box[3] - box[1]) / 2 + 2)]
    return center, radius, dict(mask_pixels=int(sizes[label]), source_local_bbox=box,
                                method="alpha>32, g-r>10,b-r>8,g>65; full largest component>=120px; posterior center>=68percent required")


def extract(request):
    profile, action = request["profile"], request["action"]
    name = profile + "--" + action
    source = HERE / "masters" / (name + ".png" if profile != "forager" else "forager-sweep-v2.png")
    if not source.exists():
        return None, dict(id=name, missing=str(source.relative_to(ROOT)))
    image = Image.open(source).convert("RGBA")
    labels, components = get_components(image)
    row_roots = [round(float(np.median([item["box"][3] for item in components[row * 4:row * 4 + 4]]))) for row in range(4)]
    records, images = [], []
    for index, component in enumerate(components):
        col, row = index % 4, index // 4
        x0, y0, x1, y1 = component["box"]
        if x0 == 0 or y0 == 0 or x1 == image.width or y1 == image.height:
            raise ValueError(name + f" frame{index}: actual PNG edge touches core")
        rect = [max(0, x0 - 12), max(0, y0 - 12), min(image.width, x1 + 12), min(image.height, y1 + 12)]
        foreign = np.unique(labels[rect[1]:rect[3], rect[0]:rect[2]])
        foreign = [int(value) for value in foreign if value not in (0, component["label"]) and int((labels == value).sum()) > 1000]
        if foreign:
            raise ValueError(name + f" frame{index}: expanded crop overlaps another role core {foreign}")
        root = [round((col + .60) * image.width / 4), row_roots[row]]
        nominal = [round(col * image.width / 4), round(row * image.height / 4), round((col + 1) * image.width / 4), round((row + 1) * image.height / 4)]
        crosses = x0 < nominal[0] or y0 < nominal[1] or x1 > nominal[2] or y1 > nominal[3]
        records.append(dict(index=index, sourceRect=rect, coreBBox=component["box"],
                            corePixels=component["pixels"], sourceRoot=root,
                            nominalGridRect=nominal, crossesNominalGrid=crosses,
                            actualPngEdgeTouch=False, foreignCorePixels=0))
        images.append(image.crop(tuple(rect)))
        alpha32 = np.array(images[-1])[:, :, 3]
        records[-1]["cropAlpha32EdgeTouch"] = bool(np.any(alpha32[0] > 32) or np.any(alpha32[-1] > 32) or np.any(alpha32[:, 0] > 32) or np.any(alpha32[:, -1] > 32))
        if records[-1]["cropAlpha32EdgeTouch"]:
            raise ValueError(name + f" frame{index}: expanded crop cuts alpha32 edge")
    # 从全序列相对同一名义根的union确定共用画布；只平移，原像素比例恒为1。
    bounds = [min(item["sourceRect"][0] - item["sourceRoot"][0] for item in records),
              min(item["sourceRect"][1] - item["sourceRoot"][1] for item in records),
              max(item["sourceRect"][2] - item["sourceRoot"][0] for item in records),
              max(item["sourceRect"][3] - item["sourceRoot"][1] for item in records)]
    width, height = [math.ceil((bounds[index + 2] - bounds[index]) / 8) * 8 for index in range(2)]
    pivot = [-bounds[0], -bounds[1]]
    atlas = Image.new("RGBA", (width * 4, height * 4))
    entries, hashes, review_frames, rejected_frames = [], [], [], []
    reference_height = components[0]["box"][3] - components[0]["box"][1]
    for index, (item, frame) in enumerate(zip(records, images)):
        dx = pivot[0] + item["sourceRect"][0] - item["sourceRoot"][0]
        dy = pivot[1] + item["sourceRect"][1] - item["sourceRoot"][1]
        atlas.paste(frame, (index % 4 * width + dx, index // 4 * height + dy))
        entry = dict(rect=[index % 4 * width, index // 4 * height, width, height], pivot=pivot[:])
        item["translation"] = [dx, dy]
        if profile == "pump_warden":
            try:
                center, radius, diagnosis = weakpoint(frame)
                entry.update(weak_center=[round(center[0] + dx, 3), round(center[1] + dy, 3)], weak_radius=radius)
                item["weakpoint"] = dict(diagnosis, runtime_center=entry["weak_center"], runtime_radius=radius)
            except ValueError as error:
                rejected_frames.append(dict(index=index, coreBBox=item["coreBBox"], reason=str(error)))
        entries.append(entry)
        hashes.append(visible_sha(frame))
        review_frames.append(atlas.crop((index % 4 * width, index // 4 * height, (index % 4 + 1) * width, (index // 4 + 1) * height)))
    if len(set(hashes)) != 16:
        raise ValueError(name + ": duplicated visible authored frames")
    if rejected_frames:
        raise ValueError(json.dumps(rejected_frames, ensure_ascii=False))
    target = OUT / (name + ".png")
    atlas.save(target, optimize=True)
    # 编码后读回，逐片验证落点和RGBA均与源裁片逐字节一致。
    decoded = Image.open(target).convert("RGBA")
    for item, original in zip(records, images):
        index = item["index"]
        dx, dy = item["translation"]
        left, top = index % 4 * width + dx, index // 4 * height + dy
        if decoded.crop((left, top, left + original.width, top + original.height)).tobytes() != original.tobytes():
            raise ValueError(name + f" frame{index}: PNG roundtrip source pixels changed")
    silhouette_hashes = [hashlib.sha256((np.array(frame)[:, :, 3] > 96).tobytes()).hexdigest() for frame in review_frames]
    report = dict(id=name, selected=source.relative_to(ROOT).as_posix(), source_sha256=sha(source),
                  runtime=target.relative_to(ROOT).as_posix(), runtime_sha256=sha(target),
                  source_size=list(image.size), runtime_size=list(atlas.size), cell_size=[width, height],
                  reference_height=reference_height, pivot=pivot, registration="source pixels scale1; nominal column root at60percent; per-row median alpha96 core bottom; common union canvas aligned8px",
                  row_root_y=row_roots, unique_visible_rgba=16, unique_registered_alpha96_silhouettes=len(set(silhouette_hashes)),
                  source_to_decoded_png_rgba_exact=True, alpha_extrema=list(image.getchannel("A").getextrema()),
                  crosses_nominal_grid=sum(item["crossesNominalGrid"] for item in records), frames=records)
    render_preview(name, review_frames, entries, reference_height)
    return dict(profile=profile, action=action, entries=entries, reference_height=reference_height,
                texture="res://art/combat-animation-v2/enemies/" + target.name), report


def render_preview(name, frames, entries, reference_height):
    scale = 100 / reference_height
    width = max(180, math.ceil(frames[0].width * scale) + 12)
    height = max(150, math.ceil(frames[0].height * scale) + 28)
    board = Image.new("RGB", (width * 8, height * 4), "#15303a")
    draw = ImageDraw.Draw(board)
    gif = []
    for index, frame in enumerate(frames):
        resized = frame.resize((round(frame.width * scale), round(frame.height * scale)), Image.Resampling.LANCZOS)
        for background in range(2):
            tile = Image.new("RGBA", (width, height), "#15303a" if background == 0 else "#dfd9c6")
            tile.alpha_composite(resized, ((width - resized.width) // 2, 5))
            if "weak_center" in entries[index]:
                # QA调试标注与真实运行位图分离，不把圈线烘焙进角色素材。
                cx, cy = entries[index]["weak_center"]
                x, y = (width - resized.width) // 2 + cx * scale, 5 + cy * scale
                ImageDraw.Draw(tile).ellipse((x - 5, y - 5, x + 5, y + 5), outline="#ff4ef1", width=1)
            bx = (index % 8) * width
            by = (index // 8 + background * 2) * height
            board.paste(tile.convert("RGB"), (bx, by))
            draw.text((bx + 3, by + height - 16), f"{index:02d}", fill="white" if background == 0 else "black")
            if background == 0: gif.append(tile.convert("RGB"))
    board.save(QA / (name + "-100px.png"))
    gif[0].save(QA / (name + "-slow.gif"), save_all=True, append_images=gif[1:], duration=180, loop=0)


def add_clip(config, packed, state, ids, action=None, pulse=None, source_note=None):
    enemy = config["enemies"].setdefault(packed["profile"], dict(clips=[], windups=[]))
    clip = dict(action=action or packed["action"], state=state, texture=packed["texture"],
                reference_height=packed["reference_height"],
                frames=[dict(packed["entries"][index], at=round(cursor / len(ids), 6)) for cursor, index in enumerate(ids)])
    if packed["profile"] == "forager": clip.update(chapter_height=163.18, chapter_ground_offset=26.24)
    if pulse is not None: clip["pulse"] = pulse
    if source_note: clip["source_note"] = source_note
    enemy["clips"].append(clip)


def map_states(config, packed, available):
    action = packed["action"]
    for state, ids in PHASES.items():
        if action == "elder_mimic" and state != "tell": continue
        if action == "hunter_escape": continue
        add_clip(config, packed, state, ids)
    if action == "hunter_escape":
        for alias in ["hunter_escape", "hunter_pounce", "hunter_glide", "hunter_drop"]:
            add_clip(config, packed, "escape_tell", PHASES["tell"], action=alias, source_note="escape keeps previous move_key; explicit state alias")
            add_clip(config, packed, "evade", list(range(6, 16)), action=alias, source_note="evade phase_duration sampled across release and recovery")
    if action == "eel_burrow": add_clip(config, packed, "emerge", PHASES["tell"])
    if action == "eel_brood" and "eel_bite" in available:
        bite = available["eel_bite"]
        add_clip(config, bite, "link", PHASES["tell"], action=action, source_note="explicit reuse eel_bite preparation")
        for pulse in [2, 3]:
            add_clip(config, bite, "coil", PHASES["tell"], action=action, pulse=pulse, source_note="explicit bite-chain preparation")
            add_clip(config, bite, "active", PHASES["active"], action=action, pulse=pulse, source_note="explicit bite-chain release")
    if action == "warden_waterstep": add_clip(config, packed, "reform", PHASES["tell"])
    if action == "beam_brace": add_clip(config, packed, "brace", PHASES["tell"])
    if action == "beam_guard":
        add_clip(config, packed, "guarding", PHASES["active"])
        add_clip(config, packed, "guard_contact", list(range(8, 12)))
    if action == "elder_vault":
        add_clip(config, packed, "vault", PHASES["active"])
        add_clip(config, packed, "settle", list(range(10, 13)))


def add_fx(config):
    normal = json.loads((OUT / "animations-normal.json").read_text(encoding="utf-8"))
    shared = normal["enemies"]["forager"]["windups"][0]
    heights = dict(forager=72, membrane_hunter=85, nest_eel=68, pump_warden=108, beam_guard=102, elder_guardian=135)
    for profile, enemy in config["enemies"].items():
        # 支持仅重建FX数据；清空旧列表避免反复调用叠出同state的别名。
        enemy["windups"] = []
        actions = list(dict.fromkeys(clip["action"] for clip in enemy["clips"] if clip["state"] == "tell"))
        for action in actions:
            fx = copy.deepcopy(shared)
            fx.update(action=action, scale=round(heights[profile] * .0026, 4), anchor=[0, -round(heights[profile] * .42, 2)])
            enemy["windups"].append(fx)
    aliases = []
    plans = [
        ("membrane_hunter", action, "escape_tell", None)
        for action in ["hunter_pounce", "hunter_glide", "hunter_drop"]
    ] + [
        ("nest_eel", "eel_burrow", "emerge", None),
        # end_position()的头端为facing*112,-26；windup_view对anchor.x乘-facing。
        ("nest_eel", "eel_brood", "coil", [-112, -26]),
        ("nest_eel", "eel_brood", "link", [-112, -26]),
        ("pump_warden", "warden_waterstep", "reform", None),
        ("beam_guard", "beam_brace", "brace", None),
    ]
    for profile, action, state, anchor in plans:
        enemy = config["enemies"].get(profile, {})
        base = next((item for item in enemy.get("windups", []) if item["action"] == action and item["state"] == "tell"), None)
        if base is None:
            raise ValueError(f"Missing tell FX for explicit preparation alias {profile}/{action}/{state}")
        alias = copy.deepcopy(base)
        alias["state"] = state
        if anchor is not None: alias["anchor"] = anchor
        enemy["windups"].append(alias)
        aliases.append(dict(profile=profile, action=action, state=state, anchor=alias["anchor"], texture=alias["texture"]))
    return dict(texture=shared["texture"], frames=len(shared["frames"]),
                method="reuse same-action tell FX for explicit preparation states only; base anchor=-0.42 target-height, scale=0.0026 target-height; eel coil/link use actual head endpoint112,-26",
                aliases=aliases, alias_count=len(aliases),
                total_windup_clips=sum(len(enemy["windups"]) for enemy in config["enemies"].values()),
                excluded_states=["active", "recover", "vault", "settle", "dive", "tunnel", "wash"],
                anchor_source=["game/src/prototypes/enemy_lab/eel.gd:10", "game/src/prototypes/enemy_lab/eel.gd:18", "game/src/prototypes/enemy_lab/windup_view.gd:23"])


def render_weakpoints(actions):
    water = [action for action in actions if action["id"].startswith("pump_warden--")]
    board = Image.new("RGB", (16 * 150, len(water) * 170), "#dfd9c6")
    draw = ImageDraw.Draw(board)
    for row, action in enumerate(water):
        atlas = Image.open(ROOT / action["runtime"]).convert("RGBA")
        width, height = action["cell_size"]
        scale = 100 / action["reference_height"]
        for item in action["frames"]:
            index = item["index"]
            frame = atlas.crop((index % 4 * width, index // 4 * height, (index % 4 + 1) * width, (index // 4 + 1) * height))
            frame = frame.resize((round(width * scale), round(height * scale)), Image.Resampling.LANCZOS)
            tile = Image.new("RGBA", (150, 150), "#dfd9c6")
            left = (150 - frame.width) // 2
            tile.alpha_composite(frame, (left, 5))
            cx, cy = item["weakpoint"]["runtime_center"]
            x, y = left + cx * scale, 5 + cy * scale
            ImageDraw.Draw(tile).ellipse((x - 5, y - 5, x + 5, y + 5), outline="#ff00ff", width=1)
            board.paste(tile.convert("RGB"), (index * 150, row * 170 + 18))
            draw.text((index * 150 + 3, row * 170 + 150), str(index), fill="black")
        draw.text((4, row * 170 + 2), action["id"], fill="black")
    board.save(QA / "weakpoints-96.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    QA.mkdir(parents=True, exist_ok=True)
    requests = json.loads((HERE / "requests-special.json").read_text(encoding="utf-8"))
    requests.append(dict(profile="forager", action="sweep"))
    config = dict(schema_version=1, enemies={})
    report = dict(method="connected complete bodies, adaptive common per-action canvas, original RGBA pixels at scale1", actions=[], missing=[], rejected=[], limits=["source-generated anatomical/texture continuity remains subject to slow preview and engine review", "component and unique-pixel tests do not establish anatomical or timing acceptance", "dive/tunnel/wash retain old hidden execution; elder_mimic active/copy remains original owner"])
    packed_actions = []
    for request in requests:
        try:
            packed, diagnosis = extract(request)
            if packed is None: report["missing"].append(diagnosis)
            else:
                packed_actions.append(packed)
                report["actions"].append(diagnosis)
        except ValueError as error:
            report["rejected"].append(dict(profile=request["profile"], action=request["action"], reason=str(error)))
    available = {item["action"]: item for item in packed_actions}
    for packed in packed_actions: map_states(config, packed, available)
    report["windup_fx"] = add_fx(config)
    report["body_frames"] = len(packed_actions) * 16
    report["clip_count"] = sum(len(item["clips"]) for item in config["enemies"].values())
    report["runtime_files"] = [item["runtime"] for item in report["actions"]]
    report["runtime_atlas_pixels"] = sum(item["runtime_size"][0] * item["runtime_size"][1] for item in report["actions"])
    render_weakpoints(report["actions"])
    report["weakpoint_contactboard"] = "game/build/qa/combat-animation-v2/special/weakpoints-96.png"
    report["verification"] = dict(
        png_rgba_exact_frames=sum(16 for action in report["actions"] if action["source_to_decoded_png_rgba_exact"]),
        alpha32_crop_edge_contacts=sum(frame["cropAlpha32EdgeTouch"] for action in report["actions"] for frame in action["frames"]),
        actual_png_core_edge_contacts=sum(frame["actualPngEdgeTouch"] for action in report["actions"] for frame in action["frames"]),
        unique_rgba_per_action=[action["unique_visible_rgba"] for action in report["actions"]],
        unique_alpha96_silhouettes_per_action=[action["unique_registered_alpha96_silhouettes"] for action in report["actions"]],
        engine_run=False,
        slow_gif_playback="generated16frames at180ms each; frame contactboards reviewed; game/GPU acceptance owned by parent")
    (OUT / "animations-special.json").write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (HERE / "special-production.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(actions=len(packed_actions), frames=report["body_frames"], clips=report["clip_count"], missing=report["missing"], rejected=report["rejected"]), ensure_ascii=False))


def rebuild_fx_only():
    """只重建JSON准备态FX，不解码、裁片或重写任何PNG/GIF。"""
    target = OUT / "animations-special.json"
    report_path = HERE / "special-production.json"
    config = json.loads(target.read_text(encoding="utf-8"))
    report = json.loads(report_path.read_text(encoding="utf-8"))
    before = json.dumps({key: enemy["clips"] for key, enemy in config["enemies"].items()}, sort_keys=True)
    report["windup_fx"] = add_fx(config)
    after = json.dumps({key: enemy["clips"] for key, enemy in config["enemies"].items()}, sort_keys=True)
    if before != after: raise ValueError("FX-only update changed body clips")
    report["windup_fx"]["body_clips_unchanged"] = True
    report["windup_fx"]["png_gif_reexported"] = False
    target.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["windup_fx"], ensure_ascii=False))


if __name__ == "__main__":
    if "--fx-only" in sys.argv: rebuild_fx_only()
    else: main()
