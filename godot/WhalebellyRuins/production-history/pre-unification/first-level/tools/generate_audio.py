"""Deterministic original procedural first-level sound set; Python standard library only.

Run with Python 3.10+. Writes only the runtime WAVs and production audio report.
No samples, music, voices, third-party models or paid services are used.
"""
from pathlib import Path
import array
import hashlib
import math
import random
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/runtime/audio"
RATE = 44100
TAU = math.tau


def env(t, duration, attack=0.008, decay=3.0):
    """Raised-cosine attack and final 25 ms release with exponential body."""
    if t <= 0 or t >= duration:
        return 0.0
    fade_in = 0.5 - 0.5 * math.cos(math.pi * min(1.0, t / attack))
    fade_out = 0.5 - 0.5 * math.cos(math.pi * min(1.0, (duration - t) / 0.025))
    return fade_in * fade_out * math.exp(-decay * t / duration)


def chirp(t, f0, f1, duration):
    return math.sin(TAU * (f0 * t + (f1-f0) * t*t / (2*duration)))


def bell(t, frequency):
    return (math.sin(TAU * frequency*t) +
            0.28*math.sin(TAU * frequency*2.71*t)*math.exp(-8*t) +
            0.10*math.sin(TAU * frequency*4.07*t)*math.exp(-15*t))


SPECS = [
    ("jump", 0.20, "抬脚／起跳", "180→430 Hz柔软上行，短气泡声", 0.48),
    ("strike", 0.18, "短击起手", "带通风声＋700→260 Hz，区别于命中", 0.42),
    ("heavy", 0.48, "重鸣蓄振起手", "95→58 Hz下行，190 Hz壳体共鸣", 0.58),
    ("hit", 0.16, "敌人受到有效命中", "380 Hz壳片敲击，短噪声起音", 0.56),
    ("hurt", 0.31, "玩家受伤", "210→85 Hz低落音，粗糙短摩擦", 0.58),
    ("dash", 0.25, "贴流冲开始", "滤波水流噪声，620→170 Hz短扫频", 0.44),
    ("heal", 0.70, "调息成功", "220/330/440 Hz逐次柔和水晶音", 0.45),
    ("save", 0.75, "营地记录成功", "196/294/392 Hz三次壳铃回应", 0.47),
    ("collect", 0.90, "永久收获／结关", "262/330/392/524 Hz四音逐次上行", 0.48),
    ("sweep", 0.25, "敌人横扫有效阶段", "120→64 Hz＋宽带短扫风，与举钳视觉预告配合", 0.53),
    ("slam", 0.48, "Boss砸击有效阶段", "65→38 Hz低频冲击＋130 Hz壳体及衰减噪声", 0.62),
]


