"""将白盒真实视口帧编码为正常速度的单项及总览 GIF。需要 ffmpeg、Pillow。"""
import argparse
import json
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

from PIL import Image


def encode(ffmpeg, pattern, output):
    # 调色板在同一滤镜内生成；差分矩形降低静态背景的体积。
    filters = (
        "scale=960:540:flags=lanczos,split[a][b];"
        "[a]palettegen=max_colors=128:stats_mode=diff[p];"
        "[b][p]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle"
    )
    subprocess.run([
        ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
        "-framerate", "20", "-i", str(pattern), "-filter_complex_threads", "1",
        "-filter_complex", filters, "-loop", "0", str(output),
    ], check=True)


def verify(path, expected_frames):
    with Image.open(path) as gif:
        duration = 0
        for frame in range(gif.n_frames):
            gif.seek(frame)
            gif.load()
            duration += gif.info.get("duration", 0)
        assert gif.size == (960, 540)
        assert gif.info.get("loop") == 0
        assert abs(duration - expected_frames * 50) <= 50
    return {"file": path.name, "seconds": duration / 1000, "bytes": path.stat().st_size}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw", type=Path, default=Path("game/build/qa/skill-gifs"))
    parser.add_argument("--out", type=Path, default=Path("game/build/share/skills-20261116"))
    args = parser.parse_args()
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required")
    clips = json.loads((args.raw / "index.json").read_text(encoding="utf-8"))
    args.out.mkdir(parents=True, exist_ok=True)
    reel = args.raw / "reel"
    reel.mkdir(exist_ok=True)
    count = 0
    report = []
    names = []
    for clip in clips:
        raw = args.raw / clip["id"]
        assert len(list(raw.glob("*.png"))) == clip["frames"]
        output = args.out / (clip["id"] + ".gif")
        encode(ffmpeg, raw / "%04d.png", output)
        report.append(verify(output, clip["frames"]))
        names.append(output)
        for frame in range(clip["frames"]):
            target = reel / f"{count:04d}.png"
            if not target.exists():
                os.link(raw / f"{frame:04d}.png", target)
            count += 1
        print(f"Encoded {clip['id']}: {output.stat().st_size} bytes", flush=True)
    # 限制输入帧数由目录帧数一致性保证，避免旧录制尾帧混入。
    assert len(list(reel.glob("*.png"))) == count
    overview = args.out / "skill-reel.gif"
    encode(ffmpeg, reel / "%04d.png", overview)
    report.append(verify(overview, count))
    manifest = args.out / "技能清单.txt"
    manifest.write_text("鲸落万物生 · 战斗白盒技能实录\n正常速度，20fps，960×540，无限循环。\n\n" + "\n".join(
        f"{clip['id']}.gif：{clip['title']} / {clip['hint']}" for clip in clips
    ), encoding="utf-8-sig")
    with zipfile.ZipFile(args.out / "skill-gifs.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        for path in names + [manifest]:
            archive.write(path, path.name)
    (args.out / "validation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report[-1]), flush=True)


if __name__ == "__main__":
    main()
