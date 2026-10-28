# -*- coding: utf-8 -*-
# 【鲸口 → 胃部】操作演示视频 · 渲染脚本
# 做法：以真实原画宽景面板作为可平移底板，叠加从角色设定图抠出的「拾潮者」精灵，
#       用三套镜头（纯2D横版 / 2.5D横版 / 全3D第三人称）分别输出一条短片。
import os, sys, math, subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

# ---------------- 基础参数 ----------------
W, H, FPS = 960, 540, 24          # 输出分辨率与帧率
SEG = 5.0                          # 每个区域时长（秒）
NSEG = 3                           # 区域数：鲸口门庭 / 食道滑井 / 胃库沼泽
NF = int(FPS * SEG * NSEG)         # 总帧数
FONT = 'C:/Windows/Fonts/msyh.ttc'  # 中文字体

V2 = r'G:\鲸落万物生\outputs\鲸落万物生_V2\images'          # V2 关卡原画（宽景面板来源）
CHAR_SRC = os.path.join(V2, 'A03_角色_拾潮者与动作语言.png')  # 角色设定图
OUT = r'G:\鲸落万物生\outputs\鲸口至胃部_操作演示'
WORK = r'G:\鲸落万物生\BOB\work\operation_demos'

# 调色盘：取自设计说明（青、骨、岩、红、金）
TEAL = (74, 170, 158)
BONE = (206, 202, 158)
ROCK = (34, 66, 72)
RED  = (166, 84, 74)
GOLD = (249, 191, 92)
INK  = (10, 22, 26)

# 三个区域：底板裁切（刻意避开原画中已绘制的角色，保证画面干净）、角色落点与身高
LEVELS = [
    dict(key='L02', file='L02_鲸口门庭.png', crop=(205, 28, 1190, 570),
         feet=430, hero_h=78, win_w=760, ff=0.78,
         name='鲸口门庭 · 鲸须筛'),
    dict(key='L03', file='L03_食道滑井.png', crop=(170, 42, 1290, 538),
         feet=380, hero_h=74, win_w=780, ff=0.70,
         name='食道滑井 · 高速滑道'),
    dict(key='L04', file='L04_胃库沼泽.png', crop=(130, 26, 902, 488),
         feet=300, hero_h=52, win_w=600, ff=0.68,
         name='胃库沼泽 · 浮桥菌阀'),
]

MODES = [
    ('01_纯2D横版', '① 纯 2D 横版'),
    ('02_2.5D横版', '② 2.5D 横版'),
    ('03_全3D第三人称', '③ 全 3D 第三人称'),
]

# 每区的操作提示（按键 → 动作 → 说明）
OPS = [
    ('长鸣', '激活骨鸣器', '鲸须筛随共鸣展开，让出通路'),
    ('S / SPACE', '抓褶皱 · 跃入水潭', '贴住食道褶皱减速，再纵身入水'),
    ('E / SPACE', '转菌阀 · 跳浮囊', '调节胃液，踏浮囊过沼泽'),
]


# ---------------- 资源加载 ----------------
def load_plates():
    """加载三张原画，按区域裁出宽景底板。

    裁切框已在 LEVELS 中刻意避开原画里已绘制的角色所在区域，
    因此底板天然干净，无需再做修补（历史涂抹方案均会留下痕迹，已弃用）。
    """
    plates = []
    for lv in LEVELS:
        im = Image.open(os.path.join(V2, lv['file'])).convert('RGB').crop(lv['crop'])
        plates.append(im)
    return plates


def load_hero():
    """从角色设定图按背景色抠出「拾潮者」，输出 RGBA 精灵。"""
    im = Image.open(CHAR_SRC).convert('RGB').crop((55, 30, 335, 480))
    a = np.array(im).astype(np.float32)
    bg = np.array([172, 163, 150], np.float32)
    dist = np.sqrt(((a - bg) ** 2).sum(2))
    al = np.clip((dist - 16) / (34 - 16), 0, 1)
    alpha = Image.fromarray((al * 255).astype(np.uint8))
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    out = im.convert('RGBA')
    out.putalpha(alpha)
    return out


