# -*- coding: utf-8 -*-
# 擦除预览 v5：同列纵向 1:1 平移覆盖（水平结构不变，最自然）
from PIL import Image, ImageDraw, ImageFilter
import os

WORK = r'G:\鲸落万物生\BOB\work\operation_demos'

# box=(l,t,r,b) 目标；off=(dx,dy) 采样平移（尽量同列、纵向）
PATCHES = {
    'L02': [((80, 336, 270, 472), (0, -150))],
    'L03': [((92, 372, 268, 468), (0, -170))],
    'L04': [((790, 292, 850, 360), (0, -110))],
}


def _erase(img, box, off):
    l, t, r, b = box
    dx, dy = off
    src = img.crop((l + dx, t + dy, r + dx, b + dy))
    mask = Image.new('L', (r - l, b - t), 0)
    inset = max(3, (b - t) // 10)
    ImageDraw.Draw(mask).rectangle((inset, inset, r - l - inset, b - t - inset), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(7, (b - t) // 6)))
    img.paste(src, (l, t), mask)
    return img


for k, ps in PATCHES.items():
    im = Image.open(os.path.join(WORK, f'_wide_{k}.png')).convert('RGB')
    for box, off in ps:
        _erase(im, box, off)
    if k == 'L02':
        c = im.crop((0, 290, 320, 490))
    elif k == 'L03':
        c = im.crop((60, 330, 340, 490))
    else:
        c = im.crop((700, 240, 920, 390))
    c = c.resize((int(c.width * 2.4), int(c.height * 2.4)), Image.NEAREST)
    c.save(os.path.join(WORK, f'_erasechk_{k}.png'))
    print(k, 'done')
print('saved')