def synth(name, duration, seed):
    rng = random.Random(seed)
    low = 0.0
    slower = 0.0
    values = []
    for i in range(round(RATE*duration)):
        t = i/RATE
        n = rng.uniform(-1, 1)
        low += 0.12*(n-low)
        slower += 0.025*(n-slower)
        band = low-slower
        e = env(t, duration)
        if name == "jump":
            v = (0.75*chirp(t, 180, 430, duration)+0.35*low)*e
        elif name == "strike":
            v = (2.8*band+0.12*chirp(t, 700, 260, duration))*e
        elif name == "heavy":
            v = (0.75*chirp(t, 95, 58, duration)+0.25*bell(t, 190)+0.5*low)*e
        elif name == "hit":
            v = (0.65*bell(t, 380)+1.1*band*math.exp(-28*t))*e
        elif name == "hurt":
            v = (0.68*chirp(t, 210, 85, duration)+0.85*band)*e
        elif name == "dash":
            v = (3*band+0.12*chirp(t, 620, 170, duration))*env(t, duration, 0.015, 1.7)
        elif name in ("heal", "save", "collect"):
            tones = {"heal": (220, 330, 440), "save": (196, 294, 392), "collect": (262, 330, 392, 524)}[name]
            v = 0
            for idx, f in enumerate(tones):
                local = t-idx*0.105
                if local > 0:
                    v += bell(local, f)*env(local, duration-idx*0.105, 0.014, 4.5)
        elif name == "sweep":
            v = (0.42*chirp(t, 120, 64, duration)+2.0*band)*env(t, duration, 0.008, 2.0)
        else:  # slam
            v = (0.75*chirp(t, 65, 38, duration)+0.26*bell(t, 130)+1.0*low*math.exp(-10*t))*e
        values.append(v)
    values[0] = values[-1] = 0.0
    return values


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for seed, (name, duration, event, design, target) in enumerate(SPECS, start=7401):
        samples = synth(name, duration, seed)
        maximum = max(abs(v) for v in samples)
        pcm = array.array("h", [round(v/maximum*target*32767) for v in samples])
        normalized = [v/32768 for v in pcm]
        peak = max(abs(v) for v in normalized)
        rms = math.sqrt(sum(v*v for v in normalized)/len(normalized))
        assert pcm[0] == pcm[-1] == 0
        assert peak < 0.65
        assert all(abs(v) < 32767 for v in pcm)
        assert max(abs(v) for v in pcm[:44]) < 2000, "Non-smooth attack"
        assert max(abs(v) for v in pcm[-44:]) < 100, "Non-smooth release"
        filename = OUT/(name+".wav")
        if sys.byteorder != "little":
            pcm.byteswap()
        with wave.open(str(filename), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(pcm.tobytes())
        # Decode the written file, not just in-memory values.
        with wave.open(str(filename), "rb") as wav:
            assert wav.getnchannels() == 1 and wav.getsampwidth() == 2
            assert wav.getframerate() == RATE and wav.getnframes() == len(pcm)
        digest = hashlib.sha256(filename.read_bytes()).hexdigest()
        rows.append(f"| {name} | {duration:.2f} s | {20*math.log10(peak):.2f} dBFS | {20*math.log10(rms):.2f} dBFS | {event} | {design} |")
        rows.append(f"<!-- {name}.wav SHA256 {digest} -->")
    report = """# 首关声音资产 v1

来源：本项目 `tools/generate_audio.py` 原创程序合成，固定随机种子；无采样、无第三方音乐、无语音、无外部生成服务。可用 Python 标准库重复生成。

格式：44,100 Hz / 单声道 / signed PCM 16 bit WAV。独立短音效，不循环。实际引用：`main.gd::sfx()` 按事件名加载 `assets/runtime/audio/<name>.wav`；运行代码总体增益 -14 dB（由主代理集成验证）。

| 文件名 | 时长 | 写盘峰值 | 写盘 RMS | 触发事件 | 声音设计 |
|---|---:|---:|---:|---|---|
"""+"\n".join(rows)+"""

## 数值验收

执行脚本后重新用 `wave` 打开全部 11 个文件，验证声道、采样率、位深、帧数；无削波，峰值低于 0.65 FS；所有首末采样为零。检查最初 1 ms 的幅值小于 2000/32768，末尾 1 ms 小于 100/32768；8–15 ms 平滑起音和末尾 25 ms 余弦释放避免突变。底噪由固定随机种子产生；不存在文件外采样依赖。此项是数据与包络检查，不等于试听验收。

## 试听与运行边界

本子任务 **未实际试听（not_run）**，也未声称声画同步通过。主代理应在 Godot 中验证起跳、命中、受击、Boss横扫与砸击、营地和收获事件的实际播放，关注连续重击是否掩盖敌人预告。没有音乐或环境循环；首关采用安静的水下视觉氛围与短事件声音。低频砸击在手机/笔记本小扬声器上可能不明显，130 Hz 壳体分量提供辅助辨识；仍需真实设备听感确认。
"""
    (ROOT/"docs/production/audio.md").write_text(report, encoding="utf-8")
    print("Generated and decoded 11 PCM WAVs; peak, smooth edges, frame counts PASS. Listening NOT_RUN.")


if __name__ == "__main__":
    main()