# ---------------- 采样工具 ----------------
def sample(plate, cx, cy, win_w, out_w=W, out_h=H):
    """从底板按 16:9 窗口采样并缩放到输出尺寸；(cx,cy) 为窗口中心（底板坐标）。"""
    pw, ph = plate.size
    wh = win_w * out_h / out_w
    left = cx - win_w / 2.0
    top = cy - wh / 2.0
    left = max(0, min(pw - win_w, left))
    top = max(0, min(ph - wh, top))
    box = (int(round(left)), int(round(top)), int(round(left + win_w)), int(round(top + wh)))
    return plate.crop(box).resize((out_w, out_h), Image.LANCZOS)


def vgrad(w, h, top_a, bot_a, r, g, b):
    """生成竖直渐变覆盖层，用于雾/暗角。"""
    col = np.linspace(top_a, bot_a, h, dtype=np.float32)[:, None]
    arr = np.zeros((h, w, 4), np.float32)
    arr[..., 0], arr[..., 1], arr[..., 2] = r, g, b
    arr[..., 3] = np.repeat(col, w, axis=1)
    return Image.fromarray(arr.astype(np.uint8))


def paste_center(base, sprite, cx, feet_y):
    """把精灵按底边(y=feet_y)水平居中于 cx 贴到 base 上。"""
    px = int(round(cx - sprite.width / 2))
    py = int(round(feet_y - sprite.height))
    base.paste(sprite, (px, py), sprite)


def ground_shadow(base, cx, feet_y, rx, ry, alpha=90):
    """在脚底画一个柔和椭圆接触阴影。"""
    sh = Image.new('RGBA', (int(rx * 2), int(ry * 2)), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((0, 0, sh.width - 1, sh.height - 1), fill=(8, 18, 20, alpha))
    sh = sh.filter(ImageFilter.GaussianBlur(ry * 0.6))
    base.alpha_composite(sh, (int(cx - rx), int(feet_y - ry)))


# ---------------- 角色姿态 ----------------
def hero_sprite(base, pose, t):
    """按姿态对精灵做小幅变换，营造站立/行走/下滑/腾空的感觉。"""
    s = base
    if pose == 'walk':
        bob = math.sin(t * 14.0) * 2.0
        ang = math.sin(t * 14.0) * 3.0
        s = s.rotate(ang, resample=Image.BICUBIC, expand=True)
        return s, bob
    if pose == 'slide':
        s = s.rotate(-16, resample=Image.BICUBIC, expand=True)
        return s, 0.0
    if pose == 'air':
        s = s.rotate(8, resample=Image.BICUBIC, expand=True)
        return s, 0.0
    if pose == 'hold':
        return s, math.sin(t * 6.0) * 1.2
    return s, math.sin(t * 3.0) * 1.5   # idle


# ---------------- 特效 ----------------
def fx_rings(ov, cx, cy, t, k):
    """共鸣金环：从胸口扩散的同心圆。"""
    d = ImageDraw.Draw(ov)
    for i in range(3):
        p = (t * 0.9 + i * 0.33) % 1.0
        rr = 14 + p * 120 * k
        a = int(200 * (1 - p))
        d.ellipse((cx - rr, cy - rr * 0.7, cx + rr, cy + rr * 0.7),
                  outline=(GOLD[0], GOLD[1], GOLD[2], a), width=3)


def fx_streaks(ov, cx, cy, t, down=False):
    """滑行速度线。"""
    d = ImageDraw.Draw(ov)
    for i in range(7):
        p = (t * 2.2 + i * 0.17) % 1.0
        L = 26 + p * 70
        a = int(150 * (1 - p))
        y = cy - 26 + i * 8
        if down:
            d.line((cx + 10 + p * 40, y, cx + 10 + p * 40 + L * 0.5, y + L),
                   fill=(220, 235, 240, a), width=2)
        else:
            d.line((cx - 16, y, cx - 16 - L, y), fill=(220, 235, 240, a), width=2)


def fx_valve(ov, cx, cy, t):
    """菌阀：旋转的红色圆阀。"""
    d = ImageDraw.Draw(ov)
    rr = 20
    d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=(RED[0], RED[1], RED[2], 220), width=4)
    for i in range(4):
        a = t * 2.4 + i * math.pi / 2
        d.line((cx, cy, cx + math.cos(a) * rr, cy + math.sin(a) * rr),
               fill=(RED[0], RED[1], RED[2], 200), width=3)


def fx_bladders(ov, cx, feet, t):
    """浮囊：胃液上漂浮的软囊，随波起伏。"""
    d = ImageDraw.Draw(ov)
    for i, (dx, w, ph) in enumerate([(-150, 78, 0.2), (-30, 96, 0.9), (120, 84, 0.5)]):
        yy = feet + 26 + math.sin(t * 1.8 + ph * 6) * 4
        d.ellipse((cx + dx - w / 2, yy - 15, cx + dx + w / 2, yy + 15),
                  fill=(176, 190, 150, 120), outline=(120, 140, 104, 180), width=2)


def fx_splash(ov, cx, feet, t):
    """跃入水潭的水花。"""
    d = ImageDraw.Draw(ov)
    p = t % 1.0
    if p < 0.6:
        a = int(200 * (1 - p / 0.6))
        rr = 12 + p * 90
        d.arc((cx - rr, feet - rr * 0.5, cx + rr, feet + rr * 0.5), 200, 340,
              fill=(225, 240, 245, a), width=3)


def draw_hero_glow(ov, cx, cy, t):
    """菌灯暖光。"""
    rr = 40 + math.sin(t * 3.0) * 6
    ov.alpha_composite(_glow_disc(rr, GOLD, 70), (int(cx - rr), int(cy - rr)))


_GLOW_CACHE = {}


def _glow_disc(r, color, a):
    key = (int(r), color, a)
    if key in _GLOW_CACHE:
        return _GLOW_CACHE[key]
    n = int(r * 2)
    im = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i in range(10, 0, -1):
        rr = r * i / 10.0
        aa = int(a * (1 - i / 10.0) ** 1.6)
        d.ellipse((n / 2 - rr, n / 2 - rr, n / 2 + rr, n / 2 + rr),
                  fill=(color[0], color[1], color[2], aa))
    im = im.filter(ImageFilter.GaussianBlur(r * 0.25))
    _GLOW_CACHE[key] = im
    return im


# ---------------- 3D 粒子（第三人称用） ----------------
def make_particles(n=46):
    ps = []
    rng = np.random.default_rng(7)
    for _ in range(n):
        ps.append(dict(x=rng.uniform(-1, 1), y=rng.uniform(-0.6, 0.6),
                       z=rng.uniform(0.2, 1.0), r=rng.uniform(2, 6), sp=rng.uniform(0.05, 0.16)))
    return ps


def draw_particles(ov, ps, t):
    """透视投影的漂浮气泡/碎屑，营造三维纵深。"""
    d = ImageDraw.Draw(ov)
    for p in ps:
        z = (p['z'] - t * p['sp']) % 1.1 + 0.06          # 沿深度向镜头靠近并循环
        s = 1.0 / z
        sx = W / 2 + p['x'] * W * 0.62 * s
        sy = H * 0.42 - p['y'] * H * 0.55 * s
        rr = p['r'] * s * 0.9
        if rr < 0.6:
            continue
        a = int(min(150, 300 * z))
        d.ellipse((sx - rr, sy - rr, sx + rr, sy + rr),
                  fill=(214, 232, 230, a), outline=(255, 255, 255, min(200, a + 40)), width=1)


# ---------------- HUD ----------------
def font(sz):
    from PIL import ImageFont
    return ImageFont.truetype(FONT, sz)


def chip(d, xy, text, f, fg, bg, pad=(12, 6), alpha=210):
    x, y = xy
    bb = d.textbbox((0, 0), text, font=f)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    box = (x, y, x + w + pad[0] * 2, y + h + pad[1] * 2)
    d.rounded_rectangle(box, radius=8, fill=(bg[0], bg[1], bg[2], alpha))
    d.text((x + pad[0], y + pad[1] - bb[1]), text, font=f, fill=fg)
    return box


def draw_hud(frame, mi, mode_name, region, phase, tseg):
    d = ImageDraw.Draw(frame, 'RGBA')
    f_title = font(24)
    f_tag = font(19)
    f_key = font(23)
    f_txt = font(19)
    f_sm = font(16)

    # 顶部渐变条
    frame.alpha_composite(vgrad(W, 92, 165, 0, 6, 16, 20), (0, 0))
    chip(d, (22, 16), '鲸落万物生', f_title, (236, 238, 232, 255), (8, 20, 24), alpha=0)
    chip(d, (W - 175, 20), mode_name, f_tag, (12, 26, 30, 255), GOLD, alpha=235)

    # 区域名
    chip(d, (22, 52), region, f_tag, (240, 240, 230, 255), (18, 46, 48), alpha=180)

    # 底部操作区
    frame.alpha_composite(vgrad(W, 118, 0, 180, 6, 16, 20), (0, H - 118))
    key, act, cap = OPS[mi]
    kb = chip(d, (22, H - 100), key, f_key, (12, 26, 30, 255), GOLD, alpha=240)
    d.text((kb[2] + 12, H - 96), act, font=f_txt, fill=(240, 240, 232, 255))
    d.text((22, H - 46), cap, font=f_sm, fill=(196, 208, 200, 230))

    # 进度条
    bx0, bx1, by = W - 250, W - 22, H - 30
    d.rounded_rectangle((bx0, by, bx1, by + 6), radius=3, fill=(30, 52, 54, 200))
    prog = (mi + phase) / NSEG
    d.rounded_rectangle((bx0, by, bx0 + (bx1 - bx0) * prog, by + 6), radius=3, fill=GOLD)
    for i in range(1, NSEG):
        xx = bx0 + (bx1 - bx0) * i / NSEG
        d.line((xx, by - 3, xx, by + 9), fill=(180, 190, 180, 160), width=1)


# ---------------- 单帧合成 ----------------
def render_frame(plate, hero_base, lv, mode, mi, t):
    """按模式合成一帧。mi=当前区域序号，t=该区域内时间(0..SEG)。"""
    phase = t / SEG
    pw, ph = plate.size
    win_w = lv['win_w']
    wh = win_w * H / W

    # 相机：窗口中心沿底板水平推移；脚底在画面中的高度比例 ff
    cx0 = win_w / 2.0
    cx1 = pw - win_w / 2.0
    cam_center = cx0 + (cx1 - cx0) * phase

    if mode == 0:
        cy = (lv['feet'] - lv['ff'] * wh) + wh / 2.0
        bg = sample(plate, cam_center, cy, win_w)
    elif mode == 1:
        # 2.5D：背景缓慢、前景拍得多，制造视差
        far_w = win_w * 1.12
        cy = (lv['feet'] - lv['ff'] * wh) + wh / 2.0
        bg = sample(plate, cam_center, cy, far_w)
    else:
        # 3D 第三人称：推镜 + 轻微偏航
        dolly = 1.0 + 0.16 * phase
        cy = (lv['feet'] - lv['ff'] * wh) + wh / 2.0 - 0.02 * wh * phase
        bg = sample(plate, cam_center, cy, win_w / dolly)

    frame = bg.convert('RGBA')

    # 2.5D 前景层：画面底部一条柔和的近景地面快速掠过（浅、短，避免糊成污渍）
    if mode == 1:
        near_w = win_w * 1.32
        near = sample(plate, cam_center, cy + wh * 0.30, near_w)
        near = near.filter(ImageFilter.GaussianBlur(1.6))
        near = ImageChops.multiply(near.convert('RGB'), Image.new('RGB', near.size, (168, 178, 176)))
        m = Image.new('L', (W, H), 0)
        ImageDraw.Draw(m).rectangle((0, int(H * 0.84), W, H), fill=200)
        m = m.filter(ImageFilter.GaussianBlur(30))
        frame.paste(near.convert('RGB'), (0, 0), m)

    # 角色屏幕位置
    hero_screen_h = lv['hero_h'] * (W / win_w) * 1.15
    scale = hero_screen_h / hero_base.height
    sprite = hero_base.resize((max(1, int(hero_base.width * scale)), max(1, int(hero_screen_h))), Image.LANCZOS)

    hx = W * (0.40 if mode == 2 else 0.34)
    feet_y = (lv['feet'] - cy + wh / 2.0) * (H / wh)

    # 姿态与竖直位移
    pose = 'walk'
    vy = 0.0
    if mi == 1:                      # 食道滑井：下滑 → 抓握 → 腾空入水
        if phase < 0.45:
            pose = 'slide'
            feet_y += phase / 0.45 * (H * 0.46)
        elif phase < 0.68:
            pose = 'hold'
        else:
            pose = 'air'
            feet_y += H * 0.10
            q = (phase - 0.68) / 0.32
            vy = -math.sin(q * math.pi) * H * 0.16
    elif mi == 2:                    # 胃库沼泽：转阀 → 跳浮囊
        if phase < 0.4:
            pose = 'idle'
        else:
            pose = 'air'
            q = ((phase - 0.4) / 0.6) % 0.5 / 0.5
            vy = -math.sin(q * math.pi) * H * 0.14

    s2, bob = hero_sprite(sprite, pose, t)
    fx = Image.new('RGBA', (W, H), (0, 0, 0, 0))

    if mi == 0:
        draw_hero_glow(fx, hx, feet_y - hero_screen_h * 0.42, t)
        fx_rings(fx, hx, feet_y - hero_screen_h * 0.45, t, 1.0)
    elif mi == 1:
        fx_streaks(fx, hx, feet_y - hero_screen_h * 0.5, t, down=(pose == 'slide'))
        if phase >= 0.68:
            fx_splash(fx, hx, feet_y, phase)
    else:
        fx_valve(fx, hx + hero_screen_h * 1.1, feet_y - hero_screen_h * 0.9, t)
        fx_bladders(fx, hx, feet_y, t)

    if mode == 2:
        draw_particles(fx, PARTICLES, t + mi * SEG)

    ground_shadow(frame, hx, feet_y + bob, hero_screen_h * 1.15, hero_screen_h * 0.20,
                  alpha=80 if mode != 2 else 110)
    frame.alpha_composite(fx)
    paste_center(frame, s2, hx, feet_y + bob)

    # 模式专属后处理
    if mode == 2:
        # 3D：偏航剪切 + 雾 + 暗角
        sh = 0.035 * math.sin(t * 0.6)
        frame = frame.transform((W, H), Image.AFFINE, (1, sh, -sh * H / 2, 0, 1, 0), resample=Image.BICUBIC)
        frame.alpha_composite(vgrad(W, H, 0, 120, 8, 20, 26), (0, 0))
        frame.alpha_composite(_vignette(), (0, 0))
    else:
        frame.alpha_composite(vgrad(W, H, 0, 80, 8, 20, 26), (0, 0))

    draw_hud(frame, mi, MODES[mode][1], lv['name'], phase, t)
    return frame.convert('RGB')


_VIG = None


def _vignette():
    global _VIG
    if _VIG is None:
        y, x = np.mgrid[0:H, 0:W]
        d = np.sqrt(((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2)
        a = np.clip((d - 0.62) / 0.6, 0, 1) ** 1.5 * 150
        arr = np.zeros((H, W, 4), np.uint8)
        arr[..., 3] = a.astype(np.uint8)
        _VIG = Image.fromarray(arr)
    return _VIG


PARTICLES = None


# ---------------- 主流程 ----------------
def main():
    os.makedirs(OUT, exist_ok=True)
    global PARTICLES
    PARTICLES = make_particles()

    plates = load_plates()
    hero_base = load_hero()
    print('plates:', [p.size for p in plates], 'hero:', hero_base.size)

    import imageio_ffmpeg
    exe = imageio_ffmpeg.get_ffmpeg_exe()
    marks = [int(FPS * SEG * (s + 0.5)) for s in range(NSEG)]   # 每区域中点用于抽预览
    previews = []

    for mode, (fname, tag) in enumerate(MODES):
        path = os.path.join(OUT, fname + '.mp4')
        p = subprocess.Popen(
            [exe, '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
             '-r', str(FPS), '-i', '-', '-an', '-vcodec', 'libx264', '-crf', '20',
             '-pix_fmt', 'yuv420p', path],
            stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        shots = []
        for fi in range(NF):
            mi = min(NSEG - 1, fi // int(FPS * SEG))
            t = fi / FPS - mi * SEG
            frame = render_frame(plates[mi], hero_base, LEVELS[mi], mode, mi, t)
            p.stdin.write(frame.tobytes())
            if fi in marks:
                shot = frame.copy()
                shot.save(os.path.join(WORK, f'_pv_{mode}_{mi}.jpg'), quality=88)
                shots.append(shot)
        p.stdin.close()
        p.wait()
        previews.append(shots)
        print('done', fname)

    # 俯视九宫格对比图
    cw, ch = 480, 270
    grid = Image.new('RGB', (cw * 3, ch * 3), (12, 22, 26))
    for r in range(3):
        for c in range(3):
            grid.paste(previews[r][c].resize((cw, ch), Image.LANCZOS), (c * cw, r * ch))
    grid.save(os.path.join(OUT, '三种视角对比.jpg'), quality=90)
    print('grid saved')


if __name__ == '__main__':
    main()